//Esta es la interfaz que le dice al Provider qué funciones tiene disponibles, sin decirle cómo funcionan por dentro.

import '../models/pedido.dart';
import '../models/plato.dart';

abstract class PedidoRepository {
  // Métodos para Pedidos
  Future<int> insertPedido(String mesaId, List<Pedido> carrito);
  Future<List<Pedido>> getPedidos();
  Future<void> updateEstado(int id, EstadoPedido nuevoEstado);
  Future<void> deletePedido(int id);

  // Método auxiliar para obtener el Menú (Platos)
  // En el futuro, esto vendrá de tu API, hoy vendrá de un Mock o SQLite
  Future<List<Plato>> getMenu();
}
