import '../../domain/models/plato.dart';

class PlatoModel extends Plato {
  PlatoModel({
    required int id,
    required String nombre,
    required double precio,
    required String ingredientePrincipal,
    String? imagenUrl,
  }) : super(
         id: id,
         nombre: nombre,
         precio: precio,
         ingredientePrincipal: ingredientePrincipal,
         imagenUrl: imagenUrl,
       );

  // ----------------------------------------------------------
  // 💾 CONSTRUCTOR 1: Para SQLite (Base de Datos Local)
  // ----------------------------------------------------------
  // SQLite usa snake_case (ingrediente_principal)
  factory PlatoModel.fromMap(Map<String, dynamic> map) {
    return PlatoModel(
      id: map['id'],
      nombre: map['nombre'],
      precio: (map['precio'] as num).toDouble(),
      ingredientePrincipal: map['ingrediente_principal'], // Con guion bajo
      imagenUrl: map['imagen_path'], // En local guardamos el path, no la URL
    );
  }

  // ----------------------------------------------------------
  // ☁️ CONSTRUCTOR 2: Para API Node.js (Internet)
  // ----------------------------------------------------------
  // Node.js usa camelCase (ingredientePrincipal)
  factory PlatoModel.fromJson(Map<String, dynamic> json) {
    return PlatoModel(
      id: json['id'],
      nombre: json['nombre'],
      precio: (json['precio'] as num).toDouble(),
      ingredientePrincipal: json['ingredientePrincipal'], // <-- CAMELCASE, IGUAL QUE EL LOG
      imagenUrl: json['imagenUrl'], // Si viene null, no pasa nada
    );
  }

  // ----------------------------------------------------------
  // 🔄 MÉTODO: Para guardar en SQLite
  // ----------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'ingrediente_principal': ingredientePrincipal,
      'imagen_path': imagenUrl,
    };
  }
}
