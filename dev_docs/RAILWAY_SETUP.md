# Configuración de Variables de Entorno en Railway

## 🚂 Variables que debes agregar en Railway

Ve a tu proyecto en Railway → Settings → Variables

### Variables de Supabase Storage (NUEVAS)

Agrega estas variables para habilitar Supabase Storage:

```env
SUPABASE_URL=https://truglonwkigckwrhcmru.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRydWdsb253a2lnY2t3cmhjbXJ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA4MzgzODEsImV4cCI6MjA3NjQxNDM4MX0.fqSU8947v58QMgpNTlUr9-6VsRM2Ih99Z8XU8VgqbxY
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRydWdsb253a2lnY2t3cmhjbXJ1Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDgzODM4MSwiZXhwIjoyMDc2NDE0MzgxfQ.q-WFG25yx8sCJu0u1CtIVNo3j7DTKCJz0x1EyCm9d8o
SUPABASE_BUCKET_NAME=Productos
```

### Verificar que DEBUG esté en False

```env
DEBUG=False
```

**IMPORTANTE:** Con `DEBUG=False`, Django automáticamente usará Supabase Storage en lugar del filesystem local.

## 📋 Checklist de Variables

Verifica que tengas TODAS estas variables configuradas en Railway:

### Core Django
- [ ] `SECRET_KEY` - Secret key de Django (genera uno nuevo para producción)
- [ ] `DEBUG=False` - Modo producción
- [ ] `ALLOWED_HOSTS` - Dominio de Railway (ej: `mercatico.railway.app`)

### Database
- [ ] `DATABASE_URL` - URL de PostgreSQL de Supabase (ya debería estar configurada)

### Supabase
- [ ] `SUPABASE_URL=https://truglonwkigckwrhcmru.supabase.co`
- [ ] `SUPABASE_KEY` - Anon key
- [ ] `SUPABASE_SERVICE_KEY` - Service role key
- [ ] `SUPABASE_BUCKET_NAME=Productos`

### JWT
- [ ] `JWT_SECRET_KEY` - Key para tokens JWT
- [ ] `JWT_ACCESS_TOKEN_LIFETIME=60`
- [ ] `JWT_REFRESH_TOKEN_LIFETIME=1440`

### CORS
- [ ] `CORS_ALLOWED_ORIGINS` - URLs permitidas (ej: tu app Flutter en producción)

## 🔄 Después de agregar las variables

1. Railway automáticamente redesplegará tu aplicación
2. El nuevo despliegue usará Supabase Storage
3. Las nuevas imágenes se guardarán en Supabase automáticamente

## ✅ Verificar que funciona

### Desde los logs de Railway:

Busca en los logs durante el despliegue:

```
Collecting supabase==2.3.4
  Downloading supabase-2.3.4-py3-none-any.whl
Installing collected packages: supabase
Successfully installed supabase-2.3.4
```

### Probar subida de imagen:

1. Desde la app Flutter, sube una imagen a un producto
2. Verifica en Supabase Dashboard → Storage → Productos
3. Deberías ver la carpeta del producto con las imágenes

### URL esperada:

Las URLs de las imágenes ahora deberían verse así:

```
https://truglonwkigckwrhcmru.supabase.co/storage/v1/object/public/Productos/productos/{product_id}/{uuid}.jpg
```

## 🚨 Solución de Problemas

### Error: "No module named 'supabase'"

**Causa:** Railway no instaló la dependencia

**Solución:**
1. Verifica que `supabase==2.3.4` esté en `requirements.txt`
2. Haz commit y push del cambio
3. Railway redesplegará automáticamente

### Error: "Bucket not found"

**Causa:** El nombre del bucket no coincide

**Solución:**
1. Verifica que en Supabase el bucket se llame exactamente: `Productos`
2. Verifica que `SUPABASE_BUCKET_NAME=Productos` en Railway
3. Los nombres son case-sensitive

### Las imágenes se siguen guardando en media/

**Causa:** DEBUG está en True o las variables no están configuradas

**Solución:**
1. Verifica `DEBUG=False` en Railway
2. Verifica que `SUPABASE_URL` y `SUPABASE_KEY` estén configuradas
3. Revisa los logs de Railway para ver si hay errores

### Error 403: Forbidden al subir imagen

**Causa:** Las políticas de Supabase Storage no permiten la operación

**Solución:**
1. Ve a Supabase Dashboard → Storage → Productos → Policies
2. Verifica que tengas las políticas de INSERT y DELETE habilitadas
3. Si no, agrégalas desde el SQL Editor:

```sql
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
WITH CHECK ( bucket_id = 'Productos' );

CREATE POLICY "Authenticated users can delete"
ON storage.objects FOR DELETE
USING ( bucket_id = 'Productos' );
```

## 📊 Monitoreo

### Ver logs en Railway:

```bash
railway logs
```

### Buscar logs de Supabase:

```bash
railway logs | grep -i supabase
```

### Ver errores de storage:

```bash
railway logs | grep -i "storage\|bucket"
```

## 🎉 ¡Listo!

Una vez configuradas las variables:

1. ✅ DEBUG=False activa Supabase Storage automáticamente
2. ✅ Las imágenes se guardan en la nube (no en el servidor)
3. ✅ Las URLs son públicas y permanentes
4. ✅ CDN global incluido
5. ✅ Sin problemas con reinicios o múltiples instancias

## 📝 Notas Importantes

- **No pongas el SERVICE_KEY en el frontend** - Solo úsalo en el backend
- **El bucket "Productos" debe ser público** para que las imágenes sean accesibles
- **Railway cobra por uso** - Supabase Storage está incluido en tu plan de Supabase
- **Primer 1GB gratis** en Supabase Storage

## 🔗 Links Útiles

- Railway Dashboard: https://railway.app/dashboard
- Supabase Dashboard: https://app.supabase.com/project/truglonwkigckwrhcmru
- Supabase Storage: https://app.supabase.com/project/truglonwkigckwrhcmru/storage/buckets
