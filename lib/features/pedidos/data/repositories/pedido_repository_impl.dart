import '../../domain/models/pedido.dart';
import '../../domain/models/plato.dart';
import '../../domain/models/rubro_model.dart';
import '../../domain/repositories/pedido_repository.dart';
import '../datasources/pedido_datasource.dart';

/// **PedidoRepositoryImpl**
///
/// Implementación concreta del contrato `PedidoRepository`.
///
/// Responsabilidad: traducir entre el lenguaje del Dominio (entidades puras)
/// y el lenguaje del DataSource (modelos con JSON/SQLite).
/// NO hace HTTP ni SQLite directamente — eso es trabajo del `PedidoDataSource`.
///
/// Arquitectura:
/// ```
/// PedidoProvider → PedidoRepository → [PedidoRepositoryImpl] → PedidoDataSource → Backend / SQLite
/// ```
class PedidoRepositoryImpl implements PedidoRepository {
  final PedidoDataSource dataSource;

  /**
   * @description Crea el repositorio de pedidos con su data source.
   * @param {PedidoDataSource} dataSource - Fuente de datos.
   * @returns {PedidoRepositoryImpl} Instancia del repositorio.
   * @throws {Error} No lanza errores por diseno.
   */
  PedidoRepositoryImpl(this.dataSource);

  @override
  /**
   * @description Obtiene el menu desde el data source.
   * @param {bool} forceOnline - Si es true, fuerza carga desde backend sin fallback offline.
   * @returns {Future<List<Plato>>} Lista de platos.
   * @throws {Exception} Error de red o backend.
   */
  Future<List<Plato>> getMenu({bool forceOnline = false}) {
    return dataSource.getMenu(forceOnline: forceOnline);
  }

  @override
  /**
   * @description Obtiene rubros desde el data source.
   * @returns {Future<List<Rubro>>} Lista de rubros.
   * @throws {Exception} Error de red o backend.
   */
  Future<List<Rubro>> getRubros() {
    return dataSource.getRubros();
  }

  @override
  /**
   * @description Obtiene pedidos desde el data source.
   * @returns {Future<List<Pedido>>} Lista de pedidos.
   * @throws {Exception} Error de red o backend.
   */
  Future<List<Pedido>> getPedidos() {
    return dataSource.getPedidos();
  }

  @override
  /**
   * @description Obtiene pedidos por mesa desde el data source.
   * @param {String} mesa - Numero o id de mesa.
   * @returns {Future<List<Pedido>>} Lista de pedidos.
   * @throws {Exception} Error de red o backend.
   */
  Future<List<Pedido>> getPedidosPorMesa(String mesa) {
    return dataSource.getPedidosPorMesa(mesa);
  }

  @override
  /**
   * @description Inserta un pedido y retorna su id.
   * @param {String} mesaId - Identificador de mesa.
   * @param {List<Pedido>} carrito - Items del pedido.
   * @returns {Future<int>} Id del pedido creado.
   * @throws {Exception} Error de red o backend.
   */
  Future<int> insertPedido(String mesaId, List<Pedido> carrito) {
    return dataSource.insertPedido(mesaId, carrito);
  }

  @override
  /**
   * @description Elimina un pedido completo.
   * @param {int} id - Id del pedido.
   * @returns {Future<void>} Operacion asincronica sin valor de retorno.
   * @throws {Exception} Error de red o backend.
   */
  Future<void> deletePedido(int id) {
    return dataSource.deletePedido(id);
  }

  @override
  /**
   * @description Modifica un pedido completo.
   * @param {int} pedidoId - Id del pedido.
   * @param {String} mesa - Numero o id de mesa.
   * @param {List<Pedido>} pedidoModificado - Items modificados.
   * @returns {Future<void>} Operacion asincronica sin valor de retorno.
   * @throws {Exception} Error de red o backend.
   */
  Future<void> modificarPedido(
      int pedidoId, String mesa, List<Pedido> pedidoModificado) {
    return dataSource.modificarPedido(pedidoId, mesa, pedidoModificado);
  }

  @override
  /**
   * @description Actualiza el estado de un pedido (pendiente de implementar).
   * @param {int} id - Id del pedido.
   * @param {EstadoPedido} nuevoEstado - Estado nuevo.
   * @returns {Future<void>} Operacion asincronica sin valor de retorno.
   * @throws {Error} No lanza errores; no implementado.
   */
  Future<void> updateEstado(int id, EstadoPedido nuevoEstado) async {
    // TODO: Implementar en DataSource cuando el backend lo soporte
  }
}
