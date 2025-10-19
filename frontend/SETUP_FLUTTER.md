# Setup de Flutter para MercaTico

Esta guía te ayudará a configurar el frontend de Flutter para MercaTico.

## Paso 1: Instalar Flutter

Ejecuta el script de instalación:

```bash
cd /home/fonck/development/projects/mercatico
./install_flutter.sh
```

Después de la instalación, reinicia tu terminal o ejecuta:

```bash
source ~/.bashrc
# O si usas zsh:
source ~/.zshrc
```

Verifica la instalación:

```bash
flutter --version
flutter doctor
```

## Paso 2: Crear el Proyecto Flutter

Una vez Flutter esté instalado:

```bash
cd frontend
flutter create --org cr.mercatico mercatico_app
cd mercatico_app
```

## Paso 3: Configurar Dependencias

Edita `pubspec.yaml` y agrega las dependencias:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Estado y Gestión
  provider: ^6.1.1
  flutter_riverpod: ^2.4.9

  # HTTP y API
  dio: ^5.4.0
  json_annotation: ^4.8.1

  # Almacenamiento
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0

  # UI/UX
  google_fonts: ^6.1.0
  cached_network_image: ^3.3.1
  image_picker: ^1.0.7
  shimmer: ^3.0.0

  # Navegación
  go_router: ^13.0.0

  # Utilidades
  intl: ^0.18.1
  uuid: ^4.3.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
```

Luego ejecuta:

```bash
flutter pub get
```

## Paso 4: Estructura de Carpetas

Crea la siguiente estructura en `lib/`:

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   │   ├── api_constants.dart
│   │   └── app_constants.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── colors.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   └── formatters.dart
│   └── services/
│       ├── api_service.dart
│       ├── auth_service.dart
│       └── storage_service.dart
├── features/
│   ├── auth/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   ├── products/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   ├── orders/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   └── profile/
│       ├── models/
│       ├── providers/
│       ├── screens/
│       └── widgets/
└── shared/
    ├── models/
    ├── widgets/
    └── providers/
```

## Paso 5: Configurar la API

La API del backend está corriendo en:
- **Desarrollo Local**: `http://127.0.0.1:8000/api/`
- **Para Android Emulator**: `http://10.0.2.2:8000/api/`
- **Para Dispositivo Físico**: `http://[TU_IP_LOCAL]:8000/api/`

## Paso 6: Ejecutar la App

Para web (desarrollo rápido):
```bash
flutter run -d chrome
```

Para Android:
```bash
flutter run -d android
```

Para iOS (solo macOS):
```bash
flutter run -d ios
```

## Recursos

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Guide](https://riverpod.dev/docs/introduction/getting_started)
- [Dio HTTP Client](https://pub.dev/packages/dio)
- [Go Router](https://pub.dev/packages/go_router)

## Próximos Pasos

1. Instalar Flutter con `./install_flutter.sh`
2. Crear proyecto con `flutter create`
3. Copiar archivos base que te proporcionaré
4. Ejecutar `flutter run`
