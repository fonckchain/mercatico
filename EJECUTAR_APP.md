# Cómo Ejecutar MercaTico App

## ✅ Estado Actual

- ✅ Flutter instalado
- ✅ Android toolchain configurado
- ✅ Chrome instalado
- ✅ Backend Django corriendo en http://127.0.0.1:8000/

---

## 🚀 Opción 1: Ejecutar en Chrome (Web) - MÁS RÁPIDO

Esta es la forma más rápida para desarrollo:

```bash
cd ~/development/projects/mercatico/frontend/mercatico_app
export PATH="$PATH:$HOME/flutter/bin"
flutter run -d chrome
```

**Nota**: La URL del backend ya está configurada para `http://127.0.0.1:8000/api`

---

## 📱 Opción 2: Ejecutar en Android - Dispositivo Físico

### Paso 1: Habilitar Modo Desarrollador en tu Teléfono

1. Ve a **Ajustes** > **Acerca del teléfono**
2. Busca **Número de compilación** (o **Build number**)
3. Toca 7 veces hasta que aparezca "Eres un desarrollador"

### Paso 2: Activar Depuración USB

1. Ve a **Ajustes** > **Sistema** > **Opciones de desarrollador** (o **Developer options**)
2. Activa **Depuración USB** (USB debugging)
3. (Opcional) Activa **Instalación vía USB** para instalar la app

### Paso 3: Conectar el Dispositivo

1. Conecta tu teléfono por USB a la computadora
2. En el teléfono aparecerá un mensaje pidiendo autorización
3. Marca "Permitir siempre desde esta computadora"
4. Toca **Permitir** o **Aceptar**

### Paso 4: Verificar Conexión

```bash
export PATH="$PATH:$HOME/flutter/bin"
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools

flutter devices
```

Deberías ver tu dispositivo listado.

### Paso 5: Configurar URL del Backend

**IMPORTANTE**: Los dispositivos Android no pueden usar `127.0.0.1` para conectarse a tu computadora.

Edita el archivo de constantes:

```bash
cd ~/development/projects/mercatico/frontend/mercatico_app
nano lib/core/constants/api_constants.dart
```

**Obtén tu IP local:**
```bash
ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1
```

Ejemplo de salida: `192.168.1.100`

**En el archivo `api_constants.dart`, cambia:**

```dart
static String get apiBaseUrl {
  // Para dispositivo Android físico en la misma WiFi
  return 'http://192.168.1.100:8000/api';  // <-- USA TU IP AQUÍ
}
```

### Paso 6: Asegurar que el Backend Escuche en Todas las Interfaces

```bash
cd ~/development/projects/mercatico/backend
source venv/bin/activate
python manage.py runserver 0.0.0.0:8000
```

### Paso 7: Ejecutar la App

```bash
cd ~/development/projects/mercatico/frontend/mercatico_app
flutter run
```

Flutter detectará tu dispositivo automáticamente y compilará la app.

---

## 🖥️ Opción 3: Ejecutar en Emulador Android

### Paso 1: Crear un Emulador

```bash
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/emulator

# Crear emulador
avdmanager create avd \
  -n mercatico_pixel \
  -k "system-images;android-34;google_apis;x86_64" \
  -d "pixel_6"
```

### Paso 2: Listar Emuladores

```bash
flutter emulators
```

### Paso 3: Iniciar Emulador

```bash
flutter emulators --launch mercatico_pixel
```

O manualmente:
```bash
emulator -avd mercatico_pixel &
```

### Paso 4: Configurar URL para Emulador

En `lib/core/constants/api_constants.dart`:

```dart
static String get apiBaseUrl {
  // Para emulador Android (10.0.2.2 = localhost de la máquina host)
  return 'http://10.0.2.2:8000/api';
}
```

### Paso 5: Ejecutar la App

```bash
cd ~/development/projects/mercatico/frontend/mercatico_app
flutter run
```

---

## 🎯 Desarrollo con Hot Reload

Una vez la app esté corriendo, puedes hacer cambios en el código y:

- Presiona `r` en la terminal para **hot reload** (recarga cambios)
- Presiona `R` para **hot restart** (reinicia la app)
- Presiona `q` para **salir**

---

## 🔧 Comandos Útiles

```bash
# Ver todos los dispositivos disponibles
flutter devices

# Ver emuladores disponibles
flutter emulators

# Ejecutar en un dispositivo específico
flutter run -d <device_id>

# Ejecutar en modo release (más rápido)
flutter run --release

# Limpiar build cache si hay problemas
flutter clean
flutter pub get
```

---

## 📝 Configuración para Cada Plataforma

| Plataforma | URL del Backend | Comando |
|------------|-----------------|---------|
| **Web (Chrome)** | `http://127.0.0.1:8000/api` | `flutter run -d chrome` |
| **Emulador Android** | `http://10.0.2.2:8000/api` | `flutter run -d emulator` |
| **Dispositivo Android** | `http://TU_IP_LOCAL:8000/api` | `flutter run -d <device>` |

---

## 🚨 Solución de Problemas

### Error: "No devices available"

```bash
# Verifica que adb vea el dispositivo
export PATH=$PATH:$HOME/Android/Sdk/platform-tools
adb devices

# Si no aparece, reinicia adb
adb kill-server
adb start-server
```

### Error: "Unable to connect to localhost"

- Si usas dispositivo físico, asegúrate de usar tu IP local (no `127.0.0.1`)
- Verifica que el backend esté corriendo con `python manage.py runserver 0.0.0.0:8000`
- Verifica que tu teléfono y computadora estén en la misma red WiFi

### Error al compilar

```bash
cd ~/development/projects/mercatico/frontend/mercatico_app
flutter clean
flutter pub get
flutter run
```

---

## 🎉 ¡Listo para Desarrollar!

Ahora puedes:

1. Hacer cambios en `lib/main.dart`
2. Ver los cambios instantáneamente con hot reload
3. Probar la app en múltiples plataformas
4. Conectarte al backend Django para APIs reales

**Próximo paso**: Implementar las pantallas de la app (Login, Productos, etc.)
