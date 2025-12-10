import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:el_buen_sabor_app/core/database/db_helper.dart';
import '../../domain/models/pedido.dart';
import '../../domain/models/plato.dart';
import '../../domain/repositories/pedido_repository.dart';
import '../models/pedido_model.dart';
import '../models/plato_model.dart';

class PedidoRepositoryImpl implements PedidoRepository {
  // Arquitectura híbrida: API REST + Base de datos local
  final DBHelper _dbHelper = DBHelper.instance;

  // ⚠️ IP local del servidor Node.js
  static const String _baseUrl = 'http://192.168.18.3:3000/api';

  // ===========================================================================
  // 🥘 GET MENU (HÍBRIDO: Network First -> Fallback to Cache)
  // ===========================================================================
  @override
  Future<List<Plato>> getMenu() async {
    try {
      // 1. INTENTO ONLINE
      final url = Uri.parse('$_baseUrl/platos');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final platosOnline =
            jsonList.map((j) => PlatoModel.fromJson(j)).toList();

        // 💾 SINCRONIZACIÓN: Guardamos en SQLite
        await _syncMenuLocal(platosOnline);

        return platosOnline;
      } else {
        throw Exception('Error servidor: ${response.statusCode}');
      }
    } catch (e) {
      // 2. FALLBACK OFFLINE
      return await _getLocalMenu();
    }
  }

  // 📥 Helper: Leer de SQLite
  Future<List<Plato>> _getLocalMenu() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('platos');
    if (maps.isEmpty) return [];
    return maps.map((map) => PlatoModel.fromMap(map)).toList();
  }

  // 💾 Helper: Guardar en SQLite (Upsert)
  Future<void> _syncMenuLocal(List<PlatoModel> platos) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (var plato in platos) {
        await txn.insert(
          'platos',
          plato.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // ===========================================================================
  // 📝 INSERTAR PEDIDO (CORREGIDO)
  // ===========================================================================
  @override
  Future<int> insertPedido(Pedido pedido) async {
    final url = Uri.parse('$_baseUrl/pedidos');
    try {
      // 👇 1. CONVERSIÓN (Aquí ocurre la magia)
      // Transformamos la Entidad pura en un Modelo capaz de convertirse a JSON
      final pedidoModel = PedidoModel.fromEntity(pedido);
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        // 👇 CAMBIO CLAVE: Usamos .toJson() para manejar el ENUM automáticamente
        body: jsonEncode(pedidoModel.toJson()),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);

        // 👇 SOLUCIÓN DEL ERROR 'Null subtype':
        // Verificamos que 'id' exista antes de devolverlo
        if (json is Map && json.containsKey('id')) {
          return int.parse(json['id'].toString());
        }
        return 0; // Si el backend no devuelve ID, devolvemos 0 (seguro)
      } else {
        final errorJson = jsonDecode(response.body);
        throw Exception(
            errorJson['error'] ?? 'Error desconocido al crear pedido');
      }
    } catch (e) {
      throw Exception('No se pudo enviar el pedido: $e');
    }
  }

  // ===========================================================================
  // 📋 GET PEDIDOS
  // ===========================================================================
  @override
  Future<List<Pedido>> getPedidos() async {
    final url = Uri.parse('$_baseUrl/pedidos');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        // Usamos Pedido.fromJson para que parsee el ENUM correctamente
        return jsonList.map((j) => PedidoModel.fromJson(j)).toList();
      } else {
        throw Exception('Error al cargar pedidos: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  // ===========================================================================
  // 🗑️ DELETE PEDIDO
  // ===========================================================================
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

  // ===========================================================================
  // 🔄 UPDATE ESTADO
  // ===========================================================================
  @override
  Future<void> updateEstado(int id, EstadoPedido nuevoEstado) async {
    final db = await _dbHelper.database;
    await db.update(
      'pedidos',
      {'estado': nuevoEstado.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
