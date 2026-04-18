import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/conductor.dart';
import '../models/viaje.dart';
import 'dart:async';

class ApiClient {
  static String get _baseUrl => dotenv.get('API_BASE_URL', fallback: '');
  static String get _apiKey  => dotenv.get('API_KEY', fallback: '');

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-API-Key': _apiKey,
  };

  // ── CONDUCTORES ──────────────────────────────────────────────────────────

  static Future<List<Conductor>> getConductores() async {
    final res = await http.get(Uri.parse('$_baseUrl/conductores'), headers: _headers);
    _checkStatus(res);
    final list = jsonDecode(res.body) as List;
    return list.map((j) => Conductor.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<void> crearConductor(String nombre, String matricula) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/conductores'),
      headers: _headers,
      body: jsonEncode({'nombre': nombre, 'matricula': matricula}),
    ).timeout(const Duration(seconds: 10));
    _checkStatus(res);
  }

  static Future<void> editarConductor(int id, String nuevoNombre) async {
    final url = Uri.parse('$_baseUrl/conductores/$id').replace(
      queryParameters: {'nuevoNombre': nuevoNombre},
    );
    final res = await http.put(url, headers: _headers);
    _checkStatus(res);
  }

  static Future<void> eliminarConductor(int id) async {
    final res = await http.delete(Uri.parse('$_baseUrl/conductores/$id'), headers: _headers);
    _checkStatus(res);
  }

  // ── VIAJES ───────────────────────────────────────────────────────────────

  static Future<List<Viaje>> getViajes() async {
    final res = await http.get(Uri.parse('$_baseUrl/viajes'), headers: _headers);
    _checkStatus(res);
    final list = jsonDecode(res.body) as List;
    return list.map((j) => Viaje.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<List<Viaje>> getViajesPorConductor(int conductorId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/viajes/conductor/$conductorId'),
      headers: _headers,
    );
    _checkStatus(res);
    final list = jsonDecode(res.body) as List;
    return list.map((j) => Viaje.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<void> crearViaje(int conductorId, Viaje viaje) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/viajes/conductor/$conductorId'),
      headers: _headers,
      body: jsonEncode(viaje.toJson()),
    ).timeout(const Duration(seconds: 10));
    _checkStatus(res);
  }

  static Future<void> editarViaje(String id, Viaje viaje) async {
    final body = <String, dynamic>{
      'id': viaje.id,
      ...viaje.toJson(),
    };

    if (viaje.conductor != null) {
      body['conductor'] = {
        'id': viaje.conductor!.id,
        'matricula': viaje.conductor!.matricula,
        'nombre': viaje.conductor!.nombre,
      };
    }

    final res = await http.put(
      Uri.parse('$_baseUrl/viajes/$id'),
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));

    _checkStatus(res);
  }

  static Future<void> eliminarViaje(String id) async {
    final res = await http.delete(Uri.parse('$_baseUrl/viajes/$id'), headers: _headers);
    _checkStatus(res);
  }

  // ── UTILIDADES ────────────────────────────────────────────────────────────

  static void _checkStatus(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }
  }
}