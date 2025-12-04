import 'dart:convert'; // Para jsonDecode y jsonEncode
import 'package:http/http.dart' as http; // Para hacer peticiones HTTP
import 'package:sqflite/sqflite.dart'; // Importante para ConflictAlgorithm
import 'package:el_buen_sabor_app/core/database/db_helper.dart';
import '../../domain/models/pedido.dart';
import '../../domain/models/plato.dart';
import '../../domain/repositories/pedido_repository.dart';
import '../models/pedido_model.dart';
import '../models/plato_model.dart';

class PedidoRepositoryImpl implements PedidoRepository {
  // Arquitectura híbrida: API REST + Base de datos local
  final DBHelper _dbHelper = DBHelper.instance; 

  // ⚠️ IP local del servidor Node.js (Asegúrate que sea la correcta)
  static const String _baseUrl = 'http://192.168.18.3:3000/api';

  // ===========================================================================
  // 🥘 GET MENU (HÍBRIDO: Network First -> Fallback to Cache)
  // ===========================================================================
  @override
  Future<List<Plato>> getMenu() async {
    print("🔄 [REPO] Buscando menú...");

    try {
      // ---------------------------------------------------------
      // 1. INTENTO ONLINE (Network)
      // ---------------------------------------------------------
      final url = Uri.parse('$_baseUrl/platos');
      final response = await http.get(url).timeout(const Duration(seconds: 5)); // Timeout corto

      if (response.statusCode == 200) {
        print("✅ [REPO] Conexión API exitosa. Actualizando base local...");
        
        final List<dynamic> jsonList = jsonDecode(response.body);
        
        // Convertimos JSON -> Objetos Dart
        final platosOnline = jsonList.map((j) => PlatoModel.fromJson(j)).toList();

        // 💾 SINCRONIZACIÓN: Guardamos en SQLite para uso futuro
        await _syncMenuLocal(platosOnline);

        return platosOnline;
      } else {
        print("⚠️ [REPO] Error API: ${response.statusCode}");
        throw Exception('Error servidor: ${response.statusCode}');
      }

    } catch (e) {
      // ---------------------------------------------------------
      // 2. FALLBACK OFFLINE (Local SQLite)
      // ---------------------------------------------------------
      print("🔌 [REPO] Sin conexión o error ($e). Cargando datos locales...");
      return await _getLocalMenu();
    }
  }

  // 📥 Helper: Leer de SQLite
  Future<List<Plato>> _getLocalMenu() async {
    final db = await _dbHelper.database;
    // Traemos TODAS las columnas, incluyendo las nuevas stock_cantidad, stock_estado...
    final List<Map<String, dynamic>> maps = await db.query('platos');

    if (maps.isEmpty) {
      print("📭 [REPO] Base de datos local vacía.");
      return [];
    }

    // Usamos el fromMap que actualizamos en el paso anterior
    return maps.map((map) => PlatoModel.fromMap(map)).toList();
  }

  // 💾 Helper: Guardar en SQLite (Upsert)
  Future<void> _syncMenuLocal(List<PlatoModel> platos) async {
    final db = await _dbHelper.database;
    
    // Usamos una transacción para que sea rápido y seguro
    await db.transaction((txn) async {
      // Opcional: Podrías borrar todo antes si quieres limpiar platos viejos
      // await txn.delete('platos'); 

      for (var plato in platos) {
        // Insertamos o Reemplazamos si el ID ya existe
        // Aquí se usa el toMap que incluye el stock aplanado
        await txn.insert(
          'platos',
          plato.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    print("💾 [REPO] ${platos.length} platos guardados en SQLite.");
  }

  // ===========================================================================
  // 📝 INSERTAR PEDIDO
  // ===========================================================================
  @override
  Future<int> insertPedido(Pedido pedido) async {
    final url = Uri.parse('$_baseUrl/pedidos');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "mesa": pedido.mesa,
          "cliente": pedido.cliente,
          "platoId": pedido.platoId,
        }),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return json['id']; 
      } else {
        // Aquí podríamos capturar errores de stock (409)
        final errorJson = jsonDecode(response.body); 
        throw Exception(errorJson['error'] ?? 'Error desconocido al crear pedido');
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
        return jsonList.map((j) => PedidoModel.fromJson(j)).toList();
      } else {
        throw Exception('Error al cargar pedidos: ${response.statusCode}');
      }
    } catch (e) {
      print("⚠️ Error obteniendo pedidos: $e");
      return []; // Retornamos vacío para no romper la UI
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
  // 🔄 UPDATE ESTADO (Local simulado por ahora)
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