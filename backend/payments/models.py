"""
Payment models for MercaTico.
Handles SINPE Móvil payment verification using LLM.
"""
import uuid
from django.db import models
from django.utils import timezone
from datetime import timedelta
from django.conf import settings
from orders.models import Order


class PaymentReceipt(models.Model):
    """
    Model to store and verify SINPE Móvil payment receipts.
    """

    class VerificationStatus(models.TextChoices):
        PENDING = 'PENDING', 'Pendiente'
        VERIFYING = 'VERIFYING', 'Verificando'
        APPROVED = 'APPROVED', 'Aprobado'
        REJECTED = 'REJECTED', 'Rechazado'
        MANUAL_REVIEW = 'MANUAL_REVIEW', 'Revisión manual'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    # Order relationship
    order = models.OneToOneField(
        Order,
        on_delete=models.CASCADE,
        related_name='payment_receipt'
    )

    # Receipt image (encrypted URL or base64)
    receipt_image = models.ImageField(
        'comprobante',
        upload_to='receipts/%Y/%m/%d/',
        help_text='Captura de pantalla del comprobante SINPE Móvil'
    )

    # Verification status
    verification_status = models.CharField(
        'estado de verificación',
        max_length=20,
        choices=VerificationStatus.choices,
        default=VerificationStatus.PENDING
    )

    # Extracted data from LLM (stored as JSON)
    extracted_data = models.JSONField(
        'datos extraídos',
        default=dict,
        blank=True,
        help_text='Datos extraídos del comprobante por el LLM'
    )
    """
    Expected structure:
    {
        "amount": "12500.00",
        "receiver_phone": "+50612345678",
        "sender_phone": "+50687654321",
        "transaction_id": "ABC123456",
        "transaction_date": "2024-01-15T14:30:00",
        "bank": "Banco Nacional"
    }
    """

    # Verification details
    verification_notes = models.TextField('notas de verificación', blank=True)
    verified_by_llm = models.BooleanField('verificado por LLM', default=False)
    llm_confidence = models.DecimalField(
        'confianza del LLM',
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        help_text='Nivel de confianza del LLM (0-100%)'
    )

    # Manual review
    reviewed_manually = models.BooleanField('revisado manualmente', default=False)
    reviewed_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reviewed_receipts'
    )
    manual_review_notes = models.TextField('notas de revisión manual', blank=True)

    # Timestamps
    created_at = models.DateTimeField('fecha de subida', auto_now_add=True)
    verified_at = models.DateTimeField('fecha de verificación', null=True, blank=True)
    expires_at = models.DateTimeField('fecha de expiración', null=True, blank=True)

    class Meta:
        verbose_name = 'comprobante de pago'
        verbose_name_plural = 'comprobantes de pago'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['order']),
            models.Index(fields=['verification_status', '-created_at']),
            models.Index(fields=['-expires_at']),
        ]

    def __str__(self):
        return f"Comprobante {self.order.order_number} - {self.get_verification_status_display()}"

    def save(self, *args, **kwargs):
        """Set expiration date on creation."""
        if not self.expires_at:
            days = settings.RECEIPT_STORAGE_DAYS
            self.expires_at = timezone.now() + timedelta(days=days)
        super().save(*args, **kwargs)

    def is_expired(self):
        """Check if receipt has expired."""
        return timezone.now() > self.expires_at

    def approve(self, notes=''):
        """Approve the payment receipt."""
        self.verification_status = self.VerificationStatus.APPROVED
        self.verified_at = timezone.now()
        self.verification_notes = notes
        self.save(update_fields=['verification_status', 'verified_at', 'verification_notes'])

        # Update order payment status
        self.order.confirm_payment()

    def reject(self, notes=''):
        """Reject the payment receipt."""
        self.verification_status = self.VerificationStatus.REJECTED
        self.verified_at = timezone.now()
        self.verification_notes = notes
        self.save(update_fields=['verification_status', 'verified_at', 'verification_notes'])

    def request_manual_review(self, notes=''):
        """Request manual review by seller."""
        self.verification_status = self.VerificationStatus.MANUAL_REVIEW
        self.verification_notes = notes
        self.save(update_fields=['verification_status', 'verification_notes'])

    def verify_with_llm_results(self, extracted_data, confidence, approved=True):
        """
        Update receipt with LLM verification results.

        Args:
            extracted_data (dict): Data extracted by LLM
            confidence (float): Confidence level (0-100)
            approved (bool): Whether verification passed
        """
        self.extracted_data = extracted_data
        self.llm_confidence = confidence
        self.verified_by_llm = True

        if approved and confidence >= 80:  # High confidence approval
            self.approve(notes='Verificado automáticamente por LLM')
        elif confidence < 50 or not approved:  # Low confidence or failed
            self.request_manual_review(notes='Confianza baja, requiere revisión manual')
        else:  # Medium confidence
            self.request_manual_review(notes='Requiere confirmación del vendedor')

        self.save(update_fields=['extracted_data', 'llm_confidence', 'verified_by_llm'])


class PaymentVerificationLog(models.Model):
    """
    Log all verification attempts for auditing.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    receipt = models.ForeignKey(
        PaymentReceipt,
        on_delete=models.CASCADE,
        related_name='verification_logs'
    )

    # Verification details
    verification_method = models.CharField(
        'método de verificación',
        max_length=20,
        choices=[
            ('LLM', 'LLM Automático'),
            ('MANUAL', 'Revisión Manual'),
        ]
    )
    result = models.CharField(
        'resultado',
        max_length=20,
        choices=[
            ('APPROVED', 'Aprobado'),
            ('REJECTED', 'Rechazado'),
            ('PENDING', 'Pendiente'),
        ]
    )
    details = models.JSONField('detalles', default=dict)
    performed_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )

    # Timestamp
    created_at = models.DateTimeField('fecha', auto_now_add=True)

    class Meta:
        verbose_name = 'log de verificación'
        verbose_name_plural = 'logs de verificación'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.verification_method} - {self.result} - {self.created_at}"
