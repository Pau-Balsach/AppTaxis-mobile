import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/conductor.dart';
import '../models/viaje.dart';
import '../models/cliente.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  static String get _baseUrl => dotenv.get('API_BASE_URL', fallback: '');
  static String get _apiKey  => dotenv.get('API_KEY', fallback: '');

  static Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'X-API-Key': _apiKey,
    };
  }

  // CONDUCTORES
  static Future<List<Conductor>> getConductores() async {
    final res = await http.get(
        Uri.parse('$_baseUrl/conductores'),
        headers: getHeaders()
    );
    _checkStatus(res);
    final list = jsonDecode(res.body) as List;
    return list.map((j) => Conductor.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<void> crearConductor(String nombre, String matricula) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/conductores'),
      headers: getHeaders(),
      body: jsonEncode({'nombre': nombre, 'matricula': matricula}),
    );
    _checkStatus(res);
  }

  static Future<void> editarConductor(int id, String nuevoNombre) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/conductores/$id?nuevoNombre=${Uri.encodeComponent(nuevoNombre)}'),
      headers: getHeaders(),
    );
    _checkStatus(res);
  }

  static Future<void> eliminarConductor(int id) async {
    final res = await http.delete(
        Uri.parse('$_baseUrl/conductores/$id'), headers: getHeaders());
    _checkStatus(res);
  }

  // VIAJES
  static Future<List<Viaje>> getViajes() async {
    final res = await http.get(Uri.parse('$_baseUrl/viajes'), headers: getHeaders());
    _checkStatus(res);
    final list = jsonDecode(res.body) as List;
    return list.map((j) => Viaje.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<List<Viaje>> getViajesConductor(int conductorId) async {
    final res = await http.get(
        Uri.parse('$_baseUrl/viajes/conductor/$conductorId'), headers: getHeaders());
    _checkStatus(res);
    final list = jsonDecode(res.body) as List;
    return list.map((j) => Viaje.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<List<Viaje>> getViajesPorConductor(int conductorId) =>
      getViajesConductor(conductorId);

  static Future<void> crearViaje(int conductorId, Viaje viaje, {int? clienteId}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/viajes/conductor/$conductorId'),
      headers: getHeaders(),
      body: jsonEncode(viaje.toJsonConCliente(clienteId)),
    );
    _checkStatus(res);
  }

  static Future<void> editarViaje(String id, Viaje viaje, {int? clienteId, int? conductorId}) async {
    final Map<String, dynamic> data = viaje.toJson();
    if (clienteId != null) data['cliente'] = {'id': clienteId};
    else data['cliente'] = null;
    if (conductorId != null) data['conductor'] = {'id': conductorId};

    data['hora'] = _formatLocalTime(viaje.hora);
    data['horaFinalizacion'] = _formatLocalTime(viaje.horaFinalizacion);

    final res = await http.put(
      Uri.parse('$_baseUrl/viajes/$id'),
      headers: getHeaders(),
      body: jsonEncode(data),
    );
    _checkStatus(res);
  }

  static String _formatLocalTime(String hhmm) {
    if (hhmm.split(':').length == 2) return '$hhmm:00';
    return hhmm;
  }

  static Future<void> eliminarViaje(String id) async {
    final res = await http.delete(
        Uri.parse('$_baseUrl/viajes/$id'), headers: getHeaders());
    _checkStatus(res);
  }

  // CLIENTES
  static Future<List<Cliente>> getClientes({String? q}) async {
    final uri = q != null && q.isNotEmpty
        ? Uri.parse('$_baseUrl/clientes?q=${Uri.encodeComponent(q)}')
        : Uri.parse('$_baseUrl/clientes');
    final res = await http.get(uri, headers: getHeaders());
    _checkStatus(res);
    final list = jsonDecode(res.body) as List;
    return list.map((j) => Cliente.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<List<Viaje>> getViajesCliente(int clienteId) async {
    final res = await http.get(
        Uri.parse('$_baseUrl/clientes/$clienteId/viajes'), headers: getHeaders());
    _checkStatus(res);
    final list = jsonDecode(res.body) as List;
    return list.map((j) => Viaje.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<Cliente> crearCliente(String nombre, String telefono, {String? email, String? notas}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/clientes'),
      headers: getHeaders(),
      body: jsonEncode({
        'nombre': nombre,
        'telefono': telefono,
        if (email != null && email.isNotEmpty) 'email': email,
        if (notas != null && notas.isNotEmpty) 'notas': notas,
      }),
    );
    _checkStatus(res);
    return Cliente.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Cliente> editarCliente(int id, {String? nombre, String? telefono, String? email, String? notas}) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/clientes/$id'),
      headers: getHeaders(),
      body: jsonEncode({
        if (nombre != null) 'nombre': nombre,
        if (telefono != null) 'telefono': telefono,
        if (email != null) 'email': email,
        if (notas != null) 'notas': notas,
      }),
    );
    _checkStatus(res);
    return Cliente.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> eliminarCliente(int id) async {
    final res = await http.delete(
        Uri.parse('$_baseUrl/clientes/$id'), headers: getHeaders());
    _checkStatus(res);
  }

  static void _checkStatus(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }
  }
}