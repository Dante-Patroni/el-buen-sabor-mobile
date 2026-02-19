import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:el_buen_sabor_app/features/pedidos/domain/models/pedido.dart';
import 'package:el_buen_sabor_app/features/pedidos/domain/models/plato.dart';
import 'package:el_buen_sabor_app/features/pedidos/domain/models/rubro_model.dart';
import 'package:el_buen_sabor_app/features/pedidos/domain/repositories/pedido_repository.dart';
import 'package:el_buen_sabor_app/features/pedidos/presentation/providers/pedido_provider.dart';

import 'pedido_provider_test.mocks.dart';

@GenerateMocks([PedidoRepository])
void main() {
  late MockPedidoRepository repository;
  late PedidoProvider provider;

  // ── Helper: plato de prueba ──────────────────────────────────────────────
  Plato platoDeEjemplo() => Plato(
        id: 1,
        nombre: 'Milanesa',
        precio: 1500.0,
        descripcion: 'Con papas fritas',
        imagenPath: '',
        esMenuDelDia: false,
        categoria: 'Platos',
        stock:
            StockInfo(cantidad: 10, esIlimitado: false, estado: 'DISPONIBLE'),
      );

  // ── Helper: pedido de prueba (ya confirmado en servidor) ─────────────────
  Pedido pedidoDeEjemplo() => Pedido(
        id: 42,
        mesa: '3',
        cliente: 'Cliente App',
        platoId: 1,
        cantidad: 2,
        total: 1500.0,
        estado: EstadoPedido.pendiente,
      );

  // ── Helper: stub mínimo para inicializarDatos ────────────────────────────
  void stubInicializar() {
    when(repository.getMenu()).thenAnswer((_) async => []);
    when(repository.getRubros()).thenAnswer((_) async => <Rubro>[]);
    when(repository.getPedidos()).thenAnswer((_) async => []);
  }

  setUp(() {
    repository = MockPedidoRepository();
    provider = PedidoProvider(pedidoRepository: repository);
  });

  // =========================================================================
  // 🛒 GESTIÓN DEL CARRITO (lógica local — sin red)
  // =========================================================================

  group('Carrito', () {
    test('agregarAlCarrito añade un item nuevo', () {
      provider.iniciarPedido('5');
      provider.agregarAlCarrito(platoDeEjemplo());

      expect(provider.carrito.length, 1);
      expect(provider.carrito.first.platoId, 1);
      expect(provider.carrito.first.cantidad, 1);
    });

    test('agregarAlCarrito acumula cantidad si el plato ya existe', () {
      provider.iniciarPedido('5');
      provider.agregarAlCarrito(platoDeEjemplo());
      provider.agregarAlCarrito(platoDeEjemplo(), cantidad: 2);

      expect(provider.carrito.length, 1);
      expect(provider.carrito.first.cantidad, 3);
    });

    test('totalCarrito calcula correctamente el subtotal', () {
      provider.iniciarPedido('5');
      provider.agregarAlCarrito(platoDeEjemplo(), cantidad: 2);

      // 1500 * 2 = 3000
      expect(provider.totalCarrito, 3000.0);
    });

    test('quitarDelCarrito elimina el item del carrito', () {
      provider.iniciarPedido('5');
      provider.agregarAlCarrito(platoDeEjemplo());
      provider.quitarDelCarrito(provider.carrito.first);

      expect(provider.carrito.isEmpty, true);
    });

    test('confirmarPedido retorna false si el carrito está vacío', () async {
      final resultado = await provider.confirmarPedido();

      expect(resultado, false);
      verifyNever(repository.insertPedido(any, any));
    });
  });

  // =========================================================================
  // 🚀 CONFIRMAR PEDIDO (interacción con el servidor)
  // =========================================================================

  group('Confirmar Pedido', () {
    test('confirmarPedido llama a insertPedido y luego recarga datos',
        () async {
      stubInicializar();
      when(repository.insertPedido(any, any)).thenAnswer((_) async => 99);

      provider.iniciarPedido('3');
      provider.agregarAlCarrito(platoDeEjemplo());

      final resultado = await provider.confirmarPedido();

      expect(resultado, true);
      expect(provider.carrito.isEmpty, true); // carrito vaciado
      verify(repository.insertPedido('3', any)).called(1);
      verify(repository.getMenu()).called(1); // recargó datos
    });

    test('confirmarPedido retorna false y guarda error si el servidor falla',
        () async {
      when(repository.insertPedido(any, any))
          .thenThrow(Exception('Stock insuficiente'));

      provider.iniciarPedido('3');
      provider.agregarAlCarrito(platoDeEjemplo());

      final resultado = await provider.confirmarPedido();

      expect(resultado, false);
      expect(provider.errorMessage, isNotEmpty);
      expect(provider.isLoading, false);
    });
  });

  // =========================================================================
  // 🗑️ BORRAR PEDIDO HISTÓRICO
  // =========================================================================

  group('Borrar Pedido Histórico', () {
    test(
        'borrarPedidoHistorico elimina del estado local antes de llamar al servidor',
        () async {
      stubInicializar();
      when(repository.deletePedido(42)).thenAnswer((_) async {});

      // Simulamos que ya hay un pedido en la lista
      provider.listaPedidos = [pedidoDeEjemplo()];

      await provider.borrarPedidoHistorico(42);

      expect(provider.listaPedidos.isEmpty, true); // borrado optimista
      verify(repository.deletePedido(42)).called(1);
    });
  });

  // =========================================================================
  // 🔄 MODIFICAR PEDIDO
  // =========================================================================

  group('Modificar Pedido', () {
    test('modificarPedido llama al repository y recarga datos si tiene éxito',
        () async {
      stubInicializar();
      when(repository.modificarPedido(any, any, any)).thenAnswer((_) async {});

      final resultado =
          await provider.modificarPedido(42, '3', [pedidoDeEjemplo()]);

      expect(resultado, true);
      expect(provider.isLoading, false);
      verify(repository.modificarPedido(42, '3', any)).called(1);
      verify(repository.getMenu()).called(1); // recargó datos
    });

    test('modificarPedido retorna false si el servidor lanza excepción',
        () async {
      when(repository.modificarPedido(any, any, any))
          .thenThrow(Exception('Error de red'));

      final resultado =
          await provider.modificarPedido(42, '3', [pedidoDeEjemplo()]);

      expect(resultado, false);
      expect(provider.errorMessage, isNotEmpty);
      expect(provider.isLoading, false);
    });
  });

  // =========================================================================
  // 📦 INICIALIZAR DATOS
  // =========================================================================

  group('Inicializar Datos', () {
    test('inicializarDatos carga menú, rubros y pedidos correctamente',
        () async {
      final platos = [platoDeEjemplo()];
      final pedidos = [pedidoDeEjemplo()];

      when(repository.getMenu()).thenAnswer((_) async => platos);
      when(repository.getRubros()).thenAnswer((_) async => <Rubro>[]);
      when(repository.getPedidos()).thenAnswer((_) async => pedidos);

      await provider.inicializarDatos();

      expect(provider.menuPlatos.length, 1);
      expect(provider.listaPedidos.length, 1);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, '');
    });

    test('inicializarDatos maneja error de conexión sin romper la app',
        () async {
      when(repository.getMenu()).thenThrow(Exception('Sin internet'));
      when(repository.getRubros()).thenAnswer((_) async => <Rubro>[]);
      when(repository.getPedidos()).thenAnswer((_) async => []);

      await provider.inicializarDatos();

      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNotEmpty);
    });
  });
}
