import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cliente.dart';
import '../models/viaje.dart';
import '../services/api_client.dart';
import '../main.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  List<Cliente> _clientes = [];
  bool _cargando = true;
  final _busquedaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar({String? q}) async {
    setState(() => _cargando = true);
    try {
      final lista = await ApiClient.getClientes(q: q);
      setState(() => _clientes = lista);
    } catch (_) {
      rootScaffoldKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Error al cargar clientes.')),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _anadir() async {
    final nombreCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final notasCtrl = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Teléfono *',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email (opcional)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notasCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar')),
        ],
      ),
    );

    if (resultado != true || !mounted) return;

    if (nombreCtrl.text.trim().isEmpty ||
        telefonoCtrl.text.trim().isEmpty) {
      rootScaffoldKey.currentState?.showSnackBar(
        const SnackBar(
            content:
            Text('Nombre y teléfono son obligatorios.')),
      );
      nombreCtrl.dispose();
      telefonoCtrl.dispose();
      emailCtrl.dispose();
      notasCtrl.dispose();
      return;
    }

    try {
      await ApiClient.crearCliente(
        nombreCtrl.text.trim(),
        telefonoCtrl.text.trim(),
        email: emailCtrl.text.trim().isEmpty
            ? null
            : emailCtrl.text.trim(),
        notas: notasCtrl.text.trim().isEmpty
            ? null
            : notasCtrl.text.trim(),
      );
      await _cargar();
      rootScaffoldKey.currentState?.showSnackBar(
        SnackBar(
            content:
            Text('Cliente ${nombreCtrl.text.trim()} creado.')),
      );
    } catch (_) {
      rootScaffoldKey.currentState?.showSnackBar(
        const SnackBar(
            content: Text('Error al crear el cliente.')),
      );
    } finally {
      nombreCtrl.dispose();
      telefonoCtrl.dispose();
      emailCtrl.dispose();
      notasCtrl.dispose();
    }
  }

  Future<void> _editar(Cliente c) async {
    final nombreCtrl = TextEditingController(text: c.nombre);
    final telefonoCtrl = TextEditingController(text: c.telefono);
    final emailCtrl = TextEditingController(text: c.email ?? '');
    final notasCtrl = TextEditingController(text: c.notas ?? '');

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar — ${c.nombre}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: notasCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Notas',
                      border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar')),
        ],
      ),
    );

    if (resultado != true || !mounted) return;

    try {
      await ApiClient.editarCliente(
        c.id,
        nombre: nombreCtrl.text.trim().isEmpty
            ? null
            : nombreCtrl.text.trim(),
        telefono: telefonoCtrl.text.trim().isEmpty
            ? null
            : telefonoCtrl.text.trim(),
        email: emailCtrl.text.trim().isEmpty
            ? null
            : emailCtrl.text.trim(),
        notas: notasCtrl.text.trim().isEmpty
            ? null
            : notasCtrl.text.trim(),
      );
      await _cargar();
      rootScaffoldKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Cliente actualizado.')),
      );
    } catch (_) {
      rootScaffoldKey.currentState?.showSnackBar(
        const SnackBar(
            content: Text('Error al editar el cliente.')),
      );
    } finally {
      nombreCtrl.dispose();
      telefonoCtrl.dispose();
      emailCtrl.dispose();
      notasCtrl.dispose();
    }
  }

  Future<void> _eliminar(Cliente c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text(
            '¿Eliminar a ${c.nombre}? Sus viajes quedarán sin cliente asignado.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      await ApiClient.eliminarCliente(c.id);
      await _cargar();
      rootScaffoldKey.currentState?.showSnackBar(
        SnackBar(content: Text('${c.nombre} eliminado.')),
      );
    } catch (_) {
      rootScaffoldKey.currentState?.showSnackBar(
        const SnackBar(
            content: Text('Error al eliminar el cliente.')),
      );
    }
  }

  Future<void> _verHistorial(Cliente c) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => _HistorialScreen(cliente: c)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _cargar()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _anadir,
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add),
        label: const Text('Añadir'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _busquedaCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o teléfono...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busquedaCtrl.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _busquedaCtrl.clear();
                    _cargar();
                  },
                )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onChanged: (v) =>
                  _cargar(q: v.isEmpty ? null : v),
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _clientes.isEmpty
                ? const Center(
                child: Text('No hay clientes.',
                    style:
                    TextStyle(color: Colors.grey)))
                : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    12, 0, 12, 80),
                itemCount: _clientes.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final c = _clientes[i];
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12)),
                    child: ListTile(
                      onTap: () => _verHistorial(c),
                      leading: CircleAvatar(
                        backgroundColor:
                        Colors.green.shade100,
                        child: Text(
                          c.nombre.isNotEmpty
                              ? c.nombre[0]
                              .toUpperCase()
                              : '?',
                          style: TextStyle(
                              color:
                              Colors.green.shade700,
                              fontWeight:
                              FontWeight.bold),
                        ),
                      ),
                      title: Text(c.nombre,
                          style: const TextStyle(
                              fontWeight:
                              FontWeight.w600)),
                      subtitle: Text(
                        c.telefono +
                            (c.email != null
                                ? '\n${c.email}'
                                : ''),
                      ),
                      isThreeLine: c.email != null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                                Icons.history,
                                color: Colors.blue),
                            tooltip: 'Historial',
                            onPressed: () =>
                                _verHistorial(c),
                          ),
                          IconButton(
                            icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.orange),
                            onPressed: () =>
                                _editar(c),
                          ),
                          IconButton(
                            icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () =>
                                _eliminar(c),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── HISTORIAL DE VIAJES ───────────────────────────────────────────────────────

class _HistorialScreen extends StatefulWidget {
  final Cliente cliente;
  const _HistorialScreen({required this.cliente});

  @override
  State<_HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<_HistorialScreen> {
  List<Viaje> _viajes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final lista =
      await ApiClient.getViajesCliente(widget.cliente.id);
      setState(() => _viajes = lista);
    } catch (_) {
      setState(() => _viajes = []);
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cliente.nombre),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.phone,
                      size: 16, color: Colors.green.shade700),
                  const SizedBox(width: 6),
                  Text(widget.cliente.telefono,
                      style: const TextStyle(fontSize: 14)),
                ]),
                if (widget.cliente.email != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.email_outlined,
                        size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 6),
                    Text(widget.cliente.email!,
                        style: const TextStyle(fontSize: 14)),
                  ]),
                ],
                if (widget.cliente.notas != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.notes,
                        size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(widget.cliente.notas!,
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ]),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.history,
                    size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Historial de viajes',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${_viajes.length} viajes',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _viajes.isEmpty
                ? const Center(
                child: Text('Sin viajes registrados.',
                    style:
                    TextStyle(color: Colors.grey)))
                : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _viajes.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final v = _viajes[i];
                final fecha =
                DateFormat('dd/MM/yyyy').format(
                    DateTime.parse(v.dia));
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Container(
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius:
                        BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(v.hora,
                              style: TextStyle(
                                  fontWeight:
                                  FontWeight.bold,
                                  color: Colors
                                      .amber.shade800,
                                  fontSize: 13)),
                          Text(fecha,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors
                                      .amber.shade700)),
                        ],
                      ),
                    ),
                    title: Text(
                      '${v.puntorecogida} → ${v.puntodejada}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    subtitle: v.conductor != null
                        ? Text(
                        '${v.conductor!.nombre} · ${v.conductor!.matricula}',
                        style: const TextStyle(
                            fontSize: 12))
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}