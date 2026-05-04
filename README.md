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

👉 **[Descargar AppTaxis v1.0.9 (.apk)](https://github.com/Pau-Balsach/AppTaxis-mobile/releases/latest/download/app-arm64-v8a-release.apk)**

*Nota: Al ser un APK fuera de la Play Store, es posible que debas habilitar la instalación desde fuentes desconocidas en tu dispositivo Android.*

---

## ⚙️ Configuración de Credenciales

La autenticación se realiza exclusivamente mediante una **API Key** incluida en el propio compilado de la aplicación. No existe pantalla de login — la app arranca directamente en el menú principal.

Para compilar la aplicación con tus propias credenciales, crea un archivo `.env` en la raíz del proyecto con los siguientes valores:

```
API_BASE_URL=https://tu-api-taxis.com
API_KEY=tu_clave_secreta_aquí
DEFAULT_LAT=41.3851
DEFAULT_LNG=2.1734
DEFAULT_RADIUS_KM=50
```

* `API_KEY` debe estar registrada previamente en la base de datos del servidor (tabla `api_keys`, campo `key_hash` con el SHA-256 de la clave y `activa = true`).
* `DEFAULT_LAT` / `DEFAULT_LNG` definen las coordenadas de sesgo para el autocompletado de direcciones cuando el GPS no está disponible.
* `DEFAULT_RADIUS_KM` define el radio de búsqueda preferente alrededor de las coordenadas anteriores.

---

## 🚀 Funcionalidades Implementadas

| Módulo | Descripción |
| :--- | :--- |
| **🔑 Autenticación por API Key** | Acceso directo sin pantalla de login. La clave se incluye en el compilado y se envía en cada petición como header `X-API-Key`. |
| **👥 Gestión de Conductores** | Registro (CRUD) completo de conductores con validación de matrículas (formato 1234ABC). |
| **📅 Calendario de Viajes** | Visualización interactiva de servicios por día con indicadores de ocupación por conductor (código de colores). |
| **⚡ Asignación en Vivo** | Creación, edición y eliminación de viajes asignados a conductores específicos en tiempo real. |
| **👤 Gestión de Clientes** | Asignación de clientes en viajes (tanto al crear como al editar), con búsqueda por nombre o teléfono y autocompletado de datos de contacto. |
| **📍 Autocompletado de Direcciones** | Búsqueda de puntos de recogida y dejada vía Nominatim (OpenStreetMap), con sesgo geográfico por GPS o coordenadas fijas. Funciona correctamente con el teclado abierto en Android. |
| **🌙 Viajes de Madrugada** | Soporte completo para viajes que cruzan la medianoche, con detección automática y confirmación del día de finalización. |

---

## 🐛 Correcciones Recientes

### v1.1.0

**Autocompletado de direcciones (`PlacesAutocompleteField`)**

- **Sugerencias no seleccionables con teclado abierto** — Causa raíz: el `OverlayEntry` dentro de un `AlertDialog` crea un árbol de renderizado separado. Con `adjustPan` activo en Android, el sistema desplaza la ventana nativa pero no recalcula las zonas táctiles registradas, provocando un desfase entre la posición visual de las sugerencias y donde Android registra los toques. Solución: las sugerencias se renderizan ahora **inline** (dentro del mismo árbol del widget, como un `Column` hijo), eliminando el problema de hit-testing por completo.

- **Crash `RenderShrinkWrappingViewport does not support returning intrinsic dimensions`** — `AlertDialog` envuelve su contenido en `IntrinsicWidth` para calcular su ancho óptimo. `ListView` con `shrinkWrap: true` usa un `RenderShrinkWrappingViewport` que prohíbe el cálculo de dimensiones intrínsecas y lanza la excepción. Solución: `ListView` reemplazado por `SingleChildScrollView` + `Column` con ítems generados directamente, eliminando cualquier viewport del árbol.

- **Lista de sugerencias recortada por el clip del diálogo** — El `AlertDialog` fija su altura máxima y recorta el contenido que la supera. Cuando las sugerencias aparecen, el `Column` del diálogo crece más allá de ese límite. Solución: `Scrollable.ensureVisible` con `alignmentPolicy: keepVisibleAtEnd` hace scroll automático en el `SingleChildScrollView` del diálogo tras cada búsqueda, garantizando que la lista quede siempre completamente visible.

**Formulario de creación de viajes (`_DialogoCrearViaje`)**

- **`_SelectorCliente` ausente en el diálogo de creación** — El widget estaba implementado y presente en el diálogo de edición, pero había sido omitido en el árbol del diálogo de creación. Añadido en la posición correcta (tras el selector de conductor), con la misma lógica de autocompletado de teléfono que en edición.

---

## 🧪 Tests

Los tests unitarios se ubican en `test/widget_test.dart` y cubren la capa de modelos y excepciones sin dependencias externas ni UI.

| Grupo | Qué se verifica |
| :--- | :--- |
| **Cliente** | `fromJson` (todos los campos, opcionales nulos, alias `adminId`/`admin_id`, prioridad camelCase) · `toJson` (omisión de nulos, presencia de obligatorios, round-trip) |
| **Conductor** | `fromJson` (alias `cond_admin`/`condAdmin`, campo nulo) · `toJson` (inclusión/omisión de `cond_admin`) · Igualdad y `hashCode` basados en `id` (uso en `Map` y `Set`) |
| **Viaje** | `fromJson` (parseo completo, recorte de hora a `HH:mm`, conductor y cliente anidados, campos nulos) · `cruzaMedianoche` (diaFin distinto, igual o nulo) · Conversión `DateTime` · `toJson` y `toJsonConCliente` (inclusión/omisión de cliente, fallback de `diaFin`) |
| **AppException** | `toString`, `statusCode`, herencia correcta de `NetworkException`, `RequestTimeoutException`, `AuthException` y `ServerException` · Captura genérica como `Exception` |
| **Integración** | Parseo de relaciones anidadas Viaje ↔ Conductor ↔ Cliente · Agrupación por conductor en `Map` · Ordenación por hora · Filtrado de viajes por día (lógica de calendario) · Sobreescritura de `clienteId` en `toJsonConCliente` |

Para ejecutar los tests localmente:

```bash
flutter test test/ --coverage
```

El CI ejecuta los tests automáticamente en cada push o pull request a `main`, `master` o `develop`, con reporte de cobertura vía Codecov.

---

## 📦 Dependencias Principales

| Paquete | Uso |
| :--- | :--- |
| **`dio`** | Comunicación con el servidor central (API REST) y peticiones a Nominatim. |
| **`flutter_dotenv`** | Carga de variables de entorno desde el archivo `.env`. |
| **`geolocator`** | Obtención de la posición GPS para sesgar el autocompletado de direcciones. |
| **`table_calendar`** | Interfaz de calendario interactiva. |
| **`intl`** | Soporte para formatos de fecha/hora internacionales. |

---

## 🏗️ Estructura del Proyecto

El código fuente está organizado siguiendo las mejores prácticas de Flutter para garantizar la escalabilidad:

```text
lib/
├── models/      # Definición de objetos de datos (Conductor, Viaje, Cliente)
├── screens/     # Pantallas de la interfaz de usuario (Menú, Calendario, Conductores, Clientes)
├── services/    # Lógica de conexión con la API REST
├── utils/       # Utilidades (apertura de mapas, etc.)
├── widgets/     # Widgets reutilizables (PlacesAutocompleteField, etc.)
└── main.dart    # Punto de entrada y configuración global de la aplicación
```