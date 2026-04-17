# AppTaxis — App Móvil Flutter

## Requisitos previos

- Flutter SDK 3.x o superior → https://docs.flutter.dev/get-started/install
- Android Studio Hedgehog o superior (con plugin Flutter instalado)
- Un emulador Android o dispositivo físico con USB debugging activado

---

## 1. Instalar Flutter y el plugin en Android Studio

1. Descarga Flutter SDK y añádelo al PATH de tu sistema.
2. En Android Studio → Settings → Plugins → busca "Flutter" → Instalar (instala Dart automáticamente).
3. Ejecuta `flutter doctor` en terminal y resuelve cualquier aviso marcado con ✗.

---

## 2. Abrir el proyecto

1. Android Studio → Open → selecciona la carpeta `apptaxis_flutter/`
2. Android Studio detecta el proyecto Flutter automáticamente.
3. Espera a que descargue las dependencias (esquina inferior derecha: "pub get").

Si no lanza "pub get" automáticamente, abre terminal en Android Studio y ejecuta:
```
flutter pub get
```

---

## 3. Configurar tus credenciales (OBLIGATORIO)

Edita los dos archivos siguientes con tus valores reales:

### lib/services/auth_service.dart
```dart
const _supabaseUrl     = 'https://TU_PROYECTO.supabase.co';  // ← supabase.url
const _supabaseAnonKey = 'TU_ANON_KEY';                       // ← supabase.anon_key
```

### lib/services/api_client.dart
```dart
const _baseUrl = 'http://apptaxis-api-production.up.railway.app'; // ya está correcto
const _apiKey  = 'TU_API_KEY';  // ← api.key de tu config.properties
```

Estos valores son los mismos que tienes en tu `config.properties` del proyecto Java.

---

## 4. Ejecutar en el emulador

1. En Android Studio, selecciona el dispositivo en la barra superior (emulador o físico).
2. Pulsa el botón ▶ verde ("Run 'main.dart'").
3. La primera compilación tarda 2-3 minutos. Las siguientes son instantáneas (hot reload con R).

---

## Estructura del proyecto

```
lib/
├── main.dart                    ← Entrada, tema global, splash + restaurar sesión
├── models/
│   ├── admin.dart               ← Modelo sesión de usuario
│   ├── conductor.dart           ← Modelo conductor
│   └── viaje.dart               ← Modelo viaje
├── services/
│   ├── api_client.dart          ← Todas las llamadas a la API REST (X-API-Key)
│   ├── auth_service.dart        ← Login/logout con Supabase Auth
│   └── session_manager.dart     ← Estado global de sesión (en memoria)
└── screens/
    ├── login_screen.dart        ← Pantalla de login
    ├── menu_screen.dart         ← Menú principal
    ├── conductores_screen.dart  ← CRUD completo de conductores
    └── calendario_screen.dart   ← Calendario con viajes por día
```

---

## Funcionalidades implementadas

| Pantalla | Qué hace |
|---|---|
| Login | Llama a Supabase Auth igual que el desktop. Guarda el token de forma segura. |
| Splash | Al arrancar la app restaura la sesión automáticamente si el token es válido. |
| Menú | Navegación a Conductores y Calendario. Botón logout. |
| Conductores | Lista todos, añade con validación de matrícula (1234ABC), edita nombre, elimina con confirmación. |
| Calendario | Muestra puntos en los días con viajes, lista viajes del día seleccionado, crea y elimina viajes. |

---

## Dependencias utilizadas

| Paquete | Uso |
|---|---|
| `http` | Llamadas HTTP a la API REST |
| `flutter_secure_storage` | Token guardado cifrado en el dispositivo |
| `table_calendar` | Calendario interactivo |
| `intl` | Formato de fechas |
| `provider` | Gestión de estado (disponible para extender) |

---

## Próximos pasos sugeridos

- Editar viaje existente (pantalla de formulario)
- Filtrar viajes por conductor en el calendario
- Notificaciones push para avisos de viajes
- Modo oscuro automático (ya funciona con Material 3)
- Publicar en Google Play Store
