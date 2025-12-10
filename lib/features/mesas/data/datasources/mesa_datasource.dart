import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/mesa_model.dart';

class MesaDataSource {
  // ⚠️ Tu IP local
  final String baseUrl = 'http://192.168.18.3:3000/api/mesas';

  // 1. GET MESAS (El que ya tenías)
  Future<List<MesaModel>> getMesasFromApi() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => MesaModel.fromJson(json)).toList();
      } else {
        throw Exception('Error API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // 👇 2. CERRAR MESA (El nuevo método)
  // Aquí encapsulamos toda la lógica sucia de la API
  // 2. SOLO MODIFICAMOS ESTE (Para coincidir con tu Backend)
  Future<void> cerrarMesa(int id) async {
    // 👇 AQUÍ AGREGAMOS "/cierre" PORQUE TU BACKEND LO PIDE
    final url = Uri.parse('$baseUrl/$id/cierre'); 
    
    debugPrint("🌐 CERRANDO MESA EN: $url");

    try {
      // 👇 USAMOS POST (Porque en tu ruta dice router.post)
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"estado": "libre"}), 
      );

      if (response.statusCode != 200) {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}