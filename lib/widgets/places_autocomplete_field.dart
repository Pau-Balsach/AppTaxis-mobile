import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

// ── Resultado público ──────────────────────────────────────────────────────────

class PlaceResult {
  final String direccion;
  final double lat;
  final double lng;

  const PlaceResult({
    required this.direccion,
    required this.lat,
    required this.lng,
  });
}

// ── Widget público ─────────────────────────────────────────────────────────────

/// Campo de texto con autocompletado de direcciones via Nominatim.
///
/// Las sugerencias se renderizan inline (sin OverlayEntry) para que el
/// hit-testing de Android sea correcto con el teclado abierto.
///
/// Cuando las sugerencias aparecen, el widget hace scroll automático dentro
/// del ScrollView ancestro (el SingleChildScrollView del AlertDialog) para
/// que la lista quede siempre visible y no quede recortada por el clip del
/// diálogo.
class PlacesAutocompleteField extends StatefulWidget {
  final String labelText;
  final String initialValue;
  final ValueChanged<PlaceResult> onPlaceSelected;

  const PlacesAutocompleteField({
    super.key,
    required this.labelText,
    required this.initialValue,
    required this.onPlaceSelected,
  });

  @override
  State<PlacesAutocompleteField> createState() =>
      _PlacesAutocompleteFieldState();
}

class _PlacesAutocompleteFieldState extends State<PlacesAutocompleteField> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  final _dio = Dio();

  // GlobalKey sobre el Column raíz: permite llamar a ensureVisible
  // para hacer scroll hasta este widget dentro del ScrollView del diálogo.
  final _widgetKey = GlobalKey();

  Timer? _debounce;
  List<_Suggestion> _sugerencias = [];
  bool _mostrar = false;

  // ── Sesgo de ubicación ───────────────────────────────────────────────────────

  static double get _defaultLat =>
      double.tryParse(dotenv.get('DEFAULT_LAT', fallback: '41.3851')) ?? 41.3851;
  static double get _defaultLng =>
      double.tryParse(dotenv.get('DEFAULT_LNG', fallback: '2.1734')) ?? 2.1734;
  static double get _defaultRadiusKm =>
      double.tryParse(dotenv.get('DEFAULT_RADIUS_KM', fallback: '50')) ?? 50.0;

  double? _biasLat;
  double? _biasLng;

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.initialValue;
    _inicializarSesgo();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _mostrar = false);
        });
      }
    });
  }

  Future<void> _inicializarSesgo() async {
    try {
      bool servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) { _usarSesgoFijo(); return; }

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        _usarSesgoFijo();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
      if (mounted) setState(() { _biasLat = pos.latitude; _biasLng = pos.longitude; });
    } catch (_) {
      _usarSesgoFijo();
    }
  }

  void _usarSesgoFijo() {
    if (mounted) setState(() { _biasLat = _defaultLat; _biasLng = _defaultLng; });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focusNode.dispose();
    _dio.close();
    super.dispose();
  }

  // ── Búsqueda ─────────────────────────────────────────────────────────────────

  Future<void> _buscar(String query) async {
    if (query.length < 3) {
      if (mounted) setState(() { _sugerencias = []; _mostrar = false; });
      return;
    }
    try {
      final params = <String, dynamic>{
        'q': query,
        'format': 'json',
        'addressdetails': 1,
        'limit': 5,
        'countrycodes': 'es',
      };

      if (_biasLat != null && _biasLng != null) {
        final delta = _defaultRadiusKm / 111.0;
        params['viewbox'] =
        '${_biasLng! - delta},${_biasLat! + delta},${_biasLng! + delta},${_biasLat! - delta}';
        params['bounded'] = 0;
      }

      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: params,
        options: Options(headers: {
          'User-Agent': 'AppTaxis/1.0',
          'Accept-Language': 'es',
        }),
      );

      if (!mounted) return;

      final lista = (res.data as List).map((item) => _Suggestion(
        displayName: item['display_name'] as String,
        lat: double.parse(item['lat'] as String),
        lng: double.parse(item['lon'] as String),
      )).toList();

      setState(() {
        _sugerencias = lista;
        _mostrar = lista.isNotEmpty && _focusNode.hasFocus;
      });

      // Tras el setState el nuevo frame ya tiene la lista pintada.
      // Scrollable.ensureVisible busca el Scrollable ancestro más cercano
      // (el SingleChildScrollView del AlertDialog) y hace scroll para que
      // este widget quede completamente visible. alignmentPolicy.keepVisibleAtEnd
      // solo actúa si el widget está recortado por abajo, que es exactamente
      // lo que ocurre cuando las sugerencias aparecen debajo del campo.
      if (_mostrar) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _widgetKey.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
            );
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() { _sugerencias = []; _mostrar = false; });
    }
  }

  void _seleccionar(_Suggestion s) {
    _ctrl.text = s.displayName;
    setState(() { _sugerencias = []; _mostrar = false; });
    _focusNode.unfocus();
    widget.onPlaceSelected(PlaceResult(
      direccion: s.displayName,
      lat: s.lat,
      lng: s.lng,
    ));
  }

  // ── Sugerencia individual ─────────────────────────────────────────────────────

  Widget _buildSugerencia(_Suggestion s) {
    final partes = s.displayName.split(', ');
    final titulo = partes.take(2).join(', ');
    final subtitulo = partes.skip(2).join(', ');

    return InkWell(
      onTap: () => _seleccionar(s),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: Colors.amber, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  if (subtitulo.isNotEmpty)
                    Text(
                      subtitulo,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      // GlobalKey aquí: ensureVisible lo usa para localizar este widget
      // dentro del árbol y calcular el scroll necesario.
      key: _widgetKey,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Campo de texto ──────────────────────────────────────────────────
        TextField(
          controller: _ctrl,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.labelText,
            isDense: true,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: const OutlineInputBorder(),
            prefixIcon:
            const Icon(Icons.location_on_outlined, color: Colors.amber),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, size: 18),
              tooltip: 'Borrar',
              onPressed: () {
                _ctrl.clear();
                setState(() { _sugerencias = []; _mostrar = false; });
              },
            )
                : null,
          ),
          onChanged: (val) {
            _debounce?.cancel();
            _debounce = Timer(
              const Duration(milliseconds: 400),
                  () => _buscar(val),
            );
          },
        ),

        // ── Lista de sugerencias inline ─────────────────────────────────────
        // Sin OverlayEntry → hit-testing correcto con teclado abierto.
        // Sin ListView/viewport → compatible con IntrinsicWidth del AlertDialog.
        // ensureVisible (en _buscar) → nunca queda recortada por el clip del diálogo.
        if (_mostrar && _sugerencias.isNotEmpty)
          Material(
            elevation: 4,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
            child: ConstrainedBox(
              // ~3 ítems visibles antes de activar scroll interno de la lista.
              constraints: const BoxConstraints(maxHeight: 168),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < _sugerencias.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      _buildSugerencia(_sugerencias[i]),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Modelo interno ─────────────────────────────────────────────────────────────

class _Suggestion {
  final String displayName;
  final double lat;
  final double lng;

  const _Suggestion({
    required this.displayName,
    required this.lat,
    required this.lng,
  });
}