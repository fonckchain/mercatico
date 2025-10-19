"""
URLs for reviews app.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter

# Placeholder router for future views
router = DefaultRouter()

app_name = 'reviews'

urlpatterns = [
    path('', include(router.urls)),
]
