class Plato {
  final int id;
  final String nombre;
  final double precio;
  final String ingredientePrincipal;
  final String? imagenUrl; // 🆕 Puede ser null si no tiene foto

  Plato({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.ingredientePrincipal,
    this.imagenUrl,
  });
}