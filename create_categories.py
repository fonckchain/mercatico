#!/usr/bin/env python3
"""Script para crear categorías iniciales en producción via API"""
import requests
import json

# Login
login_url = "https://mercatico-production.up.railway.app/api/token/"
login_data = {
    "email": "vendedor.test@mercatico.cr",
    "password": "Vendedor2024"
}

response = requests.post(login_url, json=login_data)
token = response.json()["access"]
print(f"✓ Token obtenido")

# Crear categorías
categories_url = "https://mercatico-production.up.railway.app/api/products/categories/"
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

categories = [
    {"name": "Artesanías", "description": "Productos artesanales hechos a mano"},
    {"name": "Alimentos", "description": "Productos alimenticios frescos y procesados"},
    {"name": "Ropa y Textiles", "description": "Prendas de vestir y productos textiles"},
    {"name": "Joyería", "description": "Joyas y accesorios"},
    {"name": "Decoración", "description": "Artículos decorativos para el hogar"},
    {"name": "Productos Orgánicos", "description": "Productos orgánicos y naturales"},
]

for cat in categories:
    try:
        response = requests.post(categories_url, headers=headers, json=cat)
        if response.status_code == 201:
            print(f"✓ Categoría creada: {cat['name']}")
        else:
            print(f"✗ Error creando {cat['name']}: {response.text}")
    except Exception as e:
        print(f"✗ Error: {e}")

print("\n✓ Categorías creadas exitosamente")
