# AppTaxis — Gestión de Taxis en la Palma de tu Mano 🚖

AppTaxis es una solución móvil moderna diseñada para la gestión eficiente de conductores y viajes en tiempo real. Esta aplicación permite a los administradores organizar la logística diaria de forma sencilla e intuitiva desde cualquier lugar.

---

## 📋 Requisitos para el Usuario Final

Para utilizar la aplicación correctamente, asegúrate de cumplir con lo siguiente:

* **📱 Dispositivo:** Smartphone o Tablet con Android 8.0 (Oreo) o superior.
* **🌐 Conexión a Internet:** Se requiere una conexión activa (WiFi o Datos Móviles) para sincronizar viajes y conductores.
* **🔑 Credenciales de acceso:** Debes disponer de una cuenta de administrador autorizada previamente en el sistema.

---

## ⚙️ Configuración de Credenciales

Para que la aplicación pueda conectarse con los servidores de base de datos y la API de gestión, es **obligatorio** configurar las claves antes de realizar la compilación:

1.  Asegúrate de tener las credenciales configuradas en los archivos `api_client.dart` y `auth_service.dart`.
2.  Si usas un archivo `.env`, rellena los siguientes valores:

API_BASE_URL=https://tu-api-taxis.com
API_KEY=tu_clave_secreta_aquí
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu_anon_key_aquí

---

## 🚀 Funcionalidades Implementadas

| Módulo | Descripción |
| :--- | :--- |
| **🔐 Control de Acceso** | Sistema de login seguro con restauración de sesión automática (Splash Screen). |
| **👥 Gestión de Conductores** | Registro (CRUD) completo de conductores con validación de matrículas (formato 1234ABC). |
| **📅 Calendario de Viajes** | Visualización interactiva de servicios por día con indicadores de ocupación. |
| **⚡ Asignación en Vivo** | Creación y eliminación de viajes asignados a conductores específicos en tiempo real. |
| **🛡️ Seguridad de Datos** | Almacenamiento cifrado de tokens de sesión mediante `flutter_secure_storage`. |

---

## 📦 Dependencias Principales

La aplicación utiliza las siguientes tecnologías clave:

* **`http`**: Comunicación robusta con el servidor central (API REST).
* **`flutter_secure_storage`**: Cifrado de datos sensibles en el almacenamiento local.
* **`table_calendar`**: Interfaz de calendario interactiva.
* **`intl`**: Soporte para formatos de fecha/hora internacionales.

---

## 🏗️ Estructura del Proyecto

El código fuente está organizado siguiendo las mejores prácticas de Flutter para garantizar la escalabilidad:

```text
lib/
├── models/      # Definición de objetos de datos (Admin, Conductor, Viaje)
├── screens/     # Pantallas de la interfaz de usuario (Login, Menú, Calendario...)
├── services/    # Lógica de conexión con APIs, Supabase y autenticación
└── main.dart    # Punto de entrada y configuración global de la aplicación
