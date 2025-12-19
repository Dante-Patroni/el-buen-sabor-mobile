import 'package:flutter/material.dart';
import '../../domain/models/pedido.dart';
import '../../domain/models/plato.dart';
import '../../domain/repositories/pedido_repository.dart';

class PedidoProvider extends ChangeNotifier {
  // 💉 Inyección de Dependencias
  final PedidoRepository pedidoRepository;

  // 📦 Variables de Estado
  List<Pedido> listaPedidos = []; // Historial de pedidos de la base de datos
  List<Pedido> carrito = []; // Pedidos nuevos que se van a enviar
  List<Plato> menuPlatos = []; // El menú completo descargado del servidor

  // ⚙️ Configuración del Pedido Actual
  String mesaSeleccionada = "Mesa 4";
  String clienteActual = "Cliente Anónimo"; // 👈 Faltaba esta variable

  // 🔄 Estado de UI
  bool _isLoading = false;
  String _errorMessage = "";

  // Constructor
  PedidoProvider({required this.pedidoRepository});

  // Getters para la UI
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  double get totalCarrito {
    return carrito.fold(0.0, (suma, pedido) {
      return suma + (pedido.total * pedido.cantidad);
    });
  }
  // ===============================================================
  // 1️⃣ MÉTODOS DE INICIALIZACIÓN Y CARGA
  // ===============================================================

  // Se llama al iniciar la pantalla principal para descargar datos
  Future<void> inicializarDatos() async {
    _isLoading = true;
    notifyListeners();

    try {
      print("🔄 Cargando datos del servidor...");

      // A. Cargar el Menú (Platos)
      final menu = await pedidoRepository.getMenu();
      menuPlatos = menu;

      // B. Cargar el Historial de Pedidos (Para ver qué pidieron antes)
      final pedidosBackend = await pedidoRepository.getPedidos();
      listaPedidos = pedidosBackend;

      print(
        "✅ Datos cargados: ${menuPlatos.length} platos y ${listaPedidos.length} pedidos históricos.",
      );
    } catch (e) {
      print("❌ Error cargando datos: $e");
      _errorMessage = "No se pudo conectar con el servidor.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===============================================================
  // 2️⃣ MÉTODOS DE CONFIGURACIÓN (MESA Y CLIENTE)
  // ===============================================================

  // Se llama al entrar al detalle de una mesa
  void iniciarPedido(String mesaId) {
    mesaSeleccionada = mesaId;
    carrito.clear(); // Limpiamos el carrito anterior por seguridad
    notifyListeners();
    print("🚀 Iniciando sesión para la Mesa: $mesaId");
  }

  // Guarda el nombre para el ticket
  void setCliente(String nombre) {
    clienteActual = nombre;
    notifyListeners();
  }

  // ===============================================================
  // 3️⃣ GESTIÓN DEL CARRITO (LÓGICA LOCAL)
  // ===============================================================

  void agregarAlCarrito(Plato plato) {
    // Verificamos si el plato ya está en el carrito
    final index = carrito.indexWhere((p) => p.platoId == plato.id);

    if (index != -1) {
      // CASO A: Ya existe -> Aumentamos la cantidad (+1)
      print("➕ Aumentando cantidad de: ${plato.nombre}");
      carrito[index] = carrito[index].copyWith(
        cantidad: carrito[index].cantidad + 1,
      );
    } else {
      // CASO B: Es nuevo -> Creamos el Pedido
      print("🆕 Agregando nuevo plato: ${plato.nombre}");
      final nuevoPedido = Pedido(
        mesa: mesaSeleccionada, // Usa la variable de estado
        cliente: clienteActual, // Usa la variable de estado
        platoId: plato.id,
        total: plato.precio,
        cantidad: 1,
        estado: EstadoPedido.pendiente,
        aclaracion: "",
      );
      carrito.add(nuevoPedido);
    }
    notifyListeners();
  }

  void quitarDelCarrito(Pedido pedido) {
    carrito.removeWhere((p) => p.platoId == pedido.platoId);
    notifyListeners();
    print("🗑️ Plato eliminado del carrito");
  }

  // ===============================================================
  // 4️⃣ ENVÍO AL SERVIDOR
  // ===============================================================

  Future<bool> confirmarPedido() async {
    if (carrito.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      print("📤 Enviando pedido de ${carrito.length} items...");

      // Enviamos la mesa y la lista completa al repositorio
      await pedidoRepository.insertPedido(mesaSeleccionada, carrito);

      // Si todo sale bien:
      carrito.clear();
      _isLoading = false;

      // Opcional: Recargar el historial para ver el pedido nuevo en la lista
      await inicializarDatos();

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      print("❌ Error al confirmar: $e");
      notifyListeners();
      return false;
    }
  }

  // ===============================================================
  // 5️⃣ UTILIDADES
  // ===============================================================

  // Busca un plato por su ID para mostrar nombre/precio en el historial
  // 🔍 BUSCADOR DE PLATOS POR ID (CORREGIDO)
  Plato getPlatoById(int id) {
    try {
      // 👇 AGREGAMOS .cast<Plato>() AQUÍ
      // Esto evita el conflicto entre Plato y PlatoModel
      return menuPlatos.cast<Plato>().firstWhere(
        (plato) => plato.id == id,

        orElse: () {
          // Si no lo encuentra, devolvemos un objeto Plato genérico
          return Plato(
            id: id,
            nombre: 'Falta Plato (ID: $id)',
            precio: 0.0,
            descripcion: 'El producto no existe en el menú actual.',
            imagenPath: '',
            esMenuDelDia: false,
            categoria: 'Sistema',
            stock: StockInfo(
              cantidad: 0,
              esIlimitado: false,
              estado: 'AGOTADO',
            ),
          );
        },
      );
    } catch (e) {
      print("🔥 ERROR CRÍTICO: $e");
      // Fallback de seguridad
      return Plato(
        id: 0,
        nombre: 'Error Interno',
        precio: 0.0,
        descripcion: e.toString(),
        imagenPath: '',
        esMenuDelDia: false,
        categoria: 'Error',
        stock: StockInfo(cantidad: 0, esIlimitado: false, estado: 'AGOTADO'),
      );
    }
  }

  // 🗑️ BORRAR DEL HISTORIAL (Backend)
  // Elimina un pedido confirmado de la base de datos y de la lista visual
  Future<void> borrarPedidoHistorico(int id) async {
    try {
      print("🗑️ Intentando borrar pedido histórico ID: $id");

      // 1. ACTUALIZACIÓN OPTIMISTA (UI)
      // Lo borramos de la lista local inmediatamente para que la app se sienta rápida
      listaPedidos.removeWhere((p) => p.id == id);
      notifyListeners();

      // 2. LLAMADA AL SERVIDOR
      // Le decimos al backend que lo borre definitivamente
      await pedidoRepository.deletePedido(id);

      print("✅ Pedido $id eliminado correctamente del servidor.");
    } catch (e) {
      print("❌ Error eliminando pedido: $e");

      // Si falla el servidor, recargamos la lista para que el pedido vuelva a aparecer
      // (Así el usuario sabe que no se borró)
      await inicializarDatos();
    }
  }
}
