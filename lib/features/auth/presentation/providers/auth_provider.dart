import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/auth_repository.dart';
import '../../domain/models/usuario.dart'; // 👈 Importamos el modelo

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();
  final StorageService _storage = StorageService();

  bool _isLoading = false;
  String? _errorMessage;
  Usuario? _usuario; // 👈 Aquí guardaremos al Mozo "Dante"

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Usuario? get usuario => _usuario; // Getter para acceder desde la UI

  Future<bool> login(String legajo, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Pedimos el pack completo (Token + Usuario) al repo
      final response = await _repository.login(legajo, password);

      // 2. Extraemos los datos
      final String token = response['token'];
      final Usuario usuarioRecibido = response['usuario'];

      // 3. Guardamos el token en la CAJA FUERTE 🔐
      await _storage.saveToken(token);

      // 4. Guardamos al usuario en memoria para mostrar "Hola Dante"
      _usuario = usuarioRecibido;

      _isLoading = false;
      notifyListeners();
      return true; // Éxito
    } catch (e) {
      // Limpiamos el mensaje de error para que sea legible
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false; // Falló
    }
  }

  Future<void> logout() async {
    await _storage.deleteToken();
    _usuario = null; // Borramos al usuario de la memoria
    notifyListeners();
  }
}