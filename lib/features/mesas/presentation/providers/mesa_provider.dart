import 'package:flutter/material.dart';
import '../../presentation/models/mesa_ui_model.dart';

import '../../domain/repositories/mesa_repository.dart';

class MesaProvider extends ChangeNotifier {
  final MesaRepository _repository;

  /**
   * @description Crea el provider de mesas.
   * @param {MesaRepository} _repository - Repositorio de mesas.
   * @returns {MesaProvider} Instancia del provider.
   * @throws {Error} No lanza errores por diseno.
   */
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
  /**
   * @description Lista de mesas para la UI.
   * @returns {List<MesaUiModel>} Mesas actuales.
   * @throws {Error} No lanza errores.
   */
  List<MesaUiModel> get mesas => _mesas;
  /**
   * @description Indica si hay carga en progreso.
   * @returns {bool} True si esta cargando.
   * @throws {Error} No lanza errores.
   */
  bool get isLoading => _isLoading;
  /**
   * @description Mensaje de error actual.
   * @returns {String} Mensaje de error o vacio.
   * @throws {Error} No lanza errores.
   */
  String get error => _error;

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

  // =========================
  // Caso de uso: cargar mesas
  // =========================
  /**
   * @description Carga mesas y actualiza el estado del provider.
   * @returns {Future<void>} Operacion asincronica sin valor de retorno.
   * @throws {Exception} Error de red o backend.
   */
  Future<void> cargarMesas() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final mesasDominio = await _repository.getMesas();
      _mesas = mesasDominio.map(MesaUiModel.fromDomain).toList();
    } catch (e) {
      _error = _normalizarError(e, fallback: 'Error cargando mesas');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================
  // Caso de uso: abrir mesa
  // =========================
  /**
   * @description Abre una mesa y recarga el listado.
   * @param {int} idMesa - Identificador de la mesa.
   * @param {int} idMozo - Identificador del mozo.
   * @returns {Future<bool>} True si tuvo exito; false si fallo.
   * @throws {Exception} Error de red o backend.
   */
  Future<bool> ocuparMesa(int idMesa, int idMozo) async {
    try {
      await _repository.abrirMesa(idMesa, idMozo);
      await cargarMesas();
      return true;
    } catch (e) {
      _error = _normalizarError(e, fallback: 'Error al abrir mesa');
      notifyListeners();
      return false;
    }
  }

  // =========================
  // Caso de uso: cerrar mesa
  // =========================
  /**
   * @description Cierra una mesa y recarga el listado.
   * @param {int} idMesa - Identificador de la mesa.
   * @returns {Future<double?>} Total cobrado o null si falla.
   * @throws {Exception} Error de red o backend.
   */
 Future<double?> cerrarMesa(int idMesa) async {
  _isLoading = true;
  _error = '';
  notifyListeners();

  try {
    final total = await _repository.cerrarMesa(idMesa);
    await cargarMesas();
    return total;
  } catch (e) {
    _error = _normalizarError(e, fallback: 'Error al cerrar mesa');
    return null;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

}
