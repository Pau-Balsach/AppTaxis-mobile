import 'conductor.dart';

class Viaje {
  final String id;
  final String dia;        // formato ISO: "2025-04-15"
  final String hora;       // formato: "HH:mm"
  final String puntorecogida;
  final String puntodejada;
  final String telefonocliente;
  final Conductor? conductor;

  Viaje({
    required this.id,
    required this.dia,
    required this.hora,
    required this.puntorecogida,
    required this.puntodejada,
    required this.telefonocliente,
    this.conductor,
  });

  factory Viaje.fromJson(Map<String, dynamic> json) {
    return Viaje(
      id: json['id'] as String,
      dia: json['dia'] as String,
      hora: (json['hora'] as String).substring(0, 5), // recorta segundos si vienen
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
    'hora': hora,
    'puntorecogida': puntorecogida,
    'puntodejada': puntodejada,
    'telefonocliente': telefonocliente,
  };
}
