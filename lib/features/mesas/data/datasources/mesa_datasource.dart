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
  /**
   * @description Construye headers HTTP con token JWT.
   * @returns {Future<Map<String, String>>} Headers con Authorization.
   * @throws {Exception} Sesion expirada o token ausente.
   */
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

  /**
   * @description Lanza error si la respuesta es 401/403.
   * @param {http.Response} response - Respuesta HTTP.
   * @returns {void} No retorna valor.
   * @throws {Exception} Sesion expirada.
   */
  void _throwIfUnauthorized(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception(_sessionExpiredMessage);
    }
  }

  /**
   * @description Extrae un mensaje de error desde el body del backend.
   * @param {String} body - Cuerpo de la respuesta HTTP.
   * @param {String} fallback - Mensaje por defecto si no hay mensaje.
   * @returns {String} Mensaje de error.
   * @throws {Error} No lanza errores; devuelve fallback si falla el parseo.
   */
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
  /**
   * @description Obtiene el listado de mesas desde el backend.
   * @returns {Future<List<MesaModel>>} Lista de mesas.
   * @throws {Exception} Error de red, backend o sesion.
   */
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

  // 2. SOLICITAR COBRO (FACTURACIÓN BACKEND)
 /**
 * @description Solicita a caja el cierre y cobro de una mesa.
 * @param {int} idMesa - Identificador de la mesa.
 * @returns {Future<void>} Confirmación de solicitud.
 * @throws {Exception} Error de red, backend o sesión.
 */
Future<void> solicitarCobro(int idMesa) async {
  try {
    final headers = await _getAuthHeaders();

    final url = Uri.parse(
      '$baseUrl/$idMesa/solicitar-cobro',
    );

    print('📡 SOLICITANDO COBRO - URL: $url');
    print('📡 HEADERS: $headers');

    final response = await http.post(
      url,
      headers: headers,
    );

    print('📡 RESPUESTA SOLICITARCOBRO - Status: ${response.statusCode}');
    print('📡 BODY: ${response.body}');

    _throwIfUnauthorized(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      print('✅ COBRO SOLICITADO EXITOSAMENTE');
      return;
    }

    throw Exception(
      _extractBackendMessage(
        response.body,
        fallback:
            'Error al solicitar cobro: ${response.statusCode}',
      ),
    );
  } catch (e) {
    print('❌ ERROR EN SOLICITARCOBRO: $e');
    throw Exception(
      'No se pudo solicitar el cobro: $e',
    );
  }
}

  /**
   * @description Parsea el total cobrado desde una respuesta JSON.
   * @param {String} body - Cuerpo de la respuesta HTTP.
   * @returns {double} Total cobrado o 0.0 si no se puede parsear.
   * @throws {Error} No lanza errores; retorna 0.0 si falla.
   */
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
  /**
   * @description Abre u ocupa una mesa asignando un mozo.
   * @param {int} idMesa - Identificador de la mesa.
   * @param {int} idMozo - Identificador del mozo.
   * @returns {Future<void>} Operacion asincronica sin valor de retorno.
   * @throws {Exception} Error de red, backend o sesion.
   */
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
