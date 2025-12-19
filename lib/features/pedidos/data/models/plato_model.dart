import '../../domain/models/plato.dart';

class PlatoModel extends Plato {
  PlatoModel({
    required super.id,
    required super.nombre,
    required super.precio,
    required super.descripcion,
    required super.imagenPath,
    required super.esMenuDelDia,
    required super.categoria,
    required super.stock,
  });

  factory PlatoModel.fromJson(Map<String, dynamic> json) {
    // ---------------------------------------------------------
    // 1. LÓGICA DE STOCK HÍBRIDA (La solución al misterio)
    // ---------------------------------------------------------
    int cantidad = 0;
    String estadoLeido = 'AGOTADO';

    // A. ¿Viene el número directo (stockActual)?
    if (json['stockActual'] != null) {
      cantidad = int.tryParse(json['stockActual'].toString()) ?? 0;
    }

    // B. ¿Viene el objeto stock anidado? (Lo que vimos en tu log)
    if (json['stock'] != null && json['stock'] is Map) {
      // Leemos el estado que manda el servidor
      if (json['stock']['estado'] != null) {
        estadoLeido = json['stock']['estado'];
      }

      // Intentamos leer cantidad si existe
      if (json['stock']['cantidad'] != null) {
        cantidad = int.tryParse(json['stock']['cantidad'].toString()) ?? 0;
      }
    }

    // 🚨 EL PARCHE SALVAVIDAS:
    // Si la cantidad es 0, pero el servidor jura que está "DISPONIBLE",
    // le ponemos un stock falso de 10 para que el botón se habilite.
    if (cantidad == 0 && estadoLeido == 'DISPONIBLE') {
      cantidad = 10;
    }

    // Recalculamos el estado final basado en la cantidad corregida
    final estadoFinal = cantidad > 0 ? 'DISPONIBLE' : 'AGOTADO';

    // ---------------------------------------------------------
    // 2. PARSEO DEL RUBRO
    // ---------------------------------------------------------
    String nombreRubro = 'General';
    if (json['rubro'] != null) {
      if (json['rubro'] is Map && json['rubro']['denominacion'] != null) {
        nombreRubro = json['rubro']['denominacion'];
      } else if (json['rubro'] is String) {
        nombreRubro = json['rubro'];
      }
    }

    return PlatoModel(
      id: json['id'],
      nombre: json['nombre'] ?? 'Sin Nombre',
      precio: double.tryParse(json['precio'].toString()) ?? 0.0,
      descripcion: json['descripcion'] ?? '',
      imagenPath: json['imagenPath'] ?? '',
      esMenuDelDia: json['esMenuDelDia'] == true || json['esMenuDelDia'] == 1,
      categoria: nombreRubro,
      stock: StockInfo(
        cantidad: cantidad,
        esIlimitado: false,
        estado: estadoFinal,
      ),
    );
  }

  // ... (El resto de métodos fromMap y toMap quedan igual) ...
  // 📥 SQLite (Local) -> APP
  factory PlatoModel.fromMap(Map<String, dynamic> map) {
    return PlatoModel(
      id: map['id'],
      nombre: map['nombre'],
      precio: (map['precio'] as num).toDouble(),
      descripcion: map['descripcion'] ?? '',
      imagenPath: map['imagen_path'] ?? '',
      esMenuDelDia: (map['es_menu_del_dia'] == 1),
      categoria: map['categoria'] ?? 'General',
      stock: StockInfo(
        cantidad: map['stock_cantidad'] ?? 0,
        esIlimitado: (map['stock_ilimitado'] == 1),
        estado: map['stock_estado'] ?? 'AGOTADO',
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'descripcion': descripcion,
      'imagen_path': imagenPath,
      'es_menu_del_dia': esMenuDelDia ? 1 : 0,
      'categoria': categoria,
      'stock_cantidad': stock.cantidad,
      'stock_ilimitado': stock.esIlimitado ? 1 : 0,
      'stock_estado': stock.estado,
    };
  }
}
