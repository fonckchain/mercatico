# Generated manually on 2025-10-26

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0004_add_gps_to_buyer_profile"),
    ]

    operations = [
        migrations.AddField(
            model_name="sellerprofile",
            name="accepts_sinpe",
            field=models.BooleanField(
                default=True,
                help_text="Indica si el vendedor acepta pagos con SINPE Móvil (valor por defecto para nuevos productos)",
                verbose_name="acepta SINPE Móvil",
            ),
        ),
    ]
