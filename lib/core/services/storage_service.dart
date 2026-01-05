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

  /// Factory constructor que siempre retorna la misma instancia
  ///
  /// EJEMPLO DE USO:
  /// ```dart
  /// final storage = StorageService(); // Siempre retorna _instance
  /// final storage2 = StorageService(); // Misma instancia que storage
  /// ```
  factory StorageService() => _instance;

  /// Constructor privado nombrado
  /// Solo se llama una vez cuando se crea _instance
  /// El _ lo hace privado (no se puede llamar desde fuera)
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

  /// 📥 GUARDAR TOKEN (Create/Update)
  ///
  /// Guarda el token JWT de forma segura después del login exitoso.
  /// Si ya existe un token, lo sobrescribe.
  ///
  /// FLUJO DE AUTENTICACIÓN:
  /// 1. Usuario ingresa credenciales
  /// 2. Backend valida y retorna JWT
  /// 3. App guarda JWT con este método
  /// 4. JWT se incluye en headers de futuras peticiones
  ///
  /// PARÁMETROS:
  /// - token: String del JWT recibido del backend
  ///
  /// RETORNA: `Future<void>` - Operación asíncrona sin valor de retorno
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
    }
  }

  /// 📤 LEER TOKEN (Read)
  ///
  /// Recupera el token JWT guardado previamente.
  /// Se usa para verificar si el usuario tiene sesión activa.
  ///
  /// CASOS DE USO:
  /// - Al iniciar la app (verificar si hay sesión)
  /// - Antes de cada petición HTTP (incluir en headers)
  /// - Para validar permisos del usuario
  ///
  /// RETORNA: `Future<String?>` - Token si existe, null si no hay token guardado
  ///
  /// EJEMPLO DE USO:
  /// ```dart
  /// final token = await StorageService().getToken();
  /// if (token != null) {
  ///   // Usuario tiene sesión activa
  ///   headers['Authorization'] = 'Bearer $token';
  /// } else {
  ///   // Redirigir a login
  /// }
  /// ```
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

  /// 🗑️ BORRAR TOKEN (Delete)
  ///
  /// Elimina el token JWT del almacenamiento seguro.
  /// Se usa cuando el usuario cierra sesión (logout).
  ///
  /// FLUJO DE LOGOUT:
  /// 1. Usuario presiona "Cerrar Sesión"
  /// 2. Se llama a este método para borrar el token
  /// 3. Se limpia el estado de la app (providers)
  /// 4. Se redirige a la pantalla de login
  ///
  /// RETORNA: `Future<void>` - Operación asíncrona sin valor de retorno
  Future<void> deleteToken() async {
    // Elimina la entrada con clave _keyToken
    await _storage.delete(key: _keyToken);
    debugPrint("👋 Token eliminado (Logout)");
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
