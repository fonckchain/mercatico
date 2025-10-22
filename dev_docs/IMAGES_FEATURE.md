# Funcionalidad de Imágenes para Productos

## Resumen de Cambios

Se ha implementado una funcionalidad completa para manejar imágenes de productos en Mercatico, permitiendo a los vendedores subir hasta 5 imágenes por producto.

## Cambios Realizados

### Backend (Django)

1. **Nuevos endpoints en `products/views.py`:**
   - `POST /api/products/{id}/upload_images/` - Subir imágenes a un producto
   - `DELETE /api/products/{id}/delete_image/` - Eliminar una imagen específica

2. **Validaciones implementadas:**
   - Máximo 5 imágenes por producto
   - Tipos de archivo permitidos: JPEG, JPG, PNG, WEBP
   - Tamaño máximo: 5MB por imagen
   - Solo el propietario puede subir/eliminar imágenes

3. **Almacenamiento:**
   - Las imágenes se guardan en `backend/media/products/{product_id}/`
   - URLs absolutas generadas automáticamente

### Frontend (Flutter)

1. **Nuevo widget `ImagePickerWidget`:**
   - Ubicación: `lib/widgets/image_picker_widget.dart`
   - Funcionalidades:
     - Seleccionar imagen desde cámara
     - Seleccionar imagen desde galería
     - Seleccionar múltiples imágenes
     - Vista previa de imágenes
     - Eliminar imágenes
     - Indicador de imagen principal
     - Contador de imágenes (X/5)

2. **Modelo `Product` actualizado:**
   - Nuevo campo: `List<String> images` - Lista completa de URLs
   - Campo existente mantenido: `String? imageUrl` - Para compatibilidad

3. **ApiService actualizado:**
   - `uploadProductImages(productId, imagePaths)` - Sube imágenes nuevas
   - `deleteProductImage(productId, imageUrl)` - Elimina una imagen

4. **ProductFormScreen actualizado:**
   - Integra `ImagePickerWidget`
   - Maneja carga de imágenes después de crear/actualizar producto
   - Muestra progreso durante carga de imágenes
   - Carga imágenes existentes al editar

## Instalación y Configuración

### 1. Backend

El backend ya está listo. Solo asegúrate de que el directorio de medios tenga los permisos correctos:

```bash
cd backend
chmod -R 755 media/
```

### 2. Frontend

Instala las dependencias de Flutter:

```bash
cd frontend/mercatico_app
flutter pub get
```

### 3. Permisos de la App (Importante)

Debes configurar los permisos para acceder a la cámara y galería:

#### Android (`android/app/src/main/AndroidManifest.xml`)

Agrega antes de `</manifest>`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

#### iOS (`ios/Runner/Info.plist`)

Agrega dentro de `<dict>`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Necesitamos acceso a tu galería para que puedas seleccionar fotos de productos</string>
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a tu cámara para que puedas tomar fotos de productos</string>
<key>NSMicrophoneUsageDescription</key>
<string>Necesitamos acceso al micrófono para videos (opcional)</string>
```

## Uso

### Como Vendedor

1. **Crear un nuevo producto:**
   - Ve a "Mis Productos" → "+" (botón flotante)
   - Llena los datos del producto
   - Toca "Agregar imágenes"
   - Selecciona la fuente (cámara, galería, múltiples)
   - Las imágenes se subirán automáticamente al guardar

2. **Editar un producto existente:**
   - Ve a "Mis Productos" → Toca un producto → "Editar"
   - Verás las imágenes existentes
   - Puedes agregar más (hasta el límite de 5)
   - Puedes eliminar imágenes existentes tocando la "X"
   - Los cambios se guardan al tocar "Actualizar Producto"

### Detalles Técnicos

- **Primera imagen = Imagen principal:** La primera imagen en la lista se usa como portada
- **Optimización automática:** Las imágenes se redimensionan a max 1920x1920 con calidad 85%
- **Carga diferida:** Las nuevas imágenes se suben DESPUÉS de crear/actualizar el producto
- **Manejo de errores:** Si falla la carga de imágenes, el producto se guarda de todos modos

## Flujo de Trabajo

```
1. Usuario crea/edita producto
   ↓
2. Se guarda la información del producto
   ↓
3. Si hay imágenes nuevas seleccionadas:
   → Se suben al servidor
   → Se agregan a la lista de imágenes del producto
   ↓
4. Confirmación al usuario
```

## Estructura de Archivos

```
backend/
├── media/
│   └── products/
│       └── {product_id}/
│           ├── {uuid}.jpg
│           ├── {uuid}.png
│           └── ...
└── products/
    └── views.py  (endpoints de imágenes)

frontend/mercatico_app/
├── lib/
│   ├── widgets/
│   │   └── image_picker_widget.dart  (NUEVO)
│   ├── models/
│   │   └── product.dart  (actualizado)
│   ├── core/services/
│   │   └── api_service.dart  (actualizado)
│   └── screens/seller/
│       └── product_form_screen.dart  (actualizado)
└── pubspec.yaml  (agregado image_picker)
```

## Endpoints API

### Subir Imágenes
```http
POST /api/products/{product_id}/upload_images/
Content-Type: multipart/form-data

Form Data:
- images: File[] (lista de archivos)

Response: ProductSerializer
```

### Eliminar Imagen
```http
DELETE /api/products/{product_id}/delete_image/
Content-Type: application/json

Body:
{
  "image_url": "http://..."
}

Response: ProductSerializer
```

## Próximos Pasos Sugeridos

1. **Optimización:**
   - Implementar compresión de imágenes en el backend (Pillow)
   - Generar thumbnails para listados
   - Almacenamiento en la nube (AWS S3, Cloudinary, etc.)

2. **UX:**
   - Reordenar imágenes (drag & drop)
   - Vista ampliada de imágenes en detalle de producto
   - Carrusel de imágenes en la pantalla de producto

3. **Performance:**
   - Lazy loading de imágenes en listados
   - Cache de imágenes en la app
   - Progressive JPEG

## Notas Importantes

⚠️ **Desarrollo vs Producción:**
- En desarrollo, las URLs son absolutas: `http://localhost:8000/media/...`
- En producción, asegúrate de:
  - Configurar CORS correctamente
  - Usar HTTPS para las URLs
  - Configurar un servicio de almacenamiento escalable (no filesystem)

⚠️ **Seguridad:**
- Las imágenes solo pueden ser subidas/eliminadas por el propietario del producto
- Se validan tipos MIME y tamaños de archivo
- Las rutas se generan con UUIDs para evitar colisiones

⚠️ **Pruebas:**
- Prueba con diferentes formatos de imagen
- Prueba con imágenes grandes (>5MB) para verificar validación
- Prueba con conexiones lentas
- Prueba en iOS y Android

## Troubleshooting

### "No se proporcionaron imágenes"
- Verifica que el FormData se esté enviando correctamente
- Revisa los logs del servidor Django

### "Permission denied" en Android
- Asegúrate de haber agregado los permisos en AndroidManifest.xml
- En Android 13+, necesitas `READ_MEDIA_IMAGES`

### Imágenes no se muestran
- Verifica que el backend esté sirviendo archivos media correctamente
- Revisa la configuración de CORS si estás en diferentes dominios
- Confirma que las URLs sean absolutas y accesibles

### "flutter: command not found"
- Flutter no está instalado o no está en el PATH
- Ejecuta manualmente: `cd frontend/mercatico_app && flutter pub get`

## Soporte

Para dudas o problemas, revisa:
- Logs del backend: `python manage.py runserver` output
- Logs de Flutter: `flutter run` output
- Network inspector en Chrome DevTools (para web)
