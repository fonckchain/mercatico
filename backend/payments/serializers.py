"""
Serializers for payments app.
"""
from rest_framework import serializers
from payments.models import PaymentReceipt, PaymentVerificationLog
from orders.models import Order


class PaymentReceiptSerializer(serializers.ModelSerializer):
    """Serializer for payment receipts."""
    order_number = serializers.CharField(source='order.order_number', read_only=True)
    order_total = serializers.DecimalField(
        source='order.total',
        max_digits=10,
        decimal_places=2,
        read_only=True
    )
    verification_status_display = serializers.CharField(
        source='get_verification_status_display',
        read_only=True
    )

    class Meta:
        model = PaymentReceipt
        fields = [
            'id',
            'order',
            'order_number',
            'order_total',
            'receipt_image',
            'verification_status',
            'verification_status_display',
            'extracted_data',
            'verification_notes',
            'verified_by_llm',
            'llm_confidence',
            'reviewed_by',
            'created_at',
            'updated_at',
            'expires_at',
        ]
        read_only_fields = [
            'id',
            'verification_status',
            'extracted_data',
            'verification_notes',
            'verified_by_llm',
            'llm_confidence',
            'reviewed_by',
            'created_at',
            'updated_at',
            'expires_at',
        ]

    def validate_order(self, value):
        """Validate that order doesn't already have a receipt."""
        if hasattr(value, 'payment_receipt'):
            raise serializers.ValidationError(
                "Esta orden ya tiene un comprobante de pago"
            )

        # Validate order belongs to current user
        user = self.context['request'].user
        if value.buyer != user:
            raise serializers.ValidationError(
                "Solo puedes subir comprobantes para tus propias órdenes"
            )

        return value


class PaymentReceiptUploadSerializer(serializers.Serializer):
    """Serializer for uploading payment receipt."""
    order_id = serializers.UUIDField()
    receipt_image = serializers.ImageField()

    def validate_order_id(self, value):
        """Validate order exists and belongs to user."""
        try:
            order = Order.objects.get(id=value)
        except Order.DoesNotExist:
            raise serializers.ValidationError("Orden no encontrada")

        # Check if order already has a receipt
        if hasattr(order, 'payment_receipt'):
            raise serializers.ValidationError(
                "Esta orden ya tiene un comprobante de pago"
            )

        # Validate order belongs to current user
        user = self.context['request'].user
        if order.buyer != user:
            raise serializers.ValidationError(
                "Solo puedes subir comprobantes para tus propias órdenes"
            )

        return value

    def create(self, validated_data):
        """Create payment receipt."""
        order = Order.objects.get(id=validated_data['order_id'])

        receipt = PaymentReceipt.objects.create(
            order=order,
            receipt_image=validated_data['receipt_image'],
            verification_status=PaymentReceipt.VerificationStatus.PENDING
        )

        # Update order status
        if order.status == Order.OrderStatus.PENDING:
            order.status = Order.OrderStatus.PAYMENT_PENDING
            order.save()

        return receipt


class PaymentVerificationLogSerializer(serializers.ModelSerializer):
    """Serializer for payment verification logs."""
    performed_by_name = serializers.CharField(
        source='performed_by.get_full_name',
        read_only=True
    )

    class Meta:
        model = PaymentVerificationLog
        fields = [
            'id',
            'receipt',
            'action',
            'llm_response',
            'success',
            'error_message',
            'performed_by',
            'performed_by_name',
            'created_at',
        ]
        read_only_fields = ['id', 'created_at']


class ManualReviewSerializer(serializers.Serializer):
    """Serializer for manual payment review."""
    approved = serializers.BooleanField()
    notes = serializers.CharField(required=False, allow_blank=True)

    def update(self, instance, validated_data):
        """Update receipt verification status."""
        if validated_data['approved']:
            instance.verification_status = PaymentReceipt.VerificationStatus.APPROVED
            instance.order.confirm_payment()
        else:
            instance.verification_status = PaymentReceipt.VerificationStatus.REJECTED

        instance.verification_notes = validated_data.get('notes', '')
        instance.reviewed_by = self.context['request'].user
        instance.save()

        # Create verification log
        PaymentVerificationLog.objects.create(
            receipt=instance,
            action='MANUAL_REVIEW',
            llm_response={'manual_review': True, 'approved': validated_data['approved']},
            success=True,
            performed_by=self.context['request'].user
        )

        return instance
