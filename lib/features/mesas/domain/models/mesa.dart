class Mesa {
  final int id;
  final String nombre;
  final String estado; // 'libre', 'ocupada'
  final double totalActual;
  final int itemsPendientes;
  final String? mozoAsignado;
  /**
   * @description Crea una instancia inmutable de Mesa.
   * @param {int} id - Identificador unico de la mesa.
   * @param {String} nombre - Nombre visible de la mesa.
   * @param {String} estado - Estado actual (libre u ocupada).
   * @param {double} totalActual - Total acumulado de la mesa.
   * @param {int} itemsPendientes - Cantidad de items pendientes.
   * @param {String?} mozoAsignado - Nombre del mozo asignado.
   * @returns {Mesa} Instancia creada.
   * @throws {Error} No lanza errores por diseno.
   */
  Mesa({
    required this.id,
    required this.nombre,
    required this.estado,
    required this.totalActual,
    required this.itemsPendientes,
    this.mozoAsignado,
  });
}
