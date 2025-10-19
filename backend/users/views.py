"""
Views for Users app.
"""
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from users.models import SellerProfile
from users.serializers import (
    UserSerializer,
    UserRegistrationSerializer,
    ChangePasswordSerializer,
    PublicSellerProfileSerializer,
    SellerProfileSerializer,
    BuyerProfileSerializer,
)

User = get_user_model()


class UserViewSet(viewsets.ModelViewSet):
    """
    ViewSet for User management.
    """
    queryset = User.objects.all()
    serializer_class = UserSerializer

    def get_permissions(self):
        """Set permissions based on action."""
        if self.action == 'register':
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        """Filter queryset based on user permissions."""
        if self.request.user.is_staff:
            return User.objects.all()
        return User.objects.filter(id=self.request.user.id)

    @action(detail=False, methods=['get', 'put', 'patch'])
    def me(self, request):
        """
        Get or update current user profile.
        """
        if request.method == 'GET':
            serializer = self.get_serializer(request.user)
            return Response(serializer.data)

        # Update profile
        serializer = self.get_serializer(
            request.user,
            data=request.data,
            partial=True
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()

        # Update seller/buyer profile if provided
        if request.user.user_type == User.UserType.SELLER and 'seller_profile' in request.data:
            profile_serializer = SellerProfileSerializer(
                request.user.seller_profile,
                data=request.data['seller_profile'],
                partial=True
            )
            profile_serializer.is_valid(raise_exception=True)
            profile_serializer.save()
        elif request.user.user_type == User.UserType.BUYER and 'buyer_profile' in request.data:
            profile_serializer = BuyerProfileSerializer(
                request.user.buyer_profile,
                data=request.data['buyer_profile'],
                partial=True
            )
            profile_serializer.is_valid(raise_exception=True)
            profile_serializer.save()

        return Response(UserSerializer(request.user).data)

    @action(detail=False, methods=['post'], permission_classes=[permissions.AllowAny])
    def register(self, request):
        """
        Register a new user.
        """
        serializer = UserRegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        return Response(
            {
                'message': 'Usuario registrado exitosamente',
                'user': UserSerializer(user).data
            },
            status=status.HTTP_201_CREATED
        )

    @action(detail=False, methods=['post'])
    def change_password(self, request):
        """
        Change user password.
        """
        serializer = ChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        # Check old password
        if not request.user.check_password(serializer.validated_data['old_password']):
            return Response(
                {'old_password': 'Contraseña incorrecta'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Set new password
        request.user.set_password(serializer.validated_data['new_password'])
        request.user.save()

        return Response({'message': 'Contraseña actualizada exitosamente'})


class SellerViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Public ViewSet for browsing sellers.
    """
    queryset = User.objects.filter(user_type=User.UserType.SELLER, is_active=True)
    serializer_class = PublicSellerProfileSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        """Filter and optimize queryset."""
        queryset = super().get_queryset()
        queryset = queryset.select_related('seller_profile')

        # Filter by location
        province = self.request.query_params.get('province')
        if province:
            queryset = queryset.filter(seller_profile__province=province)

        canton = self.request.query_params.get('canton')
        if canton:
            queryset = queryset.filter(seller_profile__canton=canton)

        # Order by rating
        queryset = queryset.order_by('-seller_profile__rating_avg')

        return queryset
