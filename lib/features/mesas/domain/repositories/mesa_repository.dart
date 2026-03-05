import '../models/mesa.dart';

abstract class MesaRepository {
  /**
   * @description Obtiene el listado de mesas desde el backend.
   * @returns {Future<List<Mesa>>} Lista de mesas.
   * @throws {Exception} Error de red o backend.
   */
  Future<List<Mesa>> getMesas();

  /**
   * @description Abre u ocupa una mesa asignando un mozo.
   * @param {int} idMesa - Identificador de la mesa.
   * @param {int} idMozo - Identificador del mozo.
   * @returns {Future<void>} Operacion asincronica sin valor de retorno.
   * @throws {Exception} Error de red o backend.
   */
  Future<void> abrirMesa(int idMesa, int idMozo);
  
  /**
   * @description Cierra la mesa y retorna el total cobrado.
   * @param {int} idMesa - Identificador de la mesa.
   * @returns {Future<double>} Total cobrado.
   * @throws {Exception} Error de red o backend.
   */
  Future<double> cerrarMesa(int idMesa);
}
