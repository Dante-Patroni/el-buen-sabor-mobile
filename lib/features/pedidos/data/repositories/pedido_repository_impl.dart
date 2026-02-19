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

  PedidoRepositoryImpl(this.dataSource);

  @override
  Future<List<Plato>> getMenu() {
    return dataSource.getMenu();
  }

  @override
  Future<List<Rubro>> getRubros() {
    return dataSource.getRubros();
  }

  @override
  Future<List<Pedido>> getPedidos() {
    return dataSource.getPedidos();
  }

  @override
  Future<int> insertPedido(String mesaId, List<Pedido> carrito) {
    return dataSource.insertPedido(mesaId, carrito);
  }

  @override
  Future<void> deletePedido(int id) {
    return dataSource.deletePedido(id);
  }

  @override
  Future<void> modificarPedido(
      int pedidoId, String mesa, List<Pedido> pedidoModificado) {
    return dataSource.modificarPedido(pedidoId, mesa, pedidoModificado);
  }

  @override
  Future<void> updateEstado(int id, EstadoPedido nuevoEstado) async {
    // TODO: Implementar en DataSource cuando el backend lo soporte
  }
}
