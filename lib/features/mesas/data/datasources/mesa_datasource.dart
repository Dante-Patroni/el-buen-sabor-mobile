import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart'; // 👈 Importamos Config Central
import '../../../../core/services/storage_service.dart'; // 👈 Importamos la Caja Fuerte
import '../models/mesa_model.dart';

class MesaDataSource {
  final String baseUrl = '${AppConfig.apiBaseUrl}/mesas';
  final String pedidosBaseUrl = '${AppConfig.apiBaseUrl}/pedidos';
  static const String _sessionExpiredMessage =
      'Sesión expirada. Iniciá sesión nuevamente.';

  // Instancia del servicio de almacenamiento
  final StorageService _storage = StorageService();

  // 🔐 HELPER: Obtener Headers con Token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception(_sessionExpiredMessage);
    }

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  void _throwIfUnauthorized(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception(_sessionExpiredMessage);
    }
  }

  String _extractBackendMessage(String body, {String fallback = 'Error de servidor'}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['mensaje'] ?? decoded['message'] ?? decoded['error'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
    } catch (_) {
      // Ignorado: usamos fallback
    }
    return fallback;
  }

  // 1. GET MESAS (Ahora blindado)
  Future<List<MesaModel>> getMesasFromApi() async {
    try {
      final url = Uri.parse(baseUrl);

      final response = await http.get(url, headers: await _getAuthHeaders());
      _throwIfUnauthorized(response);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => MesaModel.fromJson(json)).toList();
      } else {
        throw Exception(_extractBackendMessage(
          response.body,
          fallback: 'Error API: ${response.statusCode}',
        ));
      }
    } catch (e) {
      throw Exception('No se pudo obtener mesas: $e');
    }
  }

  // 2. CERRAR MESA (FACTURACIÓN BACKEND)
  Future<double> cerrarMesa(int idMesa) async {
    try {
      final headers = await _getAuthHeaders();
      final urlMesas = Uri.parse('$baseUrl/$idMesa/cerrar');

      http.Response response = await http.post(urlMesas, headers: headers);
      if (response.statusCode == 404) {
        final urlPedidos = Uri.parse('$pedidosBaseUrl/cerrar-mesa');
        response = await http.post(
          urlPedidos,
          headers: headers,
          body: jsonEncode({"mesaId": idMesa}),
        );
      }

      _throwIfUnauthorized(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseTotalCobrado(response.body);
      }

      throw Exception(_extractBackendMessage(
        response.body,
        fallback: 'Error al cerrar mesa: ${response.statusCode}',
      ));
    } catch (e) {
      throw Exception('No se pudo cerrar la mesa: $e');
    }
  }

  double _parseTotalCobrado(String body) {
    if (body.trim().isEmpty) {
      return 0.0;
    }

    try {
      final data = jsonDecode(body);
      if (data is! Map<String, dynamic>) {
        return 0.0;
      }

      final totalRaw = data['totalCobrado'] ??
          (data['data'] is Map<String, dynamic>
              ? data['data']['totalCobrado']
              : null);
      if (totalRaw != null) {
        return double.tryParse(totalRaw.toString()) ?? 0.0;
      }

      final facturacion = data['facturacion'];
      if (facturacion is Map<String, dynamic>) {
        final totalFinal = facturacion['totalFinal'];
        if (totalFinal != null) {
          return double.tryParse(totalFinal.toString()) ?? 0.0;
        }
      }
    } catch (_) {
      // Ignorado: devolvemos 0.0 para respuestas no JSON
    }

    return 0.0;
  }


  // 3. ABRIR / OCUPAR MESA
  Future<void> abrirMesa(int idMesa, int idMozo) async {
    final url = Uri.parse('$baseUrl/$idMesa/abrir');
    debugPrint("🌐 ABRIENDO MESA: $url");

    try {
      final response = await http.post(
        url,
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          "idMozo": idMozo,
        }),
      );
      _throwIfUnauthorized(response);

      if (response.statusCode != 200) {
        throw Exception(_extractBackendMessage(
          response.body,
          fallback: 'Error al abrir mesa: ${response.statusCode}',
        ));
      }
    } catch (e) {
      throw Exception('No se pudo abrir la mesa: $e');
    }
  }
}
