"""Utility functions for orders."""
from decimal import Decimal
import math


def calculate_distance(lat1, lon1, lat2, lon2):
    """
    Calculate distance between two GPS coordinates using Haversine formula.
    Returns distance in kilometers.

    Args:
        lat1, lon1: First coordinate (latitude, longitude)
        lat2, lon2: Second coordinate (latitude, longitude)

    Returns:
        Distance in kilometers as Decimal
    """
    # Convert to float for calculations
    lat1, lon1, lat2, lon2 = map(float, [lat1, lon1, lat2, lon2])

    # Earth radius in kilometers
    R = 6371

    # Convert to radians
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    delta_lat = math.radians(lat2 - lat1)
    delta_lon = math.radians(lon2 - lon1)

    # Haversine formula
    a = (math.sin(delta_lat / 2) ** 2 +
         math.cos(lat1_rad) * math.cos(lat2_rad) *
         math.sin(delta_lon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    distance = R * c

    return Decimal(str(round(distance, 2)))


def calculate_delivery_fee(distance_km):
    """
    Calculate delivery fee based on distance.

    Pricing structure:
    - 0-5 km: ₡1,500 (local delivery within GAM)
    - 5-15 km: ₡3,000 (GAM delivery)
    - 15-30 km: ₡5,000 (extended GAM)
    - 30+ km: ₡7,500 (outside GAM)

    Args:
        distance_km: Distance in kilometers

    Returns:
        Delivery fee in colones as Decimal
    """
    distance = float(distance_km)

    if distance <= 5:
        return Decimal('1500.00')
    elif distance <= 15:
        return Decimal('3000.00')
    elif distance <= 30:
        return Decimal('5000.00')
    else:
        return Decimal('7500.00')
