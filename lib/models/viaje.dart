import 'conductor.dart';
import 'cliente.dart';

class Viaje {
  final String id;
  final String dia;
  final String? diaFin;
  final String hora;
  final String horaFinalizacion;
  final String puntorecogida;
  final String puntodejada;
  final String telefonocliente;
  final Conductor? conductor;
  final Cliente? cliente;
  final double? latRecogida;
  final double? lngRecogida;
  final double? latDejada;
  final double? lngDejada;

  Viaje({
    required this.id,
    required this.dia,
    this.diaFin,
    required this.hora,
    this.horaFinalizacion = '',
    required this.puntorecogida,
    required this.puntodejada,
    required this.telefonocliente,
    this.conductor,
    this.cliente,
    this.latRecogida,
    this.lngRecogida,
    this.latDejada,
    this.lngDejada,
  });

  factory Viaje.fromJson(Map<String, dynamic> json) {
    String recortar(String? s) =>
        s != null && s.length >= 5 ? s.substring(0, 5) : (s ?? '');

    return Viaje(
      id: json['id'] as String,
      dia: json['dia'] as String,
      diaFin: json['diaFin'] as String?,
      hora: recortar(json['hora'] as String?),
      horaFinalizacion: recortar(json['horaFinalizacion'] as String?),
      puntorecogida: json['puntorecogida'] as String,
      puntodejada: json['puntodejada'] as String,
      telefonocliente: json['telefonocliente'] as String,
      conductor: json['conductor'] != null
          ? Conductor.fromJson(json['conductor'] as Map<String, dynamic>)
          : null,
      cliente: json['cliente'] != null
          ? Cliente.fromJson(json['cliente'] as Map<String, dynamic>)
          : null,
      latRecogida: (json['latRecogida'] as num?)?.toDouble(),
      lngRecogida: (json['lngRecogida'] as num?)?.toDouble(),
      latDejada:   (json['latDejada'] as num?)?.toDouble(),
      lngDejada:   (json['lngDejada'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'dia': dia,
    'diaFin': diaFin ?? dia,
    'hora': hora,
    if (horaFinalizacion.isNotEmpty) 'horaFinalizacion': horaFinalizacion,
    'puntorecogida': puntorecogida,
    'puntodejada': puntodejada,
    'telefonocliente': telefonocliente,
  };

  Map<String, dynamic> toJsonConCliente(int? clienteId) => {
    'dia': dia,
    'diaFin': diaFin ?? dia,
    'hora': hora,
    if (horaFinalizacion.isNotEmpty) 'horaFinalizacion': horaFinalizacion,
    'puntorecogida': puntorecogida,
    'puntodejada': puntodejada,
    'telefonocliente': telefonocliente,
    if (clienteId != null) 'cliente': {'id': clienteId},
    if (latRecogida != null) 'latRecogida': latRecogida,
    if (lngRecogida != null) 'lngRecogida': lngRecogida,
    if (latDejada != null)   'latDejada': latDejada,
    if (lngDejada != null)   'lngDejada': lngDejada,
  };

  DateTime get diaDateTime => DateTime.parse(dia);
  DateTime get diaFinDateTime => DateTime.parse(diaFin ?? dia);

  bool get cruzaMedianoche =>
      diaFin != null && diaFin != dia;
}