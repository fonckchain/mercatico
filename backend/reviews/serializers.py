"""
Serializers for reviews app.
"""
from rest_framework import serializers
from reviews.models import Review, ReviewReport
from users.serializers import UserSerializer


class ReviewSerializer(serializers.ModelSerializer):
    """Serializer for reviews."""
    buyer = UserSerializer(read_only=True)
    seller = UserSerializer(read_only=True)
    buyer_name = serializers.CharField(source='buyer.get_full_name', read_only=True)
    seller_business_name = serializers.CharField(
        source='seller.seller_profile.business_name',
        read_only=True
    )

    class Meta:
        model = Review
        fields = [
            'id',
            'order',
            'buyer',
            'buyer_name',
            'seller',
            'seller_business_name',
            'rating',
            'comment',
            'is_visible',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'buyer',
            'seller',
            'is_visible',
            'created_at',
            'updated_at',
        ]

    def validate_rating(self, value):
        """Validate rating is between 1 and 5."""
        if not 1 <= value <= 5:
            raise serializers.ValidationError(
                "La calificación debe estar entre 1 y 5"
            )
        return value

    def validate_order(self, value):
        """Validate order can be reviewed."""
        # Check if order is delivered
        if not value.can_be_reviewed():
            raise serializers.ValidationError(
                "Solo se pueden reseñar órdenes que han sido entregadas"
            )

        # Check if order already has a review
        if hasattr(value, 'review'):
            raise serializers.ValidationError(
                "Esta orden ya ha sido reseñada"
            )

        # Check if order belongs to the current user
        user = self.context['request'].user
        if value.buyer != user:
            raise serializers.ValidationError(
                "Solo puedes reseñar tus propias órdenes"
            )

        return value

    def create(self, validated_data):
        """Create review with buyer and seller from order."""
        order = validated_data['order']
        validated_data['buyer'] = order.buyer
        validated_data['seller'] = order.seller
        return super().create(validated_data)


class ReviewReportSerializer(serializers.ModelSerializer):
    """Serializer for review reports."""
    reported_by_name = serializers.CharField(
        source='reported_by.get_full_name',
        read_only=True
    )
    review_comment = serializers.CharField(
        source='review.comment',
        read_only=True
    )

    class Meta:
        model = ReviewReport
        fields = [
            'id',
            'review',
            'review_comment',
            'reason',
            'description',
            'reported_by',
            'reported_by_name',
            'created_at',
        ]
        read_only_fields = [
            'id',
            'reported_by',
            'created_at',
        ]

    def validate_review(self, value):
        """Validate user hasn't already reported this review."""
        user = self.context['request'].user

        if ReviewReport.objects.filter(review=value, reported_by=user).exists():
            raise serializers.ValidationError(
                "Ya has reportado esta reseña"
            )

        return value
