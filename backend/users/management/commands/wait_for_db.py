"""
Management command to wait for database to be ready.
This is useful for Docker/containerized deployments where the database
might not be immediately available when the app starts.
"""
import time
from django.core.management.base import BaseCommand
from django.db import connection
from django.db.utils import OperationalError


class Command(BaseCommand):
    help = 'Wait for database to be ready'

    def add_arguments(self, parser):
        parser.add_argument(
            '--max-retries',
            type=int,
            default=30,
            help='Maximum number of retry attempts (default: 30)',
        )
        parser.add_argument(
            '--retry-delay',
            type=int,
            default=2,
            help='Delay between retries in seconds (default: 2)',
        )

    def handle(self, *args, **options):
        max_retries = options['max_retries']
        retry_delay = options['retry_delay']
        
        self.stdout.write('Waiting for database...')
        
        for attempt in range(1, max_retries + 1):
            try:
                with connection.cursor() as cursor:
                    cursor.execute("SELECT 1")
                self.stdout.write(
                    self.style.SUCCESS('✓ Database is ready!')
                )
                return
            except OperationalError as e:
                if attempt < max_retries:
                    self.stdout.write(
                        f'Attempt {attempt}/{max_retries}: Database not ready, waiting {retry_delay}s...'
                    )
                    time.sleep(retry_delay)
                else:
                    self.stdout.write(
                        self.style.ERROR(
                            f'✗ Database connection failed after {max_retries} attempts'
                        )
                    )
                    self.stdout.write(
                        self.style.ERROR(f'Error: {str(e)}')
                    )
                    raise

