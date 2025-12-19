import 'package:el_buen_sabor_app/features/mesas/data/repositories/mesa_repository_impl.dart';
import 'package:flutter/material.dart';
import '../../domain/models/mesa.dart';
import '../../data/datasources/mesa_datasource.dart';

class MesaProvider extends ChangeNotifier {
  // 👇 CORRECCIÓN 2: Corregido el nombre de la clase (Impl)
  final MesaRepositoryImpl repository = MesaRepositoryImpl(MesaDataSource());

  List<Mesa> _mesas = [];
  bool _isLoading = false;
  String _error = '';

  List<Mesa> get mesas => _mesas;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> cargarMesas() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Aquí llamamos al repositorio correctamente
      _mesas = await repository.getMesas();
    } catch (e) {
      _error = e.toString();
      _mesas = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 👇 2. CERRAR MESA (El método nuevo para EBS-17)
  Future<void> cerrarMesa(int id) async {
    try {
      // A. Mandamos la orden al backend
      await repository.cerrarMesa(id);

      // B. Si el backend dijo OK, recargamos la lista inmediatamente
      // Esto hará que la mesa se pinte de GRIS en el mapa
      await cargarMesas();
    } catch (e) {
      // Si falla, pasamos el error a la UI (pantalla)
      rethrow;
    }
  }
}
