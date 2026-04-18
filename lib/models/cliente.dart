class Cliente {
  final int id;
  final String nombre;
  final String telefono;
  final String? email;
  final String? notas;

  Cliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    this.email,
    this.notas,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String,
      email: json['email'] as String?,
      notas: json['notas'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'telefono': telefono,
    if (email != null) 'email': email,
    if (notas != null) 'notas': notas,
  };
}