"""
Views for Products app.
"""
from rest_framework import viewsets, permissions, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from products.models import Category, Product
from products.serializers import (
    CategorySerializer,
    ProductSerializer,
    ProductListSerializer,
    ProductDetailSerializer
)


class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for browsing product categories.
    """
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        """Filter by category type if provided."""
        queryset = super().get_queryset()

        category_type = self.request.query_params.get('type')
        if category_type:
            queryset = queryset.filter(category_type=category_type)

        return queryset


class ProductViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing products.
    """
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['category', 'seller', 'is_available']
    search_fields = ['name', 'description', 'seller__seller_profile__business_name']
    ordering_fields = ['price', 'created_at', 'sales_count', 'views_count']
    ordering = ['-created_at']

    def get_permissions(self):
        """Set permissions based on action."""
        if self.action in ['list', 'retrieve']:
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    def get_serializer_class(self):
        """Return appropriate serializer based on action."""
        if self.action == 'list':
            return ProductListSerializer
        elif self.action == 'retrieve':
            return ProductDetailSerializer
        return ProductSerializer

    def get_queryset(self):
        """Optimize queryset with select_related."""
        queryset = super().get_queryset()
        queryset = queryset.select_related('seller', 'category', 'seller__seller_profile')

        # Filter by seller's location
        province = self.request.query_params.get('province')
        if province:
            queryset = queryset.filter(seller__seller_profile__province=province)

        canton = self.request.query_params.get('canton')
        if canton:
            queryset = queryset.filter(seller__seller_profile__canton=canton)

        # Filter by price range
        min_price = self.request.query_params.get('min_price')
        if min_price:
            queryset = queryset.filter(price__gte=min_price)

        max_price = self.request.query_params.get('max_price')
        if max_price:
            queryset = queryset.filter(price__lte=max_price)

        # Only show available products for non-owners
        if not self.request.user.is_authenticated:
            queryset = queryset.filter(is_available=True, stock__gt=0)

        return queryset

    def perform_create(self, serializer):
        """Set seller to current user."""
        serializer.save(seller=self.request.user)

    def perform_update(self, serializer):
        """Only allow sellers to update their own products."""
        product = self.get_object()
        if product.seller != self.request.user:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("No puedes editar productos de otros vendedores")
        serializer.save()

    def perform_destroy(self, instance):
        """Only allow sellers to delete their own products."""
        if instance.seller != self.request.user:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("No puedes eliminar productos de otros vendedores")
        instance.delete()

    def retrieve(self, request, *args, **kwargs):
        """Increment view count when retrieving a product."""
        instance = self.get_object()
        instance.increment_views()
        serializer = self.get_serializer(instance)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def my_products(self, request):
        """Get products of the current seller."""
        if request.user.user_type != 'SELLER':
            return Response(
                {'error': 'Solo vendedores pueden acceder a esta funcionalidad'},
                status=403
            )

        queryset = self.get_queryset().filter(seller=request.user)
        page = self.paginate_queryset(queryset)

        if page is not None:
            serializer = ProductListSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = ProductListSerializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def featured(self, request):
        """Get featured products (top sellers)."""
        queryset = self.get_queryset().filter(
            is_available=True,
            stock__gt=0
        ).order_by('-sales_count')[:10]

        serializer = ProductListSerializer(queryset, many=True)
        return Response(serializer.data)
