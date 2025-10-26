# Generated manually on 2025-10-26

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("products", "0008_add_stock_constraint"),
    ]

    operations = [
        migrations.AddField(
            model_name="product",
            name="accepts_sinpe",
            field=models.BooleanField(
                default=True,
                help_text="Si el vendedor acepta SINPE Móvil para este producto",
                verbose_name="acepta SINPE Móvil",
            ),
        ),
    ]
