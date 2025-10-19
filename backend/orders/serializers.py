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
            'payment_method',
            'buyer_phone',
            'buyer_email',
            'buyer_notes',
            'items',
        ]

    def validate_items(self, value):
        """Validate that items list is not empty."""
        if not value:
            raise serializers.ValidationError("Debe incluir al menos un producto")
        return value

    def create(self, validated_data):
        """Create order with items."""
        items_data = validated_data.pop('items')
        buyer = self.context['request'].user

        # Create order
        order = Order.objects.create(
            buyer=buyer,
            **validated_data
        )

        # Create order items
        from products.models import Product

        for item_data in items_data:
            product = Product.objects.get(id=item_data['product_id'])

            # Check stock
            if product.stock < item_data['quantity']:
                order.delete()
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
            product.save()

        # Calculate totals
        order.calculate_total()

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
