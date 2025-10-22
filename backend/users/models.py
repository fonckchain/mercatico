"""
User models for MercaTico.
"""
import uuid
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.core.validators import RegexValidator
from django.utils import timezone


class UserManager(BaseUserManager):
    """
    Custom user manager for MercaTico users.
    """

    def create_user(self, email, password=None, **extra_fields):
        """
        Create and save a regular user with the given email and password.
        """
        if not email:
            raise ValueError('El correo electrónico es obligatorio')

        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        """
        Create and save a superuser with the given email and password.
        """
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)
        extra_fields.setdefault('is_verified', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser debe tener is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser debe tener is_superuser=True.')

        return self.create_user(email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    """
    Custom User model for MercaTico.
    Supports both buyers and sellers.
    """

    class UserType(models.TextChoices):
        BUYER = 'BUYER', 'Comprador'
        SELLER = 'SELLER', 'Vendedor'

    # Primary key
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    # Authentication fields
    email = models.EmailField('correo electrónico', unique=True, max_length=255)
    phone_regex = RegexValidator(
        regex=r'^(\+506)?\d{8}$',
        message="El número debe estar en formato: '+50612345678' o '12345678'"
    )
    phone = models.CharField(
        'teléfono',
        validators=[phone_regex],
        max_length=17,
        unique=True,
        help_text='Número de teléfono costarricense'
    )

    # User information
    first_name = models.CharField('nombre', max_length=50)
    last_name = models.CharField('apellidos', max_length=50)
    user_type = models.CharField(
        'tipo de usuario',
        max_length=10,
        choices=UserType.choices,
        default=UserType.BUYER
    )

    # Status flags
    is_active = models.BooleanField('activo', default=True)
    is_staff = models.BooleanField('es staff', default=False)
    is_verified = models.BooleanField('verificado', default=False)

    # Timestamps
    date_joined = models.DateTimeField('fecha de registro', default=timezone.now)
    last_login = models.DateTimeField('último inicio de sesión', null=True, blank=True)

    # Manager
    objects = UserManager()

    # Settings for authentication
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['first_name', 'last_name', 'phone']

    class Meta:
        verbose_name = 'usuario'
        verbose_name_plural = 'usuarios'
        ordering = ['-date_joined']
        indexes = [
            models.Index(fields=['email']),
            models.Index(fields=['phone']),
            models.Index(fields=['user_type']),
        ]

    def __str__(self):
        return f"{self.get_full_name()} ({self.email})"

    def get_full_name(self):
        """
        Return the first_name plus the last_name, with a space in between.
        """
        return f"{self.first_name} {self.last_name}".strip()

    def get_short_name(self):
        """
        Return the short name for the user.
        """
        return self.first_name


class SellerProfile(models.Model):
    """
    Extended profile for seller users.
    """
    # One-to-one relationship with User
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        primary_key=True,
        related_name='seller_profile'
    )

    # Business information
    business_name = models.CharField('nombre del negocio', max_length=100)
    description = models.TextField('descripción', max_length=500, blank=True)

    # SINPE Móvil information
    sinpe_regex = RegexValidator(
        regex=r'^(\+506)?\d{8}$',
        message="El número SINPE debe estar en formato: '+50612345678' o '12345678'"
    )
    sinpe_number = models.CharField(
        'número SINPE Móvil',
        validators=[sinpe_regex],
        max_length=17,
        help_text='Número de teléfono para recibir pagos SINPE Móvil'
    )

    # Accept cash on delivery
    accepts_cash = models.BooleanField(
        'acepta efectivo contra entrega',
        default=False,
        help_text='Indica si el vendedor acepta pagos en efectivo al momento de la entrega'
    )

    # Delivery options
    offers_pickup = models.BooleanField(
        'ofrece recogida',
        default=True,
        help_text='Si el vendedor permite que clientes recojan productos en su ubicación'
    )
    offers_delivery = models.BooleanField(
        'ofrece entrega',
        default=False,
        help_text='Si el vendedor ofrece servicio de entrega a domicilio'
    )

    # Business logo/photo
    logo = models.ImageField(
        'logo/foto',
        upload_to='seller_logos/',
        null=True,
        blank=True
    )

    # Location information
    province = models.CharField('provincia', max_length=50, blank=True)
    canton = models.CharField('cantón', max_length=50, blank=True)
    district = models.CharField('distrito', max_length=50, blank=True)
    address = models.TextField('dirección exacta', blank=True)

    # GPS coordinates
    latitude = models.DecimalField(
        'latitud',
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True,
        help_text='Coordenada de latitud GPS'
    )
    longitude = models.DecimalField(
        'longitud',
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True,
        help_text='Coordenada de longitud GPS'
    )

    # Statistics
    total_sales = models.DecimalField(
        'total de ventas',
        max_digits=12,
        decimal_places=2,
        default=0
    )
    rating_avg = models.DecimalField(
        'calificación promedio',
        max_digits=3,
        decimal_places=2,
        default=0,
        help_text='Promedio de calificaciones (0-5)'
    )
    rating_count = models.IntegerField('cantidad de calificaciones', default=0)

    # Timestamps
    created_at = models.DateTimeField('fecha de creación', auto_now_add=True)
    updated_at = models.DateTimeField('última actualización', auto_now=True)

    class Meta:
        verbose_name = 'perfil de vendedor'
        verbose_name_plural = 'perfiles de vendedores'
        indexes = [
            models.Index(fields=['business_name']),
            models.Index(fields=['province', 'canton']),
            models.Index(fields=['-rating_avg']),
        ]

    def __str__(self):
        return self.business_name

    def update_rating(self):
        """
        Update the average rating based on all reviews.
        """
        from reviews.models import Review
        reviews = Review.objects.filter(seller=self.user)
        if reviews.exists():
            self.rating_count = reviews.count()
            self.rating_avg = reviews.aggregate(models.Avg('rating'))['rating__avg']
            self.save(update_fields=['rating_avg', 'rating_count'])


class BuyerProfile(models.Model):
    """
    Extended profile for buyer users.
    """
    # One-to-one relationship with User
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        primary_key=True,
        related_name='buyer_profile'
    )

    # Delivery information
    province = models.CharField('provincia', max_length=50, blank=True)
    canton = models.CharField('cantón', max_length=50, blank=True)
    district = models.CharField('distrito', max_length=50, blank=True)
    address = models.TextField('dirección de entrega', blank=True)

    # GPS coordinates (default delivery location)
    latitude = models.DecimalField(
        'latitud',
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True,
        help_text='Coordenada de latitud GPS para ubicación de entrega'
    )
    longitude = models.DecimalField(
        'longitud',
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True,
        help_text='Coordenada de longitud GPS para ubicación de entrega'
    )

    # Timestamps
    created_at = models.DateTimeField('fecha de creación', auto_now_add=True)
    updated_at = models.DateTimeField('última actualización', auto_now=True)

    class Meta:
        verbose_name = 'perfil de comprador'
        verbose_name_plural = 'perfiles de compradores'

    def __str__(self):
        return f"Perfil de {self.user.get_full_name()}"
