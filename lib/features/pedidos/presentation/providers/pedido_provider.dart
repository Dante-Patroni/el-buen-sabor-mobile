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
  /**
   * @description Lista de rubros disponibles para la UI.
   * @returns {List<Rubro>} Rubros cargados.
   * @throws {Error} No lanza errores.
   */
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

  /**
   * @description Crea el provider de pedidos con repositorio inyectado.
   * @param {PedidoRepository} pedidoRepository - Repositorio de pedidos.
   * @returns {PedidoProvider} Instancia del provider.
   * @throws {Error} No lanza errores por diseno.
   */
  PedidoProvider({required this.pedidoRepository});

  /**
   * @description Indica si hay una operacion de carga en progreso.
   * @returns {bool} True si esta cargando; false si no.
   * @throws {Error} No lanza errores.
   */
  bool get isLoading => _isLoading;

  /**
   * @description Mensaje de error actual.
   * @returns {String} Mensaje de error o vacio.
   * @throws {Error} No lanza errores.
   */
  String get errorMessage => _errorMessage;

  /**
   * @description Normaliza un error a un mensaje legible.
   * @param {Object} e - Error capturado.
   * @param {String} fallback - Mensaje por defecto.
   * @returns {String} Mensaje normalizado.
   * @throws {Error} No lanza errores.
   */
  String _normalizarError(Object e, {String fallback = 'Error inesperado'}) {
    final msg = e.toString().replaceAll('Exception: ', '').trim();
    return msg.isEmpty ? fallback : msg;
  }

  /**
   * @description Calcula el total monetario del carrito.
   * @returns {double} Total del carrito.
   * @throws {Error} No lanza errores.
   */
  double get totalCarrito {
    return carrito.fold(0.0, (suma, pedido) {
      return suma + (pedido.total * pedido.cantidad);
    });
  }

  // ===========================================================================
  // 3️⃣ MÉTODOS DE LÓGICA DE NEGOCIO (BUSINESS LOGIC)
  // ===========================================================================

  /**
   * @description Inicializa menu, rubros y pedidos en memoria.
   * @param {bool} forceMenuOnline - Si es true, fuerza menu desde backend sin fallback offline.
   * @returns {Future<void>} Operacion asincronica sin valor de retorno.
   * @throws {Exception} Error de red o backend.
   */
  Future<void> inicializarDatos({bool forceMenuOnline = false}) async {
    _errorMessage = '';
    _isLoading = true;
    notifyListeners(); // 📢 Avisamos a la UI: "Hey, estoy cargando, muestra el spinner".

    try {
      // A. Cargar el Menú (Platos)
      // `await` significa: "Espera aquí hasta que el servidor responda antes de seguir".
      final menu = await pedidoRepository.getMenu(forceOnline: forceMenuOnline);
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
      _errorMessage = _normalizarError(
        e,
        fallback: "No se pudo conectar con el servidor.",
      );
      if (forceMenuOnline) {
        menuPlatos = [];
        _listaRubros = [];
      }
      debugPrint("Error en inicializarDatos: $e");
    } finally {
      // El bloque `finally` se ejecuta SIEMPRE, haya error o no.
      _isLoading = false;
      notifyListeners(); // 📢 Avisamos a la UI: "Ya terminé, redibújate".
    }
  }

  /**
   * @description Configura la mesa activa para nuevos pedidos.
   * @param {String} mesaId - Numero o id de mesa.
   * @returns {void} No retorna valor.
   * @throws {Error} No lanza errores.
   */
  void iniciarPedido(String mesaId) {
    mesaSeleccionada = mesaId;
    carrito
        .clear(); // Limpiamos el carrito anterior por seguridad, empezamos frescos.
    notifyListeners();
  }

  /**
   * @description Configura el nombre del cliente actual.
   * @param {String} nombre - Nombre del cliente.
   * @returns {void} No retorna valor.
   * @throws {Error} No lanza errores.
   */
  void setCliente(String nombre) {
    clienteActual = nombre;
    notifyListeners();
  }

  // ===========================================================================
  // 4️⃣ GESTIÓN DEL CARRITO (LÓGICA LOCAL)
  // ===========================================================================

  /**
   * @description Agrega un plato al carrito, diferenciando por aclaracion.
   * @param {Plato} plato - Plato a agregar.
   * @param {int} cantidad - Cantidad a agregar.
   * @param {String?} aclaracion - Nota opcional del pedido.
   * @returns {void} No retorna valor.
   * @throws {Error} No lanza errores.
   */
  void agregarAlCarrito(Plato plato, {int cantidad = 1, String? aclaracion}) {
    final nota = (aclaracion ?? '').trim();
    // Buscamos si ya está en la lista (plato + aclaración)
    final index = carrito.indexWhere(
      (p) => p.platoId == plato.id && (p.aclaracion ?? '').trim() == nota,
    );

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
        aclaracion: nota,
      );
      carrito.add(nuevoPedido);
    }
    notifyListeners(); // 📢 Actualiza el contador del carrito en la UI
  }

  /**
   * @description Elimina un item especifico del carrito.
   * @param {Pedido} pedido - Item a eliminar.
   * @returns {void} No retorna valor.
   * @throws {Error} No lanza errores.
   */
  void quitarDelCarrito(Pedido pedido) {
    final nota = (pedido.aclaracion ?? '').trim();
    carrito.removeWhere(
      (p) => p.platoId == pedido.platoId && (p.aclaracion ?? '').trim() == nota,
    );
    notifyListeners();
  }

  // ===========================================================================
  // 5️⃣ INTERACCIÓN CON EL SERVIDOR (PERSISTENCIA)
  // ===========================================================================

  /**
   * @description Confirma y envia el carrito al backend.
   * @returns {Future<bool>} True si tuvo exito; false si fallo.
   * @throws {Exception} Error de red o backend.
   */
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
      _errorMessage =
          _normalizarError(e, fallback: 'No se pudo confirmar el pedido.');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // 6️⃣ RECURSOS AUXILIARES (HELPERS)
  // ===========================================================================

  /**
   * @description Obtiene un plato por id desde el menu en memoria.
   * @param {int} id - Id del plato.
   * @returns {Plato} Plato encontrado o placeholder.
   * @throws {Error} No lanza errores; retorna placeholder si falla.
   */
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

  /**
   * @description Elimina un pedido historico y actualiza la UI.
   * @param {int} id - Id del pedido.
   * @returns {Future<bool>} True si tuvo exito; false si fallo.
   * @throws {Exception} Error de red o backend.
   */
  Future<bool> borrarPedidoHistorico(int id) async {
    try {
      // 1. Server API Call (si falla, no tocamos la UI local)
      await pedidoRepository.deletePedido(id);

      // 2. UI update
      listaPedidos.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _normalizarError(
        e,
        fallback: 'No se pudo eliminar el pedido.',
      );
      notifyListeners();
      return false;
    }
  }

  /**
   * @description Carga pedidos de una mesa especifica.
   * @param {String} mesa - Numero o id de mesa.
   * @returns {Future<void>} Operacion asincronica sin valor de retorno.
   * @throws {Exception} Error de red o backend.
   */
  Future<void> cargarPedidosDeMesa(String mesa) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (menuPlatos.isEmpty) {
        menuPlatos = await pedidoRepository.getMenu();
      }
      listaPedidos = await pedidoRepository.getPedidosPorMesa(mesa);
    } catch (e) {
      _errorMessage = _normalizarError(
        e,
        fallback: "No se pudo cargar los pedidos de la mesa.",
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// =========================================================================
  /// 🔄 MODIFICAR UN PEDIDO COMPLETO
  /// =========================================================================
  /**
   * @description Modifica un pedido completo y recarga datos.
   * @param {int} pedidoId - Id del pedido.
   * @param {String} mesa - Numero o id de mesa.
   * @param {List<Pedido>} pedidoModificado - Items modificados.
   * @returns {Future<bool>} True si tuvo exito; false si fallo.
   * @throws {Exception} Error de red o backend.
   */
  Future<bool> modificarPedido(int pedidoId, String mesa, List<Pedido> pedidoModificado) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Llamamos al repositorio para actualizar en el servidor
      await pedidoRepository.modificarPedido(pedidoId, mesa, pedidoModificado);

      // Si tuvo éxito, recargamos el historial de pedidos
      await inicializarDatos();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage =
          _normalizarError(e, fallback: 'No se pudo modificar el pedido.');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

}
