import '../../domain/models/plato.dart';

class PlatoModel extends Plato {
  PlatoModel({
    required super.id,
    required super.nombre,
    required super.precio,
    required super.ingredientePrincipal,
    super.imagenUrl,
    required super.stock, // 1. Recibe el stock
  });

  factory PlatoModel.fromMap(Map<String, dynamic> map) {
    // 2. Extrae el stock del mapa
    return PlatoModel(
      id: map['id'],
      nombre: map['nombre'],
      precio: (map['precio'] as num).toDouble(),
      ingredientePrincipal: map['ingrediente_principal'],
      imagenUrl: map['imagen_path'],
      // 3. Construye el objeto Stock
      stock: StockInfo(
        cantidad: map['stock_cantidad'] ?? 0,
        esIlimitado: (map['stock_ilimitado'] == 1), 
        estado: map['stock_estado'] ?? 'AGOTADO',
      ),
    );
  }

  // ... fromJson y toMap ...
  factory PlatoModel.fromJson(Map<String, dynamic> json) {
      final stockJson = json['stock'];
      StockInfo stockInfo;
      if (stockJson != null) {
        stockInfo = StockInfo(
          cantidad: stockJson['cantidad'] ?? 0,
          esIlimitado: stockJson['ilimitado'] ?? false,
          estado: stockJson['estado'] ?? 'DISPONIBLE',
        );
      } else {
        stockInfo = StockInfo.empty();
      }

      return PlatoModel(
        id: json['id'],
        nombre: json['nombre'],
        precio: (json['precio'] as num).toDouble(),
        ingredientePrincipal: json['ingredientePrincipal'], 
        imagenUrl: json['imagenUrl'],
        stock: stockInfo,
      );
    }
    
    Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'ingrediente_principal': ingredientePrincipal,
      'imagen_path': imagenUrl,
      'stock_cantidad': stock.cantidad,
      'stock_ilimitado': stock.esIlimitado ? 1 : 0,
      'stock_estado': stock.estado,
    };
  }
}