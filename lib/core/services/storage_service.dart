import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  // Patrón Singleton: Para tener una única "Caja Fuerte" en toda la app
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Instancia de la librería segura
  final _storage = const FlutterSecureStorage();

  // La "etiqueta" con la que guardaremos el dato
  static const _keyToken = 'jwt_token';

  // ==========================================
  // 📥 1. GUARDAR (Login)
  // ==========================================
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _keyToken, value: token);
      debugPrint("🔐 Token guardado en SecureStorage");
    } catch (e) {
      debugPrint("❌ Error guardando token: $e");
    }
  }

 // ==========================================
  // 📤 2. LEER (Recuperar Token)
  // ==========================================
  Future<String?> getToken() async {
    try {
      // Usamos la misma _keyToken privada que usaste para guardar
      return await _storage.read(key: _keyToken);
    } catch (e) {
      debugPrint("❌ Error leyendo token: $e");
      return null;
    }
  }

  // ==========================================
  // 🗑️ 3. BORRAR (Logout)
  // ==========================================
  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
    debugPrint("👋 Token eliminado (Logout)");
  }
}
