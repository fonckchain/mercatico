"""
URLs for reviews app.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from reviews.views import ReviewViewSet, ReviewReportViewSet

router = DefaultRouter()
router.register(r'', ReviewViewSet, basename='review')
router.register(r'reports', ReviewReportViewSet, basename='report')

app_name = 'reviews'

urlpatterns = [
    path('', include(router.urls)),
]
