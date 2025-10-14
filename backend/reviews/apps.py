from django.apps import AppConfig


class ReviewsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'reviews'
    verbose_name = 'Reseñas'

    def ready(self):
        """Import signals when app is ready."""
        import reviews.signals
