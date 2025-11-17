#!/usr/bin/env python
"""
Standalone script to wait for database to be ready.
This can be used as a fallback if the management command doesn't work.
"""
import os
import sys
import time
import django

# Setup Django
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'mercatico.settings')
django.setup()

from django.db import connection
from django.db.utils import OperationalError

def wait_for_db(max_retries=30, retry_delay=2):
    """Wait for database to be ready."""
    print('Waiting for database...')
    
    for attempt in range(1, max_retries + 1):
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
            print('✓ Database is ready!')
            return True
        except OperationalError as e:
            if attempt < max_retries:
                print(f'Attempt {attempt}/{max_retries}: Database not ready, waiting {retry_delay}s...')
                time.sleep(retry_delay)
            else:
                print(f'✗ Database connection failed after {max_retries} attempts')
                print(f'Error: {str(e)}')
                return False
    
    return False

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Wait for database to be ready')
    parser.add_argument('--max-retries', type=int, default=30, help='Maximum retry attempts')
    parser.add_argument('--retry-delay', type=int, default=2, help='Delay between retries in seconds')
    args = parser.parse_args()
    
    success = wait_for_db(args.max_retries, args.retry_delay)
    sys.exit(0 if success else 1)

