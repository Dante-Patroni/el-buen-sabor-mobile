import 'package:flutter/material.dart';
import '../../presentation/models/mesa_ui_model.dart';

import '../../domain/repositories/mesa_repository.dart';

class MesaProvider extends ChangeNotifier {
  final MesaRepository _repository;

  MesaProvider(this._repository);

  // =========================
  // Estado
  // =========================
  List<MesaUiModel> _mesas = [];
  bool _isLoading = false;
  String _error = '';

  // =========================
  // Getters
  // =========================
  List<MesaUiModel> get mesas => _mesas;
  bool get isLoading => _isLoading;
  String get error => _error;

  // =========================
  // Caso de uso: cargar mesas
  // =========================
  Future<void> cargarMesas() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final mesasDominio = await _repository.getMesas();
      _mesas = mesasDominio.map(MesaUiModel.fromDomain).toList();
    } catch (_) {
      _error = 'Error cargando mesas';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================
  // Caso de uso: abrir mesa
  // =========================
  Future<bool> ocuparMesa(int idMesa, int idMozo) async {
    try {
      await _repository.abrirMesa(idMesa, idMozo);
      await cargarMesas();
      return true;
    } catch (_) {
      return false;
    }
  }

  // =========================
  // Caso de uso: cerrar mesa
  // =========================
  Future<bool> cerrarMesa(int idMesa) async {
    try {
      await _repository.cerrarMesa(idMesa);
      await cargarMesas();
      return true;
    } catch (_) {
      return false;
    }
  }

  // =========================
  // Caso de uso: cerrar mesa y facturar
  // =========================
  /// 
  /// **Responsabilidad:** Ejecutar el caso de uso "Cerrar Mesa y Facturar".
  /// 
  /// **Flujo:**
  /// 1. Llama al repositorio para cerrar la mesa y facturar
  /// 2. Si tiene éxito, refresca la lista de mesas (para actualizar el estado)
  /// 3. Retorna el total cobrado para mostrarlo en la UI
  /// 
  /// **Arquitectura:** Este es el caso de uso de la capa de presentación.
  /// La UI debe llamar a este método, NO al repositorio directamente.
  /// 
  /// Retorna `null` si hubo un error, o el `totalCobrado` si fue exitoso.
  Future<double?> cerrarMesaYFacturar(int idMesa) async {
    try {
      // 1. Ejecutamos el caso de uso a través del repositorio
      final totalCobrado = await _repository.cerrarMesaYFacturar(idMesa);
      
      // 2. Refrescamos la lista de mesas para que la UI se actualice
      // (la mesa ahora debería aparecer como "libre")
      await cargarMesas();
      
      // 3. Retornamos el total cobrado para que la UI lo muestre
      return totalCobrado;
    } catch (e) {
      // Si hay error, guardamos el mensaje y retornamos null
      _error = 'Error al cerrar mesa: $e';
      notifyListeners();
      return null;
    }
  }
}
