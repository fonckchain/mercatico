#!/bin/bash

echo "🔐 MercaTico - Configuración de Firma para Android"
echo "=================================================="
echo ""
echo "Este script te ayudará a configurar todo lo necesario para publicar en Play Store"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Debes ejecutar este script desde el directorio de la app Flutter"
    exit 1
fi

# Paso 1: Verificar/crear keystore
KEYSTORE_PATH="$HOME/mercatico-keystore.jks"

if [ -f "$KEYSTORE_PATH" ]; then
    echo "✅ Keystore ya existe en: $KEYSTORE_PATH"
    echo ""
else
    echo "📝 Paso 1: Crear Keystore"
    echo "========================"
    echo ""
    echo "El keystore es necesario para firmar tu app."
    echo "⚠️  IMPORTANTE: Guarda el archivo y las contraseñas en un lugar seguro!"
    echo ""
    read -p "¿Deseas crear el keystore ahora? (s/n): " create_keystore

    if [ "$create_keystore" = "s" ]; then
        echo ""
        echo "Creando keystore en: $KEYSTORE_PATH"
        echo ""
        keytool -genkey -v -keystore "$KEYSTORE_PATH" \
            -keyalg RSA -keysize 2048 -validity 10000 \
            -alias mercatico

        if [ $? -eq 0 ]; then
            echo ""
            echo "✅ Keystore creado exitosamente"
            echo ""
            echo "⚠️  IMPORTANTE: Haz backup del archivo:"
            echo "   $KEYSTORE_PATH"
            echo ""
        else
            echo "❌ Error creando keystore"
            exit 1
        fi
    else
        echo ""
        echo "⏭️  Saltando creación de keystore"
        echo "   Puedes crearlo manualmente después con:"
        echo "   keytool -genkey -v -keystore ~/mercatico-keystore.jks \\"
        echo "     -keyalg RSA -keysize 2048 -validity 10000 \\"
        echo "     -alias mercatico"
        echo ""
    fi
fi

# Paso 2: Crear key.properties
echo "📝 Paso 2: Configurar key.properties"
echo "==================================="
echo ""

KEY_PROPS_FILE="android/key.properties"

if [ -f "$KEY_PROPS_FILE" ]; then
    echo "⚠️  El archivo key.properties ya existe"
    read -p "¿Deseas sobrescribirlo? (s/n): " overwrite
    if [ "$overwrite" != "s" ]; then
        echo "⏭️  Manteniendo archivo existente"
        KEY_PROPS_EXISTS=true
    fi
fi

if [ ! -f "$KEY_PROPS_FILE" ] || [ "$overwrite" = "s" ]; then
    echo ""
    echo "Ingresa la información del keystore:"
    echo ""

    # Pedir contraseñas
    read -sp "Password del keystore: " STORE_PASSWORD
    echo ""
    read -sp "Password de la key (puede ser el mismo): " KEY_PASSWORD
    echo ""
    echo ""

    # Crear archivo key.properties
    cat > "$KEY_PROPS_FILE" << EOF
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=mercatico
storeFile=$KEYSTORE_PATH
EOF

    echo "✅ Archivo key.properties creado"
    echo ""
fi

# Paso 3: Actualizar .gitignore
echo "📝 Paso 3: Actualizar .gitignore"
echo "==============================="
echo ""

if ! grep -q "android/key.properties" .gitignore 2>/dev/null; then
    echo "android/key.properties" >> .gitignore
    echo "*.jks" >> .gitignore
    echo "✅ .gitignore actualizado"
else
    echo "✅ .gitignore ya incluye key.properties"
fi
echo ""

# Paso 4: Verificar build.gradle
echo "📝 Paso 4: Verificar build.gradle"
echo "================================"
echo ""

if grep -q "keystoreProperties" android/app/build.gradle; then
    echo "✅ build.gradle ya está configurado para firma"
else
    echo "⚠️  build.gradle necesita configuración manual"
    echo ""
    echo "Agrega esto al principio de android/app/build.gradle:"
    echo ""
    cat << 'EOF'
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
EOF
    echo ""
fi

# Paso 5: Verificar versión
echo "📝 Paso 5: Verificar versión de la app"
echo "====================================="
echo ""

CURRENT_VERSION=$(grep "^version:" pubspec.yaml | awk '{print $2}')
echo "Versión actual: $CURRENT_VERSION"
echo ""
read -p "¿Deseas actualizar la versión? (s/n): " update_version

if [ "$update_version" = "s" ]; then
    read -p "Nueva versión (formato: 1.0.0+1): " new_version
    sed -i "s/^version:.*/version: $new_version/" pubspec.yaml
    echo "✅ Versión actualizada a: $new_version"
fi
echo ""

# Paso 6: Generar íconos si no se ha hecho
echo "📝 Paso 6: Verificar íconos"
echo "========================="
echo ""

if [ -f "android/app/src/main/res/mipmap-hdpi/ic_launcher.png" ]; then
    echo "✅ Íconos de Android ya están generados"
else
    echo "⚠️  Los íconos aún no están generados"
    read -p "¿Deseas generarlos ahora? (s/n): " gen_icons

    if [ "$gen_icons" = "s" ]; then
        echo "Ejecutando flutter pub get..."
        flutter pub get
        echo "Generando íconos..."
        flutter pub run flutter_launcher_icons
        echo "✅ Íconos generados"
    fi
fi
echo ""

# Resumen
echo "🎉 Configuración Completada"
echo "========================="
echo ""
echo "✅ Pasos completados:"
echo "   • Keystore configurado: $KEYSTORE_PATH"
echo "   • key.properties creado"
echo "   • .gitignore actualizado"
echo ""
echo "📋 Próximos pasos:"
echo ""
echo "1. Hacer build del App Bundle:"
echo "   flutter build appbundle --release"
echo ""
echo "2. El archivo se generará en:"
echo "   build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "3. Sube ese archivo a Google Play Console"
echo ""
echo "4. Para más detalles, ver: DEPLOYMENT_GUIDE.md"
echo ""
echo "⚠️  RECUERDA:"
echo "   • Hacer backup del keystore: $KEYSTORE_PATH"
echo "   • Guardar las contraseñas en un lugar seguro"
echo "   • NO commitear key.properties al repositorio"
echo ""
