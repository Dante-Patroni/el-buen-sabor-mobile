//Este archivo se encarga de golpear la puerta del Backend (POST /login).

import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthRepository {
  final String _baseUrl = 'http://192.168.18.3:3000/api/usuarios';

  Future<String> login(String legajo, String password) async {
    final url = Uri.parse('$_baseUrl/login');

    // 👇 1. Imprime a dónde estás pegando
    print("🌐 Intentando Login en: $url");
    print("📤 Enviando: legajo=$legajo, pass=$password");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"legajo": legajo, "password": password}),
      );

      // 👇 2. EL CHIVATO: Imprime qué respondió el server ANTES de decodificar
      print("📥 Status Code: ${response.statusCode}");
      print("📦 Body recibido: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token'];
      } else {
        // Si el body es HTML, esto va a fallar, pero ya lo habremos visto en el print de arriba
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['mensaje'] ?? 'Error de autenticación');
        } catch (_) {
          // Si falla el decode del error, tiramos el body crudo
          throw Exception('Error raro del servidor: ${response.body}');
        }
      }
    } catch (e) {
      print("❌ Error Fatal: $e"); // Para verlo en consola
      rethrow;
    }
  }
}
