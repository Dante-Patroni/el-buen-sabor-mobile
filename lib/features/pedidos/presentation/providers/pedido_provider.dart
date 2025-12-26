import 'package:flutter/material.dart';
import '../../domain/models/pedido.dart';
import '../../domain/models/plato.dart';
import '../../domain/models/rubro_model.dart';
import '../../domain/repositories/pedido_repository.dart';

/// **PedidoProvider**
///
/// Esta clase actúa como el **Gestor de Estado (State Manager)** para todo lo relacionado con los pedidos.
/// Utiliza el patrón **Provider** (ChangeNotifier) para notificar a la interfaz gráfica (UI)
/// cuando hay cambios en los datos, provocando que los widgets se redibujen automáticamente.
///
/// **Conceptos Clave:**
/// - `ChangeNotifier`: Clase base de Flutter que nos permite usar `notifyListeners()` para avisar cambios.
/// - `Inyección de Dependencias`: Recibimos el repositorio en el constructor, desacoplando la lógica de la fuente de datos.
class PedidoProvider extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // 1️⃣ INYECCIÓN DE DEPENDENCIAS Y VARIABLES PRIVADAS
  // ---------------------------------------------------------------------------

  /// El repositorio es nuestra única fuente de verdad para hablar con el Backend.
  /// No llamamos a HTTP aquí directamente; le pedimos al repositorio que lo haga.
  final PedidoRepository pedidoRepository;

  // 📦 Variables de Estado (Datos que la UI necesita mostrar)

  /// Lista histórica de pedidos (Lo que ya se pidió y se guardó en BD).
  List<Pedido> listaPedidos = [];

  /// El "Carrito de Compras" temporal. Son pedidos que están en memoria pero NO se han enviado al servidor aún.
  List<Pedido> carrito = [];

  /// El Catálogo completo de productos disponibles, descargado del servidor.
  List<Plato> menuPlatos = [];

  // ✅ Nueva Lista de Rubros (Jerarquía)
  List<Rubro> _listaRubros = [];
  List<Rubro> get listaRubros => _listaRubros;

  // ⚙️ Configuración del Contexto Actual
  String mesaSeleccionada = "1";
  String clienteActual = "Cliente Anónimo";

  // 🔄 Estado de Carga y Errores (Feedback para el usuario)
  bool _isLoading = false;
  String _errorMessage = "";

  // ---------------------------------------------------------------------------
  // 2️⃣ CONSTRUCTOR Y GETTERS
  // ---------------------------------------------------------------------------

  /// Constructor que exige un repositorio. Esto facilita las pruebas (testing) ya que
  /// podemos pasar un "Repositorio Falso" (Mock) si quisiéramos probar sin internet.
  PedidoProvider({required this.pedidoRepository});

  /// Getter para saber si la app está "pensando" (cargando datos).
  /// La UI usa esto para mostrar el `CircularProgressIndicator`.
  bool get isLoading => _isLoading;

  /// Getter para obtener mensajes de error si algo falla.
  String get errorMessage => _errorMessage;

  /// **Propiedad Computada (Computed Property)**
  /// Calcula el total monetario del carrito en tiempo real.
  /// Se usa `.fold` que es como un bucle `for` pero funcional y más elegante.
  double get totalCarrito {
    return carrito.fold(0.0, (suma, pedido) {
      return suma + (pedido.total * pedido.cantidad);
    });
  }

  // ===========================================================================
  // 3️⃣ MÉTODOS DE LÓGICA DE NEGOCIO (BUSINESS LOGIC)
  // ===========================================================================

  /// **inicializarDatos**
  ///
  /// Método asíncrono (`async`) encargado de preparar todo al abrir la pantalla.
  ///
  /// **Flujo:**
  /// 1. Activa el estado de carga (`_isLoading = true`).
  /// 2. Pide al repositorio el menú y el historial de pedidos en paralelo (o secuencial).
  /// 3. Guarda los datos en las variables locales.
  /// 4. Desactiva la carga y avisa a la UI (`notifyListeners`) para que muestre los datos.
  Future<void> inicializarDatos() async {
    _isLoading = true;
    notifyListeners(); // 📢 Avisamos a la UI: "Hey, estoy cargando, muestra el spinner".

    try {
      // A. Cargar el Menú (Platos)
      // `await` significa: "Espera aquí hasta que el servidor responda antes de seguir".
      final menu = await pedidoRepository.getMenu();
      menuPlatos = menu;

      // B. Cargar Rubros (Nuevo)
      final rubrosBackend = await pedidoRepository.getRubros();
      _listaRubros = rubrosBackend;
      debugPrint("🌳 Rubros cargados: ${_listaRubros.length}");

      // C. Cargar el Historial de Pedidos (Para ver qué pidieron antes)
      final pedidosBackend = await pedidoRepository.getPedidos();
      listaPedidos = pedidosBackend;
    } catch (e) {
      // Si algo falla (ej: sin internet), guardamos el error para mostrarlo
      _errorMessage = "No se pudo conectar con el servidor.";
      debugPrint("Error en inicializarDatos: $e");
    } finally {
      // El bloque `finally` se ejecuta SIEMPRE, haya error o no.
      _isLoading = false;
      notifyListeners(); // 📢 Avisamos a la UI: "Ya terminé, redibújate".
    }
  }

  /// Configura el contexto de la mesa actual para saber a quién asignar los nuevos pedidos.
  void iniciarPedido(String mesaId) {
    mesaSeleccionada = mesaId;
    carrito
        .clear(); // Limpiamos el carrito anterior por seguridad, empezamos frescos.
    notifyListeners();
  }

  /// Establece el nombre del cliente (opcional) para imprimirlo en el ticket luego.
  void setCliente(String nombre) {
    clienteActual = nombre;
    notifyListeners();
  }

  // ===========================================================================
  // 4️⃣ GESTIÓN DEL CARRITO (LÓGICA LOCAL)
  // ===========================================================================

  /// Agrega un plato al carrito temporal.
  ///
  /// **Lógica:**
  /// - Busca si el plato ya existe en el carrito.
  /// - **Si existe**: Solo actualizamos la cantidad (para no tener filas duplicadas).
  /// - **Si no existe**: Creamos una nueva instancia de `Pedido` y la agregamos a la lista.
  void agregarAlCarrito(Plato plato, {int cantidad = 1, String? aclaracion}) {
    // Buscamos si ya está en la lista (devuelve -1 si no está)
    final index = carrito.indexWhere((p) => p.platoId == plato.id);

    if (index != -1) {
      // CASO A: Ya existe -> Modificamos el objeto existente usando `copyWith` (Inmutabilidad parcial)
      carrito[index] = carrito[index].copyWith(
        cantidad: carrito[index].cantidad + cantidad,
      );
    } else {
      // CASO B: Es nuevo -> Creamos el objeto Pedido desde cero
      final nuevoPedido = Pedido(
        mesa: mesaSeleccionada,
        cliente: clienteActual,
        platoId: plato.id,
        total: plato.precio,
        cantidad: cantidad,
        estado: EstadoPedido.pendiente,
        aclaracion: aclaracion ?? "",
      );
      carrito.add(nuevoPedido);
    }
    notifyListeners(); // 📢 Actualiza el contador del carrito en la UI
  }

  /// Elimina un ítem específico del carrito.
  void quitarDelCarrito(Pedido pedido) {
    carrito.removeWhere((p) => p.platoId == pedido.platoId);
    notifyListeners();
  }

  // ===========================================================================
  // 5️⃣ INTERACCIÓN CON EL SERVIDOR (PERSISTENCIA)
  // ===========================================================================

  /// Confirma y envía todos los ítems del CArrito al Backend.
  /// Retorna `true` si tuvo éxito, `false` si falló.
  Future<bool> confirmarPedido() async {
    if (carrito.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // Enviamos la mesa y la lista completa al repositorio
      await pedidoRepository.insertPedido(mesaSeleccionada, carrito);

      // Si llegamos aquí, es que no hubo excepción (Todo salió bien 200 OK)
      carrito.clear(); // Vaciamos el carrito local
      _isLoading = false;

      // Recargamos el historial para que el usuario vea su pedido recién creado en la lista "Pedidos Realizados"
      await inicializarDatos();

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // 6️⃣ RECURSOS AUXILIARES (HELPERS)
  // ===========================================================================

  /// Busca la información completa de un plato dado su ID.
  /// Útil porque el historial de pedidos solo trae el `platoId`, y necesitamos
  /// buscar el nombre y la imagen en el `menuPlatos` que tenemos en memoria.
  Plato getPlatoById(int id) {
    try {
      // `cast<Plato>()` asegura que Dart trate la lista como objetos Plato puros.
      return menuPlatos.cast<Plato>().firstWhere(
        (plato) => plato.id == id,
        orElse: () {
          // Si no lo encuentra, devolvemos un objeto "Dummy" o Placeholder para que la app no explote.
          return Plato(
            id: id,
            nombre: 'Plato Descatalogado (ID: $id)',
            precio: 0.0,
            descripcion: 'El producto ya no existe en el menú actual.',
            imagenPath: '',
            esMenuDelDia: false,
            categoria: 'Sistema',
            stock:
                StockInfo(cantidad: 0, esIlimitado: false, estado: 'AGOTADO'),
          );
        },
      );
    } catch (e) {
      // Fallback de seguridad extrema
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

  /// Eliminación Optimista (Optimistic UI Update):
  /// 1. Primero borramos el ítem de la lista visual (inmediato).
  /// 2. Luego llamamos al servidor.
  /// Si el servidor falla, revertimos el cambio (recargamos).
  /// Esto hace que la app se sienta instantánea.
  Future<void> borrarPedidoHistorico(int id) async {
    try {
      // 1. UI update
      listaPedidos.removeWhere((p) => p.id == id);
      notifyListeners();

      // 2. Server API Call
      await pedidoRepository.deletePedido(id);
    } catch (e) {
      // Rollback (Deshacer) si falla: volvemos a cargar todo
      await inicializarDatos();
    }
  }
}
