//Este archivo se encarga de golpear la puerta del Backend (POST /login).

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../domain/models/usuario.dart';

class AuthRepository {
  final String _baseUrl = 'http://192.168.18.3:3000/api/usuarios';

  Future<Map<String, dynamic>> login(String legajo, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'legajo': legajo, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Devolvemos un Mapa con el Token y el Usuario ya parseado
        return {
          'success': true,
          'token': data['token'],
          'usuario': Usuario.fromJson(data['usuario']), 
        };
      } else {
        // Si falla, devolvemos el mensaje del backend
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['mensaje'] ?? 'Error de autenticación');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
