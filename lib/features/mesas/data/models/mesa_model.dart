import '../../domain/models/mesa.dart';

class MesaModel extends Mesa {
  /**
   * @description Crea un modelo de mesa desde sus propiedades.
   * @param {int} id - Identificador de la mesa.
   * @param {String} nombre - Nombre visible.
   * @param {String} estado - Estado actual.
   * @param {double} totalActual - Total acumulado.
   * @param {int} itemsPendientes - Cantidad de items pendientes.
   * @param {String?} mozoAsignado - Nombre del mozo asignado.
   * @returns {MesaModel} Instancia creada.
   * @throws {Error} No lanza errores por diseno.
   */
  MesaModel({
    required super.id,
    required super.nombre,
    required super.estado,
    required super.totalActual,
    required super.itemsPendientes,
    super.mozoAsignado, // 👈 Pasamos el dato al padre
  });

  /**
   * @description Construye un MesaModel desde JSON del backend.
   * @param {Map<String, dynamic>} json - Datos crudos del backend.
   * @returns {MesaModel} Modelo de mesa parseado.
   * @throws {Error} No lanza errores; usa defaults si faltan campos.
   */
  factory MesaModel.fromJson(Map<String, dynamic> json) {
    final mozoNombre = json['mozo_nombre'] ??
        ((json['mozo'] is Map<String, dynamic>)
            ? json['mozo']['nombre']
            : null);
    return MesaModel(
      id: int.parse(json['id'].toString()),
      nombre: json['nombre'] ?? 'Mesa ?',
      estado: json['estado'] ?? 'libre',
      totalActual: double.tryParse(json['totalActual'].toString()) ?? 0.0,
      itemsPendientes: int.tryParse(json['itemsPendientes'].toString()) ?? 0,
      mozoAsignado: (json['estado'] == 'ocupada')
          ? mozoNombre?.toString()
          : null,
    );
  }
}
