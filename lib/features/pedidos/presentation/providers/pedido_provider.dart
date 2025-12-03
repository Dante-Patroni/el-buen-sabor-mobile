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

  // 💾 CREAR PEDIDO (Actualizado)
 Future<bool> agregarPedido(String mesa, String cliente, int platoId) async {
  if (mesa.isEmpty && cliente.isEmpty) {
    _errorMessage = "Debe indicar mesa o cliente.";
    notifyListeners();
    return false;
  }

  // ACTIVAMOS LOADING PERO SIN NOTIFICAR TODA LA UI
  _isLoading = true;
  notifyListeners(); // SOLO 1 vez aquí

  try {
    final nuevoPedido = Pedido(
      mesa: mesa,
      cliente: cliente,
      platoId: platoId,
    );

    await _repository.insertPedido(nuevoPedido);

 // 🔄 Recargar lista desde backend
    _listaPedidos = await _repository.getPedidos();

    // AL FINAL INFORMAMOS A LA UI
    notifyListeners();
    return true;

  } catch (e) {
    _errorMessage = "No se pudo guardar: $e";
    notifyListeners();
    return false;

  } finally {
    // DESACTIVAMOS LOADING Y NOTIFICAMOS SOLO UNA VEZ
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