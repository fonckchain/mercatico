"""
Views for payments app.
"""
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import OrderingFilter

from payments.models import PaymentReceipt, PaymentVerificationLog
from payments.serializers import (
    PaymentReceiptSerializer,
    PaymentReceiptUploadSerializer,
    PaymentVerificationLogSerializer,
    ManualReviewSerializer,
)
from users.models import User


class IsReceiptOwnerOrSeller(permissions.BasePermission):
    """
    Permission to only allow buyers to view their receipts
    and sellers to view receipts for their sales.
    """

    def has_object_permission(self, request, view, obj):
        # Admins can see everything
        if request.user.is_staff:
            return True

        # Buyer can see their own receipts
        if obj.order.buyer == request.user:
            return True

        # Seller can see receipts for their sales
        if obj.order.seller == request.user:
            return True

        return False


class PaymentReceiptViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing payment receipts.

    list: Get all payment receipts (filtered by user role)
    create: Upload a new payment receipt (buyers only)
    retrieve: Get receipt details
    destroy: Delete receipt (only if pending)

    Custom actions:
    - upload: Upload payment receipt
    - manual_review: Manually approve/reject receipt (sellers only)
    - verify_llm: Verify receipt using LLM (future implementation)
    """
    queryset = PaymentReceipt.objects.all().select_related(
        'order__buyer',
        'order__seller',
        'reviewed_by'
    )
    permission_classes = [permissions.IsAuthenticated, IsReceiptOwnerOrSeller]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ['verification_status', 'verified_by_llm']
    ordering_fields = ['created_at', 'updated_at']
    ordering = ['-created_at']

    def get_serializer_class(self):
        """Return appropriate serializer class."""
        if self.action == 'upload':
            return PaymentReceiptUploadSerializer
        elif self.action == 'manual_review':
            return ManualReviewSerializer
        return PaymentReceiptSerializer

    def get_queryset(self):
        """Filter queryset based on user type."""
        user = self.request.user
        queryset = super().get_queryset()

        # Admins see everything
        if user.is_staff:
            return queryset

        # Buyers see receipts for their purchases
        if user.user_type == User.UserType.BUYER:
            return queryset.filter(order__buyer=user)

        # Sellers see receipts for their sales
        if user.user_type == User.UserType.SELLER:
            return queryset.filter(order__seller=user)

        return queryset.none()

    def perform_create(self, serializer):
        """Create receipt as buyer."""
        if self.request.user.user_type != User.UserType.BUYER:
            raise permissions.PermissionDenied(
                "Solo los compradores pueden subir comprobantes de pago"
            )
        serializer.save()

    def perform_destroy(self, instance):
        """Only allow deletion of pending receipts."""
        if instance.verification_status != PaymentReceipt.VerificationStatus.PENDING:
            raise permissions.PermissionDenied(
                "Solo se pueden eliminar comprobantes pendientes"
            )
        super().perform_destroy(instance)

    @action(detail=False, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def upload(self, request):
        """
        Upload a payment receipt for an order.
        Only buyers can upload receipts.
        """
        if request.user.user_type != User.UserType.BUYER:
            return Response(
                {'detail': 'Solo los compradores pueden subir comprobantes'},
                status=status.HTTP_403_FORBIDDEN
            )

        serializer = PaymentReceiptUploadSerializer(
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        receipt = serializer.save()

        return Response(
            PaymentReceiptSerializer(receipt).data,
            status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def manual_review(self, request, pk=None):
        """
        Manually approve or reject a payment receipt.
        Only sellers can review receipts for their sales.
        """
        receipt = self.get_object()

        # Only seller or admin can review
        if receipt.order.seller != request.user and not request.user.is_staff:
            return Response(
                {'detail': 'Solo el vendedor puede revisar el comprobante'},
                status=status.HTTP_403_FORBIDDEN
            )

        serializer = ManualReviewSerializer(
            receipt,
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()

        return Response(PaymentReceiptSerializer(receipt).data)

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def verify_llm(self, request, pk=None):
        """
        Verify payment receipt using LLM (Grok AI).
        Future implementation - requires Grok API setup.
        """
        receipt = self.get_object()

        # Check if seller or admin
        if receipt.order.seller != request.user and not request.user.is_staff:
            return Response(
                {'detail': 'Solo el vendedor puede verificar el comprobante'},
                status=status.HTTP_403_FORBIDDEN
            )

        return Response(
            {
                'detail': 'Verificación con LLM no implementada aún',
                'message': 'Por favor, usa la revisión manual por ahora',
                'endpoint': f'/api/payments/{pk}/manual_review/'
            },
            status=status.HTTP_501_NOT_IMPLEMENTED
        )

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def pending(self, request):
        """Get all pending payment receipts for the current seller."""
        if request.user.user_type != User.UserType.SELLER:
            return Response(
                {'detail': 'Solo los vendedores pueden ver comprobantes pendientes'},
                status=status.HTTP_403_FORBIDDEN
            )

        receipts = self.get_queryset().filter(
            order__seller=request.user,
            verification_status=PaymentReceipt.VerificationStatus.PENDING
        )

        page = self.paginate_queryset(receipts)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(receipts, many=True)
        return Response(serializer.data)


class PaymentVerificationLogViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing payment verification logs.
    Read-only - logs are created automatically.
    """
    queryset = PaymentVerificationLog.objects.all().select_related(
        'receipt',
        'performed_by'
    )
    serializer_class = PaymentVerificationLogSerializer
    permission_classes = [permissions.IsAdminUser]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ['action', 'success']
    ordering = ['-created_at']
