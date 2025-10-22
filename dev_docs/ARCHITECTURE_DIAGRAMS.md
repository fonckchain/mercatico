# Diagramas de Arquitectura - Almacenamiento de Imágenes

## 🔴 IMPLEMENTACIÓN ACTUAL (Desarrollo)

```
┌─────────────────────────────────────────────────────────────────┐
│                         FLUJO ACTUAL                             │
└─────────────────────────────────────────────────────────────────┘

📱 Flutter App (Móvil)
    │
    │ 1. Usuario selecciona imagen
    │    - Cámara o Galería
    │    - Widget: ImagePickerWidget
    │
    ├─► 2. POST /api/products/{id}/upload_images/
    │       Headers: Authorization: Bearer {token}
    │       Body: FormData(images: [File, File, ...])
    │
    ▼
🐍 Django Backend (Puerto 8000)
    │
    │ 3. Valida permisos (solo dueño del producto)
    │    ✓ Tipo de archivo (JPEG, PNG, WEBP)
    │    ✓ Tamaño máximo (5MB)
    │    ✓ Máximo 5 imágenes
    │
    ├─► 4. Guarda archivo en:
    │       📁 backend/media/products/{product_id}/{uuid}.jpg
    │       ⚠️  PROBLEMA: Archivo en disco local
    │
    │ 5. Genera URL:
    │       http://localhost:8000/media/products/{product_id}/{uuid}.jpg
    │
    ├─► 6. Actualiza base de datos
    │
    ▼
🗄️  Supabase PostgreSQL
    │
    │ Tabla: products
    │ ┌──────────┬───────────────┬─────────────────────────────┐
    │ │ id       │ name          │ images                      │
    │ ├──────────┼───────────────┼─────────────────────────────┤
    │ │ uuid-123 │ "Manzanas"    │ ["http://localhost:8000/... │
    │ │          │               │   media/products/uuid-123/  │
    │ │          │               │   abc-def.jpg"]             │
    │ └──────────┴───────────────┴─────────────────────────────┘
    │
    │ 7. Retorna producto actualizado
    │
    ▼
📱 Flutter App
    │
    └─► 8. Muestra imágenes usando URLs


┌─────────────────────────────────────────────────────────────────┐
│                      ⚠️  PROBLEMAS                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ❌ Archivos en disco local:                                     │
│     → Se pierden al reiniciar servidor/contenedor               │
│     → No funcionan con Docker volumes efímeros                  │
│     → No compartidos entre múltiples instancias                 │
│                                                                  │
│  ❌ No escalable:                                                │
│     → Load balancer distribuye requests                         │
│     → Servidor A tiene imagen, Servidor B no                    │
│                                                                  │
│  ❌ Sin backup:                                                  │
│     → Si falla el disco, pierdes todo                           │
│                                                                  │
│  ❌ URLs rotas en producción:                                    │
│     → http://localhost:8000 no existe fuera del servidor        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🟢 IMPLEMENTACIÓN RECOMENDADA (Producción con Supabase)

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLUJO CON SUPABASE STORAGE                    │
└─────────────────────────────────────────────────────────────────┘

📱 Flutter App (Móvil)
    │
    │ 1. Usuario selecciona imagen
    │
    ├─► 2. POST /api/products/{id}/upload_images/
    │
    ▼
🐍 Django Backend
    │
    │ 3. Valida (igual que antes)
    │
    ├─► 4. Usa SupabaseStorage backend
    │       │
    │       ├─► 4a. Conecta a Supabase Storage API
    │       │       supabase_client.storage.from_('products').upload(...)
    │       │
    │       ▼
    │   ☁️  Supabase Storage (Bucket: products)
    │       │
    │       ├─► Guarda archivo en:
    │       │   products/{product_id}/{uuid}.jpg
    │       │   ✅ Almacenamiento persistente
    │       │   ✅ CDN global incluido
    │       │   ✅ Backup automático
    │       │
    │       └─► Retorna URL pública:
    │           https://{proyecto}.supabase.co/storage/v1/object/public/
    │                  products/{product_id}/{uuid}.jpg
    │
    │ 5. URL pública generada automáticamente
    │
    ├─► 6. Actualiza base de datos
    │
    ▼
🗄️  Supabase PostgreSQL
    │
    │ Tabla: products
    │ ┌──────────┬────────────┬──────────────────────────────────┐
    │ │ id       │ name       │ images                           │
    │ ├──────────┼────────────┼──────────────────────────────────┤
    │ │ uuid-123 │ "Manzanas" │ ["https://{proyecto}.supabase   │
    │ │          │            │   .co/storage/v1/object/public/  │
    │ │          │            │   products/uuid-123/abc-def.jpg"]│
    │ └──────────┴────────────┴──────────────────────────────────┘
    │
    ▼
📱 Flutter App
    │
    └─► 7. Carga imágenes desde CDN de Supabase
        ✅ Rápido (CDN global)
        ✅ Siempre disponible
        ✅ URLs públicas permanentes


┌─────────────────────────────────────────────────────────────────┐
│                      ✅ BENEFICIOS                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ✅ Persistencia garantizada:                                    │
│     → Archivos seguros en almacenamiento de Supabase            │
│     → Backup automático                                         │
│                                                                  │
│  ✅ Escalabilidad:                                               │
│     → Múltiples servidores Django comparten mismo storage       │
│     → Load balancing sin problemas                              │
│                                                                  │
│  ✅ CDN incluido:                                                │
│     → Edge locations globales                                   │
│     → Carga rápida desde cualquier ubicación                    │
│                                                                  │
│  ✅ URLs públicas:                                               │
│     → Funcionan desde cualquier lugar                           │
│     → No dependen del servidor Django                           │
│                                                                  │
│  ✅ Seguridad:                                                   │
│     → RLS (Row Level Security) de Supabase                      │
│     → Control de permisos granular                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 COMPARACIÓN LADO A LADO

```
┌──────────────────────────────────┬─────────────────────────────────┐
│      DESARROLLO (Actual)         │    PRODUCCIÓN (Supabase)        │
├──────────────────────────────────┼─────────────────────────────────┤
│                                  │                                 │
│  settings.py:                    │  settings.py:                   │
│  DEBUG = True                    │  DEBUG = False                  │
│  (usa FileSystemStorage)         │  DEFAULT_FILE_STORAGE =         │
│                                  │    'products.storage_backends   │
│                                  │     .SupabaseStorage'           │
│                                  │                                 │
│  ┌─────────────────────┐         │  ┌─────────────────────┐        │
│  │   Django Server     │         │  │   Django Server     │        │
│  │  (localhost:8000)   │         │  │  (tu-dominio.com)   │        │
│  └──────────┬──────────┘         │  └──────────┬──────────┘        │
│             │                    │             │                   │
│             ▼                    │             ▼                   │
│  ┌──────────────────────┐        │  ┌──────────────────────┐       │
│  │  backend/media/      │        │  │  Supabase Storage    │       │
│  │    products/         │        │  │     (Bucket)         │       │
│  │      └─ {id}/        │        │  │    products/         │       │
│  │         └─ img.jpg   │        │  │      └─ {id}/        │       │
│  └──────────────────────┘        │  │         └─ img.jpg   │       │
│         📁 Local                 │  └──────────────────────┘       │
│                                  │        ☁️ Nube                  │
│                                  │                                 │
│  URL generada:                   │  URL generada:                  │
│  http://localhost:8000/          │  https://abc.supabase.co/       │
│       media/products/...         │       storage/v1/object/...     │
│                                  │                                 │
│  ⚠️  Solo funciona en local      │  ✅ Funciona globalmente        │
│                                  │                                 │
└──────────────────────────────────┴─────────────────────────────────┘
```

---

## 🏗️ ARQUITECTURA DE BASE DE DATOS

```
┌─────────────────────────────────────────────────────────────────┐
│                  SUPABASE (Todo en un lugar)                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  PostgreSQL Database                                   │     │
│  │  ┌──────────────────────────────────────────────────┐  │     │
│  │  │ Tabla: products                                  │  │     │
│  │  │ ┌────────┬──────────┬─────────┬─────────────┐    │  │     │
│  │  │ │ id     │ name     │ price   │ images      │    │  │     │
│  │  │ ├────────┼──────────┼─────────┼─────────────┤    │  │     │
│  │  │ │ uuid-1 │ Producto │ 5000    │ ["https://…]│    │  │     │
│  │  │ └────────┴──────────┴─────────┴─────────────┘    │  │     │
│  │  │                                                  │  │     │
│  │  │ ✅ YA CONECTADO desde Django                    │  │     │
│  │  └──────────────────────────────────────────────────┘  │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  Storage (Buckets)                                     │     │
│  │  ┌──────────────────────────────────────────────────┐  │     │
│  │  │ Bucket: products                                 │  │     │
│  │  │ ┌──────────────────────────────────────────────┐ │  │     │
│  │  │ │ products/                                    │ │  │     │
│  │  │ │   ├─ uuid-1/                                 │ │  │     │
│  │  │ │   │   ├─ abc-123.jpg  (500KB)               │ │  │     │
│  │  │ │   │   └─ def-456.png  (300KB)               │ │  │     │
│  │  │ │   ├─ uuid-2/                                 │ │  │     │
│  │  │ │   │   └─ ghi-789.jpg  (450KB)               │ │  │     │
│  │  │ └──────────────────────────────────────────────┘ │  │     │
│  │  │                                                  │  │     │
│  │  │ ❌ PENDIENTE: Configurar desde Django           │  │     │
│  │  └──────────────────────────────────────────────────┘  │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  Auth (Autenticación)                                  │     │
│  │  └─ JWT tokens para validar requests                   │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  CDN (Edge Network)                                    │     │
│  │  └─ Distribuye archivos globalmente                    │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
         ▲                                        ▲
         │                                        │
         │ SQL queries                            │ File upload/download
         │                                        │
    ┌────┴─────────────────────────────────┬─────┴──────┐
    │        Django Backend                │            │
    │  ┌───────────────────┐  ┌───────────────────────┐ │
    │  │ psycopg2          │  │ SupabaseStorage       │ │
    │  │ (DB connection)   │  │ (File operations)     │ │
    │  └───────────────────┘  └───────────────────────┘ │
    └──────────────────────────────────────────────────┘
```

---

## 🔀 FLUJO DE ELIMINACIÓN DE IMAGEN

```
┌─────────────────────────────────────────────────────────────────┐
│               DELETE /api/products/{id}/delete_image             │
└─────────────────────────────────────────────────────────────────┘

📱 Flutter App
    │
    │ Usuario toca ❌ en imagen
    │
    ├─► DELETE /api/products/{id}/delete_image/
    │   Body: { "image_url": "https://..." }
    │
    ▼
🐍 Django Backend
    │
    │ 1. Verifica permisos (solo dueño)
    │
    │ 2. Extrae path de la URL:
    │    URL: https://abc.supabase.co/storage/.../products/uuid/img.jpg
    │    Path: products/uuid/img.jpg
    │
    ├─► 3. Elimina de Storage
    │   │
    │   ▼
    │   ☁️  Supabase Storage
    │       └─► supabase_client.storage.from_('products').remove([path])
    │           ✅ Archivo eliminado
    │
    │ 4. Elimina URL del array en DB
    │    images: ["url1", "url2"] → ["url1"]
    │
    ├─► 5. Guarda en PostgreSQL
    │
    ▼
🗄️  Supabase PostgreSQL
    │
    └─► Producto actualizado sin esa imagen


✅ RESULTADO:
   - Archivo eliminado del storage
   - URL eliminada de la base de datos
   - Cambios sincronizados
```

---

## 💰 COSTOS PROYECTADOS

```
┌─────────────────────────────────────────────────────────────────┐
│                    ESCENARIOS DE COSTO                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Supuestos:                                                      │
│  - Promedio: 3 imágenes por producto                            │
│  - Tamaño promedio: 400KB por imagen                            │
│  - Compresión automática en app: ~85% calidad                   │
│                                                                  │
│  ┌──────────────────┬──────────────┬──────────────┬────────┐    │
│  │ Productos        │ Imágenes     │ Storage      │ Costo  │    │
│  ├──────────────────┼──────────────┼──────────────┼────────┤    │
│  │ 100              │ 300          │ ~120 MB      │ FREE   │    │
│  │ 500              │ 1,500        │ ~600 MB      │ FREE   │    │
│  │ 1,000            │ 3,000        │ ~1.2 GB      │ $0.02  │    │
│  │ 5,000            │ 15,000       │ ~6 GB        │ $0.13  │    │
│  │ 10,000           │ 30,000       │ ~12 GB       │ $0.25  │    │
│  └──────────────────┴──────────────┴──────────────┴────────┘    │
│                                                                  │
│  Plan Gratuito Supabase: 1GB                                    │
│  Costo adicional: $0.021/GB/mes                                 │
│                                                                  │
│  Para 1,000 productos: ~$0.02/mes 🎉                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎯 DECISIÓN RECOMENDADA

```
┌─────────────────────────────────────────────────────────────────┐
│                      PLAN DE MIGRACIÓN                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  FASE 1: DESARROLLO (Actual) ✅                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ • Usar filesystem local (backend/media/)                  │ │
│  │ • DEBUG=True en settings.py                               │ │
│  │ • Rápido para desarrollo                                  │ │
│  │ • Sin costos                                              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  FASE 2: PREPARACIÓN (1-2 horas)                                │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ 1. Crear bucket en Supabase                               │ │
│  │ 2. pip install supabase                                   │ │
│  │ 3. Configurar settings.py                                 │ │
│  │ 4. Probar con DEBUG=False localmente                      │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  FASE 3: PRODUCCIÓN (Deploy)                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ • DEBUG=False en producción                               │ │
│  │ • DEFAULT_FILE_STORAGE = SupabaseStorage                  │ │
│  │ • Todas las imágenes nuevas → Supabase                    │ │
│  │ • URLs públicas permanentes                               │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

CONCLUSIÓN:
→ Continúa desarrollando con filesystem local
→ Migra a Supabase Storage ANTES de lanzar a producción
→ Costo inicial: $0 (plan gratuito cubre hasta ~800 productos)
```

---

¿Necesitas ayuda implementando alguna de estas opciones?
