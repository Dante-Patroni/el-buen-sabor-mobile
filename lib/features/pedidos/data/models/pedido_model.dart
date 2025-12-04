import '../../domain/models/pedido.dart';

class PedidoModel extends Pedido {
  PedidoModel({
    super.id, // ✅ Dejamos que sea opcional (int?) como en el padre
    required super.mesa,
    required super.cliente,
    required super.platoId,
    required super.fecha,
    required super.estado,
  });

  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    return PedidoModel(
      id: json['id'], // Puede ser null
      mesa: (json['mesa'] ?? '').toString(),
      cliente: (json['cliente'] ?? '').toString(),
      // 🛡️ BLINDAJE DE ID
      platoId: _parsePlatoId(json),
      fecha: DateTime.tryParse(json['fecha']?.toString() ?? "") ?? DateTime.now(),
      // 🛡️ MAPEO INTELEGENTE
      estado: _mapEstado(json['estado']),
    );
  }

  // Para SQLite
  factory PedidoModel.fromMap(Map<String, dynamic> map) {
    return PedidoModel(
      id: map['id'],
      mesa: map['mesa'],
      cliente: map['cliente'],
      platoId: map['plato_id'],
      fecha: DateTime.parse(map['fecha']),
      estado: _mapEstado(map['estado']), // Reutilizamos el mapper inteligente
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mesa': mesa,
      'cliente': cliente,
      'plato_id': platoId,
      'fecha': fecha.toIso8601String(),
      'estado': estado.name, // Guardará "enPreparacion" en SQLite
    };
  }

  // 👇 HELPER DE ESTADO CORREGIDO
  static EstadoPedido _mapEstado(dynamic estadoValue) {
    if (estadoValue == null) return EstadoPedido.pendiente;

    final String estadoString = estadoValue.toString().toLowerCase().trim();

    // 1. Mapeo Manual para el caso conflictivo (snake_case vs camelCase)
    if (estadoString == 'en_preparacion') return EstadoPedido.enPreparacion;
    if (estadoString == 'enpreparacion') return EstadoPedido.enPreparacion;

    // 2. Intentamos buscar coincidencias directas para el resto
    try {
      return EstadoPedido.values.firstWhere(
        (e) => e.name.toLowerCase() == estadoString,
        orElse: () => EstadoPedido.pendiente,
      );
    } catch (_) {
      return EstadoPedido.pendiente;
    }
  }

  // 👇 HELPER DE ID (Que ya tenías bien)
  static int _parsePlatoId(Map<String, dynamic> json) {
    final val = json['platoId'] ?? json['PlatoId'] ?? json['plato_id'];
    if (val == null) return 0;
    if (val is int) return val;
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }
}