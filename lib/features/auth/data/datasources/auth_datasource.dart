import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../domain/models/usuario.dart';

/// **AuthDataSource**
///
/// Responsabilidad única: hablar con el backend de autenticación via HTTP.
/// No conoce al Provider ni a la UI. Solo trabaja con datos crudos.
///
/// Arquitectura:
/// ```
/// AuthProvider → AuthRepository → AuthRepositoryImpl → [AuthDataSource] → Backend
/// ```
class AuthDataSource {
  final http.Client _client;
  final String _baseUrl = '${AppConfig.apiBaseUrl}/usuarios';

  AuthDataSource({http.Client? client}) : _client = client ?? http.Client();

  // ===========================================================================
  // 🔑 LOGIN (POST /usuarios/login)
  // ===========================================================================

  /// Envía las credenciales al backend y retorna el token + datos del usuario.
  /// Lanza Exception si las credenciales son inválidas o hay error de red.
  Future<Map<String, dynamic>> login(String legajo, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'legajo': legajo, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'token': data['token'],
          'usuario': Usuario.fromJson(data['usuario']),
        };
      } else {
        final data = jsonDecode(response.body);
        final errorMessage =
            data['mensaje'] ?? data['message'] ?? 'Error de autenticación';
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception('Error de conexión');
    }
  }
}
