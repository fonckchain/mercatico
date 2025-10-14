#!/bin/bash

# Script de inicialización del proyecto MercaTico Backend
# Este script ayuda a configurar rápidamente el entorno de desarrollo

echo "========================================="
echo "  MercaTico - Inicialización Backend"
echo "========================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar si estamos en el directorio correcto
if [ ! -f "manage.py" ]; then
    echo -e "${RED}Error: Este script debe ejecutarse desde el directorio backend/${NC}"
    exit 1
fi

# 1. Crear entorno virtual
echo -e "${YELLOW}[1/8] Creando entorno virtual...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo -e "${GREEN}✓ Entorno virtual creado${NC}"
else
    echo -e "${GREEN}✓ Entorno virtual ya existe${NC}"
fi

# 2. Activar entorno virtual
echo -e "${YELLOW}[2/8] Activando entorno virtual...${NC}"
source venv/bin/activate
echo -e "${GREEN}✓ Entorno virtual activado${NC}"

# 3. Actualizar pip
echo -e "${YELLOW}[3/8] Actualizando pip...${NC}"
pip install --upgrade pip > /dev/null 2>&1
echo -e "${GREEN}✓ pip actualizado${NC}"

# 4. Instalar dependencias
echo -e "${YELLOW}[4/8] Instalando dependencias...${NC}"
pip install -r requirements.txt
echo -e "${GREEN}✓ Dependencias instaladas${NC}"

# 5. Crear archivo .env si no existe
echo -e "${YELLOW}[5/8] Configurando variables de entorno...${NC}"
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo -e "${GREEN}✓ Archivo .env creado desde .env.example${NC}"
    echo -e "${YELLOW}⚠ IMPORTANTE: Edita el archivo .env con tus credenciales${NC}"
else
    echo -e "${GREEN}✓ Archivo .env ya existe${NC}"
fi

# 6. Crear directorio de logs
echo -e "${YELLOW}[6/8] Creando directorios necesarios...${NC}"
mkdir -p logs
mkdir -p media/receipts
mkdir -p media/products
mkdir -p media/seller_logos
echo -e "${GREEN}✓ Directorios creados${NC}"

# 7. Ejecutar migraciones
echo -e "${YELLOW}[7/8] Ejecutando migraciones de base de datos...${NC}"
python manage.py makemigrations
python manage.py migrate
echo -e "${GREEN}✓ Migraciones completadas${NC}"

# 8. Crear superusuario (opcional)
echo -e "${YELLOW}[8/8] ¿Deseas crear un superusuario? (s/n)${NC}"
read -r create_superuser
if [ "$create_superuser" = "s" ] || [ "$create_superuser" = "S" ]; then
    python manage.py createsuperuser
fi

echo ""
echo -e "${GREEN}========================================="
echo "  ¡Configuración Completada!"
echo "=========================================${NC}"
echo ""
echo "Próximos pasos:"
echo "1. Edita el archivo .env con tus credenciales"
echo "2. Ejecuta: python manage.py runserver"
echo "3. Visita: http://localhost:8000/admin"
echo ""
echo "Recursos:"
echo "- API Docs: http://localhost:8000/api/"
echo "- Admin: http://localhost:8000/admin/"
echo "- Health Check: http://localhost:8000/health/"
echo ""
