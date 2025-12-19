class StockInfo {
  final int cantidad;
  final bool esIlimitado;
  final String estado; // 'AGOTADO', 'BAJO_STOCK', 'DISPONIBLE'

  StockInfo({
    required this.cantidad,
    required this.esIlimitado,
    required this.estado,
  });

  // Constructor de emergencia por si el dato viene nulo
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

  Plato({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.descripcion,
    required this.imagenPath,
    required this.esMenuDelDia,
    required this.categoria,
    required this.stock,
  });
}
