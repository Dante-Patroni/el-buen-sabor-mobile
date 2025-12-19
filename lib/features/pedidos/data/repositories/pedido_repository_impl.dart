import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

// 👇 Importamos el servicio de seguridad y el DB Helper
import '../../../../core/services/storage_service.dart';
import '../../../../core/database/db_helper.dart';

import '../../domain/models/pedido.dart';
import '../../domain/models/plato.dart';
import '../../domain/repositories/pedido_repository.dart';
import '../models/pedido_model.dart';
import '../models/plato_model.dart';

class PedidoRepositoryImpl implements PedidoRepository {
  final DBHelper _dbHelper = DBHelper.instance;
  final StorageService _storage = StorageService();

  // ⚠️ Tu IP
  static const String _baseUrl = 'http://192.168.18.3:3000/api';

  // 🔐 HELPER: Obtener Headers con Token
  Future<Map<String, String>> _getAuthHeaders() async {
    String? token = await _storage.getToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // ===========================================================================
  // 🥘 GET MENU (Blindado)
  // ===========================================================================
  @override
  Future<List<Plato>> getMenu() async {
    try {
      final url = Uri.parse('$_baseUrl/platos'); // ✅ Usamos _baseUrl

      final response = await http
          .get(url, headers: await _getAuthHeaders())
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final platosOnline = jsonList
            .map((j) => PlatoModel.fromJson(j))
            .toList();

        await _syncMenuLocal(platosOnline);
        return platosOnline;
      } else {
        throw Exception('Error servidor: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("⚠️ Error Menu Online ($e). Usando modo offline.");
      return await _getLocalMenu();
    }
  }

  // ===========================================================================
  // 📝 GET PEDIDOS (SOLUCIÓN FALTA PLATO 0)
  // ===========================================================================
  @override
  Future<List<Pedido>> getPedidos() async {
    try {
      // ✅ Corregido: Usamos _baseUrl (con guion bajo)
      final response = await http.get(
        Uri.parse('$_baseUrl/pedidos'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final List<Pedido> listaAplanada = [];

        // 🔄 RECORREMOS LOS TICKETS (PEDIDOS PADRE)
        for (var jsonPedido in jsonList) {
          // Verificamos si tiene detalles (los platos)
          if (jsonPedido['DetallePedidos'] != null) {
            final detalles = jsonPedido['DetallePedidos'] as List;

            // 🔄 RECORREMOS LOS DETALLES (HIJOS)
            for (var detalle in detalles) {
              // CREAMOS UN PEDIDO VISUAL POR CADA PLATO
              listaAplanada.add(
                PedidoModel(
                  id: jsonPedido['id'],
                  mesa: jsonPedido['mesa']?.toString() ?? '',
                  cliente: jsonPedido['cliente']?.toString() ?? 'Anónimo',
                  estado: _mapEstado(jsonPedido['estado']),
                  fecha: jsonPedido['createdAt'] != null
                      ? DateTime.parse(jsonPedido['createdAt'])
                      : null,

                  // 👇 ESTO REQUIERE QUE HAYAS ACTUALIZADO PEDIDO_MODEL.DART
                  platoId: detalle['PlatoId'] ?? 0,
                  cantidad: detalle['cantidad'] ?? 1,
                  total: double.tryParse(detalle['subtotal'].toString()) ?? 0.0,
                  aclaracion: "",
                ),
              );
            }
          }
        }

        return listaAplanada;
      } else {
        throw Exception('Error al cargar pedidos: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Error en getPedidos: $e");
      throw Exception('Error de conexión: $e');
    }
  }

  EstadoPedido _mapEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'pendiente':
        return EstadoPedido.pendiente;
      case 'en_preparacion':
        return EstadoPedido.enPreparacion;
      case 'entregado':
        return EstadoPedido.entregado;
      case 'rechazado':
        return EstadoPedido.rechazado;
      case 'cancelado':
        return EstadoPedido.cancelado;
      default:
        return EstadoPedido.pendiente;
    }
  }

  // ===========================================================================
  // 🚀 INSERTAR PEDIDO
  // ===========================================================================
  @override
  Future<int> insertPedido(String mesaId, List<Pedido> carrito) async {
    final url = Uri.parse('$_baseUrl/pedidos'); // ✅ Corregido _baseUrl

    try {
      final List<Map<String, dynamic>> listaProductos = carrito.map((item) {
        return {
          "platoId": item.platoId,
          "cantidad": item.cantidad,
          "aclaracion": item.aclaracion ?? "",
        };
      }).toList();

      final Map<String, dynamic> bodyData = {
        "mesa": mesaId,
        "cliente": "Cliente App",
        "productos": listaProductos,
      };

      final String jsonBody = jsonEncode(bodyData);

      final response = await http.post(
        url,
        headers: await _getAuthHeaders(),
        body: jsonBody,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body);

        // 👇 MEJORA: Buscar ID dentro de 'data' si existe (basado en tus logs)
        if (json is Map) {
          if (json.containsKey('data') &&
              json['data'] is Map &&
              json['data'].containsKey('id')) {
            return int.parse(json['data']['id'].toString());
          }
          if (json.containsKey('id')) {
            return int.parse(json['id'].toString());
          }
        }
        return 1; // Éxito genérico si no encontramos ID
      } else {
        throw Exception('Error Backend: ${response.body}');
      }
    } catch (e) {
      debugPrint("❌ ERROR CRÍTICO: $e");
      throw Exception('No se pudo enviar el pedido: $e');
    }
  }

  // ===========================================================================
  // 🗑️ DELETE PEDIDO
  // ===========================================================================
  @override
  Future<void> deletePedido(int id) async {
    final url = Uri.parse('$_baseUrl/pedidos/$id');
    try {
      await http.delete(url, headers: await _getAuthHeaders());
    } catch (_) {}
  }

  // Implementación vacía para cumplir contrato
  @override
  Future<void> updateEstado(int id, EstadoPedido nuevoEstado) async {}

  // ---------------------------------------------------------------------------
  // 💾 MÉTODOS LOCALES
  // ---------------------------------------------------------------------------
  Future<List<Plato>> _getLocalMenu() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('platos');
    if (maps.isEmpty) return [];
    return maps.map((map) => PlatoModel.fromMap(map)).toList();
  }

  Future<void> _syncMenuLocal(List<PlatoModel> platos) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('platos');
      for (var plato in platos) {
        await txn.insert(
          'platos',
          plato.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
