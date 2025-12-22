import '../models/pedido.dart';
import '../models/plato.dart';

abstract class PedidoRepository {
  // ✅ Cambio clave: Ahora recibe mesaId y una lista de items (el carrito)
  Future<int> insertPedido(String mesaId, List<Pedido> carrito);
  
  Future<List<Pedido>> getPedidos();
  Future<List<Plato>> getMenu();
  
  // Estos pueden quedar igual o ajustarse si necesitas borrar items del servidor
  Future<void> deletePedido(int id);
  Future<void> updateEstado(int id, EstadoPedido nuevoEstado);
}