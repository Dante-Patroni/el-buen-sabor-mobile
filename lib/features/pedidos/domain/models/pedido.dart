// ✅ LINTER HAPPY: Usamos camelCase para los valores del enum
enum EstadoPedido { pendiente, enPreparacion, rechazado, entregado }

class Pedido {
  final int? id; 
  final String mesa;
  final String cliente;
  final int platoId;
  final DateTime fecha;
  final EstadoPedido estado;

  Pedido({
    this.id,
    required this.mesa,
    required this.cliente,
    required this.platoId,
    DateTime? fecha,
    this.estado = EstadoPedido.pendiente,
  }) : fecha = fecha ?? DateTime.now();
}