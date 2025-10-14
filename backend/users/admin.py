"""
Admin configuration for Users app.
"""
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from users.models import User, SellerProfile, BuyerProfile


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Admin for custom User model."""

    list_display = ['email', 'first_name', 'last_name', 'user_type', 'is_verified', 'is_active', 'date_joined']
    list_filter = ['user_type', 'is_verified', 'is_active', 'is_staff', 'date_joined']
    search_fields = ['email', 'first_name', 'last_name', 'phone']
    ordering = ['-date_joined']

    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Información Personal', {'fields': ('first_name', 'last_name', 'phone', 'user_type')}),
        ('Permisos', {'fields': ('is_active', 'is_staff', 'is_superuser', 'is_verified', 'groups', 'user_permissions')}),
        ('Fechas Importantes', {'fields': ('last_login', 'date_joined')}),
    )

    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'phone', 'first_name', 'last_name', 'user_type', 'password1', 'password2'),
        }),
    )


@admin.register(SellerProfile)
class SellerProfileAdmin(admin.ModelAdmin):
    """Admin for SellerProfile model."""

    list_display = ['business_name', 'user', 'province', 'canton', 'rating_avg', 'total_sales', 'created_at']
    list_filter = ['province', 'accepts_cash', 'created_at']
    search_fields = ['business_name', 'user__email', 'user__first_name', 'user__last_name']
    readonly_fields = ['total_sales', 'rating_avg', 'rating_count', 'created_at', 'updated_at']

    fieldsets = (
        ('Usuario', {'fields': ('user',)}),
        ('Información del Negocio', {'fields': ('business_name', 'description', 'logo')}),
        ('Pago', {'fields': ('sinpe_number', 'accepts_cash')}),
        ('Ubicación', {'fields': ('province', 'canton', 'district', 'address')}),
        ('Estadísticas', {'fields': ('total_sales', 'rating_avg', 'rating_count')}),
        ('Fechas', {'fields': ('created_at', 'updated_at')}),
    )


@admin.register(BuyerProfile)
class BuyerProfileAdmin(admin.ModelAdmin):
    """Admin for BuyerProfile model."""

    list_display = ['user', 'province', 'canton', 'created_at']
    list_filter = ['province', 'created_at']
    search_fields = ['user__email', 'user__first_name', 'user__last_name']
    readonly_fields = ['created_at', 'updated_at']

    fieldsets = (
        ('Usuario', {'fields': ('user',)}),
        ('Dirección de Entrega', {'fields': ('province', 'canton', 'district', 'address')}),
        ('Fechas', {'fields': ('created_at', 'updated_at')}),
    )
