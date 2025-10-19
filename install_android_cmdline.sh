#!/bin/bash

# Script para instalar Android SDK Command Line Tools (más ligero que Android Studio)
# Ideal para desarrollo Flutter sin necesidad de Android Studio IDE

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================="
echo "  Instalación de Android SDK (CLI)"
echo "=========================================${NC}"
echo ""

echo -e "${YELLOW}[1/6] Instalando dependencias...${NC}"
sudo apt update
sudo apt install -y openjdk-17-jdk wget unzip

echo -e "${GREEN}✓ Dependencias instaladas${NC}"

echo -e "${YELLOW}[2/6] Creando directorios...${NC}"
mkdir -p $HOME/Android/Sdk/cmdline-tools

echo -e "${GREEN}✓ Directorios creados${NC}"

echo -e "${YELLOW}[3/6] Descargando Android Command Line Tools...${NC}"
cd $HOME/Android/Sdk/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip

echo -e "${GREEN}✓ Command Line Tools descargado${NC}"

echo -e "${YELLOW}[4/6] Extrayendo archivos...${NC}"
unzip commandlinetools-linux-11076708_latest.zip
mv cmdline-tools latest
rm commandlinetools-linux-11076708_latest.zip

echo -e "${GREEN}✓ Archivos extraídos${NC}"

echo -e "${YELLOW}[5/6] Configurando variables de entorno...${NC}"

# Agregar al .bashrc
if ! grep -q "ANDROID_HOME" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Android SDK" >> ~/.bashrc
    echo "export ANDROID_HOME=\$HOME/Android/Sdk" >> ~/.bashrc
    echo "export PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin" >> ~/.bashrc
    echo "export PATH=\$PATH:\$ANDROID_HOME/platform-tools" >> ~/.bashrc
    echo "export PATH=\$PATH:\$ANDROID_HOME/emulator" >> ~/.bashrc
    echo -e "${GREEN}✓ Variables agregadas a ~/.bashrc${NC}"
else
    echo -e "${YELLOW}Variables ya configuradas${NC}"
fi

# Agregar a .zshrc si existe
if [ -f ~/.zshrc ]; then
    if ! grep -q "ANDROID_HOME" ~/.zshrc; then
        echo "" >> ~/.zshrc
        echo "# Android SDK" >> ~/.zshrc
        echo "export ANDROID_HOME=\$HOME/Android/Sdk" >> ~/.zshrc
        echo "export PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin" >> ~/.zshrc
        echo "export PATH=\$PATH:\$ANDROID_HOME/platform-tools" >> ~/.zshrc
        echo "export PATH=\$PATH:\$ANDROID_HOME/emulator" >> ~/.zshrc
    fi
fi

# Exportar para esta sesión
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

echo -e "${GREEN}✓ Variables de entorno configuradas${NC}"

echo -e "${YELLOW}[6/6] Instalando componentes del SDK...${NC}"
echo "Esto puede tomar varios minutos..."

# Aceptar licencias
yes | sdkmanager --licenses

# Instalar componentes necesarios
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" "emulator" "system-images;android-34;google_apis;x86_64"

echo -e "${GREEN}✓ Componentes del SDK instalados${NC}"

echo ""
echo -e "${GREEN}========================================="
echo "  ¡Android SDK instalado!"
echo "=========================================${NC}"
echo ""
echo "Próximos pasos:"
echo ""
echo "1. Reinicia tu terminal o ejecuta:"
echo "   source ~/.bashrc"
echo ""
echo "2. Configura Flutter con el SDK:"
echo "   export PATH=\"\$PATH:\$HOME/flutter/bin\""
echo "   flutter config --android-sdk \$HOME/Android/Sdk"
echo "   flutter doctor --android-licenses"
echo ""
echo "3. Verifica la instalación:"
echo "   flutter doctor"
echo ""
echo "4. Crear un emulador (opcional):"
echo "   avdmanager create avd -n mercatico_test -k \"system-images;android-34;google_apis;x86_64\""
echo ""
echo "5. O conecta un dispositivo físico Android con USB debugging habilitado"
echo ""
