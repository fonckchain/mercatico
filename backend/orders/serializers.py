"""
Serializers for orders app.
"""
from rest_framework import serializers
from orders.models import Order, OrderItem, OrderStatusHistory
from products.serializers import ProductSerializer
from users.serializers import UserSerializer


class OrderItemSerializer(serializers.ModelSerializer):
    """Serializer for order items."""
    product = ProductSerializer(read_only=True)
    product_id = serializers.UUIDField(write_only=True)

    class Meta:
        model = OrderItem
        fields = [
            'id',
            'product',
            'product_id',
            'product_name',
            'product_price',
            'quantity',
            'subtotal',
            'created_at',
        ]
        read_only_fields = ['id', 'subtotal', 'created_at']

    def create(self, validated_data):
        """Create order item and snapshot product details."""
        product = validated_data.pop('product_id')

        # Snapshot product details
        validated_data['product'] = product
        validated_data['product_name'] = product.name
        validated_data['product_price'] = product.price

        return super().create(validated_data)


class OrderStatusHistorySerializer(serializers.ModelSerializer):
    """Serializer for order status history."""
    changed_by_name = serializers.CharField(source='changed_by.get_full_name', read_only=True)

    class Meta:
        model = OrderStatusHistory
        fields = [
            'id',
            'status',
            'notes',
            'changed_by',
            'changed_by_name',
            'created_at',
        ]
        read_only_fields = ['id', 'created_at']


class OrderSerializer(serializers.ModelSerializer):
    """Serializer for orders."""
    items = OrderItemSerializer(many=True, read_only=True)
    buyer = UserSerializer(read_only=True)
    seller = UserSerializer(read_only=True)
    status_history = OrderStatusHistorySerializer(many=True, read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    delivery_method_display = serializers.CharField(source='get_delivery_method_display', read_only=True)
    payment_method_display = serializers.CharField(source='get_payment_method_display', read_only=True)

    class Meta:
        model = Order
        fields = [
            'id',
            'order_number',
            'buyer',
            'seller',
            'status',
            'status_display',
            'subtotal',
            'delivery_fee',
            'total',
            'delivery_method',
            'delivery_method_display',
            'delivery_address',
            'delivery_province',
            'delivery_canton',
            'delivery_district',
            'delivery_notes',
            'payment_method',
            'payment_method_display',
            'payment_proof',
            'payment_verified',
            'payment_verified_at',
            'buyer_phone',
            'buyer_email',
            'buyer_notes',
            'seller_notes',
            'items',
            'status_history',
            'created_at',
            'updated_at',
            'confirmed_at',
            'shipped_at',
            'delivered_at',
        ]
        read_only_fields = [
            'id',
            'order_number',
            'buyer',
            'seller',
            'subtotal',
            'total',
            'payment_verified',
            'payment_verified_at',
            'created_at',
            'updated_at',
            'confirmed_at',
            'shipped_at',
            'delivered_at',
        ]


class OrderCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating orders."""
    items = serializers.ListField(
        child=serializers.DictField(),
        write_only=True,
        help_text='List of items: [{"product_id": "uuid", "quantity": 1}]'
    )
    payment_proof = serializers.ImageField(required=False)
    delivery_fee = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        required=False,
        help_text='Delivery fee calculated by frontend'
    )

    class Meta:
        model = Order
        fields = [
            'seller',
            'delivery_method',
            'delivery_address',
            'delivery_province',
            'delivery_canton',
            'delivery_district',
            'delivery_notes',
            'delivery_fee',
            'payment_method',
            'payment_proof',
            'buyer_phone',
            'buyer_email',
            'buyer_notes',
            'items',
        ]

    def validate_items(self, value):
        """Validate that items list is not empty."""
        # If items comes as string (from FormData), parse it
        if isinstance(value, str):
            import json
            try:
                value = json.loads(value)
            except json.JSONDecodeError:
                raise serializers.ValidationError("Formato de items inválido")

        if not value:
            raise serializers.ValidationError("Debe incluir al menos un producto")
        return value

    def validate(self, data):
        """Validate that payment proof is provided for SINPE payments."""
        payment_method = data.get('payment_method')
        payment_proof = data.get('payment_proof')

        if payment_method == 'SINPE' and not payment_proof:
            raise serializers.ValidationError({
                'payment_proof': 'Debes subir el comprobante de pago para pagos con SINPE Móvil'
            })

        return data

    def create(self, validated_data):
        """Create order with items."""
        from django.db import transaction
        from products.models import Product
        from decimal import Decimal

        items_data = validated_data.pop('items')
        buyer = self.context['request'].user

        # Use transaction to ensure atomicity
        with transaction.atomic():
            # Pre-calculate subtotal from items before creating order
            subtotal = Decimal('0.00')
            for item_data in items_data:
                product = Product.objects.get(id=item_data['product_id'])
                subtotal += product.price * item_data['quantity']

            # Calculate total (subtotal + delivery fee)
            delivery_fee = validated_data.get('delivery_fee', Decimal('0.00'))
            total = subtotal + delivery_fee

            # Determine initial status based on payment method
            payment_method = validated_data.get('payment_method')
            initial_status = Order.OrderStatus.PAYMENT_PENDING if payment_method == 'SINPE' else Order.OrderStatus.PENDING

            # Create order with calculated totals
            order = Order.objects.create(
                buyer=buyer,
                subtotal=subtotal,
                total=total,
                status=initial_status,
                **validated_data
            )

            # Create order items and update stock
            for item_data in items_data:
                # Lock the product row for update to prevent race conditions
                product = Product.objects.select_for_update().get(id=item_data['product_id'])

                # Check stock
                if product.stock < item_data['quantity']:
                    raise serializers.ValidationError(
                        f"Stock insuficiente para {product.name}. Disponible: {product.stock}"
                    )

                # Create item
                OrderItem.objects.create(
                    order=order,
                    product=product,
                    product_name=product.name,
                    product_price=product.price,
                    quantity=item_data['quantity']
                )

                # Reduce stock
                product.stock -= item_data['quantity']
                product.save(update_fields=['stock'])

        return order


class OrderUpdateStatusSerializer(serializers.Serializer):
    """Serializer for updating order status."""
    status = serializers.ChoiceField(choices=Order.OrderStatus.choices)
    notes = serializers.CharField(required=False, allow_blank=True)

    def update(self, instance, validated_data):
        """Update order status and create history entry."""
        old_status = instance.status
        new_status = validated_data['status']

        # Update status
        instance.status = new_status

        # Update timestamp fields based on status
        if new_status == Order.OrderStatus.CONFIRMED and not instance.confirmed_at:
            from django.utils import timezone
            instance.confirmed_at = timezone.now()
        elif new_status == Order.OrderStatus.SHIPPED and not instance.shipped_at:
            from django.utils import timezone
            instance.shipped_at = timezone.now()
        elif new_status == Order.OrderStatus.DELIVERED and not instance.delivered_at:
            from django.utils import timezone
            instance.delivered_at = timezone.now()

        instance.save()

        # Create status history entry
        OrderStatusHistory.objects.create(
            order=instance,
            status=new_status,
            notes=validated_data.get('notes', f'Estado cambiado de {old_status} a {new_status}'),
            changed_by=self.context['request'].user
        )

        return instance
