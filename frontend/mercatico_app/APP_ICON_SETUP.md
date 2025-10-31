# Configuración de Íconos y Logo de la App

## Estado Actual

He configurado todo el sistema para generar automáticamente los íconos de la app. Solo necesitas crear las imágenes del logo.

## Pasos para Completar la Configuración

### 1. Crear el Logo

Necesitas crear **2 imágenes** en el directorio `assets/images/`:

#### a) `logo.png` (1024x1024px)
- **Tamaño**: 1024x1024 píxeles
- **Formato**: PNG con fondo transparente
- **Contenido**: Ícono de tienda (store icon) con el estilo verde de MercaTico (#4CAF50)
- **Uso**: Ícono principal para Android, iOS y Web

**Opciones para crear:**
1. **Usar un diseñador gráfico** (recomendado)
2. **Usar Canva**:
   - Ve a canva.com
   - Crear diseño personalizado de 1024x1024
   - Buscar "store icon" o "shop icon"
   - Personalizar con color verde (#4CAF50)
   - Descargar como PNG transparente

3. **Usar Figma/Adobe Illustrator**:
   - Crear artboard de 1024x1024
   - Diseñar ícono de tienda minimalista
   - Exportar como PNG

#### b) `logo_foreground.png` (1024x1024px)
- **Tamaño**: 1024x1024 píxeles
- **Formato**: PNG con fondo transparente
- **Contenido**: Solo el ícono (sin fondo), centrado
- **Área segura**: El ícono debe estar dentro de un círculo de 432x432 centrado
- **Uso**: Para Android adaptive icons (el fondo será el color verde)

### 2. Instalar Dependencias

```bash
cd /home/fonck/development/projects/mercatico/frontend/mercatico_app
flutter pub get
```

### 3. Generar Íconos

Una vez que hayas colocado las imágenes en `assets/images/`, ejecuta:

```bash
flutter pub run flutter_launcher_icons
```

Esto generará automáticamente:
- ✅ Íconos de Android (todos los tamaños)
- ✅ Íconos de iOS (todos los tamaños)
- ✅ Favicon para web
- ✅ Íconos PWA (Progressive Web App)
- ✅ Adaptive icons para Android

### 4. Verificar los Resultados

Después de generar, verifica que se crearon:

**Android:**
- `android/app/src/main/res/mipmap-*/ic_launcher.png`
- `android/app/src/main/res/mipmap-*/ic_launcher_foreground.png`
- `android/app/src/main/res/drawable/ic_launcher_background.xml`

**iOS:**
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

**Web:**
- `web/icons/Icon-192.png`
- `web/icons/Icon-512.png`
- `web/icons/Icon-maskable-*.png`
- `web/favicon.png`

## Archivos que He Configurado

### 1. `pubspec.yaml`
- ✅ Agregado `flutter_launcher_icons` como dev dependency
- ✅ Configurado para generar íconos para Android, iOS y Web
- ✅ Color de fondo: `#4CAF50` (verde MercaTico)
- ✅ Agregado `assets/images/` al proyecto

### 2. `web/index.html`
- ✅ Actualizado título: "MercaTico - Marketplace Local"
- ✅ Meta tags mejorados para SEO
- ✅ Favicon configurado
- ✅ Theme color: verde (#4CAF50)
- ✅ Meta tags para iOS/PWA

### 3. `web/manifest.json`
- ✅ Nombre de la app actualizado
- ✅ Descripción actualizada
- ✅ Colores de tema configurados

## Alternativa Rápida: Usar un Ícono Simple

Si quieres probar rápidamente, puedes usar un ícono simple de Material Icons:

1. Ir a https://fonts.google.com/icons
2. Buscar "store" o "storefront"
3. Descargar como SVG
4. Convertir a PNG 1024x1024 en:
   - https://convertio.co/svg-png/
   - https://cloudconvert.com/svg-to-png

O usar este comando para crear un placeholder simple (requiere ImageMagick):

```bash
# Crear un ícono verde simple con texto
convert -size 1024x1024 xc:'#4CAF50' \
  -gravity center -pointsize 200 -fill white \
  -annotate +0+0 'MT' \
  assets/images/logo.png
```

## Próximos Pasos Después de Generar Íconos

### Para Web (Vercel)
1. Hacer build: `flutter build web --release --base-href /`
2. Los íconos se incluirán automáticamente en el build
3. Push y deploy en Vercel

### Para Android
1. Hacer build: `flutter build apk --release`
2. El APK incluirá los nuevos íconos
3. Probar instalando el APK

### Para iOS
1. Hacer build: `flutter build ios --release`
2. Los íconos se aplicarán automáticamente
3. Continuar con el proceso de App Store

## Notas Importantes

- **Tamaño mínimo**: 1024x1024 píxeles para mejor calidad
- **Formato**: PNG con transparencia
- **Colores**: Usar verde (#4CAF50) como color principal
- **Estilo**: Simple y reconocible, funciona bien en tamaños pequeños
- **Adaptive icon**: El foreground debe tener margen de seguridad (área del círculo)

## Troubleshooting

**Si el comando falla:**
```bash
# Limpiar y reinstalar
flutter clean
flutter pub get
flutter pub run flutter_launcher_icons
```

**Si los íconos no se actualizan:**
- Android: Desinstalar y reinstalar la app
- iOS: Limpiar build folder en Xcode
- Web: Limpiar caché del navegador (Ctrl+Shift+R)

## Recursos Útiles

- [Flutter Launcher Icons](https://pub.dev/packages/flutter_launcher_icons)
- [Android Adaptive Icons](https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive)
- [iOS App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [PWA Icons](https://web.dev/add-manifest/)
