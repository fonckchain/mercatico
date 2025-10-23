# 🚀 Configurar Supabase Storage en Railway

## 🎯 Problema Actual

- ✅ Carrusel de imágenes funciona (vista comprador)
- ❌ Bucket de Supabase vacío
- ❌ 404 en `/media/products/...`
- ❌ Vista de vendedor no muestra imágenes

**Causa:** Las variables de Supabase NO están configuradas en Railway.

---

## ✅ Solución en 3 Pasos

### Paso 1: Configurar Variables en Railway

1. Ve a: https://railway.app/dashboard
2. Selecciona tu proyecto
3. Click en "Variables" (pestaña)
4. Agrega estas **3 variables NUEVAS**:

```env
SUPABASE_URL
https://truglonwkigckwrhcmru.supabase.co

SUPABASE_KEY
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRydWdsb253a2lnY2t3cmhjbXJ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA4MzgzODEsImV4cCI6MjA3NjQxNDM4MX0.fqSU8947v58QMgpNTlUr9-6VsRM2Ih99Z8XU8VgqbxY

SUPABASE_BUCKET_NAME
Productos
```

5. Railway redesplegará automáticamente (2-3 minutos)

---

### Paso 2: Verificar en Logs de Railway

Después del redespliegue, ve a Logs y busca:

```
✅ Uploaded to Supabase: products/uuid/imagen.jpg
```

**Si ves esto:** ✅ Supabase Storage está funcionando!

**Si NO aparece:** ⚠️ Hay un problema con las variables.

---

### Paso 3: Verificar el Bucket

1. Ve a: https://app.supabase.com/project/truglonwkigckwrhcmru/storage/buckets
2. Click en "Productos"
3. Deberías ver carpetas: `products/{uuid}/`

---

## 🔍 Verificación Local

Puedes verificar la configuración localmente:

```bash
cd backend
python check_storage.py
```

**Salida esperada:**

```
📝 DEBUG: False
🌐 SUPABASE_URL: https://truglonwkigckwrhcmr...
🔑 SUPABASE_KEY: eyJhbGciOiJIUzI1NiIsI...
🪣 SUPABASE_BUCKET: Productos

💾 DEFAULT_FILE_STORAGE:
   ✅ products.storage_backends.SupabaseStorage

🗂️  Storage backend actual:
   SupabaseStorage
   products.storage_backends

✅ Conexión exitosa!
📦 Buckets disponibles: 1
   - Productos
     ✅ Bucket 'Productos' encontrado!
```

---

## 🐛 Troubleshooting

### Problema: Variables agregadas pero bucket sigue vacío

**Causa 1:** Las imágenes se subieron ANTES de configurar Supabase.

**Solución:** Sube nuevas imágenes. Las viejas quedaron en Railway filesystem (se borraron).

---

**Causa 2:** El bucket no está configurado como público.

**Solución:**

1. Ve a Supabase Storage → Productos → Settings
2. Marca "Public bucket" como ✅ YES

---

**Causa 3:** Faltan políticas de acceso.

**Solución:**

Ve a Supabase → SQL Editor y ejecuta:

```sql
-- Permitir lectura pública
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'Productos' );

-- Permitir escritura autenticada
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
WITH CHECK ( bucket_id = 'Productos' );

-- Permitir eliminación
CREATE POLICY "Authenticated users can delete"
ON storage.objects FOR DELETE
USING ( bucket_id = 'Productos' );
```

---

### Problema: Vista de vendedor no muestra imágenes

**Causa:** Las imágenes están dando 404 (se borraron de Railway).

**Solución:**

1. Configura Supabase en Railway (Paso 1)
2. Vuelve a subir las imágenes desde la app
3. Ahora se guardarán en Supabase (permanente)

---

### Problema: Error "supabase module not found"

**Causa:** La dependencia no se instaló en Railway.

**Solución:**

Verifica que `requirements.txt` tenga:
```
supabase==2.3.4
```

Si está, Railway debería instalarlo automáticamente.

---

## 📊 Antes vs Después

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Almacenamiento** | Railway filesystem | Supabase Storage ☁️ |
| **URLs** | `http://.../media/...` | `https://.../storage/...` |
| **Persistencia** | ❌ Se borra en redeploy | ✅ Permanente |
| **Bucket** | Vacío | ✅ Con archivos |
| **Vista vendedor** | Sin imágenes ❌ | Con imágenes ✅ |

---

## ✅ Checklist Final

Después de configurar:

- [ ] Variables agregadas en Railway
- [ ] Railway redesplegado exitosamente
- [ ] Logs muestran "✅ Uploaded to Supabase"
- [ ] Bucket "Productos" tiene archivos
- [ ] Nueva imagen sube correctamente
- [ ] Vista comprador muestra carrusel
- [ ] Vista vendedor muestra thumbnail
- [ ] Al editar se ven las imágenes existentes

---

## 🎯 Próximo Paso Inmediato

**AHORA mismo:**

1. Ve a Railway Dashboard
2. Agrega las 3 variables
3. Espera 2-3 minutos
4. Sube una imagen desde la app
5. Verifica en Supabase Storage que apareció

---

## 📞 Soporte

Si después de estos pasos el bucket sigue vacío, comparte:

1. Screenshot de las variables en Railway
2. Logs de Railway (últimas 50 líneas)
3. Output de `python check_storage.py`

---

**¡Listo para configurar!** 🚀
