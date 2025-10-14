"""
Product models for MercaTico.
"""
import uuid
from django.db import models
from django.core.validators import MinValueValidator
from users.models import User


class Category(models.Model):
    """
    Product categories.
    """

    class CategoryType(models.TextChoices):
        MERCHANDISE = 'MERCHANDISE', 'Mercancías'
        FOOD = 'FOOD', 'Alimentos'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField('nombre', max_length=100, unique=True)
    category_type = models.CharField(
        'tipo de categoría',
        max_length=20,
        choices=CategoryType.choices
    )
    description = models.TextField('descripción', blank=True)
    icon = models.CharField('icono', max_length=50, blank=True, help_text='Nombre del icono para UI')

    # Timestamps
    created_at = models.DateTimeField('fecha de creación', auto_now_add=True)

    class Meta:
        verbose_name = 'categoría'
        verbose_name_plural = 'categorías'
        ordering = ['category_type', 'name']

    def __str__(self):
        return f"{self.name} ({self.get_category_type_display()})"


class Product(models.Model):
    """
    Product model for items sold on MercaTico.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    # Seller relationship
    seller = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='products',
        limit_choices_to={'user_type': User.UserType.SELLER}
    )

    # Basic information
    name = models.CharField('nombre', max_length=200)
    description = models.TextField('descripción', max_length=2000)

    # Category
    category = models.ForeignKey(
        Category,
        on_delete=models.PROTECT,
        related_name='products',
        verbose_name='categoría'
    )

    # Pricing
    price = models.DecimalField(
        'precio',
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(0)],
        help_text='Precio en colones costarricenses (CRC)'
    )

    # Inventory
    stock = models.IntegerField(
        'stock disponible',
        default=0,
        validators=[MinValueValidator(0)]
    )
    is_available = models.BooleanField('disponible', default=True)

    # Images (stored as JSON array of URLs)
    images = models.JSONField(
        'imágenes',
        default=list,
        blank=True,
        help_text='Array de URLs de imágenes (máximo 5)'
    )

    # Statistics
    views_count = models.IntegerField('vistas', default=0)
    sales_count = models.IntegerField('ventas', default=0)

    # Timestamps
    created_at = models.DateTimeField('fecha de creación', auto_now_add=True)
    updated_at = models.DateTimeField('última actualización', auto_now=True)

    class Meta:
        verbose_name = 'producto'
        verbose_name_plural = 'productos'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['seller', '-created_at']),
            models.Index(fields=['category', '-created_at']),
            models.Index(fields=['is_available', '-created_at']),
            models.Index(fields=['-sales_count']),
        ]

    def __str__(self):
        return f"{self.name} - {self.seller.seller_profile.business_name}"

    @property
    def is_in_stock(self):
        """Check if product is in stock."""
        return self.stock > 0 and self.is_available

    def increment_views(self):
        """Increment the views counter."""
        self.views_count += 1
        self.save(update_fields=['views_count'])

    def increment_sales(self, quantity=1):
        """
        Increment the sales counter and decrease stock.
        """
        self.sales_count += quantity
        self.stock -= quantity
        if self.stock <= 0:
            self.is_available = False
        self.save(update_fields=['sales_count', 'stock', 'is_available'])

    def get_main_image(self):
        """Get the main (first) image URL."""
        if self.images and len(self.images) > 0:
            return self.images[0]
        return None


class ProductImage(models.Model):
    """
    Model to store product images.
    Alternative to JSON field if needed for better control.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    product = models.ForeignKey(
        Product,
        on_delete=models.CASCADE,
        related_name='product_images'
    )
    image = models.ImageField('imagen', upload_to='products/')
    order = models.IntegerField('orden', default=0)
    created_at = models.DateTimeField('fecha de creación', auto_now_add=True)

    class Meta:
        verbose_name = 'imagen de producto'
        verbose_name_plural = 'imágenes de productos'
        ordering = ['product', 'order']

    def __str__(self):
        return f"Imagen {self.order} de {self.product.name}"
