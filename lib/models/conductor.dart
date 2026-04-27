class Conductor {
  final int id;
  final String matricula;
  final String nombre;
  final String? condAdmin;

  Conductor({
    required this.id,
    required this.matricula,
    required this.nombre,
    this.condAdmin,
  });

  factory Conductor.fromJson(Map<String, dynamic> json) {
    return Conductor(
      id: json['id'] as int,
      matricula: json['matricula'] as String,
      nombre: json['nombre'] as String,
      condAdmin: json['cond_admin'] as String? ?? json['condAdmin'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'matricula': matricula,
    'nombre': nombre,
    if (condAdmin != null) 'cond_admin': condAdmin,
  };

  @override
  bool operator ==(Object other) => identical(this, other) || (other is Conductor && other.id == id);

  @override
  int get hashCode => id.hashCode;
}