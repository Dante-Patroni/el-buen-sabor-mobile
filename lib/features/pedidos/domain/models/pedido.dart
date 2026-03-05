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

  /**
   * @description Crea una instancia de Pedido.
   * @param {int?} id - Identificador del pedido.
   * @param {String} mesa - Identificador o numero de mesa.
   * @param {String} cliente - Nombre del cliente.
   * @param {int} platoId - Identificador del plato.
   * @param {DateTime?} fecha - Fecha del pedido (default: ahora).
   * @param {EstadoPedido} estado - Estado del pedido.
   * @param {double} total - Total del item o pedido.
   * @param {int} cantidad - Cantidad del plato.
   * @param {String?} aclaracion - Nota del pedido.
   * @returns {Pedido} Instancia creada.
   * @throws {Error} No lanza errores por diseno.
   */
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
  /**
   * @description Crea una copia del pedido con cambios parciales.
   * @param {int?} id - Nuevo id opcional.
   * @param {String?} mesa - Nueva mesa opcional.
   * @param {String?} cliente - Nuevo cliente opcional.
   * @param {int?} platoId - Nuevo platoId opcional.
   * @param {EstadoPedido?} estado - Nuevo estado opcional.
   * @param {double?} total - Nuevo total opcional.
   * @param {int?} cantidad - Nueva cantidad opcional.
   * @param {String?} aclaracion - Nueva aclaracion opcional.
   * @returns {Pedido} Copia con cambios aplicados.
   * @throws {Error} No lanza errores por diseno.
   */
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
