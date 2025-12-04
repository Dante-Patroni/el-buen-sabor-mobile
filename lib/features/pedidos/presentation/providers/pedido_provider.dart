import 'package:flutter/material.dart';
import '../../domain/models/pedido.dart';
import '../../domain/models/plato.dart';
import '../../domain/repositories/pedido_repository.dart';

class PedidoProvider extends ChangeNotifier {
  final PedidoRepository _repository;

  // ESTADOS
  List<Pedido> _listaPedidos = [];
  List<Plato> _menuPlatos = [];
  bool _isLoading = false;
  String? _errorMessage;

  // GETTERS
  List<Pedido> get listaPedidos => _listaPedidos;
  List<Plato> get menuPlatos => _menuPlatos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  PedidoProvider(this._repository);

  Future<void> inicializarDatos() async {
    _setLoading(true);
    try {
      final resultados = await Future.wait([
        _repository.getMenu(),
        _repository.getPedidos(),
      ]);
      _menuPlatos = resultados[0] as List<Plato>;
      _listaPedidos = resultados[1] as List<Pedido>;
    } catch (e) {
      _errorMessage = "Error cargando datos: $e";
      debugPrint("❌ Error Provider: $e");
    } finally {
      _setLoading(false);
    }
  }

  // 💾 CREAR PEDIDO (Con actualización automática de Stock)
  Future<bool> agregarPedido(String mesa, String cliente, int platoId) async {
    if (mesa.isEmpty && cliente.isEmpty) {
      _errorMessage = "Debe indicar mesa o cliente.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final nuevoPedido = Pedido(
        mesa: mesa,
        cliente: cliente,
        platoId: platoId,
      );

      // 1. Enviamos el pedido al Backend (Aquí descuenta stock en Mongo)
      await _repository.insertPedido(nuevoPedido);

      // 🔄 2. ACTUALIZACIÓN CRÍTICA: Recargamos TODO (Pedidos y Menú)
      // Esto obliga a la app a bajar el stock nuevo (19) desde el servidor
      final resultados = await Future.wait([
        _repository.getMenu(),    // <--- ¡ESTO ES LO QUE FALTABA!
        _repository.getPedidos(),
      ]);

      _menuPlatos = resultados[0] as List<Plato>; // Actualizamos lista del dropdown
      _listaPedidos = resultados[1] as List<Pedido>; // Actualizamos lista histórica

      notifyListeners(); // Avisamos a la UI para que repinte los números
      return true;

    } catch (e) {
      _errorMessage = "No se pudo guardar: $e";
      notifyListeners();
      return false;

    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  // 🗑️ BORRAR PEDIDO
  Future<bool> borrarPedido(int id) async {
    try {
      await _repository.deletePedido(id);
      _listaPedidos.removeWhere((p) => p.id == id);
      notifyListeners(); // Avisar cambio
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