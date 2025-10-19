# MercaTico - Guía de Inicio Rápido 🚀

Esta guía te ayudará a poner en marcha MercaTico en menos de 15 minutos.

## Prerrequisitos

Antes de comenzar, asegúrate de tener instalado:

- ✅ Python 3.11 o superior
- ✅ PostgreSQL 15+ (o cuenta de Supabase)
- ✅ Flutter 3.x (para frontend)
- ✅ Git

## Paso 1: Configurar Base de Datos

**Importante**: Necesitas configurar la base de datos ANTES de ejecutar el script de inicialización del backend.

### Opción A: Docker (Recomendado para desarrollo) 🐳

Esta es la forma más rápida y fácil. Solo necesitas tener Docker instalado.

```bash
# 1. Instalar Docker (si no lo tienes)
# Ubuntu/Debian:
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 2. Iniciar PostgreSQL con el script automatizado
./start-database.sh
```

El script te dará la cadena de conexión que necesitas para el `.env`:
```env
DATABASE_URL=postgresql://mercatico_user:mercatico_dev_password@localhost:5432/mercatico
```

**Comandos útiles de Docker:**
```bash
# Ver estado de los contenedores
docker-compose ps

# Ver logs de PostgreSQL
docker logs mercatico_postgres

# Detener la base de datos
docker-compose stop

# Reiniciar la base de datos
docker-compose restart

# Eliminar todo (cuidado: borra los datos)
docker-compose down -v
```

**pgAdmin (Opcional)**: Si iniciaste pgAdmin, accede a [http://localhost:5050](http://localhost:5050)
- Email: `admin@mercatico.cr`
- Contraseña: `admin123`

### Opción B: PostgreSQL Local (Instalación nativa)

```bash
# Instalar PostgreSQL (Ubuntu/Debian)
sudo apt install postgresql postgresql-contrib python3.12-venv

# Iniciar el servicio
sudo service postgresql start

# Crear base de datos
sudo -u postgres createdb mercatico

# Crear usuario (opcional)
sudo -u postgres createuser -P tu_usuario
# Luego otorga permisos:
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE mercatico TO tu_usuario;"
```

### Opción C: Supabase (Para desarrollo en la nube)

1. Ve a [https://supabase.com](https://supabase.com)
2. Crea un nuevo proyecto
3. Ve a Settings > Database
4. Copia la cadena de conexión (Connection String)
5. Guarda las credenciales para el siguiente paso

## Paso 2: Configurar Backend (Django)

### Opción A: Script Automático (Recomendado)

```bash
cd backend
./init_project.sh
```

El script automáticamente:
- ✅ Verifica que python3-venv esté instalado
- ✅ Crea el entorno virtual
- ✅ Instala todas las dependencias
- ✅ Crea el archivo .env desde .env.example
- ✅ Ejecuta las migraciones (si la base de datos está disponible)
- ✅ Te pregunta si quieres crear un superusuario

**Importante**: Después de ejecutar el script, edita el archivo `backend/.env` con tus credenciales de base de datos

### Opción B: Manual

```bash
cd backend

# Crear entorno virtual
python3 -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt

# Configurar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales

# Crear directorios necesarios
mkdir -p logs media/receipts media/products media/seller_logos

# Ejecutar migraciones
python manage.py makemigrations
python manage.py migrate

# Crear superusuario
python manage.py createsuperuser
```

## Paso 3: Editar Variables de Entorno

Edita el archivo `backend/.env` con tus credenciales de base de datos:

```bash
cd backend
nano .env  # o usa tu editor preferido (code .env, vim .env, etc.)
```

### Para Docker PostgreSQL (más común):

```env
DATABASE_URL=postgresql://mercatico_user:mercatico_dev_password@localhost:5432/mercatico
```

### Para PostgreSQL Local (instalación nativa):

```env
DATABASE_URL=postgresql://postgres:tu_password@localhost:5432/mercatico
```

### Para Supabase:

```env
DATABASE_URL=postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres
SUPABASE_URL=https://[PROJECT_ID].supabase.co
SUPABASE_KEY=[ANON_KEY]
SUPABASE_SERVICE_KEY=[SERVICE_KEY]
```

### Ejecutar Migraciones

Si la base de datos no estaba disponible cuando ejecutaste el script de inicialización:

```bash
cd backend
source venv/bin/activate
python manage.py migrate
python manage.py createsuperuser
```

## Paso 4: Configurar API de Grok (xAI)

Para la verificación automática de pagos:

1. Ve a [https://x.ai](https://x.ai) y crea una cuenta
2. Obtén tu API key
3. Actualiza tu `.env`:

```env
GROK_API_KEY=tu_grok_api_key_aqui
```

**Nota**: Durante desarrollo puedes omitir esto. La verificación manual seguirá funcionando.

## Paso 5: Ejecutar el Backend

```bash
cd backend
source venv/bin/activate  # Si no está activado
python manage.py runserver
```

Verifica que funciona visitando:
- Admin: [http://localhost:8000/admin/](http://localhost:8000/admin/)
- Health Check: [http://localhost:8000/health/](http://localhost:8000/health/)

## Paso 6: Configurar Frontend (Flutter)

### Inicializar Proyecto Flutter

```bash
cd frontend
flutter create --org cr.mercatico --platforms web,android,ios mercatico_app
cd mercatico_app
```

### Agregar Dependencias

Edita `pubspec.yaml` y agrega:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Estado
  provider: ^6.1.1
  flutter_riverpod: ^2.4.9

  # HTTP
  dio: ^5.4.0

  # Almacenamiento
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0

  # UI
  google_fonts: ^6.1.0
  cached_network_image: ^3.3.1
  image_picker: ^1.0.7

  # Navegación
  go_router: ^13.0.0

  # Utilidades
  intl: ^0.18.1
```

Luego ejecuta:

```bash
flutter pub get
```

### Configurar API URL

Crea `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:8000/api';

  // Auth endpoints
  static const String login = '$baseUrl/auth/login/';
  static const String register = '$baseUrl/auth/register/';

  // Product endpoints
  static const String products = '$baseUrl/products/';

  // Order endpoints
  static const String orders = '$baseUrl/orders/';

  // Payment endpoints
  static const String payments = '$baseUrl/payments/';

  // Review endpoints
  static const String reviews = '$baseUrl/reviews/';
}
```

## Paso 7: Ejecutar el Frontend

```bash
cd frontend/mercatico_app

# Para web
flutter run -d chrome

# Para Android (con emulador o dispositivo conectado)
flutter run -d android

# Para iOS (solo en macOS)
flutter run -d ios
```

## Estructura del Proyecto

```
mercatico/
├── backend/              # Django REST API
│   ├── mercatico/        # Configuración del proyecto
│   ├── users/            # App de usuarios
│   ├── products/         # App de productos
│   ├── orders/           # App de órdenes
│   ├── payments/         # Verificación de pagos
│   ├── reviews/          # Sistema de reseñas
│   ├── manage.py
│   ├── requirements.txt
│   └── .env
│
├── frontend/             # Flutter
│   └── mercatico_app/
│       ├── lib/
│       │   ├── main.dart
│       │   ├── core/
│       │   ├── features/
│       │   └── services/
│       └── pubspec.yaml
│
├── docs/                 # Documentación
│   └── SETUP_GUIDE.md
│
├── README.md
└── QUICKSTART.md
```

## Datos de Prueba

### Crear Categorías Iniciales

Accede al admin de Django ([http://localhost:8000/admin/](http://localhost:8000/admin/)) y crea algunas categorías:

**Mercancías:**
- Artesanías
- Ropa
- Accesorios
- Decoración

**Alimentos:**
- Panadería
- Repostería
- Productos orgánicos
- Comidas preparadas

### Crear Usuario Vendedor de Prueba

Desde Django shell:

```bash
python manage.py shell
```

```python
from users.models import User, SellerProfile

# Crear vendedor
vendedor = User.objects.create_user(
    email='vendedor@test.com',
    phone='12345678',
    password='test1234',
    first_name='Juan',
    last_name='Pérez',
    user_type=User.UserType.SELLER,
    is_verified=True
)

# Crear perfil de vendedor
SellerProfile.objects.create(
    user=vendedor,
    business_name='Artesanías Don Juan',
    description='Artesanías costarricenses hechas a mano',
    sinpe_number='12345678',
    province='San José',
    canton='Central'
)
```

### Crear Usuario Comprador de Prueba

```python
from users.models import User, BuyerProfile

comprador = User.objects.create_user(
    email='comprador@test.com',
    phone='87654321',
    password='test1234',
    first_name='María',
    last_name='González',
    user_type=User.UserType.BUYER,
    is_verified=True
)

BuyerProfile.objects.create(
    user=comprador,
    province='Alajuela',
    canton='Central',
    address='100 metros norte de la iglesia'
)
```

## Endpoints de API Disponibles

### Autenticación
- `POST /api/token/` - Obtener token (login)
- `POST /api/token/refresh/` - Refrescar token
- `POST /api/auth/register/` - Registro de usuario
- `GET /api/auth/users/me/` - Obtener perfil actual

### Productos
- `GET /api/products/` - Listar productos
- `POST /api/products/` - Crear producto (vendedor)
- `GET /api/products/{id}/` - Detalle de producto
- `PUT /api/products/{id}/` - Actualizar producto
- `DELETE /api/products/{id}/` - Eliminar producto

### Órdenes
- `GET /api/orders/` - Listar órdenes
- `POST /api/orders/` - Crear orden
- `GET /api/orders/{id}/` - Detalle de orden
- `PUT /api/orders/{id}/status/` - Actualizar estado

### Pagos
- `POST /api/payments/upload-receipt/` - Subir comprobante
- `POST /api/payments/verify/{id}/` - Verificar con LLM
- `PUT /api/payments/{id}/manual-review/` - Revisión manual

## Testing de la API

Puedes usar curl, Postman, o HTTPie para probar la API:

```bash
# Obtener token
curl -X POST http://localhost:8000/api/token/ \
  -H "Content-Type: application/json" \
  -d '{"email": "vendedor@test.com", "password": "test1234"}'

# Listar productos
curl http://localhost:8000/api/products/ \
  -H "Authorization: Bearer TU_TOKEN_AQUI"
```

## Problemas Comunes

### Error de migraciones

```bash
# Resetear migraciones
find . -path "*/migrations/*.py" -not -name "__init__.py" -delete
find . -path "*/migrations/*.pyc" -delete
python manage.py makemigrations
python manage.py migrate
```

### Error de conexión a base de datos

Verifica que PostgreSQL esté corriendo:
```bash
sudo service postgresql status  # Linux
brew services list  # macOS
```

### Error en Flutter

```bash
# Limpiar y reconstruir
flutter clean
flutter pub get
flutter run
```

## Próximos Pasos

1. ✅ Completa la configuración de variables de entorno
2. ✅ Implementa las vistas y viewsets restantes (ver `docs/SETUP_GUIDE.md`)
3. ✅ Desarrolla las interfaces de usuario en Flutter
4. ✅ Configura Twilio para notificaciones
5. ✅ Prueba el flujo completo de compra
6. ✅ Realiza deployment a producción

## Recursos Adicionales

- 📚 [Documentación completa](./docs/SETUP_GUIDE.md)
- 🔧 [Django REST Framework](https://www.django-rest-framework.org/)
- 📱 [Flutter](https://flutter.dev/docs)
- 🚀 [Railway Deployment](https://docs.railway.app/)
- 🔷 [Supabase](https://supabase.com/docs)

## Soporte

Si tienes problemas:
1. Revisa los logs: `backend/logs/mercatico.log`
2. Verifica las variables de entorno en `.env`
3. Consulta la documentación en `docs/`

---

**¡Listo para empezar a desarrollar MercaTico! 🇨🇷**
