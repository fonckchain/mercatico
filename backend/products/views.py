"""
Views for Products app.
"""
from rest_framework import viewsets, permissions, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
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

    @action(detail=True, methods=['post'], parser_classes=[MultiPartParser, FormParser])
    def upload_images(self, request, pk=None):
        """Upload images for a product."""
        product = self.get_object()

        # Check ownership
        if product.seller != request.user:
            return Response(
                {'error': 'No puedes subir imágenes a productos de otros vendedores'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get uploaded files
        files = request.FILES.getlist('images')

        if not files:
            return Response(
                {'error': 'No se proporcionaron imágenes'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validate max images
        current_images = product.images if product.images else []
        total_images = len(current_images) + len(files)

        if total_images > 5:
            return Response(
                {'error': 'Un producto puede tener máximo 5 imágenes'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Save images and collect URLs
        import os
        from django.core.files.storage import default_storage
        from django.conf import settings

        new_image_urls = []
        for image_file in files:
            # Validate file type
            allowed_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
            if image_file.content_type not in allowed_types:
                return Response(
                    {'error': f'Tipo de archivo no permitido: {image_file.content_type}'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Validate file size (max 5MB)
            if image_file.size > 5 * 1024 * 1024:
                return Response(
                    {'error': 'Las imágenes no pueden superar 5MB'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Generate unique filename
            import uuid
            ext = os.path.splitext(image_file.name)[1]
            filename = f'products/{product.id}/{uuid.uuid4()}{ext}'

            # Save file
            path = default_storage.save(filename, image_file)

            # Generate URL - diferente para filesystem vs Supabase
            if hasattr(default_storage, 'url'):
                # Supabase Storage o custom backend con método url()
                url = default_storage.url(path)
                print(f"📸 Supabase URL generated: {url}")
            else:
                # FileSystemStorage - usar URL relativa
                url = request.build_absolute_uri(settings.MEDIA_URL + path)
                print(f"📸 FileSystem URL generated: {url}")

            new_image_urls.append(url)

        # Update product images
        product.images = current_images + new_image_urls
        product.save()

        serializer = ProductSerializer(product)
        return Response(serializer.data)

    @action(detail=True, methods=['delete'])
    def delete_image(self, request, pk=None):
        """Delete a specific image from a product."""
        product = self.get_object()

        # Check ownership
        if product.seller != request.user:
            return Response(
                {'error': 'No puedes eliminar imágenes de productos de otros vendedores'},
                status=status.HTTP_403_FORBIDDEN
            )

        image_url = request.data.get('image_url')
        if not image_url:
            return Response(
                {'error': 'Se requiere la URL de la imagen'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not product.images or image_url not in product.images:
            return Response(
                {'error': 'Imagen no encontrada'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Remove image URL from list
        product.images.remove(image_url)
        product.save()

        # Delete file from storage
        try:
            from django.core.files.storage import default_storage
            from django.conf import settings
            from urllib.parse import urlparse

            # Extract path from URL
            if settings.SUPABASE_URL and image_url.startswith(settings.SUPABASE_URL):
                # Supabase URL: extraer path del bucket
                parsed = urlparse(image_url)
                # URL format: /storage/v1/object/public/{bucket}/{path}
                path_parts = parsed.path.split(f'/{settings.SUPABASE_BUCKET_NAME}/')
                if len(path_parts) > 1:
                    path = path_parts[1]
                else:
                    path = parsed.path.split('/')[-1]
            else:
                # FileSystemStorage URL local
                path = image_url.replace(request.build_absolute_uri(settings.MEDIA_URL), '')

            if default_storage.exists(path):
                default_storage.delete(path)
        except Exception as e:
            print(f"Error deleting file from storage: {e}")
            pass  # Continue even if file deletion fails

        serializer = ProductSerializer(product)
        return Response(serializer.data)
