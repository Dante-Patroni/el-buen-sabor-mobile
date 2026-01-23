// ============================================================================
// ARCHIVO: auth_repository.dart
// ============================================================================
// 📌 PROPÓSITO:
// Gestiona la comunicación con el backend para operaciones de autenticación.
// Actúa como intermediario entre la capa de presentación y el API REST.
//
// 🏗️ CAPA: Data (Clean Architecture)
// Este repositorio pertenece a la capa de datos, responsable de:
// - Comunicarse con fuentes de datos externas (APIs, bases de datos)
// - Transformar datos del formato externo al formato de dominio
// - Manejar errores de red y validación
//
// 🎯 PATRÓN: Repository Pattern
// Abstrae el origen de los datos. La capa de presentación no sabe si los datos
// vienen de una API, base de datos local o caché. Solo pide datos al repositorio.
// ============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../domain/models/usuario.dart';

/// 🔐 REPOSITORIO DE AUTENTICACIÓN
///
/// Maneja todas las operaciones relacionadas con autenticación de usuarios.
/// Actualmente implementa login, pero puede extenderse para registro,
/// recuperación de contraseña, etc.
///
/// RESPONSABILIDADES:
/// - Realizar peticiones HTTP al backend
/// - Serializar datos de entrada (Dart → JSON)
/// - Deserializar respuestas (JSON → Dart)
/// - Manejar errores de red y del servidor
/// - Retornar datos en formato de dominio
///
/// VENTAJAS DEL PATRÓN REPOSITORY:
/// - Centraliza la lógica de acceso a datos
/// - Facilita el testing (se puede mockear)
/// - Permite cambiar la fuente de datos sin afectar la UI
/// - Separa responsabilidades (Single Responsibility Principle)
class AuthRepository {
  /// Cliente HTTP para realizar peticiones
  ///
  /// NOTA: Ahora acepta inyección de dependencias para testing
  /// En producción usa http.Client() real, en tests usa un mock
  final http.Client _client;

  /// URL base para endpoints de usuarios
  ///
  /// Se construye concatenando la URL base de la app con '/usuarios'
  /// ///Declarada en AppConfig in package:el_buen_sabor_app/core/config/app_config.dart.
  /// Ejemplo: http://192.168.18.3:3000/api/usuarios
  final String _baseUrl = '${AppConfig.apiBaseUrl}/usuarios';

  /// Constructor con inyección de dependencias opcional
  ///
  /// PARÁMETRO OPCIONAL:
  /// - client: Cliente HTTP (default: http.Client())
  ///
  /// USO EN PRODUCCIÓN:
  /// ```dart
  /// final repo = AuthRepository();  // Usa cliente HTTP real
  /// ```
  ///
  /// USO EN TESTS:
  /// ```dart
  /// final mockClient = MockClient();
  /// final repo = AuthRepository(client: mockClient);
  /// ```
  AuthRepository({http.Client? client}) : _client = client ?? http.Client();

  // ============================================================================
  // 🔑 LOGIN - Autenticación de Usuario
  // ============================================================================

  /// Autentica un usuario con legajo y contraseña
  ///
  /// FLUJO DE AUTENTICACIÓN:
  /// 1. Envía credenciales al endpoint POST /usuarios/login
  /// 2. Backend valida credenciales contra la base de datos
  /// 3. Si es válido, backend genera un JWT y retorna usuario + token
  /// 4. Si es inválido, backend retorna error 401 o 400
  ///
  /// PARÁMETROS:
  /// - legajo: Número de empleado (identificador único)
  /// - password: Contraseña del usuario
  ///
  /// RETORNA: `Future<Map<String, dynamic>>` con estructura:
  /// ```dart
  /// {
  ///   'success': true,
  ///   'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  ///   'usuario': Usuario(id: 1, nombre: 'Dante', ...)
  /// }
  /// ```
  ///
  /// LANZA: Exception si hay error de red o credenciales inválidas
  ///
  /// CÓDIGOS HTTP COMUNES:
  /// - 200 OK: Login exitoso
  /// - 400 Bad Request: Datos inválidos
  /// - 401 Unauthorized: Credenciales incorrectas
  /// - 500 Internal Server Error: Error del servidor
  Future<Map<String, dynamic>> login(String legajo, String password) async {
    try {
      // -----------------------------------------------------------------------
      // 📤 PETICIÓN HTTP POST
      // -----------------------------------------------------------------------

      // Realiza una petición POST al endpoint de login
      // `await`: Espera la respuesta sin bloquear la UI
      // NOTA: Ahora usa _client en lugar de http directamente (para testing)
      final response = await _client.post(
        // Construye la URI completa: baseUrl + /login
        // Ejemplo: http://192.168.18.3:3000/api/usuarios/login
        Uri.parse('$_baseUrl/login'),

        // Headers HTTP: Indica que enviamos JSON
        headers: {'Content-Type': 'application/json'},

        // Body: Convierte el Map de Dart a String JSON
        // jsonEncode transforma: {'legajo': '123'} → '{"legajo":"123"}'
        body: jsonEncode({'legajo': legajo, 'password': password}),
      );

      // -----------------------------------------------------------------------
      // ✅ RESPUESTA EXITOSA (Status Code 200)
      // -----------------------------------------------------------------------

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        return {
          'token': data['token'],
          'usuario': Usuario.fromJson(data['usuario']),
        };
      }

      // -----------------------------------------------------------------------
      // ❌ RESPUESTA DE ERROR (Status Code != 200)
      // -----------------------------------------------------------------------

      else {
        final data = jsonDecode(response.body);
        // Soportar tanto 'mensaje' (español) como 'message' (inglés)
        final errorMessage =
            data['mensaje'] ?? data['message'] ?? 'Error de autenticación';
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception('Error de conexión');
    }
  }

  // ============================================================================
  // 🔮 MÉTODOS FUTUROS (ejemplos de extensiones)
  // ============================================================================

  // /// Registra un nuevo usuario
  // Future<Map<String, dynamic>> register({
  //   required String nombre,
  //   required String apellido,
  //   required String legajo,
  //   required String password,
  //   required String rol,
  // }) async {
  //   final response = await http.post(
  //     Uri.parse('$_baseUrl/register'),
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode({
  //       'nombre': nombre,
  //       'apellido': apellido,
  //       'legajo': legajo,
  //       'password': password,
  //       'rol': rol,
  //     }),
  //   );
  //
  //   if (response.statusCode == 201) {
  //     return {'success': true};
  //   } else {
  //     final errorData = jsonDecode(response.body);
  //     throw Exception(errorData['mensaje'] ?? 'Error al registrar');
  //   }
  // }
  //
  // /// Verifica si el token actual es válido
  // Future<bool> verifyToken(String token) async {
  //   final response = await http.get(
  //     Uri.parse('$_baseUrl/verify'),
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     },
  //   );
  //   return response.statusCode == 200;
  // }
  //
  // /// Solicita recuperación de contraseña
  // Future<void> forgotPassword(String email) async {
  //   await http.post(
  //     Uri.parse('$_baseUrl/forgot-password'),
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode({'email': email}),
  //   );
  // }
}
