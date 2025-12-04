import '../../domain/models/plato.dart';

class PlatoModel extends Plato {
  PlatoModel({
    required int id,
    required String nombre,
    required double precio,
    required String ingredientePrincipal,
    String? imagenUrl,
    required StockInfo stock, // 1. Recibe el stock
  }) : super(
          id: id,
          nombre: nombre,
          precio: precio,
          ingredientePrincipal: ingredientePrincipal,
          imagenUrl: imagenUrl,
          stock: stock, // 2. ⚠️ ¡IMPORTANTE! Se lo pasa al padre (Plato)
        );

  factory PlatoModel.fromMap(Map<String, dynamic> map) {
    // TUS LOGS (Déjalos un momento más para verificar)
    print("🔍 [DEBUG MODEL] Leyendo Plato ID: ${map['id']} - ${map['nombre']}");
    print("   👉 stock_cantidad (raw): ${map['stock_cantidad']} (Tipo: ${map['stock_cantidad'].runtimeType})");
    
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