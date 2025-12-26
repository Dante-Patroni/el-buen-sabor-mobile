// ✅ LINTER HAPPY: Usamos camelCase para los valores del enum
enum EstadoPedido {
  pendiente,
  enPreparacion,
  rechazado,
  entregado,
  cancelado,
  pagado
}

class Pedido {
  final int? id;
  final String mesa;
  final String cliente;
  final int platoId;
  final DateTime fecha;
  final EstadoPedido estado;
  final double total;

  // 👇 AGREGAMOS ESTOS DOS CAMPOS CLAVE
  final int cantidad;
  final String? aclaracion; // Ej: "Sin cebolla"

  Pedido({
    this.id,
    required this.mesa,
    required this.cliente,
    required this.platoId,
    DateTime? fecha,
    this.estado = EstadoPedido.pendiente,
    this.total = 0.0,
    // 👇 Inicializamos
    this.cantidad = 1,
    this.aclaracion,
  }) : fecha = fecha ?? DateTime.now();

  // 🛠️ Útil para modificar la cantidad sin perder los otros datos
  // (Como las clases son 'final', no puedes hacer pedido.cantidad = 2)
  Pedido copyWith({
    int? id,
    String? mesa,
    String? cliente,
    int? platoId,
    EstadoPedido? estado,
    double? total,
    int? cantidad,
    String? aclaracion,
  }) {
    return Pedido(
      id: id ?? this.id,
      mesa: mesa ?? this.mesa,
      cliente: cliente ?? this.cliente,
      platoId: platoId ?? this.platoId,
      fecha: fecha, // Mantenemos la fecha original
      estado: estado ?? this.estado,
      total: total ?? this.total,
      cantidad: cantidad ?? this.cantidad,
      aclaracion: aclaracion ?? this.aclaracion,
    );
  }
}
