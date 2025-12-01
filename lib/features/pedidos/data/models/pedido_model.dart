import '../../domain/models/pedido.dart';

class PedidoModel extends Pedido {
  PedidoModel({
    int? id,
    required String cliente,
    required int platoId,
    DateTime? fecha,
    EstadoPedido estado = EstadoPedido.pendiente,
  }) : super(
          id: id,
          cliente: cliente,
          platoId: platoId,
          fecha: fecha,
          estado: estado,
        );

  // ----------------------------------------------------------
  // 💾 1. Para SQLite (Base de Datos Local)
  // ----------------------------------------------------------
  factory PedidoModel.fromMap(Map<String, dynamic> map) {
    return PedidoModel(
      id: map['id'],
      cliente: map['cliente'],
      platoId: map['plato_id'], // SQLite usa guion bajo
      fecha: DateTime.parse(map['fecha']),
      estado: EstadoPedido.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoPedido.pendiente,
      ),
    );
  }

  // ----------------------------------------------------------
  // ☁️ 2. Para API Node.js (Internet) - ¡ESTO FALTABA!
  // ----------------------------------------------------------
  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    return PedidoModel(
      id: json['id'],
      cliente: json['cliente'],
      
      // ⚠️ OJO: Sequelize suele devolver "PlatoId" (Mayúscula) o "platoId"
      // Ponemos un "fallback" porsiacaso: json['PlatoId'] ?? json['platoId']
      platoId: json['PlatoId'] ?? json['platoId'] ?? 0, 
      
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : DateTime.now(),
      
      // Mapeo del Estado (String del Backend -> Enum de Flutter)
      estado: EstadoPedido.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoPedido.pendiente,
      ),
    );
  }

  // ----------------------------------------------------------
  // 🔄 Guardar en SQLite
  // ----------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente': cliente,
      'plato_id': platoId,
      'fecha': fecha?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'estado': estado.name,
    };
  }
}