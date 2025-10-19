#!/bin/bash

# Script de inicialización del proyecto MercaTico Backend
# Este script ayuda a configurar rápidamente el entorno de desarrollo

# Salir inmediatamente si un comando falla
set -e

# Función para manejar errores
error_exit() {
    echo -e "${RED}✗ Error: $1${NC}" >&2
    exit 1
}

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
    error_exit "Este script debe ejecutarse desde el directorio backend/"
fi

# Verificar que python3 está instalado
if ! command -v python3 &> /dev/null; then
    error_exit "python3 no está instalado. Por favor, instala Python 3.12 o superior."
fi

# Verificar versión de Python
PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
echo "Usando Python version: $PYTHON_VERSION"

# Verificar que python3-venv está disponible
echo "Verificando disponibilidad de python3-venv..."
if ! python3 -m venv --help &> /dev/null; then
    error_exit "python3-venv no está disponible. Instala con: sudo apt install python3.12-venv"
fi

# 1. Crear entorno virtual
echo -e "${YELLOW}[1/8] Creando entorno virtual...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv || error_exit "No se pudo crear el entorno virtual"
    echo -e "${GREEN}✓ Entorno virtual creado${NC}"
else
    echo -e "${GREEN}✓ Entorno virtual ya existe${NC}"
fi

# 2. Activar entorno virtual
echo -e "${YELLOW}[2/8] Activando entorno virtual...${NC}"
if [ ! -f "venv/bin/activate" ]; then
    error_exit "No se encontró venv/bin/activate. El entorno virtual no se creó correctamente."
fi
source venv/bin/activate || error_exit "No se pudo activar el entorno virtual"
echo -e "${GREEN}✓ Entorno virtual activado${NC}"

# 3. Actualizar pip
echo -e "${YELLOW}[3/8] Actualizando pip...${NC}"
python -m pip install --upgrade pip > /dev/null 2>&1 || error_exit "No se pudo actualizar pip"
echo -e "${GREEN}✓ pip actualizado${NC}"

# 4. Instalar dependencias
echo -e "${YELLOW}[4/8] Instalando dependencias...${NC}"
if [ ! -f "requirements.txt" ]; then
    error_exit "No se encontró el archivo requirements.txt"
fi
pip install -r requirements.txt || error_exit "No se pudieron instalar las dependencias"
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

# 7. Ejecutar migraciones (si la base de datos está disponible)
echo -e "${YELLOW}[7/8] Ejecutando migraciones de base de datos...${NC}"
echo "Verificando conexión a la base de datos..."

# Intentar hacer las migraciones, pero no fallar si la DB no está disponible
if python manage.py check --database default > /dev/null 2>&1; then
    python manage.py makemigrations || error_exit "Error al crear migraciones"
    python manage.py migrate || error_exit "Error al aplicar migraciones"
    echo -e "${GREEN}✓ Migraciones completadas${NC}"

    # 8. Crear superusuario (opcional)
    echo -e "${YELLOW}[8/8] ¿Deseas crear un superusuario? (s/n)${NC}"
    read -r create_superuser
    if [ "$create_superuser" = "s" ] || [ "$create_superuser" = "S" ]; then
        python manage.py createsuperuser
    fi
else
    echo -e "${YELLOW}⚠ Base de datos no disponible. Saltando migraciones.${NC}"
    echo -e "${YELLOW}  Asegúrate de configurar PostgreSQL y ejecutar:${NC}"
    echo -e "${YELLOW}  - python manage.py migrate${NC}"
    echo -e "${YELLOW}  - python manage.py createsuperuser${NC}"
fi

echo ""
echo -e "${GREEN}========================================="
echo "  ¡Configuración Completada!"
echo "=========================================${NC}"
echo ""
echo "Próximos pasos:"
echo "1. Configura PostgreSQL (ver QUICKSTART.md para instrucciones)"
echo "2. Edita el archivo .env con tus credenciales"
echo "3. Ejecuta las migraciones: python manage.py migrate"
echo "4. Crea un superusuario: python manage.py createsuperuser"
echo "5. Inicia el servidor: python manage.py runserver"
echo ""
echo "Recursos:"
echo "- API Docs: http://localhost:8000/api/"
echo "- Admin: http://localhost:8000/admin/"
echo "- Health Check: http://localhost:8000/health/"
echo "- Documentación: Ver QUICKSTART.md"
echo ""
