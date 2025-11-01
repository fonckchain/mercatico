# MercaTico - Inicio Rápido

## 🚀 Generar Íconos de la App (Android, iOS, Web)

Los logos ya están generados usando el mismo ícono de tienda de la navegación. Solo necesitas ejecutar el generador de íconos:

### Opción 1: Script Automático (Recomendado)

```bash
./setup_icons.sh
```

### Opción 2: Manual

```bash
# 1. Instalar dependencias
flutter pub get

# 2. Generar íconos
flutter pub run flutter_launcher_icons
```

## ✅ Resultado

Después de ejecutar, tendrás:
- **Android**: Íconos en todos los tamaños + adaptive icons
- **iOS**: Íconos en Assets.xcassets
- **Web**: Favicon + PWA icons

## 🎨 Logos Incluidos

- `assets/images/logo.png` - Logo con fondo verde (#4CAF50)
- `assets/images/logo_foreground.png` - Solo ícono (para adaptive icons)

Ambos usan el mismo diseño del ícono `Icons.store` de Material.

## 📱 Siguiente Paso: Build

### Para Web (Vercel)
```bash
flutter build web --release --base-href /
```

### Para Android (APK)
```bash
flutter build apk --release
```

### Para iOS
```bash
flutter build ios --release
```

## 🔄 Regenerar Logos (Opcional)

Si quieres modificar los logos:

```bash
# Editar generate_logo.py para cambiar diseño/colores
python3 generate_logo.py

# Luego regenerar íconos
flutter pub run flutter_launcher_icons
```

## 📚 Más Información

Ver `APP_ICON_SETUP.md` para detalles técnicos completos.
