import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/conductor.dart';
import '../models/viaje.dart';
import '../models/cliente.dart';
import '../services/api_client.dart';
import '../services/app_exception.dart';

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

String _uiErrorMessage(Object e, {required String fallback}) {
  if (e is AppException) return e.message;
  return fallback;
}

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _diaSeleccionado = DateTime.now();
  DateTime _focusMes = DateTime.now();

  List<Viaje> _viajesDelMes = [];
  List<Conductor> _conductores = [];
  List<Cliente> _clientes = [];
  Map<int, Color> _conductorColorMap = {};

  Conductor? _conductorFiltro;
  bool _cargando = true;

  String _errorToMessage(Object e, {required String fallback}) {
    if (e is AppException) return e.message;
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final List<Viaje> viajes;
      final results = await Future.wait([
        ApiClient.getConductores(),
        ApiClient.getClientes(),
      ]);
      final conds = results[0] as List<Conductor>;
      final clientes = results[1] as List<Cliente>;

      if (_conductorFiltro != null) {
        viajes = await ApiClient.getViajesPorConductor(_conductorFiltro!.id);
      } else {
        viajes = await ApiClient.getViajes();
      }

      if (mounted) {
        setState(() {
          _conductores = conds;
          _clientes = clientes;
          _viajesDelMes = viajes;
          _conductorColorMap = {
            for (var i = 0; i < conds.length; i++) conds[i].id: _conductorColors[i % _conductorColors.length],
          };
          if (_conductorFiltro != null) {
            _conductorFiltro = conds.isNotEmpty
                ? conds.firstWhere(
                  (c) => c.id == _conductorFiltro!.id,
              orElse: () => conds.first,
            )
                : null;
          }
        });
      }
    } catch (e) {
      rootScaffoldKey.currentState?.showSnackBar(
        SnackBar(content: Text(_errorToMessage(e, fallback: 'Error cargando datos.'))),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<Viaje> _viajesParaDia(DateTime dia) {
    final diaStr = DateFormat('yyyy-MM-dd').format(dia);
    return _viajesDelMes.where((v) {
      if (v.dia == diaStr) return true;
      if (v.cruzaMedianoche) {
        return dia.isAfter(v.diaDateTime) && !dia.isAfter(v.diaFinDateTime);
      }
      return false;
    }).toList();
  }

  List<Viaje> get _viajesDia {
    final diaStr = DateFormat('yyyy-MM-dd').format(_diaSeleccionado);
    return _viajesDelMes.where((v) {
      if (v.dia == diaStr) return true;
      if (v.cruzaMedianoche) {
        return _diaSeleccionado.isAfter(v.diaDateTime) && !_diaSeleccionado.isAfter(v.diaFinDateTime);
      }
      return false;
    }).toList()
      ..sort((a, b) => a.hora.compareTo(b.hora));
  }

  Color _colorViaje(Viaje v) {
    if (v.conductor == null) return Colors.grey;
    return _conductorColorMap[v.conductor!.id] ?? Colors.grey;
  }

  Future<void> _crearViaje() async {
    if (_conductores.isEmpty) {
      rootScaffoldKey.currentState?.showSnackBar(
        const SnackBar(content: Text('No hay conductores disponibles.')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DialogoCrearViaje(
        diaSeleccionado: _diaSeleccionado,
        conductores: _conductores,
        clientes: _clientes,
        conductorFiltro: _conductorFiltro,
      ),
    );

    if (result == true) {
      await _cargarTodo();
      rootScaffoldKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Viaje creado correctamente.')),
      );
    }
  }

  Future<void> _editarViaje(Viaje v) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DialogoEditarViaje(
        viaje: v,
        conductores: _conductores,
        clientes: _clientes,
      ),
    );

    if (result == true) {
      await _cargarTodo();
      rootScaffoldKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Viaje actualizado correctamente.')),
      );
    }
  }

  Future<void> _eliminarViaje(Viaje v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar viaje'),
        content: Text('¿Eliminar el viaje de las ${v.hora}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
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
        SnackBar(content: Text(_errorToMessage(e, fallback: 'Error al eliminar el viaje.'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarTodo)],
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
          _FiltroCondutor(
            conductores: _conductores,
            seleccionado: _conductorFiltro,
            onChanged: (c) {
              setState(() => _conductorFiltro = c);
              _cargarTodo();
            },
          ),
          if (_conductores.isNotEmpty) _LeyendaColores(conductores: _conductores),
          TableCalendar<Viaje>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusMes,
            selectedDayPredicate: (d) => isSameDay(d, _diaSeleccionado),
            eventLoader: _viajesParaDia,
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(color: Colors.amber.shade700, shape: BoxShape.circle),
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
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
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
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
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
          Expanded(
            child: _viajesDia.isEmpty
                ? Center(
              child: Text(
                'No hay viajes el ${DateFormat('dd/MM/yyyy').format(_diaSeleccionado)}',
                style: const TextStyle(color: Colors.grey),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: _viajesDia.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
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

// ── Diálogos ──────────────────────────────────────────────────────────────────

class _DialogoCrearViaje extends StatefulWidget {
  final DateTime diaSeleccionado;
  final List<Conductor> conductores;
  final List<Cliente> clientes;
  final Conductor? conductorFiltro;

  const _DialogoCrearViaje({
    required this.diaSeleccionado,
    required this.conductores,
    required this.clientes,
    required this.conductorFiltro,
  });

  @override
  State<_DialogoCrearViaje> createState() => _DialogoCrearViajeState();
}

class _DialogoCrearViajeState extends State<_DialogoCrearViaje> {
  late Conductor conductorSel;
  Cliente? clienteSel;
  late DateTime diaFinSel;
  late TimeOfDay horaSel;
  late TimeOfDay horaFinSel;

  final recogidaCtrl = TextEditingController();
  final dejadaCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    conductorSel = widget.conductorFiltro ?? widget.conductores.first;
    diaFinSel = widget.diaSeleccionado;
    horaSel = TimeOfDay.now();
    horaFinSel = TimeOfDay.now();
  }

  @override
  void dispose() {
    recogidaCtrl.dispose();
    dejadaCtrl.dispose();
    telefonoCtrl.dispose();
    super.dispose();
  }

  String _formatHora(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nuevo viaje — ${DateFormat('dd/MM/yyyy').format(widget.diaSeleccionado)}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Conductor>(
              value: conductorSel,
              decoration: const InputDecoration(labelText: 'Conductor', border: OutlineInputBorder()),
              items: widget.conductores
                  .map((c) => DropdownMenuItem(value: c, child: Text('${c.nombre} — ${c.matricula}')))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => conductorSel = v);
              },
            ),
            const SizedBox(height: 12),
            _SelectorCliente(
              clientes: widget.clientes,
              seleccionado: clienteSel,
              onChanged: (c) {
                setState(() {
                  clienteSel = c;
                  if (c != null) telefonoCtrl.text = c.telefono;
                });
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: Text('Hora inicio: ${horaSel.format(context)}'),
              subtitle: Text(
                DateFormat('dd/MM/yyyy').format(widget.diaSeleccionado),
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: horaSel);
                if (t != null) setState(() => horaSel = t);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.flag),
              title: Text('Hora fin: ${horaFinSel.format(context)}'),
              subtitle: Row(
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(diaFinSel),
                    style: TextStyle(
                      fontSize: 12,
                      color: diaFinSel.isAfter(widget.diaSeleccionado) ? Colors.orange.shade700 : null,
                    ),
                  ),
                  if (diaFinSel.isAfter(widget.diaSeleccionado))
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'cruza medianoche',
                          style: TextStyle(fontSize: 10, color: Colors.orange.shade800),
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: horaFinSel);
                if (t == null) return;
                setState(() => horaFinSel = t);

                final inicioMin = horaSel.hour * 60 + horaSel.minute;
                final finMin = t.hour * 60 + t.minute;
                if (finMin < inicioMin) {
                  if (!context.mounted) return;
                  final diaSig = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('¿Día siguiente?'),
                      content: const Text(
                        'La hora de fin es anterior a la de inicio. ¿El viaje termina al día siguiente?',
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No, mismo día')),
                        ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sí, día siguiente')),
                      ],
                    ),
                  );
                  if (diaSig == true) {
                    setState(() => diaFinSel = widget.diaSeleccionado.add(const Duration(days: 1)));
                  }
                } else {
                  setState(() => diaFinSel = widget.diaSeleccionado);
                }
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: recogidaCtrl,
              decoration: const InputDecoration(labelText: 'Punto de recogida', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dejadaCtrl,
              decoration: const InputDecoration(labelText: 'Punto de dejada', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Teléfono cliente',
                border: const OutlineInputBorder(),
                helperText: clienteSel != null ? 'Autocompletado desde cliente' : null,
                suffixIcon: clienteSel != null ? Icon(Icons.person, color: Colors.green.shade600, size: 18) : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    if (recogidaCtrl.text.trim().isEmpty || dejadaCtrl.text.trim().isEmpty || telefonoCtrl.text.trim().isEmpty) {
      rootScaffoldKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Rellena todos los campos.')),
      );
      return;
    }

    setState(() => _guardando = true);

    final viaje = Viaje(
      id: '',
      dia: DateFormat('yyyy-MM-dd').format(widget.diaSeleccionado),
      diaFin: DateFormat('yyyy-MM-dd').format(diaFinSel),
      hora: _formatHora(horaSel),
      horaFinalizacion: _formatHora(horaFinSel),
      puntorecogida: recogidaCtrl.text.trim(),
      puntodejada: dejadaCtrl.text.trim(),
      telefonocliente: telefonoCtrl.text.trim(),
    );

    try {
      await ApiClient.crearViaje(
        conductorSel.id,
        viaje,
        clienteId: clienteSel?.id,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _guardando = false);
      rootScaffoldKey.currentState?.showSnackBar(
        SnackBar(content: Text(_uiErrorMessage(e, fallback: 'Error al guardar el viaje.'))),
      );
    }
  }
}

class _DialogoEditarViaje extends StatefulWidget {
  final Viaje viaje;
  final List<Conductor> conductores;
  final List<Cliente> clientes;

  const _DialogoEditarViaje({
    required this.viaje,
    required this.conductores,
    required this.clientes,
  });

  @override
  State<_DialogoEditarViaje> createState() => _DialogoEditarViajeState();
}

class _DialogoEditarViajeState extends State<_DialogoEditarViaje> {
  late Conductor conductorSel;
  Cliente? clienteSel;
  late DateTime diaInicio;
  late DateTime diaFinSel;
  late TimeOfDay horaSel;
  late TimeOfDay horaFinSel;

  late TextEditingController recogidaCtrl;
  late TextEditingController dejadaCtrl;
  late TextEditingController telefonoCtrl;
  bool _guardando = false;

  TimeOfDay _parseHora(String hhmm) {
    final p = hhmm.split(':');
    return TimeOfDay(
      hour: int.tryParse(p[0]) ?? 0,
      minute: int.tryParse(p.length > 1 ? p[1] : '0') ?? 0,
    );
  }

  String _formatHora(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    final v = widget.viaje;

    conductorSel =
        widget.conductores.firstWhere((c) => c.id == v.conductor?.id, orElse: () => widget.conductores.first);

    clienteSel = v.cliente != null
        ? widget.clientes.firstWhere((c) => c.id == v.cliente!.id, orElse: () => widget.clientes.first)
        : null;

    diaInicio = DateTime.parse(v.dia);
    diaFinSel = v.diaFin != null ? DateTime.parse(v.diaFin!) : diaInicio;

    horaSel = _parseHora(v.hora);
    horaFinSel = _parseHora(v.horaFinalizacion);

    recogidaCtrl = TextEditingController(text: v.puntorecogida);
    dejadaCtrl = TextEditingController(text: v.puntodejada);
    telefonoCtrl = TextEditingController(text: v.telefonocliente);
  }

  @override
  void dispose() {
    recogidaCtrl.dispose();
    dejadaCtrl.dispose();
    telefonoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar viaje'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Conductor>(
              value: conductorSel,
              decoration: const InputDecoration(labelText: 'Conductor', border: OutlineInputBorder()),
              items: widget.conductores
                  .map((c) => DropdownMenuItem(value: c, child: Text('${c.nombre} — ${c.matricula}')))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => conductorSel = val);
              },
            ),
            const SizedBox(height: 12),
            _SelectorCliente(
              clientes: widget.clientes,
              seleccionado: clienteSel,
              onChanged: (c) {
                setState(() {
                  clienteSel = c;
                  if (c != null) telefonoCtrl.text = c.telefono;
                });
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: Text('Hora inicio: ${horaSel.format(context)}'),
              subtitle: Text(
                DateFormat('dd/MM/yyyy').format(diaInicio),
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: horaSel);
                if (t != null) setState(() => horaSel = t);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.flag),
              title: Text('Hora fin: ${horaFinSel.format(context)}'),
              subtitle: Row(
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(diaFinSel),
                    style: TextStyle(
                      fontSize: 12,
                      color: diaFinSel.isAfter(diaInicio) ? Colors.orange.shade700 : null,
                    ),
                  ),
                  if (diaFinSel.isAfter(diaInicio))
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('cruza medianoche', style: TextStyle(fontSize: 10, color: Colors.orange.shade800)),
                      ),
                    ),
                ],
              ),
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: horaFinSel);
                if (t == null) return;
                setState(() => horaFinSel = t);

                final inicioMin = horaSel.hour * 60 + horaSel.minute;
                final finMin = t.hour * 60 + t.minute;
                if (finMin < inicioMin) {
                  if (!context.mounted) return;
                  final diaSig = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('¿Día siguiente?'),
                      content: const Text(
                        'La hora de fin es anterior a la de inicio. ¿El viaje termina al día siguiente?',
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No, mismo día')),
                        ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sí, día siguiente')),
                      ],
                    ),
                  );
                  if (diaSig == true) {
                    setState(() => diaFinSel = diaInicio.add(const Duration(days: 1)));
                  } else {
                    setState(() => diaFinSel = diaInicio);
                  }
                } else {
                  setState(() => diaFinSel = diaInicio);
                }
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: recogidaCtrl,
              decoration: const InputDecoration(labelText: 'Punto de recogida', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dejadaCtrl,
              decoration: const InputDecoration(labelText: 'Punto de dejada', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Teléfono cliente',
                border: const OutlineInputBorder(),
                helperText: clienteSel != null ? 'Autocompletado desde cliente' : null,
                suffixIcon: clienteSel != null ? Icon(Icons.person, color: Colors.green.shade600, size: 18) : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _guardando ? null : _actualizar,
          child: _guardando
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Actualizar'),
        ),
      ],
    );
  }

  Future<void> _actualizar() async {
    if (recogidaCtrl.text.trim().isEmpty || dejadaCtrl.text.trim().isEmpty || telefonoCtrl.text.trim().isEmpty) {
      rootScaffoldKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Rellena todos los campos.')),
      );
      return;
    }

    setState(() => _guardando = true);

    final viajeEditado = Viaje(
      id: widget.viaje.id,
      dia: widget.viaje.dia,
      diaFin: DateFormat('yyyy-MM-dd').format(diaFinSel),
      hora: _formatHora(horaSel),
      horaFinalizacion: _formatHora(horaFinSel),
      puntorecogida: recogidaCtrl.text.trim(),
      puntodejada: dejadaCtrl.text.trim(),
      telefonocliente: telefonoCtrl.text.trim(),
      conductor: conductorSel,
      cliente: clienteSel,
    );

    try {
      await ApiClient.editarViaje(
        widget.viaje.id,
        viajeEditado,
        clienteId: clienteSel?.id,
        conductorId: conductorSel.id,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _guardando = false);
      rootScaffoldKey.currentState?.showSnackBar(
        SnackBar(content: Text(_uiErrorMessage(e, fallback: 'Error al actualizar el viaje.'))),
      );
    }
  }
}

// ── Selector de cliente ───────────────────────────────────────────────────────

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
          .where((c) => c.nombre.toLowerCase().contains(q.toLowerCase()) || c.telefono.contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    '${widget.seleccionado!.nombre} · ${widget.seleccionado!.telefono}',
                    style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        if (_busquedaCtrl.text.isNotEmpty && widget.seleccionado == null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 160),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _filtrados.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Sin resultados', style: TextStyle(color: Colors.grey)),
            )
                : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _filtrados
                    .map((c) => ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      c.nombre[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(c.nombre, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(c.telefono, style: const TextStyle(fontSize: 12)),
                  onTap: () {
                    _busquedaCtrl.clear();
                    setState(() => _filtrados = widget.clientes);
                    widget.onChanged(c);
                  },
                ))
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Filtro conductor ──────────────────────────────────────────────────────────

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
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  backgroundColor: _conductorColors[conductores.indexOf(c) % _conductorColors.length],
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

// ── Leyenda colores ───────────────────────────────────────────────────────────

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
          final color = _conductorColors[e.key % _conductorColors.length];
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(e.value.nombre, style: const TextStyle(fontSize: 11, color: Colors.black87)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Tarjeta viaje ─────────────────────────────────────────────────────────────

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
    final cruzaMedianoche = viaje.cruzaMedianoche;
    final diaFinStr = viaje.diaFin != null ? DateFormat('dd/MM').format(DateTime.parse(viaje.diaFin!)) : null;

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
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(viaje.hora, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                      if (viaje.horaFinalizacion.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              viaje.horaFinalizacion,
                              style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
                            ),
                            if (cruzaMedianoche && diaFinStr != null)
                              Text(
                                ' +1',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${viaje.puntorecogida} → ${viaje.puntodejada}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      viaje.conductor != null
                          ? (viaje.telefonocliente.trim().isNotEmpty
                          ? '${viaje.conductor!.nombre} · ${viaje.telefonocliente}'
                          : viaje.conductor!.nombre)
                          : viaje.telefonocliente,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                    if (viaje.cliente != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person, size: 12, color: Colors.green.shade600),
                          const SizedBox(width: 3),
                          Text(
                            viaje.cliente!.nombre,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (cruzaMedianoche && diaFinStr != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.nightlight_round, size: 12, color: Colors.orange.shade600),
                          const SizedBox(width: 3),
                          Text(
                            'Hasta el $diaFinStr',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Editar',
                    onPressed: onEditar,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
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