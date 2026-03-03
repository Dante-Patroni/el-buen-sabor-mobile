// ============================================================================
// ARCHIVO: auth_provider.dart
// ============================================================================
// 📌 PROPÓSITO:
// Gestiona el estado de autenticación de la aplicación de forma reactiva.
// Coordina la comunicación entre la UI y el repositorio de autenticación.
//
// 🏗️ CAPA: Presentation (Clean Architecture)
// Este provider pertenece a la capa de presentación, responsable de:
// - Gestionar el estado de la UI
// - Coordinar llamadas al repositorio
// - Notificar cambios a los widgets que escuchan
//
// 🎯 PATRÓN: Provider + ChangeNotifier
// ChangeNotifier permite que los widgets se suscriban a cambios de estado
// y se reconstruyan automáticamente cuando el estado cambia.
// ============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/models/usuario.dart';

/// 🔐 PROVIDER DE AUTENTICACIÓN
///
/// Gestiona todo el estado relacionado con la autenticación del usuario.
/// Extiende ChangeNotifier para notificar cambios a los widgets suscritos.
///
/// RESPONSABILIDADES:
/// - Coordinar el proceso de login/logout
/// - Mantener el estado del usuario autenticado
/// - Gestionar estados de carga y errores
/// - Notificar a la UI cuando el estado cambia
///
/// PATRÓN CHANGENOTIFIER:
/// - Extiende ChangeNotifier de Flutter
/// - Llama a notifyListeners() cuando el estado cambia
/// - Los widgets usan Consumer o context.watch para escuchar cambios
/// - Cuando se llama notifyListeners(), los widgets se reconstruyen
///
/// CICLO DE VIDA:
/// 1. Se crea en main.dart con ChangeNotifierProvider
/// 2. Vive durante toda la ejecución de la app
/// 3. Los widgets lo acceden con Provider.of o context.watch
/// 4. Se destruye cuando la app se cierra
class AuthProvider extends ChangeNotifier {
  static const String _defaultLoginError = 'No se pudo iniciar sesión';
  static const String _defaultLogoutError = 'No se pudo cerrar sesión';
  // ============================================================================
  // 🔧 DEPENDENCIAS - Inyección de Servicios
  // ============================================================================

  /// Repositorio para comunicarse con el backend
  /// Maneja las peticiones HTTP de autenticación
  ///
  /// NOTA: Ahora acepta inyección de dependencias para testing
  /// En producción usa la instancia real, en tests usa un mock
  final AuthRepository _repository;

  /// Servicio de almacenamiento seguro
  /// Guarda el token JWT de forma encriptada
  ///
  /// NOTA: Ahora acepta inyección de dependencias para testing
  /// En producción usa la instancia real, en tests usa un mock
  final StorageService _storage;

  /// Constructor con inyección de dependencias opcional
  ///
  /// PARÁMETROS OPCIONALES:
  /// - repository: Repositorio de autenticación (default: AuthRepository())
  /// - storage: Servicio de almacenamiento (default: StorageService())
  ///
  /// USO EN PRODUCCIÓN:
  /// ```dart
  /// final provider = AuthProvider();  // Usa instancias reales
  /// ```
  ///
  /// USO EN TESTS:
  /// ```dart
  /// final mockRepo = MockAuthRepository();
  /// final mockStorage = MockStorageService();
  /// final provider = AuthProvider(
  ///   repository: mockRepo,
  ///   storage: mockStorage,
  /// );
  /// ```
  AuthProvider({
    AuthRepository? repository,
    StorageService? storage,
  })  : _repository = repository ?? AuthRepositoryImpl(AuthDataSource()),
        _storage = storage ?? StorageService();

  // ============================================================================
  // 📊 ESTADO PRIVADO - Variables Internas
  // ============================================================================

  /// Indica si hay una operación en progreso (login/logout)
  /// Se usa para mostrar indicadores de carga en la UI
  bool _isLoading = false;

  /// Mensaje de error si el login falla
  /// null si no hay error
  String? _errorMessage;

  /// Usuario autenticado actualmente
  /// null si no hay sesión activa
  Usuario? _usuario;

  // ============================================================================
  // 📤 GETTERS PÚBLICOS - Acceso al Estado desde la UI
  // ============================================================================

  /// Indica si hay una operación en progreso
  ///
  /// USO EN UI:
  /// ```dart
  /// if (authProvider.isLoading) {
  ///   return CircularProgressIndicator();
  /// }
  /// ```
  bool get isLoading => _isLoading;

  /// Mensaje de error actual (si existe)
  ///
  /// USO EN UI:
  /// ```dart
  /// if (authProvider.errorMessage != null) {
  ///   Text(authProvider.errorMessage!, style: TextStyle(color: Colors.red));
  /// }
  /// ```
  String? get errorMessage => _errorMessage;

  /// Usuario autenticado (si existe)
  ///
  /// USO EN UI:
  /// ```dart
  /// Text('Hola ${authProvider.usuario?.nombre}');
  /// ```
  Usuario? get usuario => _usuario;
  bool get isAuthenticated => _usuario != null;

  String _normalizarError(Object e, {String fallback = 'Error inesperado'}) {
    final msg = e.toString().replaceAll('Exception: ', '').trim();
    return msg.isEmpty ? fallback : msg;
  }

  Usuario? _usuarioDesdeToken(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;

    try {
      final normalized = base64Url.normalize(parts[1]);
      final payloadBytes = base64Url.decode(normalized);
      final payloadMap =
          jsonDecode(utf8.decode(payloadBytes)) as Map<String, dynamic>;

      final id = int.tryParse(payloadMap['id']?.toString() ?? '') ?? 0;
      if (id <= 0) return null;

      return Usuario(
        id: id,
        nombre: payloadMap['nombre']?.toString() ?? '',
        apellido: '',
        rol: payloadMap['rol']?.toString() ?? '',
        legajo: payloadMap['legajo']?.toString() ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> restoreSessionFromToken() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storage.getToken();
      if (token == null || token.isEmpty) {
        _usuario = null;
        return;
      }

      final usuarioToken = _usuarioDesdeToken(token);
      if (usuarioToken == null) {
        await _storage.deleteToken();
        _usuario = null;
        _errorMessage = 'Sesión inválida. Iniciá sesión nuevamente.';
        return;
      }

      _usuario = usuarioToken;
    } catch (e) {
      _usuario = null;
      _errorMessage = _normalizarError(
        e,
        fallback: 'No se pudo restaurar sesión',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // 🔑 LOGIN - Autenticación de Usuario
  // ============================================================================

  /// Autentica un usuario con legajo y contraseña
  ///
  /// FLUJO COMPLETO:
  /// 1. Actualiza estado a "cargando" y limpia errores previos
  /// 2. Notifica a la UI (muestra loading)
  /// 3. Llama al repositorio para autenticar
  /// 4. Si es exitoso:
  ///    - Guarda el token en almacenamiento seguro
  ///    - Guarda el usuario en memoria
  ///    - Actualiza estado a "no cargando"
  ///    - Notifica a la UI (oculta loading, navega a home)
  /// 5. Si falla:
  ///    - Guarda el mensaje de error
  ///    - Actualiza estado a "no cargando"
  ///    - Notifica a la UI (muestra error)
  ///
  /// PARÁMETROS:
  /// - legajo: Número de empleado
  /// - password: Contraseña del usuario
  ///
  /// RETORNA: `Future<bool>`
  /// - true si el login fue exitoso
  /// - false si falló (credenciales incorrectas, error de red, etc.)
  ///
  /// EJEMPLO DE USO:
  /// ```dart
  /// final exito = await authProvider.login('12345', 'password123');
  /// if (exito) {
  ///   Navigator.pushReplacement(context, MaterialPageRoute(...));
  /// }
  /// ```
  Future<bool> login(String legajo, String password) async {
    // -------------------------------------------------------------------------
    // 📍 PASO 1: Preparar el estado para la operación
    // -------------------------------------------------------------------------

    _isLoading = true; // Activar indicador de carga
    _errorMessage = null; // Limpiar errores previos
    notifyListeners(); // Notificar a la UI (muestra CircularProgressIndicator)

    try {
      // -----------------------------------------------------------------------
      // 📍 PASO 2: Llamar al repositorio para autenticar
      // -----------------------------------------------------------------------

      // Solicita autenticación al backend a través del repositorio
      // Retorna un Map con 'token' y 'usuario'
      final response = await _repository.login(legajo, password);

      // -----------------------------------------------------------------------
      // 📍 PASO 3: Extraer datos de la respuesta
      // -----------------------------------------------------------------------

      final String token = response['token']; // Token JWT
      final Usuario usuarioRecibido = response['usuario']; // Objeto Usuario

      // -----------------------------------------------------------------------
      // 📍 PASO 4: Persistir el token de forma segura
      // -----------------------------------------------------------------------

      // Guarda el token en almacenamiento encriptado
      // Esto permite mantener la sesión activa entre reinicios de la app
      await _storage.saveToken(token);

      // -----------------------------------------------------------------------
      // 📍 PASO 5: Actualizar el estado con el usuario autenticado
      // -----------------------------------------------------------------------

      // Guarda el usuario en memoria para acceso rápido
      // Se usa para mostrar nombre en la UI, verificar permisos, etc.
      _usuario = usuarioRecibido;
      _errorMessage = null;

      // -----------------------------------------------------------------------
      // 📍 PASO 6: Finalizar operación exitosa
      // -----------------------------------------------------------------------

      _isLoading = false; // Desactivar indicador de carga
      notifyListeners(); // Notificar a la UI (oculta loading, actualiza datos)
      return true; // Indicar éxito
    }

    // -------------------------------------------------------------------------
    // ❌ MANEJO DE ERRORES
    // -------------------------------------------------------------------------

    catch (e) {
      _errorMessage = _normalizarError(e, fallback: _defaultLoginError);

      _isLoading = false; // Desactivar indicador de carga
      notifyListeners(); // Notificar a la UI (muestra mensaje de error)
      return false; // Indicar fallo
    }
  }

  // ============================================================================
  // 🚪 LOGOUT - Cerrar Sesión
  // ============================================================================

  /// Cierra la sesión del usuario actual
  ///
  /// FLUJO:
  /// 1. Elimina el token del almacenamiento seguro
  /// 2. Limpia el usuario de la memoria
  /// 3. Notifica a la UI (redirige a login)
  ///
  /// EJEMPLO DE USO:
  /// ```dart
  /// await authProvider.logout();
  /// Navigator.pushReplacement(context, MaterialPageRoute(
  ///   builder: (_) => LoginPage(),
  /// ));
  /// ```
  Future<void> logout() async {
    try {
      await _storage.deleteToken();
    } catch (e) {
      _errorMessage = _normalizarError(e, fallback: _defaultLogoutError);
    } finally {
      _usuario = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // 🔮 MÉTODOS FUTUROS (ejemplos de extensiones)
  // ============================================================================

  // /// Verifica si hay una sesión activa al iniciar la app
  // Future<bool> checkSession() async {
  //   final token = await _storage.getToken();
  //   if (token != null) {
  //     // Verificar si el token es válido con el backend
  //     final isValid = await _repository.verifyToken(token);
  //     if (isValid) {
  //       // Cargar datos del usuario
  //       // _usuario = await _repository.getUserData(token);
  //       notifyListeners();
  //       return true;
  //     }
  //   }
  //   return false;
  // }
  //
  // /// Actualiza los datos del usuario
  // Future<void> updateUserData(Usuario updatedUser) async {
  //   _usuario = updatedUser;
  //   notifyListeners();
  // }
  //
  // /// Limpia el mensaje de error
  // void clearError() {
  //   _errorMessage = null;
  //   notifyListeners();
  // }
}
