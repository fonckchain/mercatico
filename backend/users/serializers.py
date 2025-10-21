"""
Serializers for User app.
"""
from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from users.models import User, SellerProfile, BuyerProfile


class BuyerProfileSerializer(serializers.ModelSerializer):
    """Serializer for buyer profile."""

    class Meta:
        model = BuyerProfile
        fields = [
            'province',
            'canton',
            'district',
            'address',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']


class SellerProfileSerializer(serializers.ModelSerializer):
    """Serializer for seller profile."""

    class Meta:
        model = SellerProfile
        fields = [
            'business_name',
            'description',
            'sinpe_number',
            'accepts_cash',
            'offers_pickup',
            'offers_delivery',
            'logo',
            'province',
            'canton',
            'district',
            'address',
            'latitude',
            'longitude',
            'total_sales',
            'rating_avg',
            'rating_count',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['total_sales', 'rating_avg', 'rating_count', 'created_at', 'updated_at']


class UserSerializer(serializers.ModelSerializer):
    """Serializer for User model."""

    buyer_profile = BuyerProfileSerializer(required=False, allow_null=True)
    seller_profile = SellerProfileSerializer(required=False, allow_null=True)
    full_name = serializers.CharField(source='get_full_name', read_only=True)

    class Meta:
        model = User
        fields = [
            'id',
            'email',
            'phone',
            'first_name',
            'last_name',
            'full_name',
            'user_type',
            'is_verified',
            'date_joined',
            'buyer_profile',
            'seller_profile',
        ]
        read_only_fields = ['id', 'is_verified', 'date_joined', 'full_name']

    def to_representation(self, instance):
        """Include profile based on user type."""
        data = super().to_representation(instance)

        # Remove profile fields that don't apply to this user type
        if instance.user_type == User.UserType.BUYER:
            data.pop('seller_profile', None)
        else:
            data.pop('buyer_profile', None)

        return data


class UserRegistrationSerializer(serializers.ModelSerializer):
    """Serializer for user registration."""

    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password],
        style={'input_type': 'password'}
    )
    password_confirm = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'}
    )

    # Seller-specific fields
    business_name = serializers.CharField(required=False, allow_blank=True)
    sinpe_number = serializers.CharField(required=False, allow_blank=True)

    class Meta:
        model = User
        fields = [
            'email',
            'phone',
            'password',
            'password_confirm',
            'first_name',
            'last_name',
            'user_type',
            'business_name',
            'sinpe_number',
        ]

    def validate(self, attrs):
        """Validate registration data."""
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({
                "password": "Las contraseñas no coinciden."
            })

        # Validate seller-specific fields
        if attrs.get('user_type') == User.UserType.SELLER:
            if not attrs.get('business_name'):
                raise serializers.ValidationError({
                    "business_name": "El nombre del negocio es obligatorio para vendedores."
                })
            if not attrs.get('sinpe_number'):
                raise serializers.ValidationError({
                    "sinpe_number": "El número SINPE es obligatorio para vendedores."
                })

        return attrs

    def create(self, validated_data):
        """Create user and profile."""
        validated_data.pop('password_confirm')
        business_name = validated_data.pop('business_name', None)
        sinpe_number = validated_data.pop('sinpe_number', None)

        # Create user
        user = User.objects.create_user(**validated_data)

        # Create appropriate profile
        if user.user_type == User.UserType.SELLER:
            SellerProfile.objects.create(
                user=user,
                business_name=business_name,
                sinpe_number=sinpe_number
            )
        else:
            BuyerProfile.objects.create(user=user)

        return user


class ChangePasswordSerializer(serializers.Serializer):
    """Serializer for changing password."""

    old_password = serializers.CharField(required=True, style={'input_type': 'password'})
    new_password = serializers.CharField(
        required=True,
        validators=[validate_password],
        style={'input_type': 'password'}
    )
    new_password_confirm = serializers.CharField(required=True, style={'input_type': 'password'})

    def validate(self, attrs):
        """Validate password change data."""
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError({
                "new_password": "Las contraseñas no coinciden."
            })
        return attrs


class PasswordResetRequestSerializer(serializers.Serializer):
    """Serializer for requesting password reset."""

    email = serializers.EmailField(required=True)


class PasswordResetConfirmSerializer(serializers.Serializer):
    """Serializer for confirming password reset."""

    token = serializers.CharField(required=True)
    new_password = serializers.CharField(
        required=True,
        validators=[validate_password],
        style={'input_type': 'password'}
    )
    new_password_confirm = serializers.CharField(required=True, style={'input_type': 'password'})

    def validate(self, attrs):
        """Validate password reset data."""
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError({
                "new_password": "Las contraseñas no coinciden."
            })
        return attrs


class PublicSellerProfileSerializer(serializers.ModelSerializer):
    """Public serializer for seller profile (for buyers browsing)."""

    business_name = serializers.CharField(source='seller_profile.business_name')
    description = serializers.CharField(source='seller_profile.description')
    logo = serializers.ImageField(source='seller_profile.logo')
    province = serializers.CharField(source='seller_profile.province')
    canton = serializers.CharField(source='seller_profile.canton')
    district = serializers.CharField(source='seller_profile.district')
    address = serializers.CharField(source='seller_profile.address')
    offers_pickup = serializers.BooleanField(source='seller_profile.offers_pickup')
    offers_delivery = serializers.BooleanField(source='seller_profile.offers_delivery')
    rating_avg = serializers.DecimalField(
        source='seller_profile.rating_avg',
        max_digits=3,
        decimal_places=2
    )
    rating_count = serializers.IntegerField(source='seller_profile.rating_count')
    total_sales = serializers.DecimalField(
        source='seller_profile.total_sales',
        max_digits=12,
        decimal_places=2
    )

    class Meta:
        model = User
        fields = [
            'id',
            'business_name',
            'description',
            'logo',
            'province',
            'canton',
            'district',
            'address',
            'offers_pickup',
            'offers_delivery',
            'rating_avg',
            'rating_count',
            'total_sales',
        ]
