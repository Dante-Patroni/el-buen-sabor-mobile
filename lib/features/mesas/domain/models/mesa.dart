class Mesa {
  final int id;
  final String nombre;
  final String estado; // 'libre', 'ocupada'
  final double totalActual;
  final int itemsPendientes;
  final String? mozoAsignado;
  Mesa({
    required this.id,
    required this.nombre,
    required this.estado,
    required this.totalActual,
    required this.itemsPendientes,
    this.mozoAsignado,
  });
}