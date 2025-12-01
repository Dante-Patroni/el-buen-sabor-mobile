/// ARCHIVO: pedido_provider.dart
/// DESCRIPCIÓN:
/// Este archivo gestiona el ESTADO de la pantalla de pedidos.
/// Actúa como intermediario (ViewModel) entre la UI (Widgets) y el Dominio (Repositorio).
///
/// Responsabilidades:
/// 1. Mantener la lista de pedidos y el menú de platos en memoria.
/// 2. Notificar a la UI cuando hay cambios (loading, error, nuevos datos).
/// 3. Ejecutar la lógica de negocio llamando al Repositorio.

import 'package:flutter/material.dart';
import '../../domain/models/pedido.dart';
import '../../domain/models/plato.dart';
import '../../domain/repositories/pedido_repository.dart';

class PedidoProvider extends ChangeNotifier {
  // Inyección de Dependencia: El provider necesita un Repositorio para trabajar
  final PedidoRepository _repository;

  // ESTADOS (Variables que la UI va a "escuchar")
  List<Pedido> _listaPedidos = [];
  List<Plato> _menuPlatos = []; // Para llenar el Dropdown
  bool _isLoading = false;
  String? _errorMessage;

  // GETTERS (Para que la UI lea los datos protegidos)
  List<Pedido> get listaPedidos => _listaPedidos;
  List<Plato> get menuPlatos => _menuPlatos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // CONSTRUCTOR
  PedidoProvider(this._repository) {
    inicializarDatos();
  }

  /// Carga inicial de datos (Menú y Pedidos existentes)
  Future<void> inicializarDatos() async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint("🔍 [DEBUG] Iniciando carga de datos..."); // <--- AGREGA ESTO

      final resultados = await Future.wait([
        _repository.getMenu(),
        _repository.getPedidos(),
      ]);

      _menuPlatos = resultados[0] as List<Plato>;
      _listaPedidos = resultados[1] as List<Pedido>;

      debugPrint(
        "✅ [DEBUG] Datos cargados. Pedidos encontrados: ${_listaPedidos.length}",
      ); // <--- AGREGA ESTO
    } catch (e, stackTrace) {
      // <--- Agrega stackTrace
      // ESTO ES LO IMPORTANTE: Imprime el error real
      debugPrint("❌ [ERROR CRÍTICO] Error cargando datos: $e");
      debugPrint("Stacktrace: $stackTrace");

      _errorMessage = "Error cargando datos: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crea un nuevo pedido y actualiza la lista local
  Future<bool> agregarPedido(String cliente, int platoId) async {
    if (cliente.isEmpty) return false;

    _setLoading(true);
    try {
      // 1. Crear el objeto Pedido (Sin ID, la DB lo pondrá)
      final nuevoPedido = Pedido(
        cliente: cliente,
        platoId: platoId,
        // fecha y estado se ponen solos por defecto
      );

      // 2. Guardar en Base de Datos (a través del Repo)
      await _repository.insertPedido(nuevoPedido);

      // 3. Recargar la lista para mostrar el nuevo item
      _listaPedidos = await _repository.getPedidos();

      return true; // Éxito
    } catch (e) {
      _errorMessage = "No se pudo guardar: $e";
      return false; // Error
    } finally {
      _setLoading(false);
    }
  }

  // 🗑️ Método para Borrar Pedido
  Future<bool> borrarPedido(int id) async {
    try {
      // 1. Llamamos al repositorio (API)
      await _repository.deletePedido(id);

      // 2. Si no hubo error, lo sacamos de la lista local
      // Esto hace que la UI se actualice al instante sin recargar todo
      _listaPedidos.removeWhere((p) => p.id == id);
      
      notifyListeners(); // Avisamos a la pantalla
      return true; // Éxito

    } catch (e) {
      _errorMessage = "No se pudo borrar: $e";
      notifyListeners();
      return false; // Falló
    }
  }

  // Helper para notificar cambios de carga
  void _setLoading(bool valor) {
    _isLoading = valor;
    notifyListeners(); // ¡Esto actualiza la pantalla!
  }
}
