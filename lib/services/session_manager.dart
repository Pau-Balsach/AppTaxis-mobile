import '../models/admin.dart';

class SessionManager {
  static Admin? _admin;

  static Admin? get admin => _admin;
  static bool get haySesion => _admin != null;
  static String? get token => _admin?.accessToken;

  static void iniciarSesion(Admin admin) {
    _admin = admin;
  }

  static void cerrarSesion() {
    _admin = null;
  }
}
