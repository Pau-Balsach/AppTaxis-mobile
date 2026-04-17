class Conductor {
  final int id;
  final String matricula;
  final String nombre;

  Conductor({
    required this.id,
    required this.matricula,
    required this.nombre,
  });

  factory Conductor.fromJson(Map<String, dynamic> json) {
    return Conductor(
      id: json['id'] as int,
      matricula: json['matricula'] as String,
      nombre: json['nombre'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'matricula': matricula,
    'nombre': nombre,
  };


  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Conductor && other.id == id);

  @override
  int get hashCode => id.hashCode;
}