import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/admin.dart';
import '../models/conductor.dart';
import '../models/viaje.dart';
import '../models/cliente.dart';
import '../services/api_client.dart';

// ── Paleta de colores para conductores ────────────────────────────────────────
const List<Color> _conductorColors = [
  Color(0xFF1565C0),
  Color(0xFF2E7D32),
  Color(0xFF6A1B9A),
  Color(0xFFE65100),
  Color(0xFF00695C),
  Color(0xFFC62828),
  Color(0xFF4527A0),
  Color(0xFF558B2F),
];

Color _colorParaConductor(int conductorId, List<Conductor> conductores) {
  final idx = conductores.indexWhere((c) => c.id == conductorId);
  if (idx < 0) return Colors.grey;
  return _conductorColors[idx % _conductorColors.length];
}

// ─────────────────────────────────────────────────────────────────────────────

class CalendarioScreen extends StatefulWidget {
  final Admin admin;
  const CalendarioScreen({super.key, required this.admin});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _diaSeleccionado = DateTime.now();
  DateTime _focusMes = DateTime.now();

  List<Viaje>     _viajesDelMes = [];
  List<Conductor> _conductores  = [];
  List<Cliente>   _clientes     = [];

  Conductor? _conductorFiltro;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  // ── Carga ────────────────────────────────────────────────────────────────

  Future<void> _cargarTodo() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final List<Viaje> viajes;
      final results = await Future.wait([
        ApiClient.getConductores(),
        ApiClient.getClientes(),
      ]);
      final conds    = results[0] as List<Conductor>;
      final clientes = results[1] as List<Cliente>;

      if (_conductorFiltro != null) {
        viajes = await ApiClient.getViajesPorConductor(_conductorFiltro!.id);
      } else {
        viajes = await ApiClient.getViajes();
      }

      if (mounted) {
        setState(() {
          _conductores  = conds;
          _clientes     = clientes;
          _viajesDelMes = viajes;
          if (_conductorFiltro != null) {
            _conductorFiltro = conds.firstWhere(
                  (c) => c.id == _conductorFiltro!.id,
              orElse: () => conds.first,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<Viaje> get _viajesDia => _viajesDelMes
      .where((v) => v.dia == DateFormat('yyyy-MM-dd').format(_diaSeleccionado))
      .toList()
    ..sort((a, b) => a.hora.compareTo(b.hora));

  List<Viaje> _viajesParaDia(DateTime dia) => _viajesDelMes
      .where((v) => v.dia == DateFormat('yyyy-MM-dd').format(dia))
      .toList();

  Color _colorViaje(Viaje v) {
    if (v.conductor == null) return Colors.grey;
    return _colorParaConductor(v.conductor!.id, _conductores);
  }

  String _formatHora(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  TimeOfDay _parseHora(String hhmm) {
    final partes = hhmm.split(':');
    return TimeOfDay(
      hour: int.tryParse(partes[0]) ?? 0,
      minute: int.tryParse(partes.length > 1 ? partes[1] : '0') ?? 0,
    );
  }

  // ── CREAR VIAJE ──────────────────────────────────────────────────────────

  Future<void> _crearViaje() async {
    if (_conductores.isEmpty) {
      rootScaffoldKey.currentState?.showSnackBar(
        const SnackBar(content: Text('No hay conductores disponibles.')),
      );
      return;
    }

    Conductor? conductorSel       = _conductorFiltro ?? _conductores.first;
    Cliente?   clienteSel         = null;
    final recogidaCtrl            = TextEditingController();
    final dejadaCtrl              = TextEditingController();
    final telefonoCtrl            = TextEditingController();
    TimeOfDay horaSel             = TimeOfDay.now();
    TimeOfDay horaFinalizacionSel = TimeOfDay.now();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(
              'Nuevo viaje — ${DateFormat('dd/MM/yyyy').format(_diaSeleccionado)}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // Conductor
                DropdownButtonFormField<Conductor>(
                  value: conductorSel,
                  decoration: const InputDecoration(
                      labelText: 'Conductor',
                      border: OutlineInputBorder()),
                  items: _conductores
                      .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text('${c.nombre} — ${c.matricula}'),
                  ))
                      .toList(),
                  onChanged: (v) => setDlg(() => conductorSel = v),
                ),
                const SizedBox(height: 12),

                // Cliente con buscador
                _SelectorCliente(
                  clientes: _clientes,
                  seleccionado: clienteSel,
                  onChanged: (c) => setDlg(() {
                    clienteSel = c;
                    if (c != null) telefonoCtrl.text = c.telefono;
                  }),
                ),
                const SizedBox(height: 12),

                // Hora inicio
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: Text('Hora inicio: ${horaSel.format(ctx)}'),
                  onTap: () async {
                    final t = await showTimePicker(
                        context: ctx, initialTime: horaSel);
                    if (t != null) setDlg(() => horaSel = t);
                  },
                ),

                // Hora finalización
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag),
                  title: Text(
                      'Hora finalización: ${horaFinalizacionSel.format(ctx)}'),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: horaFinalizacionSel,
                    );
                    if (t != null) setDlg(() => horaFinalizacionSel = t);
                  },
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: recogidaCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Punto de recogida',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dejadaCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Punto de dejada',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

                // Teléfono — se autocompleta al seleccionar cliente
                TextField(
                  controller: telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Teléfono cliente',
                    border: const OutlineInputBorder(),
                    helperText: clienteSel != null
                        ? 'Autocompletado desde cliente'
                        : null,
                    suffixIcon: clienteSel != null
                        ? Icon(Icons.person, color: Colors.green.shade600, size: 18)
                        : null,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (recogidaCtrl.text.trim().isEmpty ||
                    dejadaCtrl.text.trim().isEmpty ||
                    telefonoCtrl.text.trim().isEmpty) {
                  rootScaffoldKey.currentState?.showSnackBar(
                    const SnackBar(content: Text('Rellena todos los campos.')),
                  );
                  return;
                }

                final viaje = Viaje(
                  id: '',
                  dia: DateFormat('yyyy-MM-dd').format(_diaSeleccionado),
                  hora: _formatHora(horaSel),
                  horaFinalizacion: _formatHora(horaFinalizacionSel),
                  puntorecogida: recogidaCtrl.text.trim(),
                  puntodejada: dejadaCtrl.text.trim(),
                  telefonocliente: telefonoCtrl.text.trim(),
                );

                try {
                  await ApiClient.crearViaje(
                    conductorSel!.id,
                    viaje,
                    clienteId: clienteSel?.id,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _cargarTodo();
                  rootScaffoldKey.currentState?.showSnackBar(
                    const SnackBar(content: Text('Viaje creado correctamente.')),
                  );
                } catch (e) {
                  rootScaffoldKey.currentState?.showSnackBar(
                    const SnackBar(content: Text('Error al guardar el viaje.')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    recogidaCtrl.dispose();
    dejadaCtrl.dispose();
    telefonoCtrl.dispose();
  }

  // ── EDITAR VIAJE ──────────────────────────────────────────────────────────

  Future<void> _editarViaje(Viaje v) async {
    Conductor? conductorSel = _conductores.firstWhere(
            (c) => c.id == v.conductor?.id,
        orElse: () => _conductores.first);

    // Preseleccionar cliente si el viaje ya tiene uno
    Cliente? clienteSel = v.cliente != null
        ? _clientes.firstWhere(
          (c) => c.id == v.cliente!.id,
      orElse: () => _clientes.first,
    )
        : null;

    final recogidaCtrl  = TextEditingController(text: v.puntorecogida);
    final dejadaCtrl    = TextEditingController(text: v.puntodejada);
    final telefonoCtrl  = TextEditingController(text: v.telefonocliente);
    TimeOfDay horaSel             = _parseHora(v.hora);
    TimeOfDay horaFinalizacionSel = _parseHora(v.horaFinalizacion);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Editar viaje'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // Conductor
                DropdownButtonFormField<Conductor>(
                  value: conductorSel,
                  decoration: const InputDecoration(
                      labelText: 'Conductor',
                      border: OutlineInputBorder()),
                  items: _conductores
                      .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text('${c.nombre} — ${c.matricula}'),
                  ))
                      .toList(),
                  onChanged: (val) => setDlg(() => conductorSel = val),
                ),
                const SizedBox(height: 12),

                // Cliente con buscador
                _SelectorCliente(
                  clientes: _clientes,
                  seleccionado: clienteSel,
                  onChanged: (c) => setDlg(() {
                    clienteSel = c;
                    if (c != null) telefonoCtrl.text = c.telefono;
                  }),
                ),
                const SizedBox(height: 12),

                // Hora inicio
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: Text('Hora inicio: ${horaSel.format(ctx)}'),
                  onTap: () async {
                    final t = await showTimePicker(
                        context: ctx, initialTime: horaSel);
                    if (t != null) setDlg(() => horaSel = t);
                  },
                ),

                // Hora finalización
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag),
                  title: Text(
                      'Hora finalización: ${horaFinalizacionSel.format(ctx)}'),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: horaFinalizacionSel,
                    );
                    if (t != null) setDlg(() => horaFinalizacionSel = t);
                  },
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: recogidaCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Punto de recogida',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dejadaCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Punto de dejada',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

                // Teléfono
                TextField(
                  controller: telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Teléfono cliente',
                    border: const OutlineInputBorder(),
                    helperText: clienteSel != null
                        ? 'Autocompletado desde cliente'
                        : null,
                    suffixIcon: clienteSel != null
                        ? Icon(Icons.person, color: Colors.green.shade600, size: 18)
                        : null,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (recogidaCtrl.text.trim().isEmpty ||
                    dejadaCtrl.text.trim().isEmpty ||
                    telefonoCtrl.text.trim().isEmpty) {
                  rootScaffoldKey.currentState?.showSnackBar(
                    const SnackBar(content: Text('Rellena todos los campos.')),
                  );
                  return;
                }

                final viajeEditado = Viaje(
                  id: v.id,
                  dia: v.dia,
                  hora: _formatHora(horaSel),
                  horaFinalizacion: _formatHora(horaFinalizacionSel),
                  puntorecogida: recogidaCtrl.text.trim(),
                  puntodejada: dejadaCtrl.text.trim(),
                  telefonocliente: telefonoCtrl.text.trim(),
                  conductor: conductorSel,
                  cliente: clienteSel,
                );

                try {
                  await ApiClient.editarViaje(
                    v.id,
                    viajeEditado,
                    clienteId: clienteSel?.id,
                    conductorId: conductorSel?.id,
                  );

                  if (ctx.mounted) Navigator.pop(ctx);
                  await _cargarTodo();
                  rootScaffoldKey.currentState?.showSnackBar(
                    const SnackBar(content: Text('Viaje actualizado correctamente.')),
                  );
                } catch (e) {
                  print("Error al editar: $e");
                  rootScaffoldKey.currentState?.showSnackBar(
                    const SnackBar(content: Text('Error al actualizar el viaje.')),
                  );
                }
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );

    recogidaCtrl.dispose();
    dejadaCtrl.dispose();
    telefonoCtrl.dispose();
  }

  // ── ELIMINAR VIAJE ────────────────────────────────────────────────────────

  Future<void> _eliminarViaje(Viaje v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar viaje'),
        content: Text('¿Eliminar el viaje de las ${v.hora}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await ApiClient.eliminarViaje(v.id);
      await _cargarTodo();
      rootScaffoldKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Viaje eliminado.')),
      );
    } catch (e) {
      rootScaffoldKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Error al eliminar el viaje.')),
      );
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarTodo)
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearViaje,
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo viaje'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Filtro conductor
          _FiltroCondutor(
            conductores: _conductores,
            seleccionado: _conductorFiltro,
            onChanged: (c) {
              setState(() => _conductorFiltro = c);
              _cargarTodo();
            },
          ),

          // Leyenda
          if (_conductores.isNotEmpty)
            _LeyendaColores(conductores: _conductores),

          // Calendario
          TableCalendar<Viaje>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusMes,
            selectedDayPredicate: (d) => isSameDay(d, _diaSeleccionado),
            eventLoader: _viajesParaDia,
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  shape: BoxShape.circle),
              todayDecoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return const SizedBox();
                return Positioned(
                  bottom: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: events.take(4).map((viaje) {
                      return Container(
                        margin:
                        const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 7.0,
                        height: 7.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _colorViaje(viaje),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            headerStyle: const HeaderStyle(
                formatButtonVisible: false, titleCentered: true),
            onDaySelected: (sel, foc) => setState(() {
              _diaSeleccionado = sel;
              _focusMes = foc;
            }),
            onPageChanged: (foc) {
              _focusMes = foc;
              _cargarTodo();
            },
          ),
          const Divider(height: 1),

          // Lista viajes del día
          Expanded(
            child: _viajesDia.isEmpty
                ? Center(
              child: Text(
                'No hay viajes el ${DateFormat('dd/MM/yyyy').format(_diaSeleccionado)}',
                style: const TextStyle(color: Colors.grey),
              ),
            )
                : ListView.separated(
              padding:
              const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: _viajesDia.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final v = _viajesDia[i];
                return _TarjetaViaje(
                  viaje: v,
                  color: _colorViaje(v),
                  onEditar: () => _editarViaje(v),
                  onEliminar: () => _eliminarViaje(v),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget: selector de cliente con buscador ──────────────────────────────────

class _SelectorCliente extends StatefulWidget {
  final List<Cliente> clientes;
  final Cliente? seleccionado;
  final ValueChanged<Cliente?> onChanged;

  const _SelectorCliente({
    required this.clientes,
    required this.seleccionado,
    required this.onChanged,
  });

  @override
  State<_SelectorCliente> createState() => _SelectorClienteState();
}

class _SelectorClienteState extends State<_SelectorCliente> {
  final _busquedaCtrl = TextEditingController();
  List<Cliente> _filtrados = [];

  @override
  void initState() {
    super.initState();
    _filtrados = widget.clientes;
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  void _filtrar(String q) {
    setState(() {
      _filtrados = q.isEmpty
          ? widget.clientes
          : widget.clientes
          .where((c) =>
      c.nombre.toLowerCase().contains(q.toLowerCase()) ||
          c.telefono.contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Campo de búsqueda
        TextField(
          controller: _busquedaCtrl,
          onChanged: _filtrar,
          decoration: InputDecoration(
            labelText: 'Buscar cliente (opcional)',
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            suffixIcon: widget.seleccionado != null
                ? IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Quitar cliente',
              onPressed: () {
                _busquedaCtrl.clear();
                _filtrar('');
                widget.onChanged(null);
              },
            )
                : null,
          ),
        ),

        // Cliente seleccionado
        if (widget.seleccionado != null)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.seleccionado!.nombre} · ${widget.seleccionado!
                        .telefono}',
                    style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

        // Lista de resultados
        if (_busquedaCtrl.text.isNotEmpty && widget.seleccionado == null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            // SOLUCIÓN: Usamos Column en lugar de ListView.
            // Como el diálogo ya tiene un SingleChildScrollView en calendario_screen.dart (línea 150),
            // los resultados simplemente se añadirán al scroll general sin romper el layout.
            child: _filtrados.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Sin resultados',
                  style: TextStyle(color: Colors.grey)),
            )
                : Column(
              mainAxisSize: MainAxisSize.min,
              children: _filtrados.take(10).map((
                  c) { // Limitamos a 10 resultados por rendimiento
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      c.nombre[0].toUpperCase(),
                      style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(c.nombre,
                      style: const TextStyle(fontSize: 14)),
                  subtitle: Text(c.telefono,
                      style: const TextStyle(fontSize: 12)),
                  onTap: () {
                    _busquedaCtrl.clear();
                    // No hace falta resetear _filtrados aquí ya que el widget se reconstruirá
                    widget.onChanged(c);
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// ── Widget: filtro de conductor ───────────────────────────────────────────────

class _FiltroCondutor extends StatelessWidget {
  final List<Conductor> conductores;
  final Conductor? seleccionado;
  final ValueChanged<Conductor?> onChanged;

  const _FiltroCondutor({
    required this.conductores,
    required this.seleccionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: DropdownButtonFormField<Conductor?>(
        value: seleccionado,
        decoration: const InputDecoration(
          labelText: 'Filtrar por conductor',
          prefixIcon: Icon(Icons.person_search),
          border: OutlineInputBorder(),
          contentPadding:
          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem<Conductor?>(
            value: null,
            child: Text('Todos los conductores'),
          ),
          ...conductores.map((c) => DropdownMenuItem<Conductor?>(
            value: c,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 8,
                  backgroundColor: _conductorColors[
                  conductores.indexOf(c) %
                      _conductorColors.length],
                ),
                const SizedBox(width: 8),
                Text('${c.nombre} (${c.matricula})'),
              ],
            ),
          )),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

// ── Widget: leyenda de colores ────────────────────────────────────────────────

class _LeyendaColores extends StatelessWidget {
  final List<Conductor> conductores;
  const _LeyendaColores({required this.conductores});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: conductores.asMap().entries.map((e) {
          final color =
          _conductorColors[e.key % _conductorColors.length];
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(e.value.nombre,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.black87)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Widget: tarjeta de viaje ──────────────────────────────────────────────────

class _TarjetaViaje extends StatelessWidget {
  final Viaje viaje;
  final Color color;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _TarjetaViaje({
    required this.viaje,
    required this.color,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 7)),
        ),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hora
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    viaje.hora,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ),

              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${viaje.puntorecogida} → ${viaje.puntodejada}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    // Conductor y teléfono
                    Text(
                      viaje.conductor != null
                          ? (viaje.telefonocliente.trim().isNotEmpty
                          ? '${viaje.conductor!.nombre} · ${viaje.telefonocliente}'
                          : viaje.conductor!.nombre)
                          : viaje.telefonocliente,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700),
                    ),
                    // Cliente asignado (si existe)
                    if (viaje.cliente != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person,
                              size: 12, color: Colors.green.shade600),
                          const SizedBox(width: 3),
                          Text(
                            viaje.cliente!.nombre,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Botones
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: Colors.blue, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Editar',
                    onPressed: onEditar,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Eliminar',
                    onPressed: onEliminar,
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}