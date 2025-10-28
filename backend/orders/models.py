"""
Order models for MercaTico.
"""
import uuid
from django.db import models
from django.core.validators import MinValueValidator
from users.models import User
from products.models import Product


class Order(models.Model):
    """
    Order model representing a purchase transaction.
    """

    class OrderStatus(models.TextChoices):
        PENDING = 'PENDING', 'Pendiente'
        PAYMENT_PENDING = 'PAYMENT_PENDING', 'Pago pendiente de verificación'
        CONFIRMED = 'CONFIRMED', 'Confirmada'
        PROCESSING = 'PROCESSING', 'En proceso'
        SHIPPED = 'SHIPPED', 'Listo para entrega'
        DELIVERED = 'DELIVERED', 'Entregado'
        CANCELLED = 'CANCELLED', 'Cancelado'
        REFUNDED = 'REFUNDED', 'Reembolsado'

    class DeliveryMethod(models.TextChoices):
        PICKUP = 'PICKUP', 'Recogida local'
        DELIVERY = 'DELIVERY', 'Envío a domicilio'

    class PaymentMethod(models.TextChoices):
        SINPE = 'SINPE', 'SINPE Móvil'
        CASH = 'CASH', 'Efectivo contra entrega'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    # User relationships
    buyer = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name='purchases',
        limit_choices_to={'user_type': User.UserType.BUYER}
    )
    seller = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name='sales',
        limit_choices_to={'user_type': User.UserType.SELLER}
    )

    # Order information
    order_number = models.CharField(
        'número de orden',
        max_length=20,
        unique=True,
        editable=False
    )
    status = models.CharField(
        'estado',
        max_length=20,
        choices=OrderStatus.choices,
        default=OrderStatus.PENDING
    )

    # Pricing
    subtotal = models.DecimalField(
        'subtotal',
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(0)]
    )
    delivery_fee = models.DecimalField(
        'costo de envío',
        max_digits=10,
        decimal_places=2,
        default=0,
        validators=[MinValueValidator(0)]
    )
    total = models.DecimalField(
        'total',
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(0)]
    )

    # Delivery information
    delivery_method = models.CharField(
        'método de entrega',
        max_length=20,
        choices=DeliveryMethod.choices,
        default=DeliveryMethod.DELIVERY
    )
    delivery_address = models.TextField('dirección de entrega', blank=True)
    delivery_province = models.CharField('provincia', max_length=50, blank=True)
    delivery_canton = models.CharField('cantón', max_length=50, blank=True)
    delivery_district = models.CharField('distrito', max_length=50, blank=True)
    delivery_notes = models.TextField('notas de entrega', blank=True)

    # Payment information
    payment_method = models.CharField(
        'método de pago',
        max_length=20,
        choices=PaymentMethod.choices,
        default=PaymentMethod.SINPE
    )
    payment_proof = models.ImageField(
        'comprobante de pago',
        upload_to='payment_proofs/',
        null=True,
        blank=True,
        help_text='Screenshot del comprobante de pago SINPE'
    )
    payment_verified = models.BooleanField('pago verificado', default=False)
    payment_verified_at = models.DateTimeField('fecha de verificación de pago', null=True, blank=True)

    # Buyer contact information
    buyer_phone = models.CharField('teléfono del comprador', max_length=17)
    buyer_email = models.EmailField('correo del comprador', max_length=255)

    # Notes
    buyer_notes = models.TextField('notas del comprador', blank=True)
    seller_notes = models.TextField('notas del vendedor', blank=True)

    # Timestamps
    created_at = models.DateTimeField('fecha de creación', auto_now_add=True)
    updated_at = models.DateTimeField('última actualización', auto_now=True)
    confirmed_at = models.DateTimeField('fecha de confirmación', null=True, blank=True)
    shipped_at = models.DateTimeField('fecha de envío', null=True, blank=True)
    delivered_at = models.DateTimeField('fecha de entrega', null=True, blank=True)

    class Meta:
        verbose_name = 'orden'
        verbose_name_plural = 'órdenes'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['buyer', '-created_at']),
            models.Index(fields=['seller', '-created_at']),
            models.Index(fields=['status', '-created_at']),
            models.Index(fields=['order_number']),
        ]

    def __str__(self):
        return f"Orden {self.order_number} - {self.buyer.get_full_name()}"

    def save(self, *args, **kwargs):
        """Generate order number if not exists."""
        if not self.order_number:
            # Generate order number: YYYYMMDD-UUID[:6] (max 20 chars: 8 + 1 + 6 + 5 = 20)
            from django.utils import timezone
            date_str = timezone.now().strftime('%Y%m%d')
            uuid_str = str(self.id)[:6].upper()
            self.order_number = f"{date_str}-{uuid_str}"
        super().save(*args, **kwargs)

    def calculate_total(self):
        """Calculate order total from items."""
        items_total = sum(item.subtotal for item in self.items.all())
        self.subtotal = items_total
        self.total = self.subtotal + self.delivery_fee
        self.save(update_fields=['subtotal', 'total'])

    def confirm_payment(self):
        """Mark payment as verified and update status."""
        from django.utils import timezone
        self.payment_verified = True
        self.payment_verified_at = timezone.now()
        if self.status == self.OrderStatus.PAYMENT_PENDING:
            self.status = self.OrderStatus.CONFIRMED
            self.confirmed_at = timezone.now()
        self.save(update_fields=['payment_verified', 'payment_verified_at', 'status', 'confirmed_at'])

    def can_be_reviewed(self):
        """Check if order can be reviewed (delivered and not yet reviewed)."""
        return (
            self.status == self.OrderStatus.DELIVERED and
            not hasattr(self, 'review')
        )


class OrderItem(models.Model):
    """
    Individual items in an order.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    order = models.ForeignKey(
        Order,
        on_delete=models.CASCADE,
        related_name='items'
    )
    product = models.ForeignKey(
        Product,
        on_delete=models.PROTECT,
        related_name='order_items'
    )

    # Product snapshot (in case product details change)
    product_name = models.CharField('nombre del producto', max_length=200)
    product_price = models.DecimalField(
        'precio unitario',
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(0)]
    )

    quantity = models.IntegerField(
        'cantidad',
        default=1,
        validators=[MinValueValidator(1)]
    )
    subtotal = models.DecimalField(
        'subtotal',
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(0)]
    )

    created_at = models.DateTimeField('fecha de creación', auto_now_add=True)

    class Meta:
        verbose_name = 'item de orden'
        verbose_name_plural = 'items de orden'
        ordering = ['order', 'created_at']

    def __str__(self):
        return f"{self.quantity}x {self.product_name} - Orden {self.order.order_number}"

    def save(self, *args, **kwargs):
        """Calculate subtotal on save."""
        self.subtotal = self.product_price * self.quantity
        super().save(*args, **kwargs)


class OrderStatusHistory(models.Model):
    """
    Track status changes for orders.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey(
        Order,
        on_delete=models.CASCADE,
        related_name='status_history'
    )
    status = models.CharField(
        'estado',
        max_length=20,
        choices=Order.OrderStatus.choices
    )
    notes = models.TextField('notas', blank=True)
    changed_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )
    created_at = models.DateTimeField('fecha de cambio', auto_now_add=True)

    class Meta:
        verbose_name = 'historial de estado'
        verbose_name_plural = 'historiales de estado'
        ordering = ['order', '-created_at']

    def __str__(self):
        return f"{self.order.order_number} - {self.get_status_display()} - {self.created_at}"
