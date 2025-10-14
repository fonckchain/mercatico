# Guía de Configuración - MercaTico

## Resumen del Progreso

### ✅ Completado

1. **Estructura del Proyecto**
   - Carpetas backend, frontend, docs creadas
   - README.md completo con documentación

2. **Backend Django**
   - Configuración completa de Django (settings.py)
   - Modelos de base de datos para todas las apps:
     - `users`: User, SellerProfile, BuyerProfile
     - `products`: Category, Product, ProductImage
     - `orders`: Order, OrderItem, OrderStatusHistory
     - `payments`: PaymentReceipt, PaymentVerificationLog
     - `reviews`: Review, ReviewReport
   - Serializers para users y products
   - Sistema de configuración con variables de entorno
   - Health check endpoint

3. **Documentación**
   - README completo con arquitectura
   - Guía de API endpoints
   - Configuración de deployment

### 🔨 Pendiente de Implementar

## Pasos Siguientes

### 1. Completar Backend Django

#### a. Serializers Restantes

Crear `backend/orders/serializers.py`:
```python
from rest_framework import serializers
from orders.models import Order, OrderItem, OrderStatusHistory
from products.serializers import ProductListSerializer

class OrderItemSerializer(serializers.ModelSerializer):
    product_details = ProductListSerializer(source='product', read_only=True)

    class Meta:
        model = OrderItem
        fields = ['id', 'product', 'product_details', 'product_name',
                  'product_price', 'quantity', 'subtotal']

class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    buyer_name = serializers.CharField(source='buyer.get_full_name', read_only=True)
    seller_name = serializers.CharField(source='seller.seller_profile.business_name', read_only=True)

    class Meta:
        model = Order
        fields = '__all__'
        read_only_fields = ['id', 'order_number', 'buyer', 'seller', 'created_at']
```

Crear `backend/payments/serializers.py` y `backend/reviews/serializers.py` de forma similar.

#### b. Views y ViewSets

Crear `backend/users/views.py`:
```python
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from users.models import User, SellerProfile
from users.serializers import (
    UserSerializer, UserRegistrationSerializer,
    ChangePasswordSerializer, PublicSellerProfileSerializer
)

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if self.request.user.is_staff:
            return User.objects.all()
        return User.objects.filter(id=self.request.user.id)

    @action(detail=False, methods=['get', 'put', 'patch'])
    def me(self, request):
        """Get or update current user profile"""
        if request.method == 'GET':
            serializer = self.get_serializer(request.user)
            return Response(serializer.data)
        else:
            serializer = self.get_serializer(
                request.user,
                data=request.data,
                partial=True
            )
            serializer.is_valid(raise_exception=True)
            serializer.save()
            return Response(serializer.data)

    @action(detail=False, methods=['post'], permission_classes=[permissions.AllowAny])
    def register(self, request):
        """Register a new user"""
        serializer = UserRegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(
            UserSerializer(user).data,
            status=status.HTTP_201_CREATED
        )

    @action(detail=False, methods=['post'])
    def change_password(self, request):
        """Change user password"""
        serializer = ChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        if not request.user.check_password(serializer.validated_data['old_password']):
            return Response(
                {'old_password': 'Contraseña incorrecta'},
                status=status.HTTP_400_BAD_REQUEST
            )

        request.user.set_password(serializer.validated_data['new_password'])
        request.user.save()
        return Response({'message': 'Contraseña actualizada exitosamente'})
```

#### c. URLs

Crear `backend/users/urls.py`:
```python
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from users.views import UserViewSet

router = DefaultRouter()
router.register(r'users', UserViewSet, basename='user')

urlpatterns = [
    path('', include(router.urls)),
]
```

Repetir para products, orders, payments, reviews.

#### d. Servicio de Verificación de Pagos con Grok

Crear `backend/payments/services.py`:
```python
import requests
from django.conf import settings
import logging

logger = logging.getLogger(__name__)

class GrokPaymentVerifier:
    """Service to verify SINPE payment receipts using Grok API."""

    def __init__(self):
        self.api_key = settings.GROK_API_KEY
        self.api_url = settings.GROK_API_URL

    def verify_receipt(self, image_path, expected_amount, expected_receiver):
        """
        Verify payment receipt using Grok vision capabilities.

        Args:
            image_path: Path to receipt image
            expected_amount: Expected payment amount
            expected_receiver: Expected receiver phone number

        Returns:
            dict: Verification results
        """
        try:
            # Prepare the prompt for Grok
            prompt = f"""
            Analiza esta imagen de comprobante de SINPE Móvil y extrae la siguiente información:

            1. Monto transferido
            2. Número de teléfono del receptor
            3. Número de teléfono del emisor
            4. ID de transacción
            5. Fecha y hora de la transacción
            6. Nombre del banco

            Verifica que:
            - El monto sea {expected_amount} CRC
            - El receptor sea {expected_receiver}
            - La transacción sea reciente (máximo 1 hora)

            Responde en formato JSON con esta estructura:
            {{
                "amount": "monto",
                "receiver_phone": "telefono_receptor",
                "sender_phone": "telefono_emisor",
                "transaction_id": "id",
                "transaction_date": "fecha_iso",
                "bank": "nombre_banco",
                "verified": true/false,
                "confidence": 0-100,
                "issues": ["lista de problemas si existen"]
            }}
            """

            # Call Grok API (similar to OpenAI API)
            headers = {
                'Authorization': f'Bearer {self.api_key}',
                'Content-Type': 'application/json'
            }

            # Read and encode image
            import base64
            with open(image_path, 'rb') as img_file:
                img_base64 = base64.b64encode(img_file.read()).decode()

            payload = {
                'model': 'grok-vision-beta',  # Adjust based on actual Grok model
                'messages': [
                    {
                        'role': 'user',
                        'content': [
                            {'type': 'text', 'text': prompt},
                            {
                                'type': 'image_url',
                                'image_url': {
                                    'url': f'data:image/jpeg;base64,{img_base64}'
                                }
                            }
                        ]
                    }
                ],
                'temperature': 0.1,  # Low temperature for consistent extraction
            }

            response = requests.post(
                f'{self.api_url}/chat/completions',
                headers=headers,
                json=payload,
                timeout=30
            )
            response.raise_for_status()

            # Parse response
            result = response.json()
            content = result['choices'][0]['message']['content']

            # Parse JSON from response
            import json
            verification_data = json.loads(content)

            logger.info(f"Payment verification completed: {verification_data}")
            return verification_data

        except Exception as e:
            logger.error(f"Error verifying payment receipt: {e}")
            return {
                'verified': False,
                'confidence': 0,
                'issues': [f'Error en verificación: {str(e)}']
            }
```

### 2. Frontend Flutter

#### a. Inicializar Proyecto Flutter

```bash
cd frontend
flutter create --org cr.mercatico --platforms web,android,ios mercatico_app
cd mercatico_app
```

#### b. Agregar Dependencias

Editar `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter

  # Estado
  provider: ^6.1.1
  riverpod: ^2.4.9
  flutter_riverpod: ^2.4.9

  # HTTP
  dio: ^5.4.0

  # Almacenamiento
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0

  # Imágenes
  cached_network_image: ^3.3.1
  image_picker: ^1.0.7

  # UI
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.9
  shimmer: ^3.0.0

  # Navegación
  go_router: ^13.0.0

  # Utilidades
  intl: ^0.18.1
  url_launcher: ^6.2.4
```

#### c. Estructura de Carpetas Flutter

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── auth/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   ├── products/
│   ├── orders/
│   ├── seller/
│   └── buyer/
└── services/
    ├── api_service.dart
    ├── auth_service.dart
    └── storage_service.dart
```

#### d. Configuración Base

Crear `lib/core/constants/api_constants.dart`:
```dart
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  static const String authLogin = '/auth/login/';
  static const String authRegister = '/auth/register/';
  static const String products = '/products/';
  static const String orders = '/orders/';
  // ... más endpoints
}
```

### 3. Deployment

#### a. Railway (Backend)

Crear `railway.json`:
```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "gunicorn mercatico.wsgi:application",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

Crear `Procfile`:
```
web: gunicorn mercatico.wsgi --log-file -
release: python manage.py migrate
```

#### b. Vercel (Frontend)

Crear `vercel.json` en frontend:
```json
{
  "buildCommand": "flutter build web",
  "outputDirectory": "build/web",
  "framework": null
}
```

### 4. Testing

```bash
# Backend
cd backend
python manage.py test

# Frontend
cd frontend/mercatico_app
flutter test
```

## Comandos Útiles

### Backend

```bash
# Crear migraciones
python manage.py makemigrations

# Aplicar migraciones
python manage.py migrate

# Crear superusuario
python manage.py createsuperuser

# Ejecutar servidor
python manage.py runserver

# Shell interactivo
python manage.py shell
```

### Frontend

```bash
# Ejecutar en web
flutter run -d chrome

# Ejecutar en Android
flutter run -d android

# Ejecutar en iOS
flutter run -d ios

# Build para producción
flutter build web
flutter build apk
flutter build ios
```

## Próximos Pasos Prioritarios

1. ✅ Completar serializers para orders, payments, reviews
2. ✅ Implementar views y viewsets para todas las apps
3. ✅ Configurar URLs correctamente
4. ✅ Implementar servicio de verificación con Grok
5. ✅ Crear sistema de notificaciones con Twilio
6. ✅ Configurar admin.py para cada app
7. ✅ Inicializar proyecto Flutter
8. ✅ Implementar autenticación en Flutter
9. ✅ Crear interfaces de usuario
10. ✅ Testing integral
11. ✅ Deployment a producción

## Recursos

- [Django REST Framework](https://www.django-rest-framework.org/)
- [Flutter Documentation](https://flutter.dev/docs)
- [Grok API (xAI)](https://x.ai/api)
- [Supabase Docs](https://supabase.com/docs)
- [Railway Docs](https://docs.railway.app/)
- [Vercel Docs](https://vercel.com/docs)
