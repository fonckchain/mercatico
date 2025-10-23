# 🔧 Fix: Imágenes con URLs Relativas

## Problema Identificado

Las imágenes se cargan en el backend pero no se ven en la app porque el API devuelve URLs **relativas** en lugar de **absolutas**.

### Lo que estaba pasando:

```json
{
  "images": [
    "/media/products/uuid/image.jpg",  ❌ URL relativa
    "/media/products/uuid/image2.jpg"
  ]
}
```

### Lo que necesitamos:

```json
{
  "images": [
    "https://mercatico-production.up.railway.app/media/products/uuid/image.jpg",  ✅ URL absoluta
    "https://mercatico-production.up.railway.app/media/products/uuid/image2.jpg"
  ]
}
```

---

## ✅ Solución Implementada

He modificado los serializers en [backend/products/serializers.py](backend/products/serializers.py) para convertir automáticamente las URLs relativas a absolutas:

### Cambios realizados:

1. **ProductSerializer** - Agregado método `to_representation()` (líneas 127-150)
2. **ProductListSerializer** - Actualizado método `get_main_image()` (líneas 183-190)

Estos métodos detectan si una URL es relativa (no empieza con `http`) y la convierten a absoluta usando `request.build_absolute_uri()`.

---

## 🚀 Desplegar el Fix

### Paso 1: Commit y Push

```bash
git add backend/products/serializers.py
git commit -m "fix: Convertir URLs de imágenes de relativas a absolutas en serializers"
git push
```

### Paso 2: Esperar Despliegue en Railway

Railway detectará automáticamente el cambio y redesplegará el backend.

**Tiempo estimado:** 2-3 minutos

### Paso 3: Verificar que funcionó

#### Desde el API:

```bash
curl https://mercatico-production.up.railway.app/api/products/fa047a58-225d-4b8d-80c4-8ef65a7128f0/
```

Busca el campo `images`:
```json
{
  "images": [
    "https://mercatico-production.up.railway.app/media/products/...",  ✅
    "https://mercatico-production.up.railway.app/media/products/..."
  ],
  "main_image": "https://mercatico-production.up.railway.app/media/..."  ✅
}
```

#### Desde la App:

1. Abre la app
2. Ve a "Mis Productos"
3. Las imágenes deberían verse ahora ✅

---

## 📊 Antes y Después

### ANTES (con URLs relativas):

```
Flutter App
    ↓
API Response: {
  images: ["/media/products/..."]
}
    ↓
Flutter intenta cargar:
  "http:///media/products/..."  ❌ (URL inválida)
    ↓
Error: No se puede cargar la imagen
```

### DESPUÉS (con URLs absolutas):

```
Flutter App
    ↓
API Response: {
  images: ["https://mercatico-production.up.railway.app/media/products/..."]
}
    ↓
Flutter intenta cargar:
  "https://mercatico-production.up.railway.app/media/products/..."  ✅
    ↓
Imagen se carga correctamente
```

---

## 🔍 Cómo Funciona el Fix

El método `to_representation()` se ejecuta cada vez que un producto se serializa a JSON:

```python
def to_representation(self, instance):
    """Convert relative image URLs to absolute URLs."""
    data = super().to_representation(instance)
    request = self.context.get('request')

    if request and data.get('images'):
        # Convert relative URLs to absolute
        absolute_images = []
        for img_url in data['images']:
            if img_url and not img_url.startswith('http'):
                # URL relativa, convertir a absoluta
                absolute_url = request.build_absolute_uri(img_url)
                absolute_images.append(absolute_url)
            else:
                # Ya es absoluta
                absolute_images.append(img_url)
        data['images'] = absolute_images

    # También convertir main_image si existe
    if request and data.get('main_image'):
        if not data['main_image'].startswith('http'):
            data['main_image'] = request.build_absolute_uri(data['main_image'])

    return data
```

**`request.build_absolute_uri()`** convierte:
- `/media/products/uuid/image.jpg`
- → `https://mercatico-production.up.railway.app/media/products/uuid/image.jpg`

---

## ✅ Verificación Post-Despliegue

### Test Rápido:

```bash
# Verificar respuesta del API
curl -s https://mercatico-production.up.railway.app/api/products/ \
  | jq '.results[0].images'
```

**Resultado esperado:**
```json
[
  "https://mercatico-production.up.railway.app/media/products/...",
  "https://mercatico-production.up.railway.app/media/products/..."
]
```

Si ves `["/media/...", "/media/..."]` (sin el dominio), el despliegue falló.

---

## 🚨 Si Sigue Sin Funcionar

### Problema 1: Las URLs siguen siendo relativas

**Causa:** Railway no actualizó el código.

**Solución:**
1. Ve a Railway Dashboard
2. Deployments → Ver el último despliegue
3. Debería decir "SUCCESS"
4. Si dice "FAILED", revisa los logs

### Problema 2: Error 500 en el API

**Causa:** Error en el código del serializer.

**Solución:**
1. Ve a Railway → Logs
2. Busca el error
3. Si ves `'NoneType' object has no attribute 'build_absolute_uri'`:
   - Significa que `request` es None
   - Esto no debería pasar, pero verifica que los ViewSets pasen el context

### Problema 3: Las imágenes cargan pero muy lento

**Causa:** Las imágenes están en Railway (filesystem), no en Supabase Storage.

**Solución:**
Sigue la guía [MIGRATION_COMPLETE.md](MIGRATION_COMPLETE.md) para migrar a Supabase Storage.

---

## 📝 Notas Importantes

1. **Este fix es retrocompatible:**
   - URLs relativas → se convierten a absolutas
   - URLs absolutas → se dejan como están
   - URLs de Supabase → se dejan como están

2. **Funciona en desarrollo y producción:**
   - Desarrollo: `http://localhost:8000/media/...`
   - Producción: `https://mercatico-production.up.railway.app/media/...`
   - Supabase: `https://...supabase.co/storage/...`

3. **No afecta el almacenamiento:**
   - Las imágenes se siguen guardando en `/media/` (Railway filesystem)
   - Este fix solo cambia cómo se generan las URLs en el JSON
   - Para usar Supabase Storage, sigue la guía de migración

---

## ✅ Checklist Final

Después de desplegar, verifica:

- [ ] Git commit realizado
- [ ] Git push exitoso
- [ ] Railway despliegue SUCCESS
- [ ] API devuelve URLs absolutas (verificar con curl)
- [ ] App muestra imágenes en "Mis Productos"
- [ ] App muestra imágenes al editar producto
- [ ] Nuevas imágenes se suben correctamente

---

## 🎉 ¡Listo!

Una vez que hagas `git push`, espera ~3 minutos y las imágenes deberían verse en la app.

Si tienes problemas, revisa los logs de Railway:
```bash
railway logs --tail
```

O consulta [TROUBLESHOOTING_IMAGES.md](TROUBLESHOOTING_IMAGES.md) para más ayuda.
