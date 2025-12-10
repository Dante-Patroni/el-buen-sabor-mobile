import 'package:flutter/material.dart';
import '../../domain/models/pedido.dart';
import '../../domain/models/plato.dart';
import '../../domain/repositories/pedido_repository.dart';

class PedidoProvider extends ChangeNotifier {
  final PedidoRepository _repository;

  PedidoProvider(this._repository);

  // ======================================================
  // 1. ESTADO DEL BACKEND (Historial y Menú) ☁️
  // ======================================================
  List<Pedido> _listaPedidosHistoricos = [];
  List<Plato> _menuPlatos = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters Backend
  List<Pedido> get listaPedidos => _listaPedidosHistoricos;
  List<Plato> get menuPlatos => _menuPlatos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ======================================================
  // 2. ESTADO LOCAL (El Carrito / Borrador) 🛒
  // ======================================================
  final List<Plato> _carrito = [];
  String _mesaSeleccionada = '';
  String _clienteActual = '';

  // Getters Carrito
  List<Plato> get carrito => _carrito;
  String get mesaSeleccionada => _mesaSeleccionada;
  String get clienteActual => _clienteActual;

  // Calculamos el total $$ del carrito en tiempo real
  double get totalCarrito {
    return _carrito.fold(0, (sum, plato) => sum + plato.precio);
  }

  // ======================================================
  // 3. MÉTODOS DEL CARRITO (Lógica Local - EBS-15) 📝
  // ======================================================

  // A. Iniciar una nueva toma de pedido
  void iniciarPedido(String numeroMesa) {
    _mesaSeleccionada = numeroMesa;
    _clienteActual = ''; // Empieza vacío, y ahora es opcional
    _carrito.clear();
    _errorMessage = null;
    notifyListeners();
  }

  // B. Establecer nombre del cliente (Opcional)
  void setCliente(String nombre) {
    _clienteActual = nombre;
    notifyListeners();
  }

  // C. Agregar plato al borrador
  void agregarAlCarrito(Plato plato) {
    _carrito.add(plato);
    notifyListeners();
  }

  // D. Quitar plato del borrador
  void quitarDelCarrito(int index) {
    _carrito.removeAt(index);
    notifyListeners();
  }

  // ======================================================
  // 4. MÉTODOS DE CONEXIÓN (API) 🔌
  // ======================================================

  Future<void> inicializarDatos() async {
    _setLoading(true);
    try {
      final resultados = await Future.wait([
        _repository.getMenu(),
        _repository.getPedidos(),
      ]);
      _menuPlatos = resultados[0] as List<Plato>;
      _listaPedidosHistoricos = resultados[1] as List<Pedido>;
    } catch (e) {
      _errorMessage = "Error cargando datos: $e";
      debugPrint("❌ Error Provider: $e");
    } finally {
      _setLoading(false);
    }
  }

  // 💾 CONFIRMAR PEDIDO (EBS-16)
  Future<bool> confirmarPedido() async {
    // 👇 CAMBIO AQUÍ: Quitamos "_clienteActual.isEmpty" de la validación.
    // Solo exigimos que haya mesa y al menos un plato.
    if (_mesaSeleccionada.isEmpty || _carrito.isEmpty) {
      _errorMessage = "Faltan datos (Mesa o Platos)";
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
    // 2. RECORREMOS EL CARRITO Y ENVIAMOS
      for (final plato in _carrito) {
        
        final nuevoPedido = Pedido(
          id: null,
          mesa: _mesaSeleccionada,
          cliente: _clienteActual.isEmpty ? "Mesa $_mesaSeleccionada" : _clienteActual,
          platoId: plato.id, // Modelo Plato tiene 'id' int
          fecha: DateTime.now(),
          
          estado: EstadoPedido.pendiente, 
        );

        // Enviamos al repositorio
        await _repository.insertPedido(nuevoPedido);
      }

      _carrito.clear(); // Limpiamos carrito tras éxito
      _clienteActual = '';

      // Recargamos el historial del backend para ver los nuevos pedidos
      final pedidosActualizados = await _repository.getPedidos();
      _listaPedidosHistoricos = pedidosActualizados;

      return true;
    } catch (e) {
      _errorMessage = "Error al confirmar: $e";
      debugPrint("❌ Error enviando pedido: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 🗑️ BORRAR PEDIDO HISTÓRICO
  Future<bool> borrarPedidoHistorico(int id) async {
    try {
      await _repository.deletePedido(id);
      _listaPedidosHistoricos.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Error al borrar: $e";
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool valor) {
    _isLoading = valor;
    notifyListeners();
  }

  Plato? getPlatoById(int id) {
    try {
      return _menuPlatos.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
