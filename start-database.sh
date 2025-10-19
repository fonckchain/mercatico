#!/bin/bash

# Script para iniciar PostgreSQL con Docker
# MercaTico - Base de datos de desarrollo

set -e

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================="
echo "  MercaTico - Iniciar Base de Datos"
echo "=========================================${NC}"
echo ""

# Verificar que Docker está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Error: Docker no está instalado${NC}"
    echo "Instala Docker desde: https://docs.docker.com/get-docker/"
    exit 1
fi

# Verificar que Docker Compose está instalado
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
    echo -e "${RED}✗ Error: Docker Compose no está instalado${NC}"
    echo "Instala Docker Compose desde: https://docs.docker.com/compose/install/"
    exit 1
fi

# Detectar comando de docker-compose
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

echo -e "${YELLOW}[1/3] Iniciando contenedores de PostgreSQL...${NC}"

# Iniciar solo PostgreSQL (sin pgAdmin) con -d para ejecutar en background
$DOCKER_COMPOSE up -d postgres

echo -e "${GREEN}✓ Contenedor iniciado${NC}"
echo ""

echo -e "${YELLOW}[2/3] Esperando a que PostgreSQL esté listo...${NC}"

# Esperar hasta 30 segundos a que PostgreSQL esté listo
RETRY_COUNT=0
MAX_RETRIES=30

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if docker exec mercatico_postgres pg_isready -U mercatico_user -d mercatico &> /dev/null; then
        echo -e "${GREEN}✓ PostgreSQL está listo${NC}"
        break
    fi

    echo -n "."
    sleep 1
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

echo ""

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "${RED}✗ Error: PostgreSQL no respondió a tiempo${NC}"
    echo "Revisa los logs con: docker logs mercatico_postgres"
    exit 1
fi

echo ""
echo -e "${YELLOW}[3/3] Verificando conexión...${NC}"

# Mostrar información de conexión
echo -e "${GREEN}✓ Base de datos lista para usar${NC}"
echo ""
echo -e "${BLUE}Información de conexión:${NC}"
echo "  Host: localhost"
echo "  Puerto: 5432"
echo "  Base de datos: mercatico"
echo "  Usuario: mercatico_user"
echo "  Contraseña: mercatico_dev_password"
echo ""
echo -e "${BLUE}Cadena de conexión para .env:${NC}"
echo "  DATABASE_URL=postgresql://mercatico_user:mercatico_dev_password@localhost:5432/mercatico"
echo ""

# Preguntar si quiere iniciar pgAdmin
echo -e "${YELLOW}¿Deseas iniciar pgAdmin para gestión visual? (s/n)${NC}"
read -r start_pgadmin

if [ "$start_pgadmin" = "s" ] || [ "$start_pgadmin" = "S" ]; then
    echo -e "${YELLOW}Iniciando pgAdmin...${NC}"
    $DOCKER_COMPOSE up -d pgadmin
    echo -e "${GREEN}✓ pgAdmin iniciado${NC}"
    echo ""
    echo -e "${BLUE}Accede a pgAdmin en:${NC}"
    echo "  URL: http://localhost:5050"
    echo "  Email: admin@mercatico.cr"
    echo "  Contraseña: admin123"
    echo ""
fi

echo -e "${GREEN}========================================="
echo "  ¡Base de datos lista!"
echo "=========================================${NC}"
echo ""
echo "Comandos útiles:"
echo "  Ver logs:        docker logs mercatico_postgres"
echo "  Detener:         docker-compose stop"
echo "  Reiniciar:       docker-compose restart"
echo "  Eliminar todo:   docker-compose down -v"
echo ""
