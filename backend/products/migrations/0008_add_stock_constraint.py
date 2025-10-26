# Generated manually on 2025-10-26

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("products", "0007_add_delivery_options_to_product"),
    ]

    operations = [
        migrations.AddConstraint(
            model_name="product",
            constraint=models.CheckConstraint(
                check=models.Q(stock__gte=0),
                name="stock_non_negative",
            ),
        ),
    ]
