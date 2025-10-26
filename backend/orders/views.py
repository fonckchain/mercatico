"""
Views for orders app.
"""
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import OrderingFilter, SearchFilter

from orders.models import Order, OrderItem
from orders.serializers import (
    OrderSerializer,
    OrderCreateSerializer,
    OrderUpdateStatusSerializer,
    OrderItemSerializer,
)
from users.models import User


class IsOrderParticipant(permissions.BasePermission):
    """
    Permission to only allow buyers to view their purchases
    and sellers to view their sales.
    """

    def has_object_permission(self, request, view, obj):
        # Admins can see everything
        if request.user.is_staff:
            return True

        # Buyer can see their purchases
        if obj.buyer == request.user:
            return True

        # Seller can see their sales
        if obj.seller == request.user:
            return True

        return False


class OrderViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing orders.

    list: Get all orders (filtered by user role)
    create: Create a new order (buyers only)
    retrieve: Get order details
    update: Update order (limited fields)
    partial_update: Partially update order
    destroy: Cancel order

    Custom actions:
    - update_status: Update order status (sellers only)
    - my_purchases: Get current user's purchases (buyers)
    - my_sales: Get current user's sales (sellers)
    """
    queryset = Order.objects.all().select_related(
        'buyer',
        'seller',
        'seller__seller_profile'
    ).prefetch_related(
        'items__product',
        'status_history'
    )
    permission_classes = [permissions.IsAuthenticated, IsOrderParticipant]
    filter_backends = [DjangoFilterBackend, OrderingFilter, SearchFilter]
    filterset_fields = ['status', 'payment_method', 'delivery_method', 'payment_verified']
    ordering_fields = ['created_at', 'total', 'status']
    ordering = ['-created_at']
    search_fields = ['order_number', 'buyer__email', 'seller__email']

    def get_serializer_class(self):
        """Return appropriate serializer class."""
        if self.action == 'create':
            return OrderCreateSerializer
        elif self.action == 'update_status':
            return OrderUpdateStatusSerializer
        return OrderSerializer

    def get_queryset(self):
        """Filter queryset based on user type."""
        user = self.request.user
        queryset = super().get_queryset()

        # Admins see everything
        if user.is_staff:
            return queryset

        # Buyers see their purchases
        if user.user_type == User.UserType.BUYER:
            return queryset.filter(buyer=user)

        # Sellers see their sales
        if user.user_type == User.UserType.SELLER:
            return queryset.filter(seller=user)

        return queryset.none()

    def perform_create(self, serializer):
        """Create order as buyer."""
        if self.request.user.user_type != User.UserType.BUYER:
            raise permissions.PermissionDenied("Solo los compradores pueden crear órdenes")
        serializer.save()

    def perform_destroy(self, instance):
        """Cancel order instead of deleting."""
        from django.db import transaction

        if instance.status not in [Order.OrderStatus.PENDING, Order.OrderStatus.PAYMENT_PENDING]:
            raise permissions.PermissionDenied(
                "Solo se pueden cancelar órdenes en estado Pendiente o Pago Pendiente"
            )

        # Use transaction to ensure atomicity
        with transaction.atomic():
            # Restore stock for all items in the order
            for item in instance.items.all():
                product = item.product
                product.stock += item.quantity
                product.save(update_fields=['stock'])

            instance.status = Order.OrderStatus.CANCELLED
            instance.save()

            # Create status history
            from orders.models import OrderStatusHistory
            OrderStatusHistory.objects.create(
                order=instance,
                status=Order.OrderStatus.CANCELLED,
                notes="Orden cancelada por el usuario",
                changed_by=self.request.user
            )

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def update_status(self, request, pk=None):
        """
        Update order status.
        Only sellers can update their sales status.
        """
        order = self.get_object()

        # Only seller can update status
        if order.seller != request.user and not request.user.is_staff:
            return Response(
                {'detail': 'Solo el vendedor puede actualizar el estado de la orden'},
                status=status.HTTP_403_FORBIDDEN
            )

        serializer = OrderUpdateStatusSerializer(
            order,
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()

        return Response(OrderSerializer(order).data)

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def my_purchases(self, request):
        """Get current user's purchases (buyers only)."""
        if request.user.user_type != User.UserType.BUYER:
            return Response(
                {'detail': 'Solo los compradores pueden ver sus compras'},
                status=status.HTTP_403_FORBIDDEN
            )

        orders = self.get_queryset().filter(buyer=request.user)
        page = self.paginate_queryset(orders)

        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(orders, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def my_sales(self, request):
        """Get current user's sales (sellers only)."""
        if request.user.user_type != User.UserType.SELLER:
            return Response(
                {'detail': 'Solo los vendedores pueden ver sus ventas'},
                status=status.HTTP_403_FORBIDDEN
            )

        orders = self.get_queryset().filter(seller=request.user)
        page = self.paginate_queryset(orders)

        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(orders, many=True)
        return Response(serializer.data)
