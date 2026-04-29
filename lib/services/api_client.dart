import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/conductor.dart';
import '../models/viaje.dart';
import '../models/cliente.dart';
import 'app_exception.dart';

class ApiClient {
  static const Duration _requestTimeout = Duration(seconds: 15);

  static String get _baseUrl => dotenv.get('API_BASE_URL', fallback: '');
  static String get _apiKey => dotenv.get('API_KEY', fallback: '');

  static Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'X-API-Key': _apiKey,
    };
  }

  static Uri _buildUri(String path, [Map<String, String>? query]) {
    if (_baseUrl.isEmpty) {
      throw const AppException('API_BASE_URL no está configurada.');
    }
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalizedPath').replace(queryParameters: query);
  }

  static Future<http.Response> _request(Future<http.Response> Function() fn) async {
    try {
      final res = await fn().timeout(_requestTimeout);
      _checkStatus(res);
      return res;
    } on SocketException {
      throw const NetworkException('No se pudo conectar al servidor. Revisa tu conexión.');
    } on HandshakeException {
      throw const NetworkException('Error de certificado SSL/TLS en la conexión.');
    } on TimeoutException {
      throw const RequestTimeoutException('La petición tardó demasiado. Inténtalo de nuevo.');
    }
  }

  // CONDUCTORES
  static Future<List<Conductor>> getConductores() async {
    final res = await _request(() => http.get(_buildUri('/conductores'), headers: getHeaders()));
    final list = jsonDecode(res.body) as List;
    return list.map((j) => Conductor.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<void> crearConductor(String nombre, String matricula) async {
    await _request(() => http.post(
      _buildUri('/conductores'),
      headers: getHeaders(),
      body: jsonEncode({'nombre': nombre, 'matricula': matricula}),
    ));
  }

  static Future<void> editarConductor(int id, String nuevoNombre) async {
    await _request(() => http.put(
      _buildUri('/conductores/$id', {'nuevoNombre': nuevoNombre}),
      headers: getHeaders(),
    ));
  }

  static Future<void> eliminarConductor(int id) async {
    await _request(() => http.delete(_buildUri('/conductores/$id'), headers: getHeaders()));
  }

  // VIAJES
  static Future<List<Viaje>> getViajes() async {
    final res = await _request(() => http.get(_buildUri('/viajes'), headers: getHeaders()));
    final list = jsonDecode(res.body) as List;
    return list.map((j) => Viaje.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<List<Viaje>> getViajesConductor(int conductorId) async {
    final res = await _request(() => http.get(_buildUri('/viajes/conductor/$conductorId'), headers: getHeaders()));
    final list = jsonDecode(res.body) as List;
    return list.map((j) => Viaje.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<List<Viaje>> getViajesPorConductor(int conductorId) => getViajesConductor(conductorId);

  static Future<void> crearViaje(int conductorId, Viaje viaje, {int? clienteId}) async {
    await _request(() => http.post(
      _buildUri('/viajes/conductor/$conductorId'),
      headers: getHeaders(),
      body: jsonEncode(viaje.toJsonConCliente(clienteId)),
    ));
  }

  static Future<void> editarViaje(String id, Viaje viaje, {int? clienteId, int? conductorId}) async {
    final selectedConductorId = conductorId ?? viaje.conductor?.id;
    if (selectedConductorId == null) {
      throw const AppException('Debes seleccionar un conductor para el viaje.');
    }

    final conductorPayload = <String, dynamic>{
      'id': selectedConductorId,
      if (viaje.conductor != null) 'matricula': viaje.conductor!.matricula,
      if (viaje.conductor != null) 'nombre': viaje.conductor!.nombre,
      if (viaje.conductor?.condAdmin != null) 'cond_admin': viaje.conductor!.condAdmin,
    };

    final resolvedCliente = clienteId != null
        ? <String, dynamic>{
      'id': clienteId,
      if (viaje.cliente != null) 'nombre': viaje.cliente!.nombre,
      if (viaje.cliente != null) 'telefono': viaje.cliente!.telefono,
      if (viaje.cliente?.email != null) 'email': viaje.cliente!.email,
      if (viaje.cliente?.notas != null) 'notas': viaje.cliente!.notas,
      if (viaje.cliente?.adminId != null) 'adminId': viaje.cliente!.adminId,
    }
        : (viaje.cliente != null
        ? {
      'id': viaje.cliente!.id,
      'nombre': viaje.cliente!.nombre,
      'telefono': viaje.cliente!.telefono,
      if (viaje.cliente!.email != null) 'email': viaje.cliente!.email,
      if (viaje.cliente!.notas != null) 'notas': viaje.cliente!.notas,
      if (viaje.cliente!.adminId != null) 'adminId': viaje.cliente!.adminId,
    }
        : null);

    final data = <String, dynamic>{
      'id': id,
      'dia': viaje.dia,
      'diaFin': viaje.diaFin ?? viaje.dia,
      'hora': viaje.hora.isEmpty ? '00:00:00' : _ensureSeconds(viaje.hora),
      'horaFinalizacion': viaje.horaFinalizacion.isEmpty ? '00:00:00' : _ensureSeconds(viaje.horaFinalizacion),
      'puntorecogida': viaje.puntorecogida,
      'puntodejada': viaje.puntodejada,
      'telefonocliente': viaje.telefonocliente,
      'conductor': conductorPayload,
      if (resolvedCliente != null) 'cliente': resolvedCliente,
    };

    await _request(() => http.put(
      _buildUri('/viajes/$id'),
      headers: getHeaders(),
      body: jsonEncode(data),
    ));
  }

  /// Garantiza formato HH:mm:ss que Spring deserializa como LocalTime
  static String _ensureSeconds(String hhmm) {
    final parts = hhmm.trim().split(':');
    if (parts.length == 1) return '${parts[0].padLeft(2, '0')}:00:00';
    if (parts.length == 2) return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:00';
    return hhmm;
  }

  static Future<void> eliminarViaje(String id) async {
    await _request(() => http.delete(_buildUri('/viajes/$id'), headers: getHeaders()));
  }

  // CLIENTES
  static Future<List<Cliente>> getClientes({String? q}) async {
    final query = q != null && q.isNotEmpty ? {'q': q} : null;
    final res = await _request(() => http.get(_buildUri('/clientes', query), headers: getHeaders()));
    final list = jsonDecode(res.body) as List;
    return list.map((j) => Cliente.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<List<Viaje>> getViajesCliente(int clienteId) async {
    final res = await _request(() => http.get(_buildUri('/clientes/$clienteId/viajes'), headers: getHeaders()));
    final list = jsonDecode(res.body) as List;
    return list.map((j) => Viaje.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<Cliente> crearCliente(String nombre, String telefono, {String? email, String? notas}) async {
    final res = await _request(() => http.post(
      _buildUri('/clientes'),
      headers: getHeaders(),
      body: jsonEncode({
        'nombre': nombre,
        'telefono': telefono,
        if (email != null && email.isNotEmpty) 'email': email,
        if (notas != null && notas.isNotEmpty) 'notas': notas,
      }),
    ));
    return Cliente.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Cliente> editarCliente(
      int id, {
        String? nombre,
        String? telefono,
        String? email,
        String? notas,
      }) async {
    final res = await _request(() => http.put(
      _buildUri('/clientes/$id'),
      headers: getHeaders(),
      body: jsonEncode({
        if (nombre != null) 'nombre': nombre,
        if (telefono != null) 'telefono': telefono,
        if (email != null) 'email': email,
        if (notas != null) 'notas': notas,
      }),
    ));
    return Cliente.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> eliminarCliente(int id) async {
    await _request(() => http.delete(_buildUri('/clientes/$id'), headers: getHeaders()));
  }

  static void _checkStatus(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;

    final body = res.body;

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw AuthException('No autorizado. Verifica tus credenciales.', statusCode: res.statusCode);
    }
    if (res.statusCode >= 500) {
      final msg = _extractMessage(body, res.statusCode);
      throw ServerException(
        msg.isNotEmpty ? msg : 'Error del servidor (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }
    throw AppException(_extractMessage(body, res.statusCode), statusCode: res.statusCode);
  }

  static String _extractMessage(String body, int statusCode) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) {
        final msg = parsed['message'] ?? parsed['error'] ?? parsed['detail'];
        if (msg is String && msg.trim().isNotEmpty) {
          return msg;
        }
      }
    } catch (_) {}
    return '';
  }
}