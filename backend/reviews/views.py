"""
Views for reviews app.
"""
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import OrderingFilter, SearchFilter

from reviews.models import Review, ReviewReport
from reviews.serializers import ReviewSerializer, ReviewReportSerializer
from users.models import User


class IsReviewOwnerOrReadOnly(permissions.BasePermission):
    """
    Permission to allow anyone to read reviews,
    but only the review owner can update/delete.
    """

    def has_object_permission(self, request, view, obj):
        # Read permissions are allowed to any request
        if request.method in permissions.SAFE_METHODS:
            return True

        # Write permissions only to the owner (buyer) or admin
        return obj.buyer == request.user or request.user.is_staff


class ReviewViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing reviews.

    list: Get all visible reviews
    create: Create a new review (buyers only, for delivered orders)
    retrieve: Get review details
    update: Update review (owner only)
    partial_update: Partially update review (owner only)
    destroy: Delete review (owner only)

    Custom actions:
    - seller_reviews: Get reviews for a specific seller
    - my_reviews: Get current user's reviews
    - report: Report a review
    """
    queryset = Review.objects.filter(
        is_visible=True
    ).select_related(
        'buyer',
        'seller',
        'seller__seller_profile',
        'order'
    )
    serializer_class = ReviewSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsReviewOwnerOrReadOnly]
    filter_backends = [DjangoFilterBackend, OrderingFilter, SearchFilter]
    filterset_fields = ['seller', 'rating', 'is_visible']
    ordering_fields = ['created_at', 'rating']
    ordering = ['-created_at']
    search_fields = ['comment', 'buyer__first_name', 'buyer__last_name']

    def get_queryset(self):
        """Filter queryset based on user permissions."""
        queryset = super().get_queryset()

        # Admins see all reviews (including hidden ones)
        if self.request.user.is_staff:
            return Review.objects.all().select_related(
                'buyer',
                'seller',
                'seller__seller_profile',
                'order'
            )

        # Regular users only see visible reviews
        return queryset

    def perform_create(self, serializer):
        """Create review as buyer."""
        if self.request.user.user_type != User.UserType.BUYER:
            raise permissions.PermissionDenied(
                "Solo los compradores pueden crear reseñas"
            )
        serializer.save()

    @action(detail=False, methods=['get'])
    def seller_reviews(self, request):
        """
        Get all reviews for a specific seller.
        Query param: seller_id (UUID)
        """
        seller_id = request.query_params.get('seller_id')

        if not seller_id:
            return Response(
                {'detail': 'Se requiere el parámetro seller_id'},
                status=status.HTTP_400_BAD_REQUEST
            )

        reviews = self.get_queryset().filter(seller_id=seller_id)

        # Get statistics
        from django.db.models import Avg, Count
        stats = reviews.aggregate(
            average_rating=Avg('rating'),
            total_reviews=Count('id')
        )

        page = self.paginate_queryset(reviews)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response({
                'reviews': serializer.data,
                'statistics': stats
            })

        serializer = self.get_serializer(reviews, many=True)
        return Response({
            'reviews': serializer.data,
            'statistics': stats
        })

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def my_reviews(self, request):
        """Get current user's reviews."""
        if request.user.user_type != User.UserType.BUYER:
            return Response(
                {'detail': 'Solo los compradores pueden ver sus reseñas'},
                status=status.HTTP_403_FORBIDDEN
            )

        reviews = Review.objects.filter(buyer=request.user).select_related(
            'seller',
            'seller__seller_profile',
            'order'
        )

        page = self.paginate_queryset(reviews)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(reviews, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def report(self, request, pk=None):
        """Report a review as inappropriate."""
        review = self.get_object()

        # User cannot report their own review
        if review.buyer == request.user:
            return Response(
                {'detail': 'No puedes reportar tu propia reseña'},
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = ReviewReportSerializer(
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        serializer.save(review=review, reported_by=request.user)

        return Response(
            {'detail': 'Reseña reportada exitosamente'},
            status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def hide(self, request, pk=None):
        """Hide a review (admin only)."""
        review = self.get_object()
        review.is_visible = False
        review.save()

        return Response({'detail': 'Reseña ocultada exitosamente'})

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def show(self, request, pk=None):
        """Show a hidden review (admin only)."""
        review = self.get_object()
        review.is_visible = True
        review.save()

        return Response({'detail': 'Reseña mostrada exitosamente'})


class ReviewReportViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing review reports.
    Admin only - regular users report through ReviewViewSet.
    """
    queryset = ReviewReport.objects.all().select_related(
        'review',
        'review__buyer',
        'review__seller',
        'reported_by'
    )
    serializer_class = ReviewReportSerializer
    permission_classes = [permissions.IsAdminUser]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ['reason', 'review']
    ordering = ['-created_at']
