# MercaTico 🇨🇷

Plataforma web y móvil para emprendedores costarricenses que venden mercancías y alimentos.

## 📋 Descripción

MercaTico es una plataforma digital diseñada específicamente para el mercado costarricense, permitiendo a emprendedores vender sus productos (artesanías, ropa, alimentos artesanales, etc.) de manera fácil y segura, utilizando SINPE Móvil como método de pago principal.

### Características Principales

- 🛍️ **Dos tipos de usuarios**: Compradores y Vendedores
- 💳 **Pagos con SINPE Móvil**: Verificación automática con IA
- 📱 **Responsive**: Web y móvil con Flutter
- 🔒 **Seguro**: Encriptación de datos sensibles
- ⭐ **Sistema de reseñas**: Calificaciones para vendedores
- 🚚 **Gestión de entregas**: Recogida local o envío

## 🏗️ Arquitectura

```
mercatico/
├── backend/          # Django REST API
│   ├── mercatico/    # Configuración del proyecto
│   ├── users/        # App de usuarios
│   ├── products/     # App de productos
│   ├── orders/       # App de órdenes
│   ├── payments/     # Verificación de pagos con LLM
│   └── reviews/      # Sistema de reseñas
├── frontend/         # Flutter Web/Mobile
│   ├── lib/
│   │   ├── models/
│   │   ├── services/
│   │   ├── screens/
│   │   └── widgets/
│   └── web/
└── docs/            # Documentación
```

## 🛠️ Stack Tecnológico

### Backend
- **Framework**: Django 5.0+
- **API**: Django REST Framework
- **Base de datos**: PostgreSQL (Supabase)
- **Autenticación**: JWT (djangorestframework-simplejwt)
- **IA**: Grok API (xAI) para verificación de pagos
- **Notificaciones**: Twilio
- **Storage**: Supabase Storage (imágenes)

### Frontend
- **Framework**: Flutter 3.x
- **Estado**: Provider / Riverpod
- **HTTP**: Dio
- **Almacenamiento local**: SharedPreferences
- **Imágenes**: Cached Network Image

### DevOps
- **Backend hosting**: Railway
- **Frontend hosting**: Vercel
- **Base de datos**: Supabase
- **CI/CD**: GitHub Actions

## 🚀 Instalación

### Requisitos Previos

- Python 3.11+
- Flutter 3.x
- PostgreSQL 15+
- Node.js 18+ (para algunas herramientas)

### Backend (Django)

```bash
cd backend

# Crear entorno virtual
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt

# Configurar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales

# Migraciones
python manage.py makemigrations
python manage.py migrate

# Crear superusuario
python manage.py createsuperuser

# Ejecutar servidor
python manage.py runserver
```

### Frontend (Flutter)

```bash
cd frontend

# Instalar dependencias
flutter pub get

# Ejecutar en web
flutter run -d chrome

# Ejecutar en móvil (Android/iOS)
flutter run
```

## 🔧 Configuración

### Variables de Entorno (Backend)

Crear archivo `backend/.env`:

```env
# Django
SECRET_KEY=tu-secret-key-aqui
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Base de datos (Supabase)
DATABASE_URL=postgresql://user:password@host:5432/mercatico
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_KEY=tu-supabase-key

# Grok API (xAI)
GROK_API_KEY=tu-grok-api-key
GROK_API_URL=https://api.x.ai/v1

# Twilio (Notificaciones)
TWILIO_ACCOUNT_SID=tu-account-sid
TWILIO_AUTH_TOKEN=tu-auth-token
TWILIO_PHONE_NUMBER=+1234567890

# JWT
JWT_SECRET_KEY=tu-jwt-secret-key

# Email
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=tu-email@gmail.com
EMAIL_HOST_PASSWORD=tu-password
```

### Variables de Entorno (Frontend)

Crear archivo `frontend/.env`:

```env
API_BASE_URL=http://localhost:8000/api
ENABLE_ANALYTICS=false
```

## 📱 Funcionalidades

### Para Compradores

- ✅ Registro e inicio de sesión
- ✅ Búsqueda de productos con filtros
- ✅ Carrito de compras
- ✅ Checkout con SINPE Móvil
- ✅ Subida de comprobante de pago
- ✅ Seguimiento de órdenes
- ✅ Sistema de reseñas

### Para Vendedores

- ✅ Perfil público del negocio
- ✅ Gestión de productos (CRUD)
- ✅ Panel de control con estadísticas
- ✅ Gestión de órdenes
- ✅ Actualización de estados de envío
- ✅ Visualización de reseñas
- ✅ Notificaciones de nuevas órdenes

### Verificación de Pagos con IA

El sistema utiliza Grok (xAI) para verificar automáticamente los comprobantes de SINPE Móvil:

1. El comprador sube captura de pantalla del comprobante
2. El LLM extrae: monto, teléfono receptor, teléfono emisor, ID de transacción, fecha/hora
3. Verifica que:
   - El monto coincida con el total de la orden
   - El receptor sea el número SINPE del vendedor
   - La transacción sea reciente (máx. 1 hora)
4. Aprueba o rechaza automáticamente
5. Si hay discrepancias, notifica al vendedor para revisión manual

## 🔒 Seguridad

- Encriptación de datos sensibles (AES-256)
- Autenticación JWT con refresh tokens
- Protección CSRF
- Rate limiting en APIs
- Validación de inputs
- SQL injection protection (ORM Django)
- XSS protection
- Cumplimiento con Ley 8968 (Costa Rica)

## 🗄️ Modelos de Base de Datos

### Usuario
```python
- id (UUID)
- email (unique)
- phone (unique)
- password (hashed)
- user_type (BUYER/SELLER)
- is_verified
- created_at
```

### Perfil de Vendedor
```python
- user (FK)
- business_name
- description
- sinpe_number
- logo
- rating_avg
- total_sales
```

### Producto
```python
- id (UUID)
- seller (FK)
- name
- description
- price (Decimal)
- category (MERCHANDISE/FOOD)
- stock
- is_available
- images (JSONField)
- created_at
```

### Orden
```python
- id (UUID)
- buyer (FK)
- seller (FK)
- products (M2M through OrderItem)
- total (Decimal)
- status (PENDING/CONFIRMED/SHIPPED/DELIVERED)
- delivery_method (PICKUP/DELIVERY)
- delivery_address
- payment_verified
- created_at
```

### Comprobante de Pago
```python
- id (UUID)
- order (FK)
- image_url
- verification_status (PENDING/APPROVED/REJECTED)
- extracted_data (JSONField)
- verified_at
- expires_at (7 días)
```

### Reseña
```python
- id (UUID)
- order (FK)
- buyer (FK)
- seller (FK)
- rating (1-5)
- comment
- created_at
```

## 🚢 Deployment

### Backend (Railway)

```bash
# Instalar Railway CLI
npm install -g @railway/cli

# Login
railway login

# Inicializar proyecto
railway init

# Deploy
railway up
```

### Frontend (Vercel)

```bash
# Instalar Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
vercel --prod
```

## 🧪 Testing

### Backend
```bash
cd backend
python manage.py test
```

### Frontend
```bash
cd frontend
flutter test
```

## 📚 API Endpoints

### Autenticación
- `POST /api/auth/register/` - Registro de usuario
- `POST /api/auth/login/` - Inicio de sesión
- `POST /api/auth/refresh/` - Refresh token
- `POST /api/auth/forgot-password/` - Recuperar contraseña

### Usuarios
- `GET /api/users/me/` - Perfil del usuario actual
- `PUT /api/users/me/` - Actualizar perfil
- `GET /api/sellers/{id}/` - Perfil público de vendedor

### Productos
- `GET /api/products/` - Listar productos (con filtros)
- `POST /api/products/` - Crear producto (vendedor)
- `GET /api/products/{id}/` - Detalle de producto
- `PUT /api/products/{id}/` - Actualizar producto
- `DELETE /api/products/{id}/` - Eliminar producto

### Órdenes
- `GET /api/orders/` - Listar órdenes del usuario
- `POST /api/orders/` - Crear orden
- `GET /api/orders/{id}/` - Detalle de orden
- `PUT /api/orders/{id}/status/` - Actualizar estado (vendedor)

### Pagos
- `POST /api/payments/upload-receipt/` - Subir comprobante
- `POST /api/payments/verify/{id}/` - Verificar con LLM
- `PUT /api/payments/{id}/manual-review/` - Revisión manual (vendedor)

### Reseñas
- `GET /api/reviews/seller/{id}/` - Reseñas de vendedor
- `POST /api/reviews/` - Crear reseña
- `GET /api/reviews/order/{id}/` - Reseña de orden específica

## 🤝 Contribución

1. Fork el proyecto
2. Crea una rama (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -m 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.

## 👥 Equipo

Desarrollado para emprendedores costarricenses 🇨🇷

## 📞 Soporte

Para reportar problemas o solicitar ayuda:
- Email: soporte@mercatico.cr
- Formulario de contacto en la plataforma

---

**MercaTico** - Impulsando el emprendimiento tico 🚀
