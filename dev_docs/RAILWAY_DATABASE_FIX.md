# Railway Database Connection Fix

## Problem

The Django backend on Railway was failing to connect to PostgreSQL, causing:
- Frontend error: "Error al cargar productos: DioException [connection error]"
- Backend error: `psycopg2.OperationalError: connection to server at "postgres.railway.internal" failed: Connection timed out`

## Root Cause

1. The startup command was trying to run migrations immediately, before the database was ready
2. No retry logic for database connections
3. Poor error handling for database connection failures

## Changes Made

### 1. Database Connection Settings (`backend/mercatico/settings.py`)
- Added connection timeout settings (10 seconds)
- Added statement timeout configuration
- Improved database connection reliability

### 2. Database Wait Command (`backend/mercatico/management/commands/wait_for_db.py`)
- New management command that waits for database to be ready
- Configurable retry attempts (default: 30) and delay (default: 2 seconds)
- Prevents server startup before database is available

### 3. Startup Scripts Updated
- **`backend/nixpacks.toml`**: Added `wait_for_db` before migrations
- **`backend/Procfile`**: Added `wait_for_db` before migrations

### 4. Error Handling (`backend/mercatico/exceptions.py`)
- Added specific handling for `OperationalError` and `DatabaseError`
- Returns HTTP 503 (Service Unavailable) with user-friendly message
- Better error messages for database connection failures

## Railway Configuration Checklist

### 1. Verify PostgreSQL Service is Running
- Go to Railway Dashboard → Your Project
- Check that PostgreSQL service is running and healthy
- If not running, start it or create a new PostgreSQL service

### 2. Verify Service Linking
- Ensure the Django service is linked to the PostgreSQL service
- In Railway, services should be in the same project and linked
- The `DATABASE_URL` should be automatically set by Railway when services are linked

### 3. Check Environment Variables
Go to Railway Dashboard → Your Django Service → Variables

**Required Variables:**
- `DATABASE_URL` - Should be automatically set by Railway if services are linked
- `SECRET_KEY` - Django secret key
- `DEBUG=False` - Production mode
- `ALLOWED_HOSTS` - Your Railway domain (e.g., `mercatico-production.up.railway.app`)

**Optional but Recommended:**
- `CORS_ALLOWED_ORIGINS` - Your frontend URLs
- `SUPABASE_URL`, `SUPABASE_KEY`, `SUPABASE_SERVICE_KEY` - If using Supabase Storage

### 4. Verify DATABASE_URL Format
The `DATABASE_URL` should look like:
```
postgresql://postgres:password@postgres.railway.internal:5432/railway
```

Or if using external PostgreSQL (Supabase):
```
postgresql://postgres:password@db.xxxxx.supabase.co:5432/postgres
```

### 5. Check Service Dependencies
In Railway, ensure the Django service depends on PostgreSQL:
- Go to your Django service → Settings → Service Dependencies
- Add PostgreSQL service as a dependency
- This ensures PostgreSQL starts before Django

## Testing the Fix

### 1. Deploy to Railway
After pushing these changes, Railway will automatically redeploy:
```bash
git add .
git commit -m "Fix database connection issues with retry logic"
git push
```

### 2. Check Logs
Monitor Railway logs during deployment:
```bash
railway logs
```

You should see:
```
Waiting for database...
Attempt 1/30: Database not ready, waiting 2s...
Attempt 2/30: Database not ready, waiting 2s...
✓ Database is ready!
Operations to perform:
  Apply all migrations: ...
```

### 3. Test Health Endpoint
Once deployed, test the health endpoint:
```bash
curl https://your-railway-url.railway.app/health/
```

Expected response:
```json
{
  "status": "healthy",
  "service": "MercaTico Backend",
  "database": "connected"
}
```

### 4. Test Products Endpoint
Test the products API:
```bash
curl https://your-railway-url.railway.app/api/products/
```

Should return product list or empty array, not a connection error.

## Troubleshooting

### Issue: Still getting connection timeout

**Solution 1: Check PostgreSQL Service**
- Verify PostgreSQL service is running in Railway
- Check PostgreSQL logs for errors
- Restart PostgreSQL service if needed

**Solution 2: Verify Service Linking**
- Ensure Django and PostgreSQL are in the same Railway project
- Check that `DATABASE_URL` is set in Django service variables
- If not auto-set, manually add it from PostgreSQL service settings

**Solution 3: Check Network**
- Railway services should use internal hostname: `postgres.railway.internal`
- If using external database (Supabase), ensure firewall allows Railway IPs

### Issue: Migrations fail during startup

**Solution:**
The `wait_for_db` command should handle this, but if it still fails:
1. Increase retry attempts in `nixpacks.toml`:
   ```
   python manage.py wait_for_db --max-retries=60 --retry-delay=3
   ```
2. Check database permissions
3. Verify database exists and user has proper permissions

### Issue: Server starts but API returns 503

**Solution:**
- Check Railway logs for database connection errors
- Verify `DATABASE_URL` is correct
- Test database connection manually from Railway shell:
  ```bash
  railway shell
  python manage.py dbshell
  ```

## Additional Notes

- The `wait_for_db` command will wait up to 60 seconds (30 retries × 2 seconds) by default
- If database is not ready after max retries, the startup will fail (preventing broken deployments)
- Database connection errors in API requests now return HTTP 503 instead of 500
- Frontend will receive clearer error messages about database unavailability

## Next Steps

1. **Deploy the changes** to Railway
2. **Monitor the logs** during first deployment
3. **Test the endpoints** to verify everything works
4. **Update frontend** if needed to handle 503 errors gracefully

