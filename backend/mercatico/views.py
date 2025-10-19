"""
General views for MercaTico.
"""
from django.http import JsonResponse
from django.db import connection
from django.views.decorators.http import require_http_methods


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


@require_http_methods(["GET"])
def api_root(request):
    """
    API root endpoint with available routes and project info.
    """
    return JsonResponse({
        'project': 'MercaTico API',
        'version': '1.0.0',
        'description': 'API para la plataforma de marketplace costarricense MercaTico',
        'documentation': {
            'admin': request.build_absolute_uri('/admin/'),
            'health': request.build_absolute_uri('/health/'),
        },
        'endpoints': {
            'authentication': {
                'login': request.build_absolute_uri('/api/token/'),
                'refresh': request.build_absolute_uri('/api/token/refresh/'),
                'verify': request.build_absolute_uri('/api/token/verify/'),
                'register': request.build_absolute_uri('/api/auth/register/'),
                'users': request.build_absolute_uri('/api/auth/users/'),
            },
            'products': {
                'list': request.build_absolute_uri('/api/products/'),
                'categories': 'Coming soon',
            },
            'orders': {
                'list': request.build_absolute_uri('/api/orders/'),
            },
            'payments': {
                'receipts': request.build_absolute_uri('/api/payments/'),
            },
            'reviews': {
                'list': request.build_absolute_uri('/api/reviews/'),
            },
        },
        'status': 'online',
    })
