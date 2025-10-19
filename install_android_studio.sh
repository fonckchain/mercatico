#!/bin/bash

# Script para instalar Android Studio y configurar Android SDK para Flutter

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================="
echo "  Instalación de Android Studio"
echo "=========================================${NC}"
echo ""

# Verificar si ya está instalado
if command -v android-studio &> /dev/null; then
    echo -e "${YELLOW}Android Studio ya está instalado${NC}"
    exit 0
fi

echo -e "${YELLOW}[1/6] Instalando dependencias necesarias...${NC}"
sudo apt update
sudo apt install -y openjdk-17-jdk wget unzip

echo -e "${GREEN}✓ Dependencias instaladas${NC}"

echo -e "${YELLOW}[2/6] Descargando Android Studio...${NC}"
cd ~
wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2024.2.1.11/android-studio-2024.2.1.11-linux.tar.gz

echo -e "${GREEN}✓ Android Studio descargado${NC}"

echo -e "${YELLOW}[3/6] Extrayendo Android Studio...${NC}"
sudo tar -xzf android-studio-2024.2.1.11-linux.tar.gz -C /opt/

echo -e "${GREEN}✓ Android Studio extraído${NC}"

echo -e "${YELLOW}[4/6] Configurando Android Studio...${NC}"

# Crear directorio de SDK
mkdir -p $HOME/Android/Sdk

# Agregar Android Studio al PATH
if ! grep -q "android-studio/bin" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Android Studio" >> ~/.bashrc
    echo "export ANDROID_HOME=\$HOME/Android/Sdk" >> ~/.bashrc
    echo "export PATH=\$PATH:/opt/android-studio/bin" >> ~/.bashrc
    echo "export PATH=\$PATH:\$ANDROID_HOME/platform-tools" >> ~/.bashrc
    echo "export PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin" >> ~/.bashrc
    echo -e "${GREEN}✓ PATH agregado a ~/.bashrc${NC}"
else
    echo -e "${GREEN}✓ PATH ya está configurado${NC}"
fi

# Agregar a .zshrc si existe
if [ -f ~/.zshrc ]; then
    if ! grep -q "android-studio/bin" ~/.zshrc; then
        echo "" >> ~/.zshrc
        echo "# Android Studio" >> ~/.zshrc
        echo "export ANDROID_HOME=\$HOME/Android/Sdk" >> ~/.zshrc
        echo "export PATH=\$PATH:/opt/android-studio/bin" >> ~/.zshrc
        echo "export PATH=\$PATH:\$ANDROID_HOME/platform-tools" >> ~/.zshrc
        echo "export PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin" >> ~/.zshrc
    fi
fi

echo -e "${GREEN}✓ Android Studio configurado${NC}"

echo -e "${YELLOW}[5/6] Creando acceso directo...${NC}"

cat > ~/.local/share/applications/android-studio.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Android Studio
Icon=/opt/android-studio/bin/studio.png
Exec=/opt/android-studio/bin/studio.sh
Comment=Android Development IDE
Categories=Development;IDE;
Terminal=false
EOF

echo -e "${GREEN}✓ Acceso directo creado${NC}"

echo -e "${YELLOW}[6/6] Limpiando archivos temporales...${NC}"
rm ~/android-studio-2024.2.1.11-linux.tar.gz

echo ""
echo -e "${GREEN}========================================="
echo "  ¡Android Studio instalado!"
echo "=========================================${NC}"
echo ""
echo "IMPORTANTE: Ahora necesitas:"
echo ""
echo "1. Reiniciar tu terminal o ejecutar:"
echo "   source ~/.bashrc"
echo ""
echo "2. Ejecutar Android Studio por primera vez:"
echo "   /opt/android-studio/bin/studio.sh"
echo ""
echo "3. Durante la primera ejecución:"
echo "   - Acepta la configuración estándar"
echo "   - Instala el Android SDK (se descargará ~3GB)"
echo "   - Acepta las licencias de Android"
echo ""
echo "4. Después, configura Flutter:"
echo "   flutter config --android-sdk \$HOME/Android/Sdk"
echo "   flutter doctor --android-licenses"
echo ""
