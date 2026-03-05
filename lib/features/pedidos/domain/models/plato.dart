class StockInfo {
  final int cantidad;
  final bool esIlimitado;
  final String estado; // 'AGOTADO', 'BAJO_STOCK', 'DISPONIBLE'

  /**
   * @description Crea una instancia de StockInfo.
   * @param {int} cantidad - Cantidad disponible.
   * @param {bool} esIlimitado - Indica si el stock es ilimitado.
   * @param {String} estado - Estado del stock.
   * @returns {StockInfo} Instancia creada.
   * @throws {Error} No lanza errores por diseno.
   */
  StockInfo({
    required this.cantidad,
    required this.esIlimitado,
    required this.estado,
  });

  // Constructor de emergencia por si el dato viene nulo
  /**
   * @description Crea un StockInfo por defecto en estado agotado.
   * @returns {StockInfo} StockInfo con valores por defecto.
   * @throws {Error} No lanza errores por diseno.
   */
  factory StockInfo.empty() =>
      StockInfo(cantidad: 0, esIlimitado: false, estado: 'AGOTADO');
}

class Plato {
  final int id;
  final String nombre;
  final double precio;
  final String descripcion; // Antes era ingredientePrincipal
  final String imagenPath; // Antes era imagenUrl
  final bool esMenuDelDia; // ¡Nuevo!
  final String categoria; // ¡Nuevo! (Nombre del Rubro)
  final StockInfo stock;
  final int? rubroId; 
  final List<String> modificadores;

  /**
   * @description Crea una instancia de Plato.
   * @param {int} id - Identificador del plato.
   * @param {String} nombre - Nombre del plato.
   * @param {double} precio - Precio del plato.
   * @param {String} descripcion - Descripcion del plato.
   * @param {String} imagenPath - Ruta o URL de la imagen.
   * @param {bool} esMenuDelDia - Indica si es menu del dia.
   * @param {String} categoria - Categoria o rubro.
   * @param {StockInfo} stock - Informacion de stock.
   * @param {int?} rubroId - Id del rubro opcional.
   * @param {List<String>} modificadores - Modificadores disponibles.
   * @returns {Plato} Instancia creada.
   * @throws {Error} No lanza errores por diseno.
   */
  Plato({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.descripcion,
    required this.imagenPath,
    required this.esMenuDelDia,
    required this.categoria,
    required this.stock,
    this.rubroId, 
    this.modificadores = const [],
  });
}
