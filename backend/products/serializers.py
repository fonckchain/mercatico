"""
Serializers for Products app.
"""
from rest_framework import serializers
from products.models import Category, Product, ProductImage
from users.serializers import PublicSellerProfileSerializer


class FlexibleCategoryField(serializers.Field):
    """Custom field that accepts both category UUID and category name."""

    def to_representation(self, value):
        """Return the category UUID for reading."""
        return str(value.id) if value else None

    def to_internal_value(self, data):
        """Accept both UUID and name for writing."""
        print(f"DEBUG: FlexibleCategoryField received data: {data}, type: {type(data)}")
        if not data:
            raise serializers.ValidationError("Categoría es requerida.")

        # Try to find by UUID first
        try:
            category = Category.objects.get(id=data)
            print(f"DEBUG: Found category by UUID: {category}")
            return category
        except (Category.DoesNotExist, ValueError, TypeError) as e:
            print(f"DEBUG: UUID lookup failed: {e}, trying by name...")
            # If not UUID, try by name
            try:
                category = Category.objects.get(name=data)
                print(f"DEBUG: Found category by name: {category}")
                return category
            except Category.DoesNotExist:
                print(f"DEBUG: Category not found by name either")
                raise serializers.ValidationError(f"Categoría '{data}' no encontrada.")


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
            'show_stock',
            'accepts_cash',
            'offers_pickup',
            'offers_delivery',
            'is_available',
            'images',
            'latitude',
            'longitude',
            'main_image',
            'is_in_stock',
            'views_count',
            'sales_count',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'seller', 'views_count', 'sales_count', 'created_at', 'updated_at']

    def to_internal_value(self, data):
        """Convert category name to UUID before validation."""
        # If category is a string (not a UUID), try to find it by name
        if 'category' in data and isinstance(data['category'], str):
            try:
                # First try if it's already a valid UUID
                import uuid
                uuid.UUID(data['category'])
            except (ValueError, AttributeError):
                # Not a UUID, try to find by name
                try:
                    category = Category.objects.get(name=data['category'])
                    # Create a mutable copy of data
                    data = data.copy() if hasattr(data, 'copy') else dict(data)
                    data['category'] = str(category.id)
                    print(f"DEBUG: Converted category name '{data['category']}' to UUID: {category.id}")
                except Category.DoesNotExist:
                    pass  # Let the parent validation handle this error

        return super().to_internal_value(data)

    def get_main_image(self, obj):
        """Get the main image URL."""
        return obj.get_main_image()

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
            'show_stock',
            'offers_pickup',
            'offers_delivery',
        ]

    def get_main_image(self, obj):
        """Get the main image URL."""
        return obj.get_main_image()


class ProductDetailSerializer(ProductSerializer):
    """Detailed serializer for product with seller info."""

    seller_info = PublicSellerProfileSerializer(source='seller', read_only=True)

    class Meta(ProductSerializer.Meta):
        fields = ProductSerializer.Meta.fields + ['seller_info']
