"""
Signals for review app.
"""
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from reviews.models import Review


@receiver(post_save, sender=Review)
def update_seller_rating_on_save(sender, instance, created, **kwargs):
    """
    Update seller rating when a review is created or updated.
    """
    if instance.is_visible:
        instance.seller.seller_profile.update_rating()


@receiver(post_delete, sender=Review)
def update_seller_rating_on_delete(sender, instance, **kwargs):
    """
    Update seller rating when a review is deleted.
    """
    instance.seller.seller_profile.update_rating()
