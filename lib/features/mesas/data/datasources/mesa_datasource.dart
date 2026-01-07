import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart'; // 👈 Importamos Config Central
import '../../../../core/services/storage_service.dart'; // 👈 Importamos la Caja Fuerte
import '../models/mesa_model.dart';

class MesaDataSource {
  // ⚠️ Tu IP local correcta
  final String baseUrl = '${AppConfig.apiBaseUrl}/mesas';

  // Instancia del servicio de almacenamiento
  final StorageService _storage = StorageService();

  // 🔐 HELPER: Obtener Headers con Token
  Future<Map<String, String>> _getAuthHeaders() async {
    // Leemos el token de la caja fuerte
    String? token = await _storage.getToken();

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token", // 👈 LA LLAVE MAESTRA
    };
  }

  // 1. GET MESAS (Ahora blindado)
  Future<List<MesaModel>> getMesasFromApi() async {
    try {
      final url = Uri.parse(baseUrl);

      // 👇 Inyectamos los headers aquí
      final response = await http.get(url, headers: await _getAuthHeaders());

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => MesaModel.fromJson(json)).toList();
      } else {
        // Si el token expiró o es inválido, aquí saltará el error
        throw Exception('Error API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // 2. CERRAR MESA (Ahora blindado)
  Future<void> cerrarMesa(int id) async {
    final url = Uri.parse('$baseUrl/$id/cierre');

    debugPrint("🌐 CERRANDO MESA EN: $url");

    try {
      // 👇 Inyectamos los headers aquí también
      final response = await http.post(
        url,
        headers: await _getAuthHeaders(),
        body: jsonEncode({"estado": "libre"}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 3. ABRIR / OCUPAR MESA
Future<void> abrirMesa(int idMesa, int idMozo) async {
  final url = Uri.parse('$baseUrl/$idMesa/abrir');

  debugPrint("🌐 ABRIENDO MESA: $url");

  try {
    final response = await http.post(
      url,
      headers: await _getAuthHeaders(),// Inyectamos headers con token
      body: jsonEncode({
        "idMozo": idMozo,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al abrir mesa: ${response.statusCode}');
    }
  } catch (e) {
    rethrow;
  }
}

  // 4. CERRAR MESA Y FACTURAR
  /// 
  /// **Responsabilidad:** Comunicarse con el backend para cerrar una mesa
  /// y procesar la facturación de todos sus pedidos.
  /// 
  /// **Flujo:**
  /// 1. Construye la URL del endpoint `/pedidos/cerrar-mesa`
  /// 2. Obtiene el token de autenticación
  /// 3. Envía POST con el id de la mesa
  /// 4. Parsea la respuesta y extrae el total cobrado
  /// 
  /// **Arquitectura:** Esta es la capa más baja (DataSource).
  /// Aquí es donde se hacen las llamadas HTTP reales.
  /// La UI nunca debería llamar este método directamente.
  Future<double> cerrarMesaYFacturar(int idMesa) async {
    // ⚠️ NOTA: Este endpoint está en /pedidos, no en /mesas
    // porque cierra pedidos, no solo cambia el estado de la mesa
    final url = Uri.parse('${AppConfig.apiBaseUrl}/pedidos/cerrar-mesa');

    debugPrint("🌐 CERRANDO MESA Y FACTURANDO: $url");

    try {
      final response = await http.post(
        url,
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          "mesaId": idMesa,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // El backend devuelve { "totalCobrado": 1234.56 }
        final totalCobrado = double.tryParse(data['totalCobrado'].toString()) ?? 0.0;
        return totalCobrado;
      } else {
        // Si el servidor responde con error, lanzamos excepción
        throw Exception('Error al cerrar mesa: ${response.statusCode}');
      }
    } catch (e) {
      // Re-lanzamos la excepción para que la capa superior la maneje
      rethrow;
    }
  }

}
