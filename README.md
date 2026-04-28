# AppTaxis — Gestión de Taxis en la Palma de tu Mano 🚖

AppTaxis es una solución móvil moderna diseñada para la gestión eficiente de conductores y viajes en tiempo real. Esta aplicación permite a los administradores organizar la logística diaria de forma sencilla e intuitiva desde cualquier lugar.

---

## 📋 Requisitos para el Usuario Final

Para utilizar la aplicación correctamente, asegúrate de cumplir con lo siguiente:

* **📱 Dispositivo:** Smartphone o Tablet con Android 8.0 (Oreo) o superior.
* **🌐 Conexión a Internet:** Se requiere una conexión activa (WiFi o Datos Móviles) para sincronizar viajes y conductores.
* **🔑 Acceso:** La aplicación utiliza una API Key integrada en el compilado, sin necesidad de credenciales por parte del usuario.

---

## 🚀 Descarga e Instalación (Prueba)

¿Quieres probar la aplicación rápidamente? Hemos preparado una versión de prueba con datos ficticios para que puedas explorar la interfaz y las funcionalidades sin necesidad de configurar servidores:

👉 **[Descargar AppTaxis v1.0.7 (.apk)](https://github.com/Pau-Balsach/AppTaxis-mobile/releases/latest/download/app-arm64-v8a-release.apk)**

*Nota: Al ser un APK fuera de la Play Store, es posible que debas habilitar la instalación desde fuentes desconocidas en tu dispositivo Android.*

---

## ⚙️ Configuración de Credenciales

La autenticación se realiza exclusivamente mediante una **API Key** incluida en el propio compilado de la aplicación. No existe pantalla de login — la app arranca directamente en el menú principal.

Para compilar la aplicación con tus propias credenciales, crea un archivo `.env` en la raíz del proyecto con los siguientes valores:

```
API_BASE_URL=https://tu-api-taxis.com
API_KEY=tu_clave_secreta_aquí
```

La API Key debe estar registrada previamente en la base de datos del servidor (tabla `api_keys`, campo `key_hash` con el SHA-256 de la clave y `activa = true`).

---

## 🚀 Funcionalidades Implementadas

| Módulo | Descripción |
| :--- | :--- |
| **🔑 Autenticación por API Key** | Acceso directo sin pantalla de login. La clave se incluye en el compilado y se envía en cada petición como header `X-API-Key`. |
| **👥 Gestión de Conductores** | Registro (CRUD) completo de conductores con validación de matrículas (formato 1234ABC). |
| **📅 Calendario de Viajes** | Visualización interactiva de servicios por día con indicadores de ocupación por conductor (código de colores). |
| **⚡ Asignación en Vivo** | Creación, edición y eliminación de viajes asignados a conductores específicos en tiempo real. |
| **👤 Gestión de Clientes** | Asignación y modificación de clientes en viajes, con búsqueda por nombre o teléfono y autocompletado de datos. |
| **🌙 Viajes de Madrugada** | Soporte completo para viajes que cruzan la medianoche, con detección automática y confirmación del día de finalización. |

---

## 📦 Dependencias Principales

La aplicación utiliza las siguientes tecnologías clave:

* **`http`**: Comunicación robusta con el servidor central (API REST).
* **`flutter_dotenv`**: Carga de variables de entorno desde el archivo `.env`.
* **`table_calendar`**: Interfaz de calendario interactiva.
* **`intl`**: Soporte para formatos de fecha/hora internacionales.

---

## 🏗️ Estructura del Proyecto

El código fuente está organizado siguiendo las mejores prácticas de Flutter para garantizar la escalabilidad:

```text
lib/
├── models/      # Definición de objetos de datos (Conductor, Viaje, Cliente)
├── screens/     # Pantallas de la interfaz de usuario (Menú, Calendario, Conductores, Clientes)
├── services/    # Lógica de conexión con la API REST
└── main.dart    # Punto de entrada y configuración global de la aplicación
```