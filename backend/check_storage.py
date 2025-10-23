#!/usr/bin/env python
"""
Script para verificar la configuración de almacenamiento.
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'mercatico.settings')
django.setup()

from django.conf import settings
from django.core.files.storage import default_storage

print("=" * 60)
print("CONFIGURACIÓN DE ALMACENAMIENTO")
print("=" * 60)

print(f"\n📝 DEBUG: {settings.DEBUG}")
print(f"🌐 SUPABASE_URL: {settings.SUPABASE_URL[:30]}..." if settings.SUPABASE_URL else "❌ No configurado")
print(f"🔑 SUPABASE_KEY: {settings.SUPABASE_KEY[:20]}..." if settings.SUPABASE_KEY else "❌ No configurado")
print(f"🪣 SUPABASE_BUCKET: {settings.SUPABASE_BUCKET_NAME}")

print(f"\n💾 DEFAULT_FILE_STORAGE:")
if hasattr(settings, 'DEFAULT_FILE_STORAGE'):
    print(f"   ✅ {settings.DEFAULT_FILE_STORAGE}")
else:
    print(f"   ⚠️  FileSystemStorage (default)")

print(f"\n🗂️  Storage backend actual:")
print(f"   {default_storage.__class__.__name__}")
print(f"   {default_storage.__class__.__module__}")

if hasattr(default_storage, 'bucket_name'):
    print(f"   Bucket: {default_storage.bucket_name}")

print("\n" + "=" * 60)

# Verificar si puede conectarse a Supabase
if settings.SUPABASE_URL and settings.SUPABASE_KEY:
    print("\n🔌 Probando conexión a Supabase...")
    try:
        from supabase import create_client
        client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)

        # Listar buckets
        buckets = client.storage.list_buckets()
        print(f"✅ Conexión exitosa!")
        print(f"📦 Buckets disponibles: {len(buckets)}")
        for bucket in buckets:
            print(f"   - {bucket.get('name', 'Unknown')}")
            if bucket.get('name') == settings.SUPABASE_BUCKET_NAME:
                print(f"     ✅ Bucket '{settings.SUPABASE_BUCKET_NAME}' encontrado!")
    except Exception as e:
        print(f"❌ Error conectando a Supabase: {e}")
else:
    print("\n⚠️  Variables de Supabase no configuradas")
    print("   Configura SUPABASE_URL y SUPABASE_KEY en Railway")

print("\n" + "=" * 60)
