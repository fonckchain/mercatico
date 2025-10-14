"""
Admin configuration for Products app.
"""
from django.contrib import admin
from products.models import Category, Product, ProductImage


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    """Admin for Category model."""

    list_display = ['name', 'category_type', 'created_at']
    list_filter = ['category_type', 'created_at']
    search_fields = ['name', 'description']
    ordering = ['category_type', 'name']


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    """Admin for Product model."""

    list_display = ['name', 'seller', 'category', 'price', 'stock', 'is_available', 'sales_count', 'created_at']
    list_filter = ['is_available', 'category', 'created_at']
    search_fields = ['name', 'description', 'seller__seller_profile__business_name']
    readonly_fields = ['views_count', 'sales_count', 'created_at', 'updated_at']

    fieldsets = (
        ('Información Básica', {'fields': ('seller', 'name', 'description', 'category')}),
        ('Precio e Inventario', {'fields': ('price', 'stock', 'is_available')}),
        ('Imágenes', {'fields': ('images',)}),
        ('Estadísticas', {'fields': ('views_count', 'sales_count')}),
        ('Fechas', {'fields': ('created_at', 'updated_at')}),
    )

    def get_queryset(self, request):
        """Optimize queryset with select_related."""
        qs = super().get_queryset(request)
        return qs.select_related('seller', 'category')


@admin.register(ProductImage)
class ProductImageAdmin(admin.ModelAdmin):
    """Admin for ProductImage model."""

    list_display = ['product', 'order', 'created_at']
    list_filter = ['created_at']
    search_fields = ['product__name']
    ordering = ['product', 'order']
