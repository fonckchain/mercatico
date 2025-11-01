#!/usr/bin/env python3
"""
Script para generar los logos de MercaTico usando el ícono de Material Icons
Requiere: pip install Pillow requests
"""

import os
from PIL import Image, ImageDraw
import io

def create_store_icon(size, color, bg_color=None):
    """
    Crea un ícono de tienda simple similar a Material Icons store
    """
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Si hay fondo, dibujarlo con bordes redondeados
    if bg_color:
        # Crear máscara para bordes redondeados
        mask = Image.new('L', (size, size), 0)
        mask_draw = ImageDraw.Draw(mask)
        radius = int(size * 0.2)
        mask_draw.rounded_rectangle(
            [(0, 0), (size, size)],
            radius=radius,
            fill=255
        )

        # Aplicar fondo con máscara
        bg_img = Image.new('RGBA', (size, size), bg_color)
        img.paste(bg_img, (0, 0), mask)

    # Dibujar ícono de tienda (simplificado)
    icon_size = int(size * (0.6 if bg_color else 0.7))
    padding = (size - icon_size) // 2

    # Rectángulo principal (cuerpo de la tienda)
    store_top = padding + int(icon_size * 0.3)
    store_height = int(icon_size * 0.6)
    draw.rectangle(
        [padding, store_top, size - padding, store_top + store_height],
        fill=color,
        outline=None
    )

    # Techo (triángulo)
    roof_height = int(icon_size * 0.25)
    roof_points = [
        (size // 2, padding),  # Punto superior
        (padding, store_top),  # Izquierda
        (size - padding, store_top)  # Derecha
    ]
    draw.polygon(roof_points, fill=color)

    # Puerta
    door_width = int(icon_size * 0.25)
    door_height = int(icon_size * 0.4)
    door_x = (size - door_width) // 2
    door_y = store_top + store_height - door_height

    # Si hay fondo verde, la puerta es blanca, sino es transparente/oscura
    door_color = (255, 255, 255, 255) if bg_color else (200, 200, 200, 255)
    draw.rectangle(
        [door_x, door_y, door_x + door_width, door_y + door_height],
        fill=door_color
    )

    # Ventanas (dos)
    window_size = int(icon_size * 0.15)
    window_y = store_top + int(icon_size * 0.15)
    window_spacing = int(icon_size * 0.15)

    # Ventana izquierda
    window1_x = padding + window_spacing
    draw.rectangle(
        [window1_x, window_y, window1_x + window_size, window_y + window_size],
        fill=door_color
    )

    # Ventana derecha
    window2_x = size - padding - window_spacing - window_size
    draw.rectangle(
        [window2_x, window_y, window2_x + window_size, window_y + window_size],
        fill=door_color
    )

    return img

def main():
    print('🎨 Generando logos de MercaTico...')

    # Colores
    green = (76, 175, 80, 255)  # #4CAF50
    white = (255, 255, 255, 255)

    # Crear directorio si no existe
    os.makedirs('assets/images', exist_ok=True)

    # Generar logo principal (con fondo verde)
    print('📦 Generando logo.png...')
    logo = create_store_icon(1024, white, green)
    logo.save('assets/images/logo.png', 'PNG')
    print('✅ Logo principal generado: assets/images/logo.png')

    # Generar logo foreground (solo ícono blanco, sin fondo)
    print('📦 Generando logo_foreground.png...')
    logo_fg = create_store_icon(1024, white, None)
    logo_fg.save('assets/images/logo_foreground.png', 'PNG')
    print('✅ Logo foreground generado: assets/images/logo_foreground.png')

    print('')
    print('🚀 Logos generados exitosamente!')
    print('📝 Ahora ejecuta: flutter pub run flutter_launcher_icons')

if __name__ == '__main__':
    main()
