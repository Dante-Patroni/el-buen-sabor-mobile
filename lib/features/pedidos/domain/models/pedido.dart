// Mismo ENUM que en tu pedido.js
enum EstadoPedido { pendiente, en_preparacion, rechazado, entregado }

class Pedido {
  final int? id; // Puede ser null antes de guardarse en SQLite
  final String mesa;
  final String cliente;
  final int platoId; // Relación con el ID del plato (FK)
  final DateTime fecha;
  final EstadoPedido estado;

  Pedido({
    this.id,
    required this.mesa,
    required this.cliente,
    required this.platoId,
    DateTime? fecha,
    this.estado = EstadoPedido.pendiente, // Default como en tu backend
  }) : this.fecha = fecha ?? DateTime.now();
}
