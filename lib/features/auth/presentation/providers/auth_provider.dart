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
      // Limpia el mensaje de error removiendo el prefijo "Exception: "
      // para que sea más legible en la UI
      _errorMessage = e.toString().replaceAll("Exception: ", "");

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
    // Elimina el token del almacenamiento seguro
    await _storage.deleteToken();

    // Limpia el usuario de la memoria
    _usuario = null;

    // Notifica a la UI para que se actualice
    // Los widgets que escuchan verán que usuario es null
    // y pueden redirigir a la pantalla de login
    notifyListeners();
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
