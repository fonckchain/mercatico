# 👋 ¡Empieza Aquí!

## 🎉 ¡Bienvenido a MercaTico!

Este archivo te guiará en los primeros pasos para trabajar con el proyecto.

## 📚 ¿Qué es este proyecto?

MercaTico es una plataforma web/móvil para que emprendedores costarricenses vendan sus productos usando SINPE Móvil como método de pago. Incluye verificación automática de pagos con IA (Grok).

## 🚀 Inicio Rápido (5 minutos)

### 1. Verifica que tienes todo instalado

```bash
python3 --version  # Debe ser 3.11+
flutter --version  # Debe ser 3.x (opcional para frontend)
```

### 2. Configura el backend

```bash
cd backend
./init_project.sh
```

Este script automáticamente:
- ✅ Crea el entorno virtual
- ✅ Instala dependencias
- ✅ Crea archivo .env
- ✅ Ejecuta migraciones
- ✅ Te pregunta si quieres crear un superusuario

### 3. Edita las variables de entorno

Abre `backend/.env` y configura al menos:

```env
# Base de datos (puedes usar SQLite para desarrollo)
DATABASE_URL=postgresql://user:password@localhost:5432/mercatico

# O para desarrollo rápido, comenta la línea anterior y Django usará SQLite

# Opcional: Grok API para verificación de pagos
GROK_API_KEY=tu-clave-aqui
```

### 4. Inicia el servidor

```bash
cd backend
source venv/bin/activate
python manage.py runserver
```

### 5. ¡Listo! Prueba que funciona

Abre tu navegador:
- **Admin**: http://localhost:8000/admin/
- **Health Check**: http://localhost:8000/health/
- **API**: http://localhost:8000/api/

## 📖 ¿Qué leer ahora?

Dependiendo de lo que quieras hacer:

### Si eres desarrollador nuevo en el proyecto:
1. Lee [README.md](README.md) - Descripción completa del proyecto
2. Lee [QUICKSTART.md](QUICKSTART.md) - Guía de configuración detallada
3. Lee [PROJECT_STATUS.md](PROJECT_STATUS.md) - Estado actual y qué falta

### Si vas a continuar el desarrollo:
1. Lee [PROJECT_STATUS.md](PROJECT_STATUS.md) - Para ver qué está completo y qué falta
2. Lee [docs/SETUP_GUIDE.md](docs/SETUP_GUIDE.md) - Pasos específicos para completar
3. Busca `TODO` en el código para ver áreas pendientes

### Si estás evaluando el proyecto:
1. Lee [RESUMEN_EJECUTIVO.md](RESUMEN_EJECUTIVO.md) - Visión de negocio
2. Lee [README.md](README.md) - Arquitectura técnica
3. Lee [PROJECT_STATUS.md](PROJECT_STATUS.md) - Estado del desarrollo

## 🎯 Estado Actual

**Progreso: 60% completado**

### ✅ Ya funciona:
- Autenticación de usuarios (JWT)
- Registro de compradores y vendedores
- CRUD de productos
- Búsqueda y filtrado
- Sistema de ratings (modelos)
- Verificación de pagos con IA (servicio listo)

### 🔨 Falta implementar:
- APIs completas para Orders, Payments, Reviews
- Frontend en Flutter
- Notificaciones
- Testing
- Deployment

## 🗂️ Estructura del Proyecto

```
mercatico/
├── backend/              # Django REST API (60% completo)
│   ├── mercatico/        # Configuración
│   ├── users/            # ✅ Completo
│   ├── products/         # ✅ Completo
│   ├── orders/           # ⚠️  Modelos listos, falta APIs
│   ├── payments/         # ⚠️  Servicio IA listo, falta APIs
│   └── reviews/          # ⚠️  Modelos listos, falta APIs
│
├── frontend/             # Flutter (0% - por iniciar)
│
└── docs/                 # Documentación
    └── SETUP_GUIDE.md
```

## 🔧 Comandos Útiles

```bash
# Backend
cd backend
source venv/bin/activate           # Activar entorno virtual
python manage.py runserver         # Iniciar servidor
python manage.py makemigrations    # Crear migraciones
python manage.py migrate           # Aplicar migraciones
python manage.py createsuperuser   # Crear admin
python manage.py shell             # Shell de Django

# Frontend (cuando esté configurado)
cd frontend/mercatico_app
flutter run -d chrome              # Ejecutar en web
flutter run -d android             # Ejecutar en Android
```

## 🆘 ¿Problemas?

### Error de base de datos
```bash
cd backend
python manage.py migrate
```

### Error de dependencias
```bash
cd backend
pip install -r requirements.txt
```

### Error de permisos (Linux/Mac)
```bash
chmod +x backend/init_project.sh
```

### Ver logs
```bash
# Los logs se guardan en backend/logs/mercatico.log
tail -f backend/logs/mercatico.log
```

## 📞 Próximos Pasos Recomendados

1. **Configurar la base de datos** (PostgreSQL o usar SQLite para desarrollo)
2. **Crear un superusuario** para acceder al admin
3. **Crear categorías** de productos desde el admin
4. **Crear un usuario vendedor** de prueba
5. **Revisar PROJECT_STATUS.md** para ver qué desarrollar

## 🎓 Recursos de Aprendizaje

- **Django REST**: https://www.django-rest-framework.org/tutorial/quickstart/
- **Flutter**: https://flutter.dev/docs/get-started/codelab
- **PostgreSQL**: https://www.postgresql.org/docs/
- **Grok API**: https://x.ai/api

## 📝 Notas Importantes

- **El proyecto usa Python 3.11+** (verificar versión)
- **Las migraciones están incluidas** en el repositorio
- **El .env.example tiene todas las variables** necesarias
- **La documentación está completa** en los archivos .md
- **El código tiene comentarios** explicativos en español

## 🚀 ¿Listo para Desarrollar?

1. **Lee [PROJECT_STATUS.md](PROJECT_STATUS.md)** para ver qué falta
2. **Revisa [docs/SETUP_GUIDE.md](docs/SETUP_GUIDE.md)** para pasos específicos
3. **Busca `TODO` en el código** para áreas pendientes
4. **¡Empieza a programar!**

## 🎯 Próximo Milestone

**Completar Backend** (1-2 semanas estimadas):
1. Serializers para Orders, Payments, Reviews
2. Views y URLs para estas apps
3. Admin panels completados
4. Testing básico

Luego:
5. Inicializar proyecto Flutter
6. Implementar interfaces de usuario
7. Deployment

---

**¿Preguntas?** Revisa la documentación o busca comentarios en el código.

**¡Éxito con el desarrollo de MercaTico!** 🇨🇷🚀
