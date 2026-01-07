import '../../domain/models/mesa.dart';

class MesaUiModel {
  final int id;
  final int numero;
  final String estado;
  final double totalActual;
  final String? mozoAsignado;

  MesaUiModel({
    required this.id,
    required this.numero,
    required this.estado,
    required this.totalActual,
    this.mozoAsignado,
  });

  /// 🔁 Adaptador Dominio → UI
  factory MesaUiModel.fromDomain(Mesa mesa) {
    return MesaUiModel(
      id: mesa.id,
      numero: _extraerNumero(mesa.nombre),
      estado: mesa.estado,
      totalActual: mesa.totalActual,
      mozoAsignado: mesa.mozoAsignado,
    );
  }

  /// 🧠 Lógica de presentación encapsulada
  static int _extraerNumero(String nombre) {
    // "Mesa 5" → 5
    final match = RegExp(r'\d+').firstMatch(nombre);
    return match != null ? int.parse(match.group(0)!) : 0;
  }
}
