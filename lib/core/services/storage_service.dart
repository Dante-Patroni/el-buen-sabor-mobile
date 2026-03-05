// ============================================================================
// ARCHIVO: storage_service.dart
// ============================================================================
// 📌 PROPÓSITO:
// Gestiona el almacenamiento seguro de datos sensibles en el dispositivo.
// Principalmente se usa para guardar tokens de autenticación (JWT).
//
// 🔒 SEGURIDAD:
// Utiliza FlutterSecureStorage que encripta los datos usando:
// - Android: KeyStore (encriptación AES)
// - iOS: Keychain (encriptación nativa)
//
// 🏗️ PATRÓN: Singleton
// Una única instancia compartida en toda la aplicación.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 🔐 SERVICIO DE ALMACENAMIENTO SEGURO
///
/// Esta clase proporciona una interfaz simple para guardar, leer y eliminar
/// datos sensibles de forma segura en el dispositivo.
///
/// CASOS DE USO:
/// - Guardar tokens JWT de autenticación
/// - Almacenar credenciales de usuario
/// - Guardar claves API o secretos
/// - Persistir configuraciones sensibles
///
/// ⚠️ NO USAR PARA:
/// - Datos grandes (usar base de datos local)
/// - Datos no sensibles (usar SharedPreferences)
/// - Caché de imágenes (usar cache_network_image)
///
/// 💡 VENTAJAS DE FLUTTER SECURE STORAGE:
/// - Encriptación automática por el sistema operativo
/// - API simple y consistente entre plataformas
/// - No requiere configuración adicional
/// - Protección contra acceso no autorizado
class StorageService {
  // ============================================================================
  // 🔒 PATRÓN SINGLETON - Instancia Única
  // ============================================================================

  /// Instancia única del servicio (Singleton)
  /// `_internal()`: Constructor privado nombrado
  static final StorageService _instance = StorageService._internal();

  /**
   * @description Factory constructor que retorna la unica instancia del servicio.
   * @returns {StorageService} Instancia singleton del servicio.
   * @throws {Error} No lanza errores por diseno.
   */
  factory StorageService() => _instance;

  /**
   * @description Constructor privado para inicializar el singleton.
   * @returns {StorageService} Instancia creada internamente.
   * @throws {Error} No lanza errores por diseno.
   */
  StorageService._internal();

  // ============================================================================
  // 📦 INSTANCIA DE FLUTTER SECURE STORAGE
  // ============================================================================

  /// Instancia de la librería de almacenamiento seguro
  /// `const`: Inmutable, se crea en tiempo de compilación
  /// `_storage`: Privado, solo accesible dentro de esta clase
  final _storage = const FlutterSecureStorage();

  // ============================================================================
  // 🔑 CONSTANTES - Claves de Almacenamiento
  // ============================================================================

  /// Clave para almacenar el token JWT
  ///
  /// FORMATO DEL TOKEN JWT:
  /// Un JWT tiene 3 partes separadas por puntos:
  /// - Header: Tipo de token y algoritmo de encriptación
  /// - Payload: Datos del usuario (id, rol, email, etc.)
  /// - Signature: Firma digital para verificar autenticidad
  ///
  /// Ejemplo: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEsInJvbGUiOiJ3YWl0ZXIifQ.signature
  static const _keyToken = 'jwt_token';

  // ============================================================================
  // 💾 OPERACIONES CRUD - Create, Read, Update, Delete
  // ============================================================================

  /**
   * @description Guarda el token JWT de forma segura; sobrescribe si ya existe.
   * @param {String} token - Token JWT recibido del backend.
   * @returns {Future<void>} Operacion asincronica sin valor de retorno.
   * @throws {Exception} Error de almacenamiento seguro.
   */
  Future<void> saveToken(String token) async {
    try {
      // Escribe el token en almacenamiento seguro
      // key: Identificador único para recuperar el valor
      // value: El token JWT a guardar
      await _storage.write(key: _keyToken, value: token);

      // debugPrint solo se ejecuta en modo debug (no en producción)
      debugPrint("🔐 Token guardado en SecureStorage");
    } catch (e) {
      // Captura cualquier error (permisos, espacio, etc.)
      debugPrint("❌ Error guardando token: $e");
      rethrow;
    }
  }

  /**
   * @description Recupera el token JWT almacenado de forma segura.
   * @returns {Future<String?>} Token si existe; null si no hay token.
   * @throws {Error} No lanza; retorna null ante error.
   */
  Future<String?> getToken() async {
    try {
      // Lee el valor asociado a la clave _keyToken
      // Retorna null si no existe
      return await _storage.read(key: _keyToken);
    } catch (e) {
      debugPrint("❌ Error leyendo token: $e");
      return null; // En caso de error, retornar null
    }
  }

  /**
   * @description Elimina el token JWT del almacenamiento seguro.
   * @returns {Future<void>} Operacion asincronica sin valor de retorno.
   * @throws {Exception} Error al eliminar el token.
   */
  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _keyToken);
      debugPrint("👋 Token eliminado (Logout)");
    } catch (e) {
      debugPrint("❌ Error eliminando token: $e");
      rethrow;
    }
  }

  // ============================================================================
  // 🔮 MÉTODOS FUTUROS (ejemplos de extensiones)
  // ============================================================================

  // /// Guarda múltiples valores de forma segura
  // Future<void> saveAll(Map<String, String> data) async {
  //   for (var entry in data.entries) {
  //     await _storage.write(key: entry.key, value: entry.value);
  //   }
  // }
  //
  // /// Limpia todo el almacenamiento seguro
  // Future<void> clearAll() async {
  //   await _storage.deleteAll();
  // }
  //
  // /// Verifica si existe un token guardado
  // Future<bool> hasToken() async {
  //   final token = await getToken();
  //   return token != null && token.isNotEmpty;
  // }
}
