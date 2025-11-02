# MercaTico - Guía de Deployment y Publicación

## 📱 Google Play Store (Android)

### Prerrequisitos

1. **Cuenta de Google Play Developer** ($25 USD pago único)
   - Registrarse en: https://play.google.com/console/signup
   - Tiempo de aprobación: 24-48 horas

2. **Preparar la App**
   - ✅ Íconos configurados
   - ✅ Nombre de app configurado
   - ⚠️  Keystore para firmar la app
   - ⚠️  Versión y build number

### Paso 1: Crear Keystore para Firma Digital

El keystore es necesario para firmar tu app. **GUÁRDALO EN UN LUGAR SEGURO** - no podrás actualizarla sin él.

```bash
cd ~/development/projects/mercatico/frontend/mercatico_app

# Crear keystore
keytool -genkey -v -keystore ~/mercatico-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias mercatico

# Te pedirá:
# - Password del keystore (GUÁRDALO)
# - Tu nombre y organización
# - Password de la key (puede ser el mismo)
```

**⚠️ IMPORTANTE**: Haz backup del archivo `mercatico-keystore.jks` y las contraseñas en un lugar seguro (1Password, LastPass, etc.)

### Paso 2: Configurar Firma en la App

Crear archivo `android/key.properties`:

```properties
storePassword=TU_PASSWORD_DEL_KEYSTORE
keyPassword=TU_PASSWORD_DE_LA_KEY
keyAlias=mercatico
storeFile=/home/fonck/mercatico-keystore.jks
```

**⚠️ NO COMMITEAR** este archivo. Agregar a `.gitignore`:

```bash
echo "android/key.properties" >> .gitignore
```

### Paso 3: Actualizar build.gradle

El archivo `android/app/build.gradle` ya debe estar configurado para leer el keystore. Verifica:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### Paso 4: Configurar Versión de la App

Editar `pubspec.yaml`:

```yaml
version: 1.0.0+1  # formato: VERSION_NAME+BUILD_NUMBER
```

- `1.0.0` = Versión visible para usuarios
- `+1` = Build number (incrementar en cada build)

### Paso 5: Build del APK/AAB

**App Bundle (Recomendado para Play Store):**
```bash
flutter build appbundle --release
```

**APK (Para testing o distribución directa):**
```bash
flutter build apk --release
```

Los archivos se generan en:
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/flutter-apk/app-release.apk`

### Paso 6: Crear App en Google Play Console

1. Ir a https://play.google.com/console
2. Click en "Crear app"
3. Completar:
   - **Nombre**: MercaTico
   - **Idioma predeterminado**: Español (Latinoamérica)
   - **App o juego**: App
   - **Gratis o de pago**: Gratis
   - **Declaraciones**: Aceptar políticas

### Paso 7: Completar Ficha de la Tienda

#### Descripción Corta (80 caracteres):
```
Marketplace local de Costa Rica - Compra y vende productos cerca de ti
```

#### Descripción Completa (hasta 4000 caracteres):
```
MercaTico es el marketplace local de Costa Rica que conecta compradores y vendedores de tu zona.

🛍️ PARA COMPRADORES:
• Encuentra productos locales cerca de ti
• Compara precios y productos fácilmente
• Contacta directamente con vendedores
• Paga con SINPE o efectivo
• Recoge en persona o solicita entrega

🏪 PARA VENDEDORES:
• Publica tus productos gratis
• Gestiona tu catálogo fácilmente
• Recibe pedidos en tiempo real
• Configura métodos de pago
• Controla entregas y recogidas

✨ CARACTERÍSTICAS:
• Interfaz simple e intuitiva
• Búsqueda por categorías
• Filtros por ubicación
• Sistema de pedidos integrado
• Soporte para SINPE Móvil
• Notificaciones de pedidos

MercaTico hace que comprar y vender localmente sea fácil, rápido y seguro.

¡Únete a la comunidad MercaTico hoy!
```

#### Capturas de Pantalla (Mínimo 2, recomendado 8):
Necesitas capturas de:
- Homepage/Catálogo
- Detalle de producto
- Carrito de compras
- Pantalla de vendedor
- Perfil
- Búsqueda

Tamaños:
- Teléfono: 16:9 (1080x1920 o 1242x2208)
- Tablet 7": 16:9
- Tablet 10": 16:9

#### Ícono de la App:
- 512x512 px PNG (32-bit con alpha)
- Ya lo tienes en `assets/images/logo.png` - redimensionar a 512x512

#### Gráfico de Función:
- 1024x500 px JPG o PNG
- Imagen promocional opcional

### Paso 8: Configurar Contenido

#### Clasificación de Contenido:
1. Completar cuestionario
2. Para marketplace: marcar como "E para Todos"

#### Público Objetivo:
- **Grupo de edad**: Adultos (mayores de 18)
- **Contenido inapropiado**: No

#### Privacidad:
Necesitas una URL de política de privacidad. Puedes:
1. Crearla en tu sitio (mercatico.net/privacy)
2. Usar un generador: https://www.privacypolicygenerator.info/

#### Datos de Contacto:
- Email: tu-email@gmail.com
- Teléfono (opcional)
- Sitio web: https://mercatico.net

### Paso 9: Subir la App

1. Ir a "Producción" → "Crear nueva versión"
2. Subir el archivo `.aab`
3. Completar "Notas de la versión":
   ```
   Versión 1.0.0 - Lanzamiento Inicial
   • Catálogo de productos
   • Sistema de pedidos
   • Gestión de vendedores
   • Pagos con SINPE
   • Búsqueda y filtros
   ```

### Paso 10: Testing Interno/Cerrado (Recomendado)

Antes de publicar en producción, prueba con un grupo cerrado:

1. **Testing Interno** (hasta 100 testers):
   - Ir a "Testing" → "Internal testing"
   - Crear lista de emails
   - Subir AAB
   - Compartir link con testers

2. **Testing Cerrado** (Alpha/Beta):
   - Ir a "Testing" → "Closed testing"
   - Crear track "Alpha" o "Beta"
   - Subir AAB
   - Invitar testers

3. **Testing Abierto** (Beta pública):
   - Cualquiera puede unirse
   - Bueno para feedback antes del lanzamiento

### Paso 11: Publicación en Producción

1. Verificar que todo esté completo (Play Console te dirá)
2. Ir a "Producción" → "Crear versión"
3. Subir AAB
4. Click en "Revisar versión"
5. Click en "Iniciar lanzamiento en producción"

**⏰ Tiempo de revisión**: 1-7 días (usualmente 24-48 horas)

### Paso 12: Actualizaciones Futuras

Para actualizar la app:

1. Incrementar versión en `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # nueva versión, nuevo build number
   ```

2. Build nuevo AAB:
   ```bash
   flutter build appbundle --release
   ```

3. Subir en Play Console → Producción → Nueva versión

## 🍎 App Store (iOS)

### Prerrequisitos

1. **Apple Developer Program** ($99 USD/año)
   - Registrarse en: https://developer.apple.com/programs/
   - Necesitas Mac para el proceso completo

2. **Mac con Xcode** (obligatorio)
   - Descargar de App Store
   - Instalar Xcode Command Line Tools

### Paso 1: Configurar en Xcode

```bash
cd ~/development/projects/mercatico/frontend/mercatico_app/ios
open Runner.xcworkspace
```

En Xcode:
1. Seleccionar "Runner" en el navegador
2. Ir a "Signing & Capabilities"
3. Seleccionar tu equipo (Team)
4. Bundle Identifier: `com.mercatico.app` (único)

### Paso 2: Configurar Info.plist

Verificar que tenga:
```xml
<key>CFBundleDisplayName</key>
<string>MercaTico</string>
<key>CFBundleName</key>
<string>MercaTico</string>
```

### Paso 3: Build para iOS

```bash
flutter build ios --release
```

### Paso 4: Crear App en App Store Connect

1. Ir a https://appstoreconnect.apple.com
2. "Mis Apps" → "+"
3. Completar información

### Paso 5: Subir Build con Xcode

1. Abrir Xcode
2. Product → Archive
3. Window → Organizer
4. Distribute App → App Store Connect

### Paso 6: Completar Metadata

Similar a Play Store:
- Capturas de pantalla
- Descripción
- Keywords
- Categoría: Shopping
- Política de privacidad

### Paso 7: Enviar a Revisión

Tiempo de revisión: 1-3 días

## 🌐 Web (Vercel) - Ya Configurado

Tu app web ya está en producción en https://mercatico.net

Para actualizar:
```bash
git push origin main  # Vercel deploy automático
```

## 🔐 Ambiente de Testing vs Producción

### Opción 1: Branches de Git

```bash
# Crear branch de desarrollo
git checkout -b development

# Trabajar en desarrollo
# ...

# Cuando esté listo para producción
git checkout main
git merge development
git push
```

### Opción 2: Flavors/Environments en Flutter

Crear ambientes separados:

**1. Crear archivos de configuración:**

`lib/config/app_config.dart`:
```dart
class AppConfig {
  final String apiBaseUrl;
  final String appName;
  final bool isProduction;

  AppConfig({
    required this.apiBaseUrl,
    required this.appName,
    required this.isProduction,
  });

  static AppConfig _instance = AppConfig.dev();

  static AppConfig get instance => _instance;

  static void setEnvironment(AppConfig config) {
    _instance = config;
  }

  factory AppConfig.dev() {
    return AppConfig(
      apiBaseUrl: 'http://localhost:8000',
      appName: 'MercaTico DEV',
      isProduction: false,
    );
  }

  factory AppConfig.prod() {
    return AppConfig(
      apiBaseUrl: 'https://api.mercatico.net',
      appName: 'MercaTico',
      isProduction: true,
    );
  }
}
```

**2. Crear entry points:**

`lib/main_dev.dart`:
```dart
import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'main.dart' as app;

void main() {
  AppConfig.setEnvironment(AppConfig.dev());
  app.main();
}
```

`lib/main_prod.dart`:
```dart
import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'main.dart' as app;

void main() {
  AppConfig.setEnvironment(AppConfig.prod());
  app.main();
}
```

**3. Comandos de build:**

```bash
# Desarrollo
flutter run -t lib/main_dev.dart

# Producción
flutter run -t lib/main_prod.dart
flutter build apk --release -t lib/main_prod.dart
```

### Opción 3: Backend con Ambientes

En Railway/Vercel:

1. **Crear proyecto separado para staging**:
   - Backend: railway-staging.com
   - Frontend: staging.mercatico.net

2. **Variables de entorno**:
   - Producción: `ENV=production`
   - Staging: `ENV=staging`

## 📊 Monitoreo Post-Lanzamiento

### Google Play Console
- Estadísticas de instalación
- Crashes y ANRs
- Reseñas de usuarios
- Métricas de rendimiento

### Analytics (Opcional pero Recomendado)
```bash
flutter pub add firebase_analytics
```

## 📝 Checklist Pre-Lanzamiento

### Android:
- [ ] Keystore creado y guardado
- [ ] key.properties configurado
- [ ] Versión actualizada en pubspec.yaml
- [ ] Íconos generados con flutter_launcher_icons
- [ ] Build exitoso de AAB
- [ ] Testing en dispositivos físicos
- [ ] Permisos de Android configurados
- [ ] Política de privacidad publicada
- [ ] Capturas de pantalla preparadas
- [ ] Descripción de la app escrita

### iOS:
- [ ] Apple Developer account activa
- [ ] Bundle ID configurado
- [ ] Certificados de firma
- [ ] Build exitoso
- [ ] Testing en TestFlight
- [ ] Metadata completo
- [ ] Capturas para todos los tamaños

### General:
- [ ] Testing completo de funcionalidades
- [ ] Bug fixes prioritarios completados
- [ ] Términos y condiciones
- [ ] Política de privacidad
- [ ] Soporte al cliente configurado
- [ ] Plan de respuesta a reseñas

## 🚀 Recomendación: Estrategia de Lanzamiento

### Fase 1: Alpha (2-4 semanas)
- Testing interno con 10-20 usuarios
- Recolectar feedback
- Fix bugs críticos

### Fase 2: Beta Cerrada (4-8 semanas)
- 100-500 usuarios invitados
- Monitorear crashes
- Optimizar UX
- Preparar marketing

### Fase 3: Beta Abierta (2-4 semanas)
- Cualquiera puede unirse
- Marketing suave
- Escalar infraestructura
- Últimos ajustes

### Fase 4: Producción
- Lanzamiento público
- Campaña de marketing
- Soporte activo
- Iteración basada en feedback

## 💡 Tips Finales

1. **Empieza con Beta**: No publiques directamente en producción
2. **Responde reseñas**: Engagement aumenta ranking
3. **Actualiza frecuentemente**: Demuestra app activa
4. **Monitorea crashes**: Fix inmediato = mejor rating
5. **A/B testing**: Prueba descripciones e íconos diferentes
6. **ASO (App Store Optimization)**: Keywords importantes
7. **Screenshot marketing**: Primeras 2 capturas son críticas
8. **Video preview**: Aumenta conversión 25-30%

## 📞 Soporte

- Google Play Console: https://support.google.com/googleplay/android-developer
- App Store Connect: https://developer.apple.com/support/
- Flutter: https://docs.flutter.dev/deployment
