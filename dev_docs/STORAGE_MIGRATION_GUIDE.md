# Guía de Migración a Almacenamiento en la Nube

## 🎯 Situación Actual

**Base de datos:** ✅ Supabase PostgreSQL (conectado)
**Almacenamiento de imágenes:** ❌ Sistema de archivos local (NO escalable)

```
┌─────────────────────────────────────────────────────────┐
│                   IMPLEMENTACIÓN ACTUAL                  │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Flutter App                                             │
│      ↓ (POST imagen)                                     │
│  Django Backend                                          │
│      ↓ (guarda archivo)                                  │
│  backend/media/products/  ← ⚠️ PROBLEMA EN PRODUCCIÓN    │
│      ↓ (URL generada)                                    │
│  PostgreSQL (Supabase)                                   │
│      └─ images: ["http://servidor/media/..."]           │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**Problemas:**
1. ❌ Archivos se pierden al reiniciar servidor/contenedor
2. ❌ No funciona con múltiples instancias (load balancing)
3. ❌ No hay backup automático
4. ❌ Consume disco del servidor web

---

## 🚀 Opciones de Migración

### Opción 1: Supabase Storage ⭐ (RECOMENDADO)

**Por qué es la mejor opción para ti:**
- Ya tienes Supabase configurado
- Plan gratuito: 1GB storage
- CDN global incluido
- Integración sencilla
- Sin costos adicionales hasta 1GB

**Pasos de implementación:**

#### 1. Instalar dependencia

```bash
cd backend
pip install supabase
pip freeze > requirements.txt
```

#### 2. Crear bucket en Supabase

Ve a tu dashboard de Supabase:
1. Storage → Create bucket
2. Nombre: `products`
3. Public bucket: **YES** ✅
4. File size limit: 5 MB
5. Allowed MIME types: `image/jpeg, image/png, image/webp`

#### 3. Configurar Django

Edita `backend/mercatico/settings.py`:

```python
# Al final del archivo, después de MEDIA_ROOT

# Supabase Storage Configuration
SUPABASE_BUCKET_NAME = 'products'

# Cambiar el storage backend
if not DEBUG:  # Solo en producción
    DEFAULT_FILE_STORAGE = 'products.storage_backends.SupabaseStorage'
```

#### 4. Actualizar vista de upload

El archivo `products/storage_backends.py` ya fue creado. Solo necesitas modificar ligeramente el endpoint en `products/views.py`:

```python
# En lugar de:
path = default_storage.save(filename, image_file)
url = request.build_absolute_uri(settings.MEDIA_URL + path)

# Usar:
path = default_storage.save(filename, image_file)
url = default_storage.url(path)  # Esto usará Supabase URL automáticamente
```

#### 5. Probar

```bash
# En desarrollo (usa filesystem local)
python manage.py runserver

# En producción (usa Supabase)
DEBUG=False python manage.py runserver
```

**Costo:** Gratis hasta 1GB, luego $0.021/GB/mes

---

### Opción 2: AWS S3

**Para proyectos empresariales grandes.**

**Pasos:**

```bash
pip install django-storages boto3
```

```python
# settings.py
INSTALLED_APPS += ['storages']

AWS_ACCESS_KEY_ID = config('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = config('AWS_SECRET_ACCESS_KEY')
AWS_STORAGE_BUCKET_NAME = 'mercatico-products'
AWS_S3_REGION_NAME = 'us-east-1'
AWS_S3_FILE_OVERWRITE = False
AWS_DEFAULT_ACL = 'public-read'
AWS_S3_CUSTOM_DOMAIN = f'{AWS_STORAGE_BUCKET_NAME}.s3.amazonaws.com'

DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
```

**Costo:** ~$0.023/GB/mes + transferencia

---

### Opción 3: Cloudinary

**Para optimización automática de imágenes.**

```bash
pip install cloudinary
```

```python
# settings.py
import cloudinary

cloudinary.config(
    cloud_name=config('CLOUDINARY_CLOUD_NAME'),
    api_key=config('CLOUDINARY_API_KEY'),
    api_secret=config('CLOUDINARY_API_SECRET'),
)

DEFAULT_FILE_STORAGE = 'cloudinary_storage.storage.MediaCloudinaryStorage'
```

**Costo:** Gratis hasta 25GB, luego $0.10/GB/mes

---

## 🔧 Migración Completa con Supabase Storage

### Paso a Paso Detallado

#### 1. Preparar Supabase

```bash
# En tu dashboard de Supabase
1. Ve a: https://app.supabase.com
2. Selecciona tu proyecto
3. Storage → Create a new bucket
   - Name: products
   - Public: ✅ YES
   - File size limit: 5242880 (5MB)
   - Allowed MIME types: image/*
```

#### 2. Configurar RLS (Row Level Security)

En Supabase → Storage → products → Policies:

```sql
-- Permitir lectura pública
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'products' );

-- Permitir escritura autenticada
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'products' AND
  auth.role() = 'authenticated'
);

-- Permitir eliminar solo archivos propios
CREATE POLICY "Users can delete own files"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'products' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

#### 3. Instalar Dependencia

```bash
cd /home/fonck/development/projects/mercatico/backend
source venv/bin/activate  # Si usas virtualenv
pip install supabase
pip freeze > requirements.txt
```

#### 4. Actualizar Settings

Agrega al final de `settings.py`:

```python
# Supabase Storage
SUPABASE_BUCKET_NAME = config('SUPABASE_BUCKET_NAME', default='products')

# En producción, usar Supabase Storage
if not DEBUG:
    DEFAULT_FILE_STORAGE = 'products.storage_backends.SupabaseStorage'
```

#### 5. Actualizar .env

Agrega a tu archivo `.env`:

```env
SUPABASE_BUCKET_NAME=products
```

#### 6. Modificar Vista de Upload

Edita `products/views.py` en el método `upload_images`:

```python
# ANTES (línea ~207-208):
path = default_storage.save(filename, image_file)
url = request.build_absolute_uri(settings.MEDIA_URL + path)

# DESPUÉS:
path = default_storage.save(filename, image_file)
url = default_storage.url(path)
```

También actualiza `delete_image`:

```python
# ANTES (línea ~252):
path = image_url.replace(request.build_absolute_uri(settings.MEDIA_URL), '')
if default_storage.exists(path):
    default_storage.delete(path)

# DESPUÉS:
# Extraer el path del archivo de la URL de Supabase
from urllib.parse import urlparse
parsed = urlparse(image_url)
path = parsed.path.split(f'/{settings.SUPABASE_BUCKET_NAME}/')[-1]
default_storage.delete(path)
```

#### 7. Probar en Local

```bash
# Con DEBUG=True usa filesystem local
python manage.py runserver

# Sube una imagen para probar
# La URL debería ser: http://localhost:8000/media/products/...
```

#### 8. Probar con Supabase

```bash
# Temporalmente activa Supabase
DEBUG=False python manage.py runserver

# Sube una imagen
# La URL debería ser: https://[proyecto].supabase.co/storage/v1/object/public/products/...
```

---

## 📊 Comparación de Opciones

| Característica | Filesystem Local | Supabase | AWS S3 | Cloudinary |
|---------------|------------------|----------|---------|------------|
| Costo inicial | Gratis | Gratis | ~$5/mes | Gratis |
| Límite gratis | - | 1GB | - | 25GB |
| CDN | ❌ | ✅ | ✅ | ✅ |
| Optimización | ❌ | ❌ | ❌ | ✅ |
| Escalabilidad | ❌ | ✅ | ✅ | ✅ |
| Complejidad | Baja | Media | Alta | Media |
| Ya configurado | ✅ | ✅ DB | ❌ | ❌ |

---

## 🔄 Estrategia de Migración

### Fase 1: Desarrollo (Actual)
```
DEBUG=True → Filesystem local (backend/media/)
```

### Fase 2: Staging/Testing
```
DEBUG=False → Supabase Storage
Probar subida/eliminación
Verificar URLs públicas
```

### Fase 3: Producción
```
Desplegar con DEBUG=False
Todas las imágenes → Supabase Storage
URLs públicas con CDN
```

---

## 🎬 Plan de Acción Recomendado

### AHORA (Desarrollo):
```bash
# No cambiar nada, funciona con filesystem local
# Útil para desarrollo rápido
```

### ANTES DE PRODUCCIÓN:
```bash
1. Crear bucket en Supabase
2. pip install supabase
3. Configurar settings.py
4. Actualizar views.py (2 líneas)
5. Probar con DEBUG=False
6. Desplegar
```

---

## ❓ Preguntas Frecuentes

### ¿Las imágenes existentes en local se migrarán automáticamente?

No. Tendrás que migrarlas manualmente con un script:

```python
# migrate_images.py
import os
from supabase import create_client
from django.conf import settings

def migrate_images():
    client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)

    media_dir = settings.MEDIA_ROOT / 'products'
    for root, dirs, files in os.walk(media_dir):
        for file in files:
            filepath = os.path.join(root, file)
            with open(filepath, 'rb') as f:
                relative_path = filepath.replace(str(media_dir), '').lstrip('/')
                client.storage.from_('products').upload(relative_path, f.read())
                print(f"Migrated: {relative_path}")
```

### ¿Puedo usar ambos (local en dev, Supabase en prod)?

¡Sí! Eso es exactamente lo que recomiendo:

```python
# settings.py
if not DEBUG:
    DEFAULT_FILE_STORAGE = 'products.storage_backends.SupabaseStorage'
# De lo contrario, usa el filesystem local por defecto
```

### ¿Cuánto cuesta Supabase Storage?

- Gratis: 1GB
- Luego: $0.021/GB/mes
- Transferencia: $0.09/GB

**Ejemplo:**
- 100 productos × 3 imágenes × 500KB = ~150MB
- Costo mensual: **$0** (dentro del plan gratuito)

### ¿Qué pasa si cambio de proveedor después?

Django usa `DEFAULT_FILE_STORAGE`, solo cambias el backend:

```python
# De Supabase a S3
DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'

# De S3 a Cloudinary
DEFAULT_FILE_STORAGE = 'cloudinary_storage.storage.MediaCloudinaryStorage'
```

Las URLs en la base de datos cambiarían, necesitarías migración.

---

## 📝 Resumen

### Estado Actual
- ✅ Base de datos: Supabase PostgreSQL
- ❌ Archivos: Filesystem local (no escalable)

### Recomendación
1. **Ahora:** Continuar con filesystem para desarrollo
2. **Antes de producción:** Migrar a Supabase Storage
3. **Costo:** Gratis hasta 1GB

### Próximos Pasos
```bash
# Cuando estés listo para producción:
cd backend
pip install supabase
# Configurar según sección "Migración Completa"
```

¿Tienes más preguntas sobre la implementación?
