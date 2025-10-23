"""
Custom storage backend for Supabase Storage.
"""
from django.core.files.storage import Storage
from django.conf import settings
from supabase import create_client, Client
import uuid
from urllib.parse import urljoin


class SupabaseStorage(Storage):
    """
    Custom storage backend para usar Supabase Storage.

    Configuración en settings.py:
    - SUPABASE_URL
    - SUPABASE_KEY
    - SUPABASE_BUCKET_NAME (default: 'products')
    """

    def __init__(self):
        self.supabase_url = settings.SUPABASE_URL
        self.supabase_key = settings.SUPABASE_KEY
        self.bucket_name = getattr(settings, 'SUPABASE_BUCKET_NAME', 'products')
        self.client: Client = create_client(self.supabase_url, self.supabase_key)

    def _save(self, name, content):
        """
        Guardar archivo en Supabase Storage.
        """
        # Generar nombre único si es necesario
        if not name:
            name = f"{uuid.uuid4()}"

        # Leer contenido del archivo
        file_content = content.read()

        # Subir a Supabase Storage
        try:
            response = self.client.storage.from_(self.bucket_name).upload(
                path=name,
                file=file_content,
                file_options={"content-type": content.content_type if hasattr(content, 'content_type') else "application/octet-stream"}
            )
            print(f"✅ Uploaded to Supabase: {name}")
        except Exception as e:
            print(f"❌ Error uploading to Supabase: {e}")
            raise

        return name

    def _open(self, name, mode='rb'):
        """
        Abrir archivo desde Supabase Storage.
        No implementado - usar URL pública directamente.
        """
        raise NotImplementedError("Use url() method to get public URL")

    def delete(self, name):
        """
        Eliminar archivo de Supabase Storage.
        """
        try:
            self.client.storage.from_(self.bucket_name).remove([name])
        except Exception as e:
            print(f"Error deleting file from Supabase: {e}")

    def exists(self, name):
        """
        Verificar si un archivo existe.
        """
        try:
            files = self.client.storage.from_(self.bucket_name).list(path=name)
            return len(files) > 0
        except:
            return False

    def url(self, name):
        """
        Obtener URL pública del archivo.
        """
        # Obtener URL pública del bucket
        public_url = self.client.storage.from_(self.bucket_name).get_public_url(name)
        return public_url

    def size(self, name):
        """
        Obtener tamaño del archivo.
        """
        # Supabase no tiene método directo, retornar 0
        return 0
