import '../models/pedido.dart';
import '../models/plato.dart';
import '../models/rubro_model.dart';

abstract class PedidoRepository {
  // ✅ Cambio clave: Ahora recibe mesaId y una lista de items (el carrito)
  /**
   * @description Inserta un pedido con sus items en el backend.
   * @param {String} mesaId - Identificador de la mesa.
   * @param {List<Pedido>} carrito - Items del pedido.
   * @returns {Future<int>} Id del pedido creado.
   * @throws {Exception} Error de red o backend.
   */
  Future<int> insertPedido(String mesaId, List<Pedido> carrito);

  /**
   * @description Obtiene el historial completo de pedidos.
   * @returns {Future<List<Pedido>>} Lista de pedidos.
   * @throws {Exception} Error de red o backend.
   */
  Future<List<Pedido>> getPedidos();
  /**
   * @description Obtiene pedidos filtrados por mesa.
   * @param {String} mesa - Numero o id de mesa.
   * @returns {Future<List<Pedido>>} Lista de pedidos de la mesa.
   * @throws {Exception} Error de red o backend.
   */
  Future<List<Pedido>> getPedidosPorMesa(String mesa);
  /**
   * @description Obtiene el menu de platos.
   * @param {bool} forceOnline - Si es true, fuerza carga desde backend sin fallback offline.
   * @returns {Future<List<Plato>>} Lista de platos.
   * @throws {Exception} Error de red o backend.
   */
  Future<List<Plato>> getMenu({bool forceOnline = false});
  /**
   * @description Obtiene la lista de rubros.
   * @returns {Future<List<Rubro>>} Lista de rubros.
   * @throws {Exception} Error de red o backend.
   */
  Future<List<Rubro>> getRubros(); // ✅ Nuevo método

  /// Elimina completamente un pedido por ID
  /**
   * @description Elimina un pedido completo por id.
   * @param {int} id - Id del pedido.
   * @returns {Future<void>} Operacion asincronica sin valor de retorno.
   * @throws {Exception} Error de red o backend.
   */
  Future<void> deletePedido(int id);

  /// Actualiza/modifica un pedido completo (cantidad, aclaración, etc)
 /// El backend mantiene el ID original
 /**
  * @description Modifica un pedido completo en el backend.
  * @param {int} pedidoId - Id del pedido a modificar.
  * @param {String} mesa - Numero o id de mesa.
  * @param {List<Pedido>} pedidoModificado - Items modificados.
  * @returns {Future<void>} Operacion asincronica sin valor de retorno.
  * @throws {Exception} Error de red o backend.
  */
 Future<void> modificarPedido(int pedidoId, String mesa, List<Pedido> pedidoModificado);



  /**
   * @description Actualiza el estado de un pedido.
   * @param {int} id - Id del pedido.
   * @param {EstadoPedido} nuevoEstado - Estado nuevo.
   * @returns {Future<void>} Operacion asincronica sin valor de retorno.
   * @throws {Exception} Error de red o backend.
   */
  Future<void> updateEstado(int id, EstadoPedido nuevoEstado);
}
