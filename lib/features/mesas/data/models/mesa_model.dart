import '../../domain/models/mesa.dart';

class MesaModel extends Mesa {
  MesaModel({
    required super.id,
    required super.nombre,
    required super.estado,
    required super.totalActual,
    required super.itemsPendientes,
  });

  factory MesaModel.fromJson(Map<String, dynamic> json) {
    return MesaModel(
      id: int.parse(json['id'].toString()),
      nombre: json['nombre'] ?? 'Mesa ?',
      estado: json['estado'] ?? 'libre',
      totalActual: double.tryParse(json['totalActual'].toString()) ?? 0.0,
      itemsPendientes: int.tryParse(json['itemsPendientes'].toString()) ?? 0,
    );
  }
}