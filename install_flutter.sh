#!/bin/bash

# Script para instalar Flutter en Ubuntu/Debian

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================="
echo "  Instalación de Flutter"
echo "=========================================${NC}"
echo ""

# Verificar dependencias
echo -e "${YELLOW}[1/5] Verificando dependencias...${NC}"

# Instalar dependencias necesarias
sudo apt update
sudo apt install -y curl git unzip xz-utils zip libglu1-mesa

echo -e "${GREEN}✓ Dependencias instaladas${NC}"

# Descargar Flutter
echo -e "${YELLOW}[2/5] Descargando Flutter SDK...${NC}"

cd ~
if [ -d "flutter" ]; then
    echo -e "${YELLOW}Flutter ya existe, actualizando...${NC}"
    cd flutter
    git pull
    cd ..
else
    git clone https://github.com/flutter/flutter.git -b stable
fi

echo -e "${GREEN}✓ Flutter descargado${NC}"

# Agregar Flutter al PATH
echo -e "${YELLOW}[3/5] Configurando PATH...${NC}"

FLUTTER_PATH="$HOME/flutter/bin"

# Agregar a .bashrc si no existe
if ! grep -q "flutter/bin" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Flutter" >> ~/.bashrc
    echo "export PATH=\"\$PATH:$FLUTTER_PATH\"" >> ~/.bashrc
    echo -e "${GREEN}✓ PATH agregado a ~/.bashrc${NC}"
else
    echo -e "${GREEN}✓ PATH ya está configurado${NC}"
fi

# Agregar a .zshrc si existe
if [ -f ~/.zshrc ]; then
    if ! grep -q "flutter/bin" ~/.zshrc; then
        echo "" >> ~/.zshrc
        echo "# Flutter" >> ~/.zshrc
        echo "export PATH=\"\$PATH:$FLUTTER_PATH\"" >> ~/.zshrc
        echo -e "${GREEN}✓ PATH agregado a ~/.zshrc${NC}"
    fi
fi

# Exportar para esta sesión
export PATH="$PATH:$FLUTTER_PATH"

# Ejecutar flutter doctor
echo -e "${YELLOW}[4/5] Ejecutando flutter doctor...${NC}"
~/flutter/bin/flutter doctor

echo -e "${YELLOW}[5/5] Aceptando licencias de Android...${NC}"
yes | ~/flutter/bin/flutter doctor --android-licenses 2>/dev/null || echo "Licencias ya aceptadas o no disponibles"

echo ""
echo -e "${GREEN}========================================="
echo "  ¡Flutter instalado!"
echo "=========================================${NC}"
echo ""
echo "Para usar Flutter en esta terminal:"
echo "  export PATH=\"\$PATH:$HOME/flutter/bin\""
echo ""
echo "Para nuevas terminales, reinicia tu sesión o ejecuta:"
echo "  source ~/.bashrc"
echo ""
echo "Verificar instalación:"
echo "  flutter --version"
echo "  flutter doctor"
echo ""
