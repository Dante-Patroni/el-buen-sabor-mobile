//Este conecta la UI con el Repositorio y usa nuestro nuevo StorageService para guardar la llave.

import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();
  final StorageService _storage =
      StorageService(); // 👈 Usamos el servicio del EBS-03

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String legajo, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Pedimos el token al backend
      final token = await _repository.login(legajo, password);

      // 2. Guardamos el token en la CAJA FUERTE 🔐
      await _storage.saveToken(token);

      _isLoading = false;
      notifyListeners();
      return true; // Éxito total
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false; // Falló
    }
  }

  // Método para cerrar sesión
  Future<void> logout() async {
    await _storage.deleteToken();
    notifyListeners();
  }
}
