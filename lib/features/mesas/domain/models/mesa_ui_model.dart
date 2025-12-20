class MesaUiModel {
  final int id;
  final int numero;
  String estado;
  String? mozoAsignado; // Ya esperamos que llegue limpio (String o null)
  final double? totalActual;

  MesaUiModel({
    required this.id,
    required this.numero,
    required this.estado,
    this.mozoAsignado,
    this.totalActual,
  });

  // Factory simple: Asume que los datos ya vienen "masticados"
  // Opcional: Podrías quitar el factory y pasarlo todo por constructor si usas un Mapper externo.
  // Pero por convención de Flutter, dejamos un fromJson "tonto" que no hace lógica compleja.
  factory MesaUiModel.fromJson(Map<String, dynamic> json) {
    return MesaUiModel(
      id: json['id'],
      numero: int.tryParse(json['numero'].toString()) ?? 0,
      estado: json['estado'] ?? 'libre',
      mozoAsignado: json['mozoAsignado'], // 👈 Espera un String directo
      totalActual: double.tryParse(json['totalActual'].toString()) ?? 0.0,
    );
  }
}