#!/bin/bash

echo "🎨 MercaTico - Configuración de Íconos"
echo "======================================"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Debes ejecutar este script desde el directorio de la app Flutter"
    exit 1
fi

# Paso 1: Instalar dependencias
echo "📦 Paso 1: Instalando dependencias..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "❌ Error instalando dependencias"
    exit 1
fi
echo "✅ Dependencias instaladas"
echo ""

# Paso 2: Generar íconos
echo "🎨 Paso 2: Generando íconos para Android, iOS y Web..."
flutter pub run flutter_launcher_icons
if [ $? -ne 0 ]; then
    echo "❌ Error generando íconos"
    exit 1
fi
echo "✅ Íconos generados exitosamente"
echo ""

# Paso 3: Verificar archivos generados
echo "🔍 Paso 3: Verificando archivos generados..."

echo "  Android:"
if [ -f "android/app/src/main/res/mipmap-hdpi/ic_launcher.png" ]; then
    echo "    ✅ Íconos Android generados"
else
    echo "    ⚠️  Íconos Android no encontrados"
fi

echo "  iOS:"
if [ -d "ios/Runner/Assets.xcassets/AppIcon.appiconset" ]; then
    echo "    ✅ Íconos iOS generados"
else
    echo "    ⚠️  Íconos iOS no encontrados"
fi

echo "  Web:"
if [ -f "web/icons/Icon-192.png" ]; then
    echo "    ✅ Íconos Web generados"
else
    echo "    ⚠️  Íconos Web no encontrados"
fi

echo ""
echo "🚀 ¡Configuración completada!"
echo ""
echo "Próximos pasos:"
echo "  • Para Android: flutter build apk"
echo "  • Para iOS: flutter build ios"
echo "  • Para Web: flutter build web --release --base-href /"
echo ""
