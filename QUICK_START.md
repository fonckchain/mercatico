# 🚀 Quick Start - Funcionalidad de Imágenes

## Pasos Inmediatos

### 1. Instalar Dependencias de Flutter

```bash
cd frontend/mercatico_app
flutter pub get
```

Esto instalará `image_picker` que es necesario para seleccionar imágenes.

### 2. Ejecutar la App

```bash
flutter run
```

### 3. Probar la Funcionalidad

1. **Crear un producto nuevo:**
   - Abre la app
   - Ve a "Mis Productos"
   - Toca el botón verde "+"
   - Llena los datos del producto
   - Toca "Agregar imágenes"
   - Selecciona 2-3 imágenes
   - Guarda

2. **Verificar que se guardaron:**
   - Busca en los logs de Flutter:
     ```
     DEBUG: Loaded X existing images
     ```
   - Ve a "Mis Productos" → deberías ver la imagen principal

3. **Editar el producto:**
   - Toca el menú (3 puntos) → Editar
   - Deberías ver las imágenes cargadas
   - Puedes agregar más o eliminar existentes

### 4. Verificar en el Backend

```bash
cd backend

# Ver imágenes guardadas localmente
ls -la media/productos/

# O en Django shell
python manage.py shell
```

```python
from products.models import Product

# Ver último producto creado
product = Product.objects.last()
print(f"Producto: {product.name}")
print(f"Imágenes: {product.images}")
print(f"Número de imágenes: {len(product.images) if product.images else 0}")
```

---

## 🐛 Si No Funciona

### Problema: "No se proporcionaron imágenes"

**Causa:** Las imágenes no llegaron al backend.

**Solución:**
1. Verifica los logs de Flutter
2. Asegúrate de haber tocado "Agregar imágenes" y seleccionado archivos
3. Revisa que el widget `ImagePickerWidget` esté mostrando las miniaturas

### Problema: No veo las imágenes en "Mis Productos"

**Sigue esta guía:** [TROUBLESHOOTING_IMAGES.md](TROUBLESHOOTING_IMAGES.md)

**Quick check:**
```bash
# En el backend
python manage.py shell
```

```python
from products.models import Product
p = Product.objects.filter(images__isnull=False).first()
print(p.images if p else "No hay productos con imágenes")
```

Si ves URLs, el problema está en Flutter. Si está vacío, el problema está en el backend.

### Problema: "image_picker no encontrado"

**Causa:** No ejecutaste `flutter pub get`.

**Solución:**
```bash
cd frontend/mercatico_app
flutter pub get
flutter clean
flutter run
```

---

## 📋 Configuración de Permisos (IMPORTANTE)

### Android

Edita `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- AGREGAR ESTOS PERMISOS -->
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>

    <application ...>
        ...
    </application>
</manifest>
```

### iOS

Edita `ios/Runner/Info.plist`:

```xml
<dict>
    <!-- AGREGAR ESTAS CLAVES -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Necesitamos acceso a tu galería para que puedas seleccionar fotos de productos</string>
    <key>NSCameraUsageDescription</key>
    <string>Necesitamos acceso a tu cámara para que puedas tomar fotos de productos</string>

    <!-- Resto de la configuración -->
</dict>
```

**Luego:**
```bash
flutter clean
flutter run
```

---

## ✅ Verificación Completa

### Backend

```bash
cd backend

# 1. Verificar que supabase está instalado
pip list | grep supabase

# 2. Verificar configuración
python manage.py shell
```

```python
from django.conf import settings
print(f"DEBUG: {settings.DEBUG}")
print(f"SUPABASE_URL: {settings.SUPABASE_URL}")
print(f"SUPABASE_BUCKET: {settings.SUPABASE_BUCKET_NAME}")
print(f"DEFAULT_FILE_STORAGE: {settings.DEFAULT_FILE_STORAGE if hasattr(settings, 'DEFAULT_FILE_STORAGE') else 'FileSystemStorage'}")
```

**Resultado esperado en desarrollo:**
```
DEBUG: True
SUPABASE_URL: https://truglonwkigckwrhcmru.supabase.co
SUPABASE_BUCKET: Productos
DEFAULT_FILE_STORAGE: FileSystemStorage  # (porque DEBUG=True)
```

### Frontend

```bash
cd frontend/mercatico_app

# 1. Verificar que image_picker está instalado
flutter pub deps | grep image_picker

# 2. Verificar que el widget existe
ls lib/widgets/image_picker_widget.dart

# 3. Ejecutar
flutter run
```

---

## 🎯 Flujo Completo de Prueba

### Test 1: Crear Producto con Imágenes

1. Abre la app
2. Login como vendedor
3. Ve a "Mis Productos"
4. Toca "+" (Nuevo Producto)
5. Llena:
   - Nombre: "Producto Test"
   - Descripción: "Test de imágenes"
   - Precio: 1000
   - Stock: 10
   - Categoría: Cualquiera
6. Toca "Agregar imágenes"
7. Selecciona "Seleccionar de galería"
8. Elige 3 imágenes
9. Verifica que se muestren las 3 miniaturas (con etiquetas "Nueva")
10. Toca "Crear Producto"

**Resultado esperado:**
- ✅ Mensaje: "Producto creado exitosamente"
- ✅ Vuelves a "Mis Productos"
- ✅ Ves el producto con su imagen principal

### Test 2: Editar Producto

1. En "Mis Productos", toca el menú (3 puntos) del producto
2. Selecciona "Editar"
3. **Verifica:** Deberías ver las 3 imágenes que subiste
4. Toca la "X" en una imagen para eliminarla
5. Toca "Agregar imágenes" y agrega 2 más
6. Toca "Actualizar Producto"

**Resultado esperado:**
- ✅ Mensaje: "Producto actualizado exitosamente"
- ✅ Ahora tiene 4 imágenes (3 - 1 + 2)

### Test 3: Verificar en Backend

```bash
cd backend
python manage.py shell
```

```python
from products.models import Product

test = Product.objects.filter(name="Producto Test").first()
print(f"Imágenes: {len(test.images)}")  # Debería ser 4
print(test.images)
```

---

## 📊 Indicadores de Éxito

✅ **Todo funciona si:**

1. Puedes seleccionar imágenes desde la galería
2. Las miniaturas aparecen en el formulario
3. El producto se guarda correctamente
4. Al volver a "Mis Productos", ves la imagen principal
5. Al editar, ves todas las imágenes cargadas
6. Puedes agregar/eliminar imágenes en edición

❌ **Hay un problema si:**

1. Error "image_picker not found" → `flutter pub get`
2. No aparece botón "Agregar imágenes" → Falta el widget
3. Las imágenes no se guardan → Revisa logs del backend
4. No se ven en "Mis Productos" → Ver [TROUBLESHOOTING_IMAGES.md](TROUBLESHOOTING_IMAGES.md)

---

## 🆘 Ayuda Rápida

**Error común: "Bad state: No element"**

Causa: El producto no tiene categoría válida.

Solución: Asegúrate de tener categorías en el backend:
```bash
python manage.py shell
```

```python
from products.models import Category
print(Category.objects.count())  # Debe ser > 0
```

---

## 📞 Siguiente Paso

Si todo funciona localmente, sigue la guía para desplegar a producción:

1. [MIGRATION_COMPLETE.md](MIGRATION_COMPLETE.md) - Configurar Supabase Storage
2. [RAILWAY_SETUP.md](RAILWAY_SETUP.md) - Desplegar en Railway

¡Buena suerte! 🚀
