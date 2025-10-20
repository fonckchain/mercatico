from django.core.management.base import BaseCommand
from products.models import Category


class Command(BaseCommand):
    help = 'Crea categorías iniciales para la plataforma'

    def handle(self, *args, **options):
        categories = [
            {"name": "Artesanías", "description": "Productos artesanales hechos a mano"},
            {"name": "Alimentos", "description": "Productos alimenticios frescos y procesados"},
            {"name": "Ropa y Textiles", "description": "Prendas de vestir y productos textiles"},
            {"name": "Joyería", "description": "Joyas y accesorios"},
            {"name": "Decoración", "description": "Artículos decorativos para el hogar"},
            {"name": "Productos Orgánicos", "description": "Productos orgánicos y naturales"},
            {"name": "Café y Té", "description": "Café, té y productos relacionados"},
            {"name": "Otros", "description": "Otros productos no categorizados"},
        ]

        for cat_data in categories:
            category, created = Category.objects.get_or_create(
                name=cat_data["name"],
                defaults={"description": cat_data["description"]}
            )
            if created:
                self.stdout.write(self.style.SUCCESS(f"✓ Categoría creada: {category.name}"))
            else:
                self.stdout.write(self.style.WARNING(f"- Categoría ya existe: {category.name}"))

        self.stdout.write(self.style.SUCCESS(f"\n✓ Total de categorías: {Category.objects.count()}"))
