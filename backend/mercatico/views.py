"""
General views for MercaTico.
"""
from django.http import JsonResponse
from django.db import connection


def health_check(request):
    """
    Health check endpoint for monitoring.
    Returns 200 if the service is healthy.
    """
    try:
        # Check database connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")

        return JsonResponse({
            'status': 'healthy',
            'service': 'MercaTico Backend',
            'database': 'connected'
        })
    except Exception as e:
        return JsonResponse({
            'status': 'unhealthy',
            'service': 'MercaTico Backend',
            'error': str(e)
        }, status=503)
