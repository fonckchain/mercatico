# MercaTico - Marketplace Costarricense 🇨🇷

Plataforma de comercio electrónico que conecta vendedores locales de Costa Rica con compradores, facilitando transacciones seguras mediante SINPE Móvil.

---

## ✅ Estado Actual: BACKEND COMPLETO | FRONTEND CONFIGURADO

- ✅ **Backend Django REST API** - 100% funcional
- ✅ **PostgreSQL con Docker** - Configurado
- ✅ **5 Apps implementadas** (Users, Products, Orders, Payments, Reviews)
- ✅ **20+ Endpoints de API** - Documentados y probados
- ✅ **Flutter configurado** - Listo para desarrollo
- ✅ **Android SDK instalado** - Listo para compilar
- ✅ **Datos de prueba** - 3 vendedores, 9 productos, 2 compradores

---

## 🚀 Inicio Rápido (5 minutos)

```bash
# 1. Iniciar PostgreSQL
./start-database.sh

# 2. Iniciar Backend (en otra terminal)
cd backend
source venv/bin/activate
python manage.py runserver

# 3. Probar API
curl http://localhost:8000/health/
# Debería responder: {"status": "healthy"}
```

**URLs Importantes:**
- API: http://localhost:8000/
- Admin: http://localhost:8000/admin/
- pgAdmin: http://localhost:5050

---

## 📚 Documentación

| Documento | Descripción |
|-----------|-------------|
| **[QUICKSTART.md](QUICKSTART.md)** | Guía completa de instalación y configuración |
| **[DOCKER.md](DOCKER.md)** | Configuración de PostgreSQL con Docker |
| **[ANDROID_SETUP.md](ANDROID_SETUP.md)** | Instalación de Android SDK para Flutter |
| **[EJECUTAR_APP.md](EJECUTAR_APP.md)** | Cómo ejecutar la app en Web/Android |
| **[ESTADO_DEL_PROYECTO.md](ESTADO_DEL_PROYECTO.md)** | Estado detallado del proyecto |

---

## 🔑 Credenciales de Prueba

### Vendedores
```
artesanias.don.juan@test.cr / test1234 (3 productos artesanales)
panaderia.maria@test.cr / test1234 (3 productos de panadería)
organicos.jose@test.cr / test1234 (3 productos orgánicos)
```

### Compradores
```
comprador1@test.cr / test1234
comprador2@test.cr / test1234
```

---

## 📦 APIs Disponibles

### Autenticación
- `POST /api/token/` - Login (obtener JWT)
- `POST /api/token/refresh/` - Refresh token
- `POST /api/auth/register/` - Registro de usuario

### Productos
- `GET /api/products/` - Listar productos
- `POST /api/products/` - Crear producto
- `GET /api/products/{id}/` - Detalle de producto

### Órdenes
- `POST /api/orders/` - Crear orden
- `GET /api/orders/my_purchases/` - Mis compras
- `GET /api/orders/my_sales/` - Mis ventas

### Pagos
- `POST /api/payments/receipts/upload/` - Subir comprobante SINPE
- `POST /api/payments/receipts/{id}/manual_review/` - Revisar pago

### Reseñas
- `POST /api/reviews/` - Crear reseña
- `GET /api/reviews/seller_reviews/?seller_id={id}` - Ver reseñas

**Ver todas las APIs**: http://localhost:8000/

---

## 🛠️ Stack Tecnológico

**Backend:**
- Django 5.0 + Django REST Framework
- PostgreSQL 15 (Docker)
- JWT Authentication
- Docker Compose

**Frontend:**
- Flutter 3.35.6
- Dio (HTTP)
- Shared Preferences

---

## 📱 Ejecutar la App Flutter

### Web (más rápido para desarrollo)
```bash
cd frontend/mercatico_app
flutter run -d chrome
```

### Android (dispositivo o emulador)
```bash
flutter run -d android
```

**Nota**: Ver [EJECUTAR_APP.md](EJECUTAR_APP.md) para instrucciones detalladas

---

## 🎯 Próximos Pasos

1. **Implementar Pantallas de UI en Flutter**
   - Login / Registro
   - Catálogo de productos
   - Carrito de compras
   - Perfil de usuario

2. **Integrar con APIs del Backend**
   - Conectar servicios HTTP
   - Implementar autenticación JWT
   - Gestión de estado

3. **Funcionalidades Avanzadas**
   - Grok AI para verificación de pagos
   - Notificaciones con Twilio
   - Chat en tiempo real

---

## 📊 Estructura del Proyecto

```
mercatico/
├── backend/                    # Django REST API ✅
│   ├── users/                 # Autenticación y perfiles ✅
│   ├── products/              # Catálogo de productos ✅
│   ├── orders/                # Gestión de órdenes ✅
│   ├── payments/              # Verificación de pagos ✅
│   └── reviews/               # Sistema de reseñas ✅
├── frontend/                   # Flutter App ⏳
│   └── mercatico_app/         # (20% completado)
├── docker-compose.yml          # PostgreSQL + pgAdmin ✅
├── start-database.sh           # Script de inicio DB ✅
└── install_android_cmdline.sh  # Script de Android SDK ✅
```

---

## 🤝 Contribución

**Developer**: fonckchain
**Email**: afonck@protonmail.com
**Versión**: 0.1.0-alpha

---

## 📝 Comandos Útiles

```bash
# Backend
python manage.py runserver      # Iniciar servidor
python manage.py shell          # Shell Django
python create_sample_data.py    # Regenerar datos de prueba

# Docker
docker-compose ps              # Ver contenedores
docker logs mercatico_postgres # Ver logs

# Flutter
flutter devices                # Ver dispositivos
flutter run                    # Ejecutar app
flutter clean                  # Limpiar cache

# Git
git status                     # Ver cambios
git log --oneline -5           # Ver commits recientes
```

---

**Hecho en Costa Rica con ❤️**
