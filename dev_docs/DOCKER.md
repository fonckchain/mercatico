# Docker Setup para MercaTico

Esta guía explica cómo usar Docker para desarrollo local de MercaTico.

## Servicios Disponibles

El archivo `docker-compose.yml` incluye dos servicios:

1. **PostgreSQL 15** - Base de datos principal
2. **pgAdmin 4** - Interfaz web para gestionar PostgreSQL (opcional)

## Inicio Rápido

### 1. Instalar Docker

Si no tienes Docker instalado:

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Agregar tu usuario al grupo docker (para no usar sudo)
sudo usermod -aG docker $USER
# Cierra sesión y vuelve a entrar para aplicar cambios
```

Verifica la instalación:
```bash
docker --version
docker-compose --version
```

### 2. Iniciar la Base de Datos

Opción A - Script automatizado (recomendado):
```bash
./start-database.sh
```

Opción B - Manual:
```bash
# Solo PostgreSQL
docker-compose up -d postgres

# PostgreSQL + pgAdmin
docker-compose up -d
```

### 3. Verificar que está corriendo

```bash
docker-compose ps
```

Deberías ver algo como:
```
NAME                   STATUS              PORTS
mercatico_postgres     Up 2 minutes        0.0.0.0:5432->5432/tcp
```

## Credenciales

### PostgreSQL
- **Host**: localhost
- **Puerto**: 5432
- **Base de datos**: mercatico
- **Usuario**: mercatico_user
- **Contraseña**: mercatico_dev_password

**Cadena de conexión para Django (.env):**
```env
DATABASE_URL=postgresql://mercatico_user:mercatico_dev_password@localhost:5432/mercatico
```

### pgAdmin (opcional)
- **URL**: http://localhost:5050
- **Email**: admin@mercatico.cr
- **Contraseña**: admin123

Para conectarte a PostgreSQL desde pgAdmin:
1. Abre http://localhost:5050
2. Login con las credenciales de pgAdmin
3. Click derecho en "Servers" > "Create" > "Server"
4. En "General" tab: Name = "MercaTico Local"
5. En "Connection" tab:
   - Host: `postgres` (nombre del contenedor)
   - Port: 5432
   - Database: mercatico
   - Username: mercatico_user
   - Password: mercatico_dev_password

## Comandos Útiles

### Ver logs
```bash
# Logs de PostgreSQL
docker logs mercatico_postgres

# Logs en tiempo real
docker logs -f mercatico_postgres
```

### Conectarse a PostgreSQL desde terminal
```bash
docker exec -it mercatico_postgres psql -U mercatico_user -d mercatico
```

Comandos útiles de psql:
```sql
-- Listar bases de datos
\l

-- Listar tablas
\dt

-- Describir una tabla
\d nombre_tabla

-- Salir
\q
```

### Gestión de contenedores
```bash
# Ver estado
docker-compose ps

# Detener servicios
docker-compose stop

# Iniciar servicios detenidos
docker-compose start

# Reiniciar servicios
docker-compose restart

# Ver logs de todos los servicios
docker-compose logs -f

# Detener y eliminar contenedores
docker-compose down

# Detener, eliminar contenedores Y datos
docker-compose down -v
```

### Backup y Restore

Crear backup:
```bash
docker exec mercatico_postgres pg_dump -U mercatico_user mercatico > backup.sql
```

Restaurar backup:
```bash
docker exec -i mercatico_postgres psql -U mercatico_user mercatico < backup.sql
```

## Personalización

### Cambiar credenciales

Edita el archivo `docker-compose.yml`:

```yaml
environment:
  POSTGRES_DB: tu_base_de_datos
  POSTGRES_USER: tu_usuario
  POSTGRES_PASSWORD: tu_contraseña_segura
```

Luego recrea los contenedores:
```bash
docker-compose down -v  # Esto BORRA los datos
docker-compose up -d
```

### Cambiar puertos

Si el puerto 5432 ya está en uso:

```yaml
ports:
  - "5433:5432"  # Puerto 5433 en tu máquina -> 5432 en el contenedor
```

Actualiza tu cadena de conexión:
```env
DATABASE_URL=postgresql://mercatico_user:mercatico_dev_password@localhost:5433/mercatico
```

## Solución de Problemas

### Puerto 5432 ya está en uso

Si tienes PostgreSQL instalado localmente:

```bash
# Ubuntu/Debian - Detener PostgreSQL local
sudo service postgresql stop

# O cambiar el puerto en docker-compose.yml
```

### Contenedor no inicia

Ver logs para diagnosticar:
```bash
docker logs mercatico_postgres
```

### Eliminar todo y empezar de cero

```bash
docker-compose down -v
docker-compose up -d
```

### Permiso denegado al ejecutar start-database.sh

```bash
chmod +x start-database.sh
./start-database.sh
```

## Desarrollo en Producción

**IMPORTANTE**: Este setup es solo para desarrollo local. Para producción:

1. Cambia las contraseñas por contraseñas seguras
2. No expongas pgAdmin públicamente
3. Usa variables de entorno en lugar de hardcodear credenciales
4. Considera usar servicios gestionados como:
   - [Supabase](https://supabase.com) (PostgreSQL gestionado)
   - [Railway](https://railway.app)
   - [AWS RDS](https://aws.amazon.com/rds/)
   - [Google Cloud SQL](https://cloud.google.com/sql)

## Recursos

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [PostgreSQL Docker Image](https://hub.docker.com/_/postgres)
- [pgAdmin Documentation](https://www.pgadmin.org/docs/)
