import '../../domain/models/pedido.dart';

class PedidoModel extends Pedido {
  PedidoModel({
    super.id,
    required super.mesa,
    required super.cliente,
    required super.platoId,
    required super.fecha,
    required super.estado,
  });

  // ==========================================================
  // 1. ADAPTERS (Domino <-> Data)
  // ==========================================================
  
  // 🔌 Mapper: Convierte Entidad (Dominio) -> Modelo (Data)
  // Este es el puente que nos faltaba para el Repositorio
  factory PedidoModel.fromEntity(Pedido pedido) {
    return PedidoModel(
      id: pedido.id,
      mesa: pedido.mesa,
      cliente: pedido.cliente,
      platoId: pedido.platoId,
      fecha: pedido.fecha,
      estado: pedido.estado,
    );
  }

  // ==========================================================
  // 2. PARSERS (Data <-> JSON/DB)
  // ==========================================================

  // 📥 API -> APP (fromJson)
  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    return PedidoModel(
      id: json['id'],
      mesa: (json['mesa'] ?? '').toString(),
      cliente: (json['cliente'] ?? '').toString(),
      platoId: _parsePlatoId(json), // Tu blindaje funciona perfecto aquí
      fecha: DateTime.tryParse(json['fecha']?.toString() ?? "") ?? DateTime.now(),
      estado: _mapEstado(json['estado']), // Tu mapper inteligente
    );
  }

  // 📤 APP -> API (toJson)
  // Usamos esto para enviar al Backend (Node.js suele preferir camelCase)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'mesa': mesa,
      'cliente': cliente,
      'platoId': platoId, // ⚠️ API suele usar camelCase
      'fecha': fecha.toIso8601String(),
      'estado': estado.name, // "pendiente", "enPreparacion"
    };
  }

  // 📥 SQLite -> APP (fromMap)
  factory PedidoModel.fromMap(Map<String, dynamic> map) {
    return PedidoModel(
      id: map['id'],
      mesa: map['mesa'],
      cliente: map['cliente'],
      platoId: map['plato_id'], // SQLite suele usar snake_case
      fecha: DateTime.parse(map['fecha']),
      estado: _mapEstado(map['estado']),
    );
  }

  // 📤 APP -> SQLite (toMap)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mesa': mesa,
      'cliente': cliente,
      'plato_id': platoId, // SQLite snake_case
      'fecha': fecha.toIso8601String(),
      'estado': estado.name,
    };
  }

  // ==========================================================
  // 3. HELPERS (Tus funciones de blindaje)
  // ==========================================================

  static EstadoPedido _mapEstado(dynamic estadoValue) {
    if (estadoValue == null) return EstadoPedido.pendiente;
    final String estadoString = estadoValue.toString().toLowerCase().trim();

    // Casos manuales
    if (estadoString == 'en_preparacion') return EstadoPedido.enPreparacion;
    if (estadoString == 'enpreparacion') return EstadoPedido.enPreparacion;

    try {
      return EstadoPedido.values.firstWhere(
        (e) => e.name.toLowerCase() == estadoString,
        orElse: () => EstadoPedido.pendiente,
      );
    } catch (_) {
      return EstadoPedido.pendiente;
    }
  }

  static int _parsePlatoId(Map<String, dynamic> json) {
    final val = json['platoId'] ?? json['PlatoId'] ?? json['plato_id'];
    if (val == null) return 0;
    if (val is int) return val;
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }
}