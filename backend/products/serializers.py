"""
Serializers for Products app.
"""
from rest_framework import serializers
from products.models import Category, Product, ProductImage
from users.serializers import PublicSellerProfileSerializer


class CategorySerializer(serializers.ModelSerializer):
    """Serializer for Category model."""

    class Meta:
        model = Category
        fields = ['id', 'name', 'category_type', 'description', 'icon', 'created_at']
        read_only_fields = ['id', 'created_at']


class ProductImageSerializer(serializers.ModelSerializer):
    """Serializer for ProductImage model."""

    class Meta:
        model = ProductImage
        fields = ['id', 'image', 'order', 'created_at']
        read_only_fields = ['id', 'created_at']


class ProductSerializer(serializers.ModelSerializer):
    """Serializer for Product model."""

    category_name = serializers.CharField(source='category.name', read_only=True)
    seller_name = serializers.CharField(source='seller.seller_profile.business_name', read_only=True)
    seller_id = serializers.UUIDField(source='seller.id', read_only=True)
    main_image = serializers.SerializerMethodField()
    is_in_stock = serializers.BooleanField(read_only=True)

    class Meta:
        model = Product
        fields = [
            'id',
            'seller',
            'seller_id',
            'seller_name',
            'name',
            'description',
            'category',
            'category_name',
            'price',
            'stock',
            'is_available',
            'images',
            'main_image',
            'is_in_stock',
            'views_count',
            'sales_count',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'seller', 'views_count', 'sales_count', 'created_at', 'updated_at']

    def get_main_image(self, obj):
        """Get the main image URL."""
        return obj.get_main_image()

    def validate_category(self, value):
        """Allow category to be passed as name or ID."""
        if isinstance(value, str):
            # If it's a string, try to find the category by name
            try:
                category = Category.objects.get(name=value)
                return category
            except Category.DoesNotExist:
                raise serializers.ValidationError(f"Categoría '{value}' no encontrada.")
        # If it's already a Category instance or UUID, return as is
        return value

    def validate_images(self, value):
        """Validate that images array has max 5 items."""
        if len(value) > 5:
            raise serializers.ValidationError("Máximo 5 imágenes permitidas.")
        return value


class ProductListSerializer(serializers.ModelSerializer):
    """Simplified serializer for product listings."""

    category_name = serializers.CharField(source='category.name', read_only=True)
    seller_name = serializers.CharField(source='seller.seller_profile.business_name', read_only=True)
    main_image = serializers.SerializerMethodField()
    seller_rating = serializers.DecimalField(
        source='seller.seller_profile.rating_avg',
        max_digits=3,
        decimal_places=2,
        read_only=True
    )

    class Meta:
        model = Product
        fields = [
            'id',
            'name',
            'price',
            'main_image',
            'category_name',
            'seller_name',
            'seller_rating',
            'is_available',
            'stock',
        ]

    def get_main_image(self, obj):
        """Get the main image URL."""
        return obj.get_main_image()


class ProductDetailSerializer(ProductSerializer):
    """Detailed serializer for product with seller info."""

    seller_info = PublicSellerProfileSerializer(source='seller', read_only=True)

    class Meta(ProductSerializer.Meta):
        fields = ProductSerializer.Meta.fields + ['seller_info']
