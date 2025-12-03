import '../../domain/models/pedido.dart';

class PedidoModel extends Pedido {
  PedidoModel({
    int? id,
    String mesa = '', // Valor por defecto en lugar de required
    String cliente = '', // Valor por defecto en lugar de required
    required int platoId,
    DateTime? fecha,
    EstadoPedido estado = EstadoPedido.pendiente,
  }) : super(
          id: id,
          mesa: mesa,
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
      mesa: map['mesa'],
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
  // Debug: imprimir lo que llega
  print("📋 [DEBUG MODEL] JSON recibido:");
  print("   id: ${json['id']} (${json['id']?.runtimeType})");
  print("   mesa: ${json['mesa']} (${json['mesa']?.runtimeType})");
  print("   cliente: ${json['cliente']} (${json['cliente']?.runtimeType})");
  print("   PlatoId: ${json['PlatoId']}, platoId: ${json['platoId']}");
  print("   estado: ${json['estado']}");
  print("   fecha: ${json['fecha']}");
  
  return PedidoModel(
    id: json['id'] as int?,
    
    // ✅ CORREGIDO: Manejar valores null
    mesa: (json['mesa'] ?? '').toString(), // Si es null, convertir a string vacío
    cliente: (json['cliente'] ?? '').toString(), // Si es null, convertir a string vacío
    
    // Manejo seguro de platoId
    platoId: _parsePlatoId(json),
    
    // Manejo seguro de fecha
    fecha: _parseFecha(json['fecha'] ?? json['createdAt']),
    
    // Manejo seguro del estado
    estado: _parseEstado(json['estado']),
  );
}

// Helper para parsear platoId
static int _parsePlatoId(Map<String, dynamic> json) {
  // Probar diferentes posibles nombres del campo
  final dynamic platoIdValue = json['PlatoId'] ?? json['platoId'] ?? json['plato_id'];
  
  if (platoIdValue == null) {
    print("⚠️ [DEBUG MODEL] platoId es null, usando 0 por defecto");
    return 0;
  }
  
  if (platoIdValue is int) return platoIdValue;
  if (platoIdValue is String) return int.tryParse(platoIdValue) ?? 0;
  if (platoIdValue is double) return platoIdValue.toInt();
  
  print("⚠️ [DEBUG MODEL] platoId tipo no reconocido: ${platoIdValue.runtimeType}");
  return 0;
}

// Helper para parsear fecha
static DateTime? _parseFecha(dynamic fechaValue) {
  if (fechaValue == null) {
    print("⚠️ [DEBUG MODEL] fecha es null, usando DateTime.now()");
    return DateTime.now();
  }
  
  try {
    if (fechaValue is DateTime) return fechaValue;
    if (fechaValue is String) return DateTime.parse(fechaValue);
    return DateTime.now();
  } catch (e) {
    print("❌ [DEBUG MODEL] Error parseando fecha: $e");
    return DateTime.now();
  }
}

// Helper para parsear estado
static EstadoPedido _parseEstado(dynamic estadoValue) {
  if (estadoValue == null) {
    print("⚠️ [DEBUG MODEL] estado es null, usando pendiente por defecto");
    return EstadoPedido.pendiente;
  }
  
  final estadoStr = estadoValue.toString().toLowerCase();
  
  // Mapear diferentes formatos posibles
  if (estadoStr.contains('preparacion') || estadoStr.contains('en_preparacion')) {
    return EstadoPedido.en_preparacion;
  } else if (estadoStr.contains('entregado')) {
    return EstadoPedido.entregado;
  } else if (estadoStr.contains('rechazado')) {
    return EstadoPedido.rechazado;
  } else if (estadoStr.contains('pendiente')) {
    return EstadoPedido.pendiente;
  }
  
  print("⚠️ [DEBUG MODEL] estado no reconocido: '$estadoStr', usando pendiente");
  return EstadoPedido.pendiente;
}

  // ----------------------------------------------------------
  // 🔄 Guardar en SQLite
  // ----------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mesa': mesa,
      'cliente': cliente,
      'plato_id': platoId,
      'fecha': fecha?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'estado': estado.name,
    };
  }
}