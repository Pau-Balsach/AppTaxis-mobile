import 'package:flutter/material.dart';
import '../main.dart';
import '../models/admin.dart';
import '../models/conductor.dart';
import '../services/api_client.dart';

class ConductoresScreen extends StatefulWidget {
  final Admin admin;
  const ConductoresScreen({super.key, required this.admin});

  @override
  State<ConductoresScreen> createState() => _ConductoresScreenState();
}

class _ConductoresScreenState extends State<ConductoresScreen> {
  static final _regexMatricula = RegExp(r'^\d{4}[A-Z]{3}$');

  // Controladores en el State para evitar errores de ciclo de vida
  final TextEditingController _matriculaCtrl = TextEditingController();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _editNombreCtrl = TextEditingController();

  List<Conductor> _conductores = [];
  bool _cargando = true;
  String _error  = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _matriculaCtrl.dispose();
    _nombreCtrl.dispose();
    _editNombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() { _cargando = true; _error = ''; });
    try {
      final lista = await ApiClient.getConductores();
      if (mounted) setState(() { _conductores = lista; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Error al cargar conductores.'; });
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _mostrarDialogoAnadir() async {
    _matriculaCtrl.clear();
    _nombreCtrl.clear();

    final resultado = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Añadir conductor'),
        content: SingleChildScrollView( // Corregido: Evita el overflow de 99752 píxeles
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _matriculaCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Matrícula (1234ABC)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre Completo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final mat = _matriculaCtrl.text.trim().toUpperCase();
              final nom = _nombreCtrl.text.trim();
              if (_regexMatricula.hasMatch(mat) && nom.isNotEmpty) {
                Navigator.pop(ctx, {'nombre': nom, 'matricula': mat});
              } else {
                Navigator.pop(ctx, {'error': 'formato'});
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (resultado == null || !mounted) return;

    if (resultado.containsKey('error')) {
      rootScaffoldKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Formato de matrícula incorrecto o nombre vacío.')),
      );
      return;
    }

    try {
      await ApiClient.crearConductor(resultado['nombre']!, resultado['matricula']!);
      await _cargar(); // Recargamos la lista
      rootScaffoldKey.currentState?.showSnackBar(
        SnackBar(content: Text('Conductor ${resultado['nombre']} guardado.')),
      );
    } catch (e) {
      rootScaffoldKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _editar(Conductor c) async {
    _editNombreCtrl.text = c.nombre;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar: ${c.matricula}'),
        content: TextField(controller: _editNombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final nuevo = _editNombreCtrl.text.trim();
              if (nuevo.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ApiClient.editarConductor(c.id, nuevo);
                await _cargar();
              } catch (e) {
                rootScaffoldKey.currentState?.showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminar(Conductor c) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar'),
        content: Text('¿Deseas eliminar a ${c.nombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    try {
      await ApiClient.eliminarConductor(c.id);
      await _cargar();
    } catch (e) {
      rootScaffoldKey.currentState?.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conductores'),
        backgroundColor: Colors.amber,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoAnadir,
        backgroundColor: Colors.amber,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Conductor'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _conductores.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final c = _conductores[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(c.nombre.isNotEmpty ? c.nombre[0].toUpperCase() : '?')),
              title: Text(c.nombre),
              subtitle: Text(c.matricula),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editar(c)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _eliminar(c)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}