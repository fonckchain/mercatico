#!/usr/bin/env python
"""
Script para crear datos de prueba en MercaTico.
Ejecutar: python create_sample_data.py
"""
import os
import sys
import django
from decimal import Decimal

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'mercatico.settings')
django.setup()

from django.contrib.auth import get_user_model
from users.models import SellerProfile, BuyerProfile
from products.models import Category, Product, ProductImage
from orders.models import Order, OrderItem

User = get_user_model()


def create_categories():
    """Crear categorías de productos."""
    print("\n📁 Creando categorías...")

    categories_data = [
        # Mercancías
        {'name': 'Artesanías', 'description': 'Productos artesanales hechos a mano'},
        {'name': 'Ropa', 'description': 'Vestimenta y accesorios de vestir'},
        {'name': 'Accesorios', 'description': 'Accesorios y complementos'},
        {'name': 'Decoración', 'description': 'Artículos decorativos para el hogar'},
        {'name': 'Joyería', 'description': 'Joyería artesanal y accesorios'},

        # Alimentos
        {'name': 'Panadería', 'description': 'Pan fresco y productos de panadería'},
        {'name': 'Repostería', 'description': 'Postres, pasteles y dulces'},
        {'name': 'Productos Orgánicos', 'description': 'Alimentos orgánicos y naturales'},
        {'name': 'Comidas Preparadas', 'description': 'Comidas listas para consumir'},
        {'name': 'Frutas y Verduras', 'description': 'Productos frescos del campo'},
    ]

    categories = []
    for cat_data in categories_data:
        category, created = Category.objects.get_or_create(
            name=cat_data['name'],
            defaults={'description': cat_data['description']}
        )
        categories.append(category)
        status = "✓ Creada" if created else "○ Ya existe"
        print(f"  {status}: {category.name}")

    return categories


def create_sellers():
    """Crear usuarios vendedores de prueba."""
    print("\n👨‍💼 Creando vendedores...")

    sellers_data = [
        {
            'email': 'artesanias.don.juan@test.cr',
            'phone': '88881111',
            'password': 'test1234',
            'first_name': 'Juan',
            'last_name': 'Pérez',
            'business_name': 'Artesanías Don Juan',
            'description': 'Artesanías costarricenses 100% hechas a mano con materiales locales',
            'sinpe_number': '88881111',
            'province': 'San José',
            'canton': 'Central',
        },
        {
            'email': 'panaderia.maria@test.cr',
            'phone': '88882222',
            'password': 'test1234',
            'first_name': 'María',
            'last_name': 'González',
            'business_name': 'Panadería Doña María',
            'description': 'Pan fresco todos los días, horneado con amor desde 1985',
            'sinpe_number': '88882222',
            'province': 'Alajuela',
            'canton': 'Central',
        },
        {
            'email': 'organicos.jose@test.cr',
            'phone': '88883333',
            'password': 'test1234',
            'first_name': 'José',
            'last_name': 'Ramírez',
            'business_name': 'Orgánicos Don José',
            'description': 'Frutas y verduras orgánicas cultivadas sin químicos',
            'sinpe_number': '88883333',
            'province': 'Heredia',
            'canton': 'San Rafael',
        },
    ]

    sellers = []
    for seller_data in sellers_data:
        user, created = User.objects.get_or_create(
            email=seller_data['email'],
            defaults={
                'phone': seller_data['phone'],
                'first_name': seller_data['first_name'],
                'last_name': seller_data['last_name'],
                'user_type': User.UserType.SELLER,
                'is_verified': True,
            }
        )

        if created:
            user.set_password(seller_data['password'])
            user.save()

        # Crear perfil de vendedor
        profile, prof_created = SellerProfile.objects.get_or_create(
            user=user,
            defaults={
                'business_name': seller_data['business_name'],
                'description': seller_data['description'],
                'sinpe_number': seller_data['sinpe_number'],
                'province': seller_data['province'],
                'canton': seller_data['canton'],
            }
        )

        sellers.append(user)
        status = "✓ Creado" if created else "○ Ya existe"
        print(f"  {status}: {seller_data['business_name']} ({user.email})")

    return sellers


def create_buyers():
    """Crear usuarios compradores de prueba."""
    print("\n🛒 Creando compradores...")

    buyers_data = [
        {
            'email': 'comprador1@test.cr',
            'phone': '88884444',
            'password': 'test1234',
            'first_name': 'Ana',
            'last_name': 'Mora',
            'province': 'San José',
            'canton': 'Escazú',
            'address': '100m norte de la iglesia',
        },
        {
            'email': 'comprador2@test.cr',
            'phone': '88885555',
            'password': 'test1234',
            'first_name': 'Carlos',
            'last_name': 'Vargas',
            'province': 'Cartago',
            'canton': 'Central',
            'address': '200m sur del parque',
        },
    ]

    buyers = []
    for buyer_data in buyers_data:
        user, created = User.objects.get_or_create(
            email=buyer_data['email'],
            defaults={
                'phone': buyer_data['phone'],
                'first_name': buyer_data['first_name'],
                'last_name': buyer_data['last_name'],
                'user_type': User.UserType.BUYER,
                'is_verified': True,
            }
        )

        if created:
            user.set_password(buyer_data['password'])
            user.save()

        # Crear perfil de comprador
        profile, prof_created = BuyerProfile.objects.get_or_create(
            user=user,
            defaults={
                'province': buyer_data['province'],
                'canton': buyer_data['canton'],
                'address': buyer_data['address'],
            }
        )

        buyers.append(user)
        status = "✓ Creado" if created else "○ Ya existe"
        print(f"  {status}: {user.get_full_name()} ({user.email})")

    return buyers


def create_products(sellers, categories):
    """Crear productos de prueba."""
    print("\n📦 Creando productos...")

    products_data = [
        # Artesanías Don Juan
        {
            'seller': 0,  # Index en sellers list
            'category': 0,  # Artesanías
            'name': 'Carreta de Madera Decorativa',
            'description': 'Carreta tradicional costarricense pintada a mano. Tamaño mediano (20cm).',
            'price': '15000.00',
            'stock': 10,
        },
        {
            'seller': 0,
            'category': 0,
            'name': 'Máscaras de Boruca',
            'description': 'Máscaras artesanales talladas en madera de balsa. Colores vibrantes.',
            'price': '25000.00',
            'stock': 5,
        },
        {
            'seller': 0,
            'category': 4,  # Joyería
            'name': 'Collar de Semillas Naturales',
            'description': 'Collar hecho con semillas y madera natural. Diseño único.',
            'price': '8000.00',
            'stock': 15,
        },

        # Panadería Doña María
        {
            'seller': 1,
            'category': 5,  # Panadería
            'name': 'Pan Casero Integral',
            'description': 'Pan integral horneado diariamente. Sin conservantes.',
            'price': '2500.00',
            'stock': 20,
        },
        {
            'seller': 1,
            'category': 6,  # Repostería
            'name': 'Tres Leches Casero',
            'description': 'Pastel tres leches tradicional. Porción individual.',
            'price': '3500.00',
            'stock': 12,
        },
        {
            'seller': 1,
            'category': 6,
            'name': 'Galletas de Avena',
            'description': 'Galletas artesanales de avena con pasas. Paquete de 6 unidades.',
            'price': '2000.00',
            'stock': 30,
        },

        # Orgánicos Don José
        {
            'seller': 2,
            'category': 7,  # Productos Orgánicos
            'name': 'Tomates Orgánicos',
            'description': 'Tomates cultivados sin pesticidas. 1 libra.',
            'price': '1500.00',
            'stock': 50,
        },
        {
            'seller': 2,
            'category': 9,  # Frutas y Verduras
            'name': 'Lechuga Hidropónica',
            'description': 'Lechuga fresca cultivada en sistema hidropónico. 1 unidad.',
            'price': '1200.00',
            'stock': 40,
        },
        {
            'seller': 2,
            'category': 7,
            'name': 'Miel de Abeja Natural',
            'description': 'Miel 100% natural de abejas locales. Frasco de 500g.',
            'price': '8000.00',
            'stock': 25,
        },
    ]

    products = []
    for prod_data in products_data:
        product, created = Product.objects.get_or_create(
            seller=sellers[prod_data['seller']],
            name=prod_data['name'],
            defaults={
                'category': categories[prod_data['category']],
                'description': prod_data['description'],
                'price': Decimal(prod_data['price']),
                'stock': prod_data['stock'],
                'is_available': True,
            }
        )

        products.append(product)
        status = "✓ Creado" if created else "○ Ya existe"
        seller_name = sellers[prod_data['seller']].seller_profile.business_name
        print(f"  {status}: {product.name} - ₡{product.price} ({seller_name})")

    return products


def print_summary(sellers, buyers, categories, products):
    """Imprimir resumen de datos creados."""
    print("\n" + "="*60)
    print("📊 RESUMEN DE DATOS DE PRUEBA")
    print("="*60)
    print(f"\n✓ {len(categories)} Categorías creadas")
    print(f"✓ {len(sellers)} Vendedores creados")
    print(f"✓ {len(buyers)} Compradores creados")
    print(f"✓ {len(products)} Productos creados")

    print("\n" + "="*60)
    print("🔐 CREDENCIALES DE ACCESO")
    print("="*60)

    print("\n👨‍💼 VENDEDORES:")
    for seller in sellers:
        print(f"\n  • {seller.seller_profile.business_name}")
        print(f"    Email: {seller.email}")
        print(f"    Password: test1234")
        print(f"    Productos: {seller.products.count()}")

    print("\n🛒 COMPRADORES:")
    for buyer in buyers:
        print(f"\n  • {buyer.get_full_name()}")
        print(f"    Email: {buyer.email}")
        print(f"    Password: test1234")

    print("\n" + "="*60)
    print("🌐 PRÓXIMOS PASOS")
    print("="*60)
    print("\n1. Inicia el servidor: python manage.py runserver")
    print("2. Accede al admin: http://localhost:8000/admin/")
    print("3. Prueba la API: http://localhost:8000/api/products/")
    print("4. Login con cualquier usuario de prueba")
    print("\n")


def main():
    """Función principal."""
    print("\n🚀 Iniciando creación de datos de prueba para MercaTico...")
    print("="*60)

    try:
        categories = create_categories()
        sellers = create_sellers()
        buyers = create_buyers()
        products = create_products(sellers, categories)

        print_summary(sellers, buyers, categories, products)

        print("✅ ¡Datos de prueba creados exitosamente!")

    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
