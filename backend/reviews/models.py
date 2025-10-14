"""
Review models for MercaTico.
"""
import uuid
from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from users.models import User
from orders.models import Order


class Review(models.Model):
    """
    Product/Seller review model.
    Buyers can review sellers after receiving their order.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    # Relationships
    order = models.OneToOneField(
        Order,
        on_delete=models.CASCADE,
        related_name='review'
    )
    buyer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='reviews_given',
        limit_choices_to={'user_type': User.UserType.BUYER}
    )
    seller = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='reviews_received',
        limit_choices_to={'user_type': User.UserType.SELLER}
    )

    # Review content
    rating = models.IntegerField(
        'calificación',
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        help_text='Calificación de 1 a 5 estrellas'
    )
    comment = models.TextField(
        'comentario',
        max_length=1000,
        blank=True,
        help_text='Comentario opcional sobre la experiencia de compra'
    )

    # Categories for detailed feedback
    product_quality = models.IntegerField(
        'calidad del producto',
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        null=True,
        blank=True
    )
    seller_communication = models.IntegerField(
        'comunicación del vendedor',
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        null=True,
        blank=True
    )
    delivery_speed = models.IntegerField(
        'rapidez de entrega',
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        null=True,
        blank=True
    )

    # Moderation
    is_visible = models.BooleanField('visible', default=True)
    is_flagged = models.BooleanField('marcada', default=False)
    flag_reason = models.TextField('razón de marcado', blank=True)

    # Seller response
    seller_response = models.TextField('respuesta del vendedor', blank=True)
    seller_responded_at = models.DateTimeField('fecha de respuesta', null=True, blank=True)

    # Timestamps
    created_at = models.DateTimeField('fecha de creación', auto_now_add=True)
    updated_at = models.DateTimeField('última actualización', auto_now=True)

    class Meta:
        verbose_name = 'reseña'
        verbose_name_plural = 'reseñas'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['seller', '-created_at']),
            models.Index(fields=['buyer', '-created_at']),
            models.Index(fields=['-rating', '-created_at']),
            models.Index(fields=['is_visible', '-created_at']),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=['order'],
                name='unique_review_per_order'
            )
        ]

    def __str__(self):
        return f"Reseña de {self.buyer.get_full_name()} para {self.seller.seller_profile.business_name} - {self.rating}★"

    def save(self, *args, **kwargs):
        """Ensure buyer and seller are from the order."""
        if not self.pk:  # Only on creation
            self.buyer = self.order.buyer
            self.seller = self.order.seller
        super().save(*args, **kwargs)


class ReviewReport(models.Model):
    """
    Model to handle reports on inappropriate reviews.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    review = models.ForeignKey(
        Review,
        on_delete=models.CASCADE,
        related_name='reports'
    )
    reported_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='review_reports'
    )

    reason = models.CharField(
        'razón',
        max_length=50,
        choices=[
            ('SPAM', 'Spam'),
            ('INAPPROPRIATE', 'Contenido inapropiado'),
            ('FAKE', 'Reseña falsa'),
            ('OFFENSIVE', 'Lenguaje ofensivo'),
            ('OTHER', 'Otro'),
        ]
    )
    description = models.TextField('descripción', max_length=500)

    # Status
    status = models.CharField(
        'estado',
        max_length=20,
        choices=[
            ('PENDING', 'Pendiente'),
            ('REVIEWED', 'Revisado'),
            ('RESOLVED', 'Resuelto'),
            ('DISMISSED', 'Descartado'),
        ],
        default='PENDING'
    )
    admin_notes = models.TextField('notas del administrador', blank=True)

    # Timestamps
    created_at = models.DateTimeField('fecha de reporte', auto_now_add=True)
    resolved_at = models.DateTimeField('fecha de resolución', null=True, blank=True)

    class Meta:
        verbose_name = 'reporte de reseña'
        verbose_name_plural = 'reportes de reseñas'
        ordering = ['-created_at']

    def __str__(self):
        return f"Reporte de {self.reported_by.get_full_name()} - {self.get_reason_display()}"
