from django.core.management.base import BaseCommand
from users.models import User


class Command(BaseCommand):
    help = 'Crea usuarios de prueba para desarrollo'

    def handle(self, *args, **options):
        # Usuario vendedor de prueba
        seller_email = "artesanias.don.juan@test.cr"
        seller_password = "test1234"

        # Verificar si ya existe
        if User.objects.filter(email=seller_email).exists():
            self.stdout.write(self.style.WARNING(f"Usuario {seller_email} ya existe"))
            seller = User.objects.get(email=seller_email)
        else:
            # Crear usuario vendedor
            seller = User.objects.create_user(
                email=seller_email,
                password=seller_password,
                first_name="Juan",
                last_name="Artesano",
                phone="+50688887777",
                role="seller",
                is_active=True,
            )
            self.stdout.write(self.style.SUCCESS(f"✓ Usuario vendedor creado: {seller_email}"))

        # Actualizar perfil de vendedor
        if hasattr(seller, 'seller_profile'):
            seller.seller_profile.business_name = "Artesanías Don Juan"
            seller.seller_profile.description = "Artesanías tradicionales costarricenses"
            seller.seller_profile.province = "San José"
            seller.seller_profile.canton = "Central"
            seller.seller_profile.district = "Carmen"
            seller.seller_profile.address = "100m norte de la iglesia"
            seller.seller_profile.sinpe_number = "88887777"
            seller.seller_profile.accepts_cash = True
            seller.seller_profile.offers_pickup = True
            seller.seller_profile.offers_delivery = True
            seller.seller_profile.save()
            self.stdout.write(self.style.SUCCESS("✓ Perfil de vendedor actualizado"))

        # Usuario comprador de prueba
        buyer_email = "maria.comprador@test.cr"
        buyer_password = "test1234"

        if User.objects.filter(email=buyer_email).exists():
            self.stdout.write(self.style.WARNING(f"Usuario {buyer_email} ya existe"))
        else:
            buyer = User.objects.create_user(
                email=buyer_email,
                password=buyer_password,
                first_name="María",
                last_name="Compradora",
                phone="+50699998888",
                role="buyer",
                is_active=True,
            )
            self.stdout.write(self.style.SUCCESS(f"✓ Usuario comprador creado: {buyer_email}"))

        self.stdout.write(self.style.SUCCESS("\n=== Usuarios de prueba creados ==="))
        self.stdout.write(f"Vendedor: {seller_email} / {seller_password}")
        self.stdout.write(f"Comprador: {buyer_email} / {buyer_password}")
