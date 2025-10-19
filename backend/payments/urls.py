"""
URLs for payments app.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from payments.views import PaymentReceiptViewSet, PaymentVerificationLogViewSet

router = DefaultRouter()
router.register(r'receipts', PaymentReceiptViewSet, basename='receipt')
router.register(r'logs', PaymentVerificationLogViewSet, basename='log')

app_name = 'payments'

urlpatterns = [
    path('', include(router.urls)),
]
