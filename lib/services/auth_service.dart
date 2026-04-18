import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/admin.dart';
import 'session_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  static String get _supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');
  static String get _supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY', fallback: '');

  Future<Admin?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_supabaseUrl/auth/v1/token?grant_type=password'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _supabaseAnonKey,
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200 || data.containsKey('error')) {
        return null;
      }

      final accessToken = data['access_token'] as String;
      final userId = (data['user'] as Map)['id'] as String;

      final admin = Admin(id: userId, email: email, accessToken: accessToken);
      SessionManager.iniciarSesion(admin);

      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'user_email', value: email);
      await _storage.write(key: 'user_id', value: userId);

      return admin;
    } catch (e) {
      return null;
    }
  }

  Future<Admin?> restaurarSesion() async {
    try {
      final token = await _storage.read(key: 'access_token');
      final email = await _storage.read(key: 'user_email');
      final id = await _storage.read(key: 'user_id');

      if (token == null || email == null || id == null) return null;

      final response = await http.get(
        Uri.parse('$_supabaseUrl/auth/v1/user'),
        headers: {
          'apikey': _supabaseAnonKey,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        await cerrarSesion();
        return null;
      }

      final admin = Admin(id: id, email: email, accessToken: token);
      SessionManager.iniciarSesion(admin);
      return admin;
    } catch (e) {
      return null;
    }
  }

  Future<void> cerrarSesion() async {
    SessionManager.cerrarSesion();
    await _storage.deleteAll();
  }
}