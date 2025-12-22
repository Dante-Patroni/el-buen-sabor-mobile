import 'dart:convert';
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
    super.rubroId,
    super.modificadores,
  });

// 📥 API (Sequelize) -> APP
  factory PlatoModel.fromJson(Map<String, dynamic> json) {
    // 1. Lógica de seguridad para Stock
    // Leemos 'stockActual' que viene de tu DB. Si es null, ponemos 0.
    int cantidadStock =
        int.tryParse(json['stockActual']?.toString() ?? "0") ?? 0;

    // Calculamos estado basado en la cantidad real
    String estadoCalculado = cantidadStock > 0 ? 'DISPONIBLE' : 'AGOTADO';

    return PlatoModel(
      id: json['id'],
      nombre: json['nombre'] ?? 'Sin Nombre',
      // Convertimos a double asegurando que no explote si viene int o string
      precio: double.tryParse(json['precio']?.toString() ?? "0") ?? 0.0,
      descripcion: json['descripcion'] ?? '',

      // 👇 Claves exactas de tu Sequelize (camelCase)
      imagenPath: json['imagenPath'] ?? '',
      rubroId: json['rubroId'],

      esMenuDelDia: json['esMenuDelDia'] == true || json['esMenuDelDia'] == 1,

      // ✅ AHORA SÍ: Mapeamos la categoría desde el objeto incluido por Sequelize
      categoria:
          (json['rubro'] != null && json['rubro']['denominacion'] != null)
              ? json['rubro']['denominacion']
              : 'Sin Categoría',

      modificadores: [],

      stock: StockInfo(
        cantidad: cantidadStock,
        esIlimitado: false,
        estado: estadoCalculado,
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
      rubroId: map['rubro_id'],
      modificadores: map['modificadores'] != null
          ? List<String>.from(jsonDecode(map['modificadores']))
          : [],
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
      'rubro_id': rubroId,
      'stock_cantidad': stock.cantidad,
      'stock_ilimitado': stock.esIlimitado ? 1 : 0,
      'stock_estado': stock.estado,
    };
  }
}
