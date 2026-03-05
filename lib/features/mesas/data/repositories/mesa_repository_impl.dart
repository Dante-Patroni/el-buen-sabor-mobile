import '../../domain/models/mesa.dart';
import '../../domain/repositories/mesa_repository.dart';
import '../datasources/mesa_datasource.dart';

class MesaRepositoryImpl implements MesaRepository {
  final MesaDataSource dataSource;

  /**
   * @description Crea el repositorio de mesas con su data source.
   * @param {MesaDataSource} dataSource - Fuente de datos HTTP.
   * @returns {MesaRepositoryImpl} Instancia del repositorio.
   * @throws {Error} No lanza errores por diseno.
   */
  MesaRepositoryImpl(this.dataSource);

  @override
  /**
   * @description Obtiene mesas desde el data source.
   * @returns {Future<List<Mesa>>} Lista de mesas.
   * @throws {Exception} Error de red o backend.
   */
  Future<List<Mesa>> getMesas() async {
    final modelos = await dataSource.getMesasFromApi();
    return modelos; // MesaModel ES un Mesa
  }

  @override
  /**
   * @description Abre u ocupa una mesa asignando un mozo.
   * @param {int} idMesa - Identificador de la mesa.
   * @param {int} idMozo - Identificador del mozo.
   * @returns {Future<void>} Operacion asincronica sin valor de retorno.
   * @throws {Exception} Error de red o backend.
   */
  Future<void> abrirMesa(int idMesa, int idMozo) {
    return dataSource.abrirMesa(idMesa, idMozo);
  }

  @override
  /**
   * @description Cierra una mesa y retorna el total cobrado.
   * @param {int} idMesa - Identificador de la mesa.
   * @returns {Future<double>} Total cobrado.
   * @throws {Exception} Error de red o backend.
   */
  Future<double> cerrarMesa(int idMesa) {
    return dataSource.cerrarMesa(idMesa);
  }
}
