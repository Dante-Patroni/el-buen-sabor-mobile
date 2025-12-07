import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mesa_model.dart';

class MesaDataSource {
  // ⚠️ RECUERDA: 10.0.2.2 para emulador Android
  final String baseUrl = 'http://192.168.18.3:3000/api/mesas';

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
}
