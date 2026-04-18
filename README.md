# AppTaxis

AppTaxis es una solución móvil moderna diseñada para la gestión eficiente de conductores y viajes en tiempo real. Esta aplicación permite a los administradores organizar la logística diaria de forma sencilla e intuitiva.

---

## 📋 Requisitos para el Usuario

Para utilizar la aplicación correctamente, asegúrate de cumplir con lo siguiente:

* **Dispositivo:** Smartphone o Tablet con Android 8.0 (Oreo) o superior.
* **Conexión a Internet:** Se requiere una conexión activa (WiFi o Datos Móviles) para sincronizar viajes y conductores.
* **Credenciales de acceso:** Debes disponer de una cuenta de administrador autorizada en el sistema.

---

## ⚙️ Configuración de Credenciales

Para que la aplicación pueda conectarse con los servidores de base de datos y la API de gestión, es **obligatorio** configurar el archivo de entorno antes de compilar la aplicación:

1. Localiza el archivo `.env` en la raíz del proyecto (si no existe, créalo basándote en `.env.example`).
2. Rellena los siguientes valores con tus claves privadas:

```env
# Configuración de la API de Gestión
API_BASE_URL=[https://tu-api-taxis.com](https://tu-api-taxis.com)
API_KEY=tu_clave_secreta_aquí

# Configuración de Autenticación (Supabase)
SUPABASE_URL=[https://tu-proyecto.supabase.co](https://tu-proyecto.supabase.co)
SUPABASE_ANON_KEY=tu_anon_key_aquí
```

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

## Funcionalidades implementadas

| Pantalla | Qué hace |
|---|---|
| Login | Llama a Supabase Auth igual que el desktop. Guarda el token de forma segura. |
| Splash | Al arrancar la app restaura la sesión automáticamente si el token es válido. |
| Menú | Navegación a Conductores y Calendario. Botón logout. |
| Conductores | Lista todos, añade con validación de matrícula (1234ABC), edita nombre, elimina con confirmación. |
| Calendario | Muestra puntos en los días con viajes, lista viajes del día seleccionado, crea y elimina viajes. |