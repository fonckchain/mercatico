# Configuración de Android para Flutter - MercaTico

Tienes **2 opciones** para desarrollar apps Android con Flutter. Elige la que prefieras:

## 🎯 Opción 1: Android SDK Command Line Tools (Recomendado - Más Rápido)

**Ventajas:**
- ✅ Instalación más rápida (~500MB vs ~3GB)
- ✅ Menos uso de recursos
- ✅ Suficiente para desarrollo Flutter
- ✅ No necesitas el IDE completo

**Desventajas:**
- ❌ No tienes el IDE Android Studio (solo si necesitas editar código Android nativo)
- ❌ Gestión por línea de comandos

### Instalación:

```bash
cd /home/fonck/development/projects/mercatico
./install_android_cmdline.sh
```

Luego reinicia tu terminal o ejecuta:
```bash
source ~/.bashrc
```

---

## 🏢 Opción 2: Android Studio Completo

**Ventajas:**
- ✅ IDE completo con interfaz gráfica
- ✅ Emulador visual
- ✅ Herramientas de debugging avanzadas
- ✅ Útil si necesitas editar código Android nativo

**Desventajas:**
- ❌ Descarga más grande (~3GB)
- ❌ Más pesado en recursos
- ❌ Tarda más en instalar

### Instalación:

```bash
cd /home/fonck/development/projects/mercatico
./install_android_studio.sh
```

Luego:
1. Ejecuta Android Studio: `/opt/android-studio/bin/studio.sh`
2. Sigue el asistente de configuración
3. Instala el Android SDK
4. Acepta las licencias

---

## 📱 Después de Instalar (Ambas Opciones)

### 1. Configurar Flutter

```bash
# Asegúrate de tener Flutter en el PATH
export PATH="$PATH:$HOME/flutter/bin"

# Configurar Android SDK
flutter config --android-sdk $HOME/Android/Sdk

# Aceptar licencias de Android
flutter doctor --android-licenses
```

### 2. Verificar Instalación

```bash
flutter doctor
```

Deberías ver algo como:
```
[✓] Flutter (Channel stable, 3.35.6)
[✓] Android toolchain - develop for Android devices (Android SDK version 34.0.0)
[✓] Chrome - develop for the web
```

### 3. Conectar un Dispositivo

**Opción A: Dispositivo Físico (Recomendado para desarrollo)**

1. En tu teléfono Android:
   - Ve a **Ajustes > Acerca del teléfono**
   - Toca **Número de compilación** 7 veces (habilita modo desarrollador)
   - Ve a **Ajustes > Sistema > Opciones de desarrollador**
   - Activa **Depuración USB**

2. Conecta tu teléfono por USB

3. Verifica que Flutter lo detecte:
   ```bash
   flutter devices
   ```

**Opción B: Emulador Android**

Si instalaste Android Studio completo:
1. Abre Android Studio
2. Ve a **Tools > Device Manager**
3. Crea un nuevo dispositivo virtual
4. Selecciona un dispositivo (ej: Pixel 6)
5. Descarga una imagen del sistema (Android 14 recomendado)
6. Inicia el emulador

Si solo instalaste Command Line Tools:
```bash
# Crear emulador
avdmanager create avd -n mercatico_test \
  -k "system-images;android-34;google_apis;x86_64"

# Listar emuladores
emulator -list-avds

# Iniciar emulador
emulator -avd mercatico_test
```

---

## 🚀 Ejecutar la App en Android

### Desde la línea de comandos:

```bash
cd frontend/mercatico_app

# Ver dispositivos disponibles
flutter devices

# Ejecutar en el dispositivo conectado
flutter run

# O especificar dispositivo
flutter run -d <device_id>
```

### Hot Reload

Una vez la app esté corriendo:
- Presiona `r` para hot reload (recarga cambios)
- Presiona `R` para hot restart (reinicia la app)
- Presiona `q` para salir

---

## 🔧 Solución de Problemas

### Error: "Android SDK not found"

```bash
export ANDROID_HOME=$HOME/Android/Sdk
flutter config --android-sdk $HOME/Android/Sdk
```

### Error: "cmdline-tools component is missing"

```bash
# Si usaste el script CLI
sdkmanager "cmdline-tools;latest"

# Si usaste Android Studio
# Abre Android Studio > SDK Manager > SDK Tools
# Marca "Android SDK Command-line Tools"
```

### Error: "Unable to locate adb"

```bash
export PATH=$PATH:$HOME/Android/Sdk/platform-tools
flutter doctor -v
```

### La app no se conecta al backend

El emulador/dispositivo necesita una URL especial:

**En `lib/core/constants/api_constants.dart`**, cambia:

```dart
// Para emulador Android
static const String baseUrl = 'http://10.0.2.2:8000/api';

// Para dispositivo físico en la misma red WiFi
static const String baseUrl = 'http://192.168.X.X:8000/api';  // Usa tu IP local
```

Para obtener tu IP local:
```bash
ip addr show | grep "inet " | grep -v 127.0.0.1
```

---

## 📊 Comparación de Opciones

| Característica | Command Line Tools | Android Studio |
|----------------|-------------------|----------------|
| Tamaño descarga | ~500 MB | ~3 GB |
| Espacio en disco | ~2 GB | ~8 GB |
| Tiempo instalación | 5-10 min | 15-30 min |
| RAM requerida | ~2 GB | ~4 GB |
| Interfaz gráfica | ❌ | ✅ |
| Suficiente para Flutter | ✅ | ✅ |
| Editor Android nativo | ❌ | ✅ |

---

## 🎯 Mi Recomendación

**Para MercaTico**: Usa **Command Line Tools** (`install_android_cmdline.sh`)

**Razones:**
1. La app es mayormente Flutter (no necesitas editar código Android nativo)
2. Más rápido de instalar y configurar
3. Menos consumo de recursos
4. Puedes agregar Android Studio después si lo necesitas

---

## 📝 Verificación Final

Ejecuta este comando para verificar que todo está listo:

```bash
flutter doctor -v
```

Deberías ver:
- ✅ Flutter
- ✅ Android toolchain
- ✅ Chrome
- ✅ Connected device (si tienes un dispositivo/emulador)

---

## 🔥 Siguiente Paso

Una vez tengas todo configurado:

```bash
cd frontend/mercatico_app
flutter run
```

¡Deberías ver la app corriendo en tu dispositivo Android!
