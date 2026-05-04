# AppTaxis — Gestión de Taxis en la Palma de tu Mano 🚖

AppTaxis es una solución móvil moderna diseñada para la gestión eficiente de conductores, clientes y viajes en tiempo real. Esta aplicación permite a los administradores organizar la logística diaria de forma sencilla e intuitiva desde cualquier lugar.

---

## 📋 Requisitos para el Usuario Final

Para utilizar la aplicación correctamente, asegúrate de cumplir con lo siguiente:

* **📱 Dispositivo:** Smartphone o Tablet con Android 8.0 (Oreo) o superior.
* **🌐 Conexión a Internet:** Se requiere una conexión activa (WiFi o Datos Móviles) para sincronizar viajes, conductores y clientes.
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
| **👥 Gestión de Conductores** | CRUD completo de conductores con validación de matrículas (formato `1234ABC`). |
| **👤 Gestión de Clientes** | CRUD completo de clientes con campos de nombre, teléfono, email y notas. Búsqueda en tiempo real con debounce de 350 ms. Al seleccionar un cliente en un viaje, su teléfono se autocompleta automáticamente. |
| **📅 Calendario de Viajes** | Visualización interactiva de servicios por día con indicadores de ocupación por conductor en código de colores. Filtro por conductor individual. |
| **⚡ Asignación en Vivo** | Creación, edición y eliminación de viajes asignados a conductores específicos en tiempo real. |
| **📍 Autocompletado de Direcciones** | Búsqueda de puntos de recogida y dejada vía Nominatim (OpenStreetMap), con sesgo geográfico por GPS o coordenadas fijas. Renderizado inline para compatibilidad con el teclado de Android. |
| **🗺️ Apertura en Mapas** | Cada punto de recogida y dejada incluye un botón para abrir la dirección directamente en Google Maps, usando coordenadas exactas si están disponibles o búsqueda por nombre en caso contrario. |
| **🌙 Viajes de Madrugada** | Soporte completo para viajes que cruzan la medianoche, con detección automática y confirmación del día de finalización. |

---

## 📍 Autocompletado de Direcciones Reales

El widget `PlacesAutocompleteField` permite buscar direcciones reales de España utilizando la API pública de **Nominatim (OpenStreetMap)**, sin coste ni API key.

**Cómo funciona:**

1. El usuario empieza a escribir una dirección (mínimo 3 caracteres).
2. Con un debounce de 400 ms, se lanza una búsqueda contra `nominatim.openstreetmap.org` con `countrycodes=es`.
3. Si el GPS está disponible y el usuario ha dado permiso, la búsqueda se sesga geográficamente usando un `viewbox` centrado en la posición actual. Si no hay GPS, se usan las coordenadas fijas de `.env` (`DEFAULT_LAT`, `DEFAULT_LNG`, `DEFAULT_RADIUS_KM`).
4. Se muestran hasta 5 sugerencias inline (sin `OverlayEntry`) con nombre principal y localidad.
5. Al seleccionar una sugerencia, el campo se rellena con la dirección completa y se notifica al widget padre con el objeto `PlaceResult` (dirección, latitud, longitud).
6. Las coordenadas resultantes se guardan en el viaje (`latRecogida`, `lngRecogida`, `latDejada`, `lngDejada`) y se usan posteriormente para abrir Google Maps con precisión de pin.

**Decisiones técnicas del widget:**

* **Renderizado inline en lugar de `OverlayEntry`** — Con `adjustPan` activo en Android, el sistema desplaza la ventana nativa pero no recalcula las zonas táctiles del overlay, provocando un desfase entre la posición visual de las sugerencias y donde Android registra los toques. Al renderizar las sugerencias como un `Column` hijo dentro del mismo árbol del widget, el hit-testing es siempre correcto.
* **`SingleChildScrollView` + `Column` en lugar de `ListView`** — `AlertDialog` envuelve su contenido en `IntrinsicWidth` para calcular su ancho. `ListView` con `shrinkWrap: true` usa un `RenderShrinkWrappingViewport` que prohíbe el cálculo de dimensiones intrínsecas y lanza una excepción en tiempo de ejecución. La combinación `SingleChildScrollView` + `Column` elimina completamente cualquier viewport del árbol.
* **`Scrollable.ensureVisible` con `keepVisibleAtEnd`** — Tras cada búsqueda, se llama a `ensureVisible` en el `postFrameCallback` para que el `SingleChildScrollView` del `AlertDialog` haga scroll automático y la lista de sugerencias quede siempre completamente visible, sin ser recortada por el clip del diálogo.

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
| **`dio`** | Peticiones HTTP a Nominatim para el autocompletado de direcciones. |
| **`http`** | Comunicación con el servidor central (API REST). |
| **`flutter_dotenv`** | Carga de variables de entorno desde el archivo `.env`. |
| **`geolocator`** | Obtención de la posición GPS para sesgar el autocompletado de direcciones. |
| **`url_launcher`** | Apertura de direcciones en Google Maps desde los detalles del viaje. |
| **`table_calendar`** | Interfaz de calendario interactiva con marcadores por conductor. |
| **`intl`** | Soporte para formatos de fecha/hora internacionales. |

---

## 🏗️ Estructura del Proyecto

```text
lib/
├── models/
│   ├── cliente.dart       # Modelo Cliente con fromJson / toJson
│   ├── conductor.dart     # Modelo Conductor con igualdad por id
│   └── viaje.dart         # Modelo Viaje con soporte de madrugada y coordenadas
├── screens/
│   ├── calendario_screen.dart   # Calendario interactivo de viajes por conductor
│   ├── clientes_screen.dart     # CRUD de clientes e historial de viajes
│   ├── conductores_screen.dart  # CRUD de conductores con validación de matrícula
│   └── menu_screen.dart         # Pantalla principal de navegación
├── services/
│   ├── api_client.dart    # Comunicación con la API REST (conductores, viajes, clientes)
│   └── app_exception.dart # Jerarquía de excepciones tipadas
├── utils/
│   └── maps_launcher.dart # Apertura de direcciones en Google Maps
├── widgets/
│   └── places_autocomplete_field.dart  # Campo con autocompletado Nominatim inline
└── main.dart              # Punto de entrada y configuración global del tema
```