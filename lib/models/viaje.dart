import 'conductor.dart';

class Viaje {
  final String id;
  final String dia; // formato ISO: "2025-04-15"
  final String hora; // formato: "HH:mm"
  final String horaFinalizacion; // formato: "HH:mm"
  final String puntorecogida;
  final String puntodejada;
  final String telefonocliente;
  final Conductor? conductor;

  Viaje({
    required this.id,
    required this.dia,
    required this.hora,
    required this.horaFinalizacion,
    required this.puntorecogida,
    required this.puntodejada,
    required this.telefonocliente,
    this.conductor,
  });

  factory Viaje.fromJson(Map<String, dynamic> json) {
    return Viaje(
      id: json['id'] as String,
      dia: json['dia'] as String,
      hora: _timeToHHmm(json['hora']),
      horaFinalizacion: _timeToHHmm(json['horaFinalizacion']),
      puntorecogida: json['puntorecogida'] as String,
      puntodejada: json['puntodejada'] as String,
      telefonocliente: json['telefonocliente'] as String,
      conductor: json['conductor'] != null
          ? Conductor.fromJson(json['conductor'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'dia': dia,
    'hora': _hhmmToApiTimeString(hora),
    'horaFinalizacion': _hhmmToApiTimeString(horaFinalizacion),
    'puntorecogida': puntorecogida,
    'puntodejada': puntodejada,
    'telefonocliente': telefonocliente,
  };

  static String _timeToHHmm(dynamic value) {
    if (value == null) return '00:00';

    if (value is String) {
      final clean = value.trim();
      if (clean.length >= 5) return clean.substring(0, 5);
      return clean.padRight(5, '0');
    }

    if (value is Map<String, dynamic>) {
      final hour = (value['hour'] as num?)?.toInt() ?? 0;
      final minute = (value['minute'] as num?)?.toInt() ?? 0;
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }

    return '00:00';
  }

  static String _hhmmToApiTimeString(String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
  }
}