"""
Custom exception handlers for MercaTico.
"""
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
from django.db import OperationalError, DatabaseError
import logging

logger = logging.getLogger(__name__)


def custom_exception_handler(exc, context):
    """
    Custom exception handler for DRF that provides consistent error responses.
    """
    # Handle database connection errors specifically
    if isinstance(exc, (OperationalError, DatabaseError)):
        logger.error(f"Database error: {exc}", exc_info=True)
        return Response(
            {
                'error': 'Error de conexión a la base de datos',
                'detail': 'El servicio no puede conectarse a la base de datos en este momento. Por favor, intente nuevamente más tarde.'
            },
            status=status.HTTP_503_SERVICE_UNAVAILABLE
        )

    # Call REST framework's default exception handler first
    response = exception_handler(exc, context)

    # Log the exception
    logger.error(f"Exception: {exc}", exc_info=True)

    # If unexpected error, return a generic message
    if response is None:
        return Response(
            {
                'error': 'Error interno del servidor',
                'detail': 'Ocurrió un error inesperado. Por favor, intente nuevamente más tarde.'
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

    # Customize the response format
    custom_response_data = {
        'error': response.data.get('detail', 'Error en la solicitud'),
    }

    # Add field-specific errors if they exist
    if isinstance(response.data, dict):
        for field, errors in response.data.items():
            if field != 'detail':
                custom_response_data[field] = errors

    response.data = custom_response_data

    return response
