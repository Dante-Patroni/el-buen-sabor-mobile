import '../../domain/models/pedido.dart';

class PedidoModel extends Pedido {
  PedidoModel({
    required int id,
    required String mesa,
    required String cliente,
    required int platoId,
    required DateTime fecha,
    required EstadoPedido estado,
  }) : super(
          id: id,
          mesa: mesa,
          cliente: cliente,
          platoId: platoId,
          fecha: fecha,
          estado: estado,
        );

  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    return PedidoModel(
      id: json['id'],
      mesa: json['mesa'].toString(),
      cliente: json['cliente'] ?? "",
      // 🛡️ BLINDAJE DE ID: Aceptamos 'platoId' (Flutter) O 'PlatoId' (Backend Sequelize)
      platoId: json['platoId'] ?? json['PlatoId'] ?? 0, 
      fecha: DateTime.tryParse(json['fecha'] ?? "") ?? DateTime.now(),
      // 🛡️ MAPEO DE ESTADO: Convertimos String -> Enum
      estado: _mapEstado(json['estado']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mesa': mesa,
      'cliente': cliente,
      'plato_id': platoId,
      'fecha': fecha.toIso8601String(),
      'estado': estado.name, 
    };
  }

  // 👇 EL MÉTODO QUE FALTABA (HELPER)
  static EstadoPedido _mapEstado(String? estadoString) {
    if (estadoString == null) return EstadoPedido.en_preparacion; // Default seguro

    // Buscamos en el Enum el valor que coincida con el texto del backend
    try {
      return EstadoPedido.values.firstWhere(
        (e) => e.name.toLowerCase() == estadoString.toLowerCase(),
        orElse: () => EstadoPedido.en_preparacion,
      );
    } catch (_) {
      // Si falla todo, devolvemos un estado por defecto para no romper la app
      return EstadoPedido.en_preparacion;
    }
  }
}