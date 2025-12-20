class Usuario {
  final int id;
  final String nombre;
  final String apellido;
  final String rol;
  final String legajo;

  Usuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.rol,
    required this.legajo,
  });

  // Factory para convertir el JSON del Backend a un Objeto Dart
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      rol: json['rol'] ?? '',
      legajo: json['legajo'] ?? '', // Asegúrate que el backend mande esto si lo necesitas
    );
  }
}