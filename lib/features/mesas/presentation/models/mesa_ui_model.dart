import '../../domain/models/mesa.dart';

class MesaUiModel {
  final int id;
  final int numero;
  final String estado;
  final double totalActual;
  final String? mozoAsignado;

  /**
   * @description Crea el modelo de UI para una mesa.
   * @param {int} id - Identificador de la mesa.
   * @param {int} numero - Numero de mesa para UI.
   * @param {String} estado - Estado actual.
   * @param {double} totalActual - Total acumulado.
   * @param {String?} mozoAsignado - Mozo asignado.
   * @returns {MesaUiModel} Instancia creada.
   * @throws {Error} No lanza errores por diseno.
   */
  MesaUiModel({
    required this.id,
    required this.numero,
    required this.estado,
    required this.totalActual,
    this.mozoAsignado,
  });

  /**
   * @description Adapta un modelo de dominio a un modelo de UI.
   * @param {Mesa} mesa - Entidad de dominio.
   * @returns {MesaUiModel} Modelo adaptado para presentacion.
   * @throws {Error} No lanza errores por diseno.
   */
  factory MesaUiModel.fromDomain(Mesa mesa) {
    return MesaUiModel(
      id: mesa.id,
      numero: _extraerNumero(mesa.nombre),
      estado: mesa.estado,
      totalActual: mesa.totalActual,
      mozoAsignado: mesa.mozoAsignado,
    );
  }

  /**
   * @description Extrae el numero desde el nombre de mesa.
   * @param {String} nombre - Nombre de mesa (ej: "Mesa 5").
   * @returns {int} Numero extraido o 0 si no hay match.
   * @throws {Error} No lanza errores por diseno.
   */
  static int _extraerNumero(String nombre) {
    // "Mesa 5" → 5
    final match = RegExp(r'\d+').firstMatch(nombre);
    return match != null ? int.parse(match.group(0)!) : 0;
  }
}
