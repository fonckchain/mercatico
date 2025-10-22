# 🔍 Troubleshooting - Imágenes no se muestran

## Problema Reportado

Las imágenes se suben pero no se muestran en:
- Mis Productos
- Editar Producto

---

## ✅ Checklist de Verificación

### 1. Verificar que las imágenes se guardaron correctamente

**En desarrollo (DEBUG=True):**

Revisa si el archivo existe:
```bash
ls -la backend/media/productos/
```

Deberías ver carpetas con UUIDs de productos.

**En producción (Supabase):**

Ve a: https://app.supabase.com/project/truglonwkigckwrhcmru/storage/buckets/Productos

Deberías ver carpetas `productos/{uuid}/` con las imágenes.

---

### 2. Verificar la respuesta del API

**Opción A: Desde el backend**

```bash
cd backend
python manage.py shell
```

```python
from products.models import Product

# Ver un producto con imágenes
product = Product.objects.first()
print(f"Product: {product.name}")
print(f"Images: {product.images}")
print(f"Main image: {product.get_main_image()}")
```

**Opción B: Desde el API directamente**

Con curl o Postman:
```bash
curl http://localhost:8000/api/products/{product_id}/ \
  -H "Authorization: Bearer {tu_token}"
```

Busca el campo `images` en la respuesta:
```json
{
  "id": "...",
  "name": "Producto",
  "images": [
    "http://localhost:8000/media/productos/uuid/image1.jpg",
    "http://localhost:8000/media/productos/uuid/image2.jpg"
  ],
  "main_image": "http://localhost:8000/media/productos/uuid/image1.jpg"
}
```

---

### 3. Verificar logs de Flutter

Ejecuta la app y busca los logs de debug que agregamos:

```bash
flutter run
```

**Logs esperados en MyProductsScreen:**

```
DEBUG Product: Nombre del producto
  - imageUrl: http://localhost:8000/media/productos/.../image.jpg
  - images: [http://localhost:8000/media/productos/.../image.jpg, ...]
```

**Logs esperados en ProductFormScreen (al editar):**

```
DEBUG: Loaded 2 existing images
DEBUG: Images: [http://localhost:8000/..., http://localhost:8000/...]
```

Si ves:
```
DEBUG: No images found in product data
DEBUG: productData[images] = null
```

**→ El problema está en el backend: las imágenes no se están guardando.**

---

### 4. Verificar modelo Product

Abre `lib/models/product.dart` y verifica que tenga:

```dart
final List<String> images; // Lista completa de URLs de imágenes
final String? imageUrl;    // URL de la imagen principal
```

Y en el constructor:
```dart
this.images = const [],
```

Y en `fromJson`:
```dart
// Parsear lista de imágenes
List<String> imagesList = [];
if (json['images'] != null && json['images'] is List) {
  imagesList = List<String>.from(json['images']);
}
```

---

## 🔧 Soluciones Comunes

### Problema 1: El campo `images` está vacío en la base de datos

**Causa:** Las imágenes no se subieron correctamente.

**Solución:**
1. Verifica que el endpoint funcione:
   ```bash
   # Desde el backend
   curl -X POST http://localhost:8000/api/products/{product_id}/upload_images/ \
     -H "Authorization: Bearer {token}" \
     -F "images=@test.jpg"
   ```

2. Revisa los logs del servidor Django:
   ```bash
   python manage.py runserver
   ```
   Deberías ver:
   ```
   POST /api/products/{id}/upload_images/ 200
   ```

3. Si ves errores, revisa la validación en `products/views.py`.

### Problema 2: Las imágenes se guardaron pero el campo `images` es `[]`

**Causa:** El producto se creó/actualizó ANTES de subir las imágenes.

**Solución:**
Esto es normal. El flujo es:
1. Crear/actualizar producto → `images: []`
2. Subir imágenes → `images: [url1, url2, ...]`

**Para verificar:**
```python
# En Django shell
product = Product.objects.get(id='uuid-del-producto')
print(product.images)  # Debería tener URLs
```

Si está vacío, las imágenes no se subieron correctamente.

### Problema 3: Las URLs de las imágenes no son accesibles

**Causa:** El servidor no está sirviendo archivos media correctamente.

**Solución:**

Verifica en `backend/mercatico/urls.py` que tenga:
```python
from django.conf import settings
from django.conf.urls.static import static

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

Prueba acceder directamente a la URL de la imagen en el navegador:
```
http://localhost:8000/media/productos/{uuid}/{filename}.jpg
```

### Problema 4: Flutter no parsea las imágenes correctamente

**Causa:** El JSON del API tiene un formato inesperado.

**Solución:**

Imprime el JSON raw en el ApiService:

```dart
// En api_service.dart, método getProduct()
final response = await _dio.get(ApiConstants.productDetail(id));
print('DEBUG RAW RESPONSE: ${response.data}');
return response.data;
```

Busca el campo `images` en el output.

### Problema 5: Las imágenes se muestran en crear pero no en editar

**Causa:** `_existingImageUrls` no se está poblando correctamente.

**Solución:**

Verifica los logs en ProductFormScreen:
```
DEBUG: Loaded X existing images
```

Si ves `X = 0` pero sabes que el producto tiene imágenes, el problema está en `_loadProductDetails()`.

---

## 🚨 Debugging Paso a Paso

### Paso 1: Crear un producto de prueba

1. Desde la app, crea un producto llamado "TEST"
2. Agrega 2 imágenes
3. Guarda

### Paso 2: Verificar en el backend

```bash
cd backend
python manage.py shell
```

```python
from products.models import Product

test_product = Product.objects.filter(name="TEST").first()
print(f"ID: {test_product.id}")
print(f"Images: {test_product.images}")
print(f"Número de imágenes: {len(test_product.images) if test_product.images else 0}")
```

**Resultado esperado:**
```
ID: abc-123-def
Images: ['http://localhost:8000/media/productos/abc-123-def/uuid1.jpg', '...']
Número de imágenes: 2
```

### Paso 3: Verificar el serializer

```python
from products.serializers import ProductSerializer

serializer = ProductSerializer(test_product)
data = serializer.data
print(data['images'])
print(data['main_image'])
```

**Resultado esperado:**
```
['http://localhost:8000/media/.../image1.jpg', 'http://localhost:8000/media/.../image2.jpg']
http://localhost:8000/media/.../image1.jpg
```

### Paso 4: Verificar el endpoint

```bash
curl http://localhost:8000/api/products/ | jq '.results[0].images'
```

**Resultado esperado:**
```json
[
  "http://localhost:8000/media/productos/.../image1.jpg",
  "http://localhost:8000/media/productos/.../image2.jpg"
]
```

### Paso 5: Verificar en Flutter

Ejecuta la app y ve a "Mis Productos". Busca en los logs:

```
DEBUG Product: TEST
  - imageUrl: http://localhost:8000/media/.../image1.jpg
  - images: [http://localhost:8000/media/.../image1.jpg, http://localhost:8000/media/.../image2.jpg]
```

Si ves esto, **el problema está en la UI, no en los datos**.

### Paso 6: Verificar la UI

El widget `_ProductListItem` usa:
```dart
product.imageUrl != null
    ? Image.network(product.imageUrl!, ...)
    : Icon(Icons.shopping_bag)
```

Si `imageUrl` es null pero `images` tiene elementos, ese es el problema.

---

## 🔎 Diagnóstico Rápido

### Las imágenes NO se ven en "Mis Productos"

**Checklist:**
- [ ] El producto tiene imágenes en la DB (`product.images` no está vacío)
- [ ] El serializer retorna `images` y `main_image`
- [ ] Flutter parsea correctamente (ver logs DEBUG)
- [ ] `product.imageUrl` no es null en Flutter
- [ ] La URL es accesible (prueba en navegador)

### Las imágenes NO se ven al "Editar"

**Checklist:**
- [ ] `_loadProductDetails()` se llama correctamente
- [ ] `productData['images']` tiene valores (ver logs DEBUG)
- [ ] `_existingImageUrls` se pobla (ver logs DEBUG)
- [ ] El widget `ImagePickerWidget` recibe las URLs

---

## 📊 Matriz de Problemas

| Síntoma | Causa Probable | Solución |
|---------|---------------|----------|
| Sin imágenes en DB | No se subieron | Revisar endpoint upload_images |
| Imágenes en DB, no en API | Serializer | Revisar ProductSerializer |
| Imágenes en API, no en Flutter | Parsing | Revisar Product.fromJson() |
| Imágenes en Flutter, no se ven | UI | Revisar Image.network() |
| Imágenes en crear, no en editar | Load | Revisar _loadProductDetails() |

---

## 📞 Información para Reportar

Si ninguna solución funciona, reporta:

1. **Logs del backend:**
   ```bash
   python manage.py runserver > backend.log 2>&1
   ```

2. **Logs de Flutter:**
   ```bash
   flutter run > flutter.log 2>&1
   ```

3. **Resultado del paso 2 (verificar en backend)**

4. **Resultado del paso 4 (verificar endpoint)**

5. **Screenshots de:**
   - Supabase Storage (si usas Supabase)
   - La pantalla "Mis Productos"
   - El error en consola (si hay)

---

## 🎯 Next Steps

Después de verificar:

1. **Si las imágenes están en la DB pero no se ven:**
   - El problema es en el frontend (Flutter)
   - Revisa `Product.fromJson()` y los logs DEBUG

2. **Si las imágenes NO están en la DB:**
   - El problema es en el backend (Django)
   - Revisa el endpoint `upload_images`
   - Verifica que se llame desde Flutter

3. **Si las imágenes se ven en crear pero no en editar:**
   - El problema es en `ProductFormScreen._loadProductDetails()`
   - Revisa los logs DEBUG al abrir el formulario de edición
