import '../models/pedido.dart';
import '../models/plato.dart';
import '../models/rubro_model.dart';

abstract class PedidoRepository {
  // ✅ Cambio clave: Ahora recibe mesaId y una lista de items (el carrito)
  Future<int> insertPedido(String mesaId, List<Pedido> carrito);

  Future<List<Pedido>> getPedidos();
  Future<List<Plato>> getMenu();
  Future<List<Rubro>> getRubros(); // ✅ Nuevo método

  /// Elimina completamente un pedido por ID
  Future<void> deletePedido(int id);

  /// Actualiza/modifica un pedido completo (cantidad, aclaración, etc)
/// El backend mantiene el ID original
Future<void> modificarPedido(int pedidoId, String mesa, List<Pedido> pedidoModificado);



  Future<void> updateEstado(int id, EstadoPedido nuevoEstado);
}
