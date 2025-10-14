"""
URL configuration for Users app.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from users.views import UserViewSet, SellerViewSet

router = DefaultRouter()
router.register(r'users', UserViewSet, basename='user')
router.register(r'sellers', SellerViewSet, basename='seller')

urlpatterns = [
    path('', include(router.urls)),
]
