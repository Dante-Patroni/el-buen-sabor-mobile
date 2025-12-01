import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:el_buen_sabor_app/core/database/db_helper.dart';
import '../../domain/models/pedido.dart';
import '../../domain/models/plato.dart';
import '../../domain/repositories/pedido_repository.dart';
import '../models/pedido_model.dart';
import '../models/plato_model.dart';

class PedidoRepositoryImpl implements PedidoRepository {
  final DBHelper _dbHelper = DBHelper.instance;

  // ⚠️ Asegúrate que esta sea la IP de tu PC
  static const String _baseUrl = 'http://192.168.18.3:3000/api';

  @override
  Future<List<Plato>> getMenu() async {
    final url = Uri.parse('$_baseUrl/platos');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((j) => PlatoModel.fromJson(j)).toList();
      } else {
        throw Exception('Error menú: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error conexión menú: $e');
    }
  }

  @override
  Future<int> insertPedido(Pedido pedido) async {
    final url = Uri.parse('$_baseUrl/pedidos');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "cliente": pedido.cliente,
          "platoId": pedido.platoId,
        }),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return json['data']['id'];
      } else {
        throw Exception('Error crear pedido: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error conexión crear: $e');
    }
  }

  @override
  Future<List<Pedido>> getPedidos() async {
    final url = Uri.parse('$_baseUrl/pedidos');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((j) => PedidoModel.fromJson(j)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Error pedidos: $e");
      return [];
    }
  }

  // 🆕 IMPLEMENTACIÓN DEL DELETE
  @override
  Future<void> deletePedido(int id) async {
    final url = Uri.parse('$_baseUrl/pedidos/$id');
    try {
      final response = await http.delete(url);
      if (response.statusCode != 200) {
        throw Exception('Error eliminar: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error conexión eliminar: $e');
    }
  }

  // 🆕 IMPLEMENTACIÓN DEL UPDATE (El que te faltaba)
  @override
  Future<void> updateEstado(int id, EstadoPedido nuevoEstado) async {
    // Implementación local temporal para cumplir con la interfaz
    final db = await _dbHelper.database;
    await db.update(
      'pedidos',
      {'estado': nuevoEstado.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
