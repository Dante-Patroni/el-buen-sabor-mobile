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
Future<double?> cerrarMesa(int idMesa) async {
  _isLoading = true;
  _error = '';
  notifyListeners();

  try {
    final total = await _repository.cerrarMesa(idMesa);
    await cargarMesas();
    return total;
  } catch (_) {
    _error = 'Error al cerrar mesa';
    return null;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

}
