class StockInfo {
  final int cantidad;
  final bool esIlimitado;
  final String estado;

  StockInfo({
    required this.cantidad,
    required this.esIlimitado,
    required this.estado,
  });

  factory StockInfo.empty() {
    return StockInfo(cantidad: 0, esIlimitado: false, estado: 'AGOTADO');
  }
}

class Plato {
  final int id;
  final String nombre;
  final double precio;
  final String ingredientePrincipal;
  final String? imagenUrl;
  final StockInfo stock; // ⚠️ ¿TIENES ESTA LÍNEA?

  Plato({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.ingredientePrincipal,
    this.imagenUrl,
    required this.stock,
  });
}
