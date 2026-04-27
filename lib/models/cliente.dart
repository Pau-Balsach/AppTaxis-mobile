class Cliente {
  final int id;
  final String nombre;
  final String telefono;
  final String? email;
  final String? notas;
  final String? adminId;

  Cliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    this.email,
    this.notas,
    this.adminId,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String,
      email: json['email'] as String?,
      notas: json['notas'] as String?,
      adminId: json['adminId'] as String? ?? json['admin_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'telefono': telefono,
    if (email != null) 'email': email,
    if (notas != null) 'notas': notas,
    if (adminId != null) 'adminId': adminId,
  };
}