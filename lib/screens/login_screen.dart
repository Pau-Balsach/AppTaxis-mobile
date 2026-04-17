import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'menu_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService  = AuthService();

  bool   _cargando = false;
  String _mensaje  = '';
  bool   _esError  = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _setMensaje('Introduce correo y contraseña.', error: true);
      return;
    }

    setState(() { _cargando = true; _mensaje = ''; });

    final admin = await _authService.login(email, password);

    if (!mounted) return;
    setState(() => _cargando = false);

    if (admin != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MenuScreen(admin: admin)),
      );
    } else {
      _setMensaje('Correo o contraseña incorrectos.', error: true);
      _passwordCtrl.clear();
    }
  }

  void _setMensaje(String msg, {required bool error}) {
    setState(() { _mensaje = msg; _esError = error; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo / título
                const Icon(Icons.local_taxi, size: 72, color: Colors.amber),
                const SizedBox(height: 16),
                Text(
                  'AppTaxis',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Panel de administración',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),

                // Email
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),

                // Mensaje de error/info
                if (_mensaje.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      _mensaje,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _esError ? Colors.red : Colors.green,
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Botón login
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                    child: _cargando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Entrar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
