"""
Health check URLs for MercaTico.
"""
from django.urls import path
from mercatico import views

urlpatterns = [
    path('', views.health_check, name='health_check'),
]
