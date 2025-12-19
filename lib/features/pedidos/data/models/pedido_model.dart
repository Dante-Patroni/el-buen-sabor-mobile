import '../../domain/models/pedido.dart';

class PedidoModel extends Pedido {
  PedidoModel({
    super.id,
    required super.mesa,
    required super.cliente,
    required super.platoId,
    super.fecha,
    super.estado,
    super.total,
    // 👇 AGREGADO: Necesarios para el detalle del pedido
    super.cantidad = 1,
    super.aclaracion,
  });

  // ==========================================================
  // 1. ADAPTERS (Dominio <-> Data)
  // ==========================================================

  // 🔌 Mapper: Convierte Entidad (Dominio) -> Modelo (Data)
  factory PedidoModel.fromEntity(Pedido pedido) {
    return PedidoModel(
      id: pedido.id,
      mesa: pedido.mesa,
      cliente: pedido.cliente,
      platoId: pedido.platoId,
      fecha: pedido.fecha,
      estado: pedido.estado,
      total: pedido.total,
      // 👇 AGREGADO: Pasamos los nuevos datos
      cantidad: pedido.cantidad,
      aclaracion: pedido.aclaracion,
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
      platoId: _parsePlatoId(json), // ✅ Mantenemos tu validador robusto
      fecha:
          DateTime.tryParse(
            json['fecha']?.toString() ?? json['createdAt']?.toString() ?? "",
          ) ??
          DateTime.now(),
      estado: _mapEstado(json['estado']),
      total: double.tryParse(json['total']?.toString() ?? "0") ?? 0.0,

      // 👇 AGREGADO: Leemos cantidad y aclaración si vienen
      cantidad: int.tryParse(json['cantidad']?.toString() ?? "1") ?? 1,
      aclaracion: json['aclaracion'],
    );
  }

  // 📤 APP -> API (toJson)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'mesa': mesa,
      'cliente': cliente,
      'platoId': platoId,
      'fecha': fecha.toIso8601String(),
      'estado': estado.name,
      'total': total,
      // 👇 AGREGADO: Incluimos los campos nuevos
      'cantidad': cantidad,
      'aclaracion': aclaracion,
    };
  }

  // 📥 SQLite -> APP (fromMap)
  factory PedidoModel.fromMap(Map<String, dynamic> map) {
    return PedidoModel(
      id: map['id'],
      mesa: map['mesa'],
      cliente: map['cliente'],
      platoId: map['plato_id'],
      fecha: DateTime.parse(map['fecha']),
      estado: _mapEstado(map['estado']),
      total: map['total'] ?? 0.0,
      // 👇 AGREGADO: Soporte para SQLite futuro
      cantidad: map['cantidad'] ?? 1,
      aclaracion: map['aclaracion'],
    );
  }

  // 📤 APP -> SQLite (toMap)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mesa': mesa,
      'cliente': cliente,
      'plato_id': platoId,
      'fecha': fecha.toIso8601String(),
      'estado': estado.name,
      'total': total,
      // 👇 AGREGADO
      'cantidad': cantidad,
      'aclaracion': aclaracion,
    };
  }

  // ==========================================================
  // 3. HELPERS (Tus funciones originales intactas)
  // ==========================================================

  static EstadoPedido _mapEstado(dynamic estadoValue) {
    if (estadoValue == null) return EstadoPedido.pendiente;
    final String estadoString = estadoValue.toString().toLowerCase().trim();

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

  // ✅ Tu parser de IDs es excelente, lo dejamos tal cual
  static int _parsePlatoId(Map<String, dynamic> json) {
    final val = json['platoId'] ?? json['PlatoId'] ?? json['plato_id'];
    if (val == null) return 0;
    if (val is int) return val;
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }
}
