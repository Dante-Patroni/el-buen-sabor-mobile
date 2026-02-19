import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/database/db_helper.dart';

import '../../domain/models/pedido.dart';
import '../../domain/models/rubro_model.dart';
import '../models/pedido_model.dart';
import '../models/plato_model.dart';

/// **PedidoDataSource**
///
/// Responsabilidad única: hablar con el mundo exterior.
/// Sabe cómo hacer peticiones HTTP al backend y leer/escribir en SQLite local.
/// NO conoce a Provider ni a la UI. Solo trabaja con datos crudos (modelos).
///
/// Arquitectura:
/// ```
/// PedidoProvider → PedidoRepository → PedidoRepositoryImpl → [PedidoDataSource] → Backend / SQLite
/// ```
class PedidoDataSource {
  static const String _baseUrl = AppConfig.apiBaseUrl;

  final DBHelper _dbHelper = DBHelper.instance;
  final StorageService _storage = StorageService();

  // ---------------------------------------------------------------------------
  // 🔐 HELPER PRIVADO: JWT Auth Headers
  // ---------------------------------------------------------------------------

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ===========================================================================
  // 🥘 MENÚ (GET /platos) — Estrategia Offline-First
  // ===========================================================================

  /// Descarga la lista de platos desde el backend.
  /// Si la conexión falla, retorna los platos guardados localmente en SQLite.
  Future<List<PlatoModel>> getMenu() async {
    try {
      final url = Uri.parse('$_baseUrl/platos');
      final response = await http
          .get(url, headers: await _getAuthHeaders())
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final platos = jsonList.map((j) => PlatoModel.fromJson(j)).toList();
        await _syncMenuLocal(platos);
        return platos;
      } else {
        throw Exception('Error servidor: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Error Menu Online ($e). Usando modo offline.');
      return await _getLocalMenu();
    }
  }

  /// Lee el menú guardado en SQLite (fallback offline).
  Future<List<PlatoModel>> _getLocalMenu() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('platos');
    if (maps.isEmpty) return [];
    return maps.map((map) => PlatoModel.fromMap(map)).toList();
  }

  /// Guarda el menú descargado en SQLite (sobrescribe lo anterior).
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

  // ===========================================================================
  // 🌳 RUBROS (GET /rubros)
  // ===========================================================================

  Future<List<Rubro>> getRubros() async {
    try {
      final url = Uri.parse('$_baseUrl/rubros');
      final response = await http.get(url, headers: await _getAuthHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((j) => Rubro.fromJson(j)).toList();
      } else {
        throw Exception('Error cargando rubros: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Error cargando rubros: $e');
      return [];
    }
  }

  // ===========================================================================
  // 📝 PEDIDOS (GET /pedidos)
  // ===========================================================================

  /// Obtiene el historial de pedidos del backend.
  /// La respuesta del backend es jerárquica (ticket → detalles).
  /// Este método la "aplana" en una lista de PedidoModel para facilitar el uso.
  Future<List<PedidoModel>> getPedidos() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pedidos'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> jsonList = decoded['data'] ?? [];
        final List<PedidoModel> listaAplanada = [];

        for (var jsonPedido in jsonList) {
          if (jsonPedido['DetallePedidos'] != null) {
            final detalles = jsonPedido['DetallePedidos'] as List;
            for (var detalle in detalles) {
              listaAplanada.add(
                PedidoModel(
                  id: jsonPedido['id'],
                  mesa: jsonPedido['mesa']?.toString() ?? '',
                  cliente: jsonPedido['cliente']?.toString() ?? 'Anónimo',
                  estado: _mapEstado(jsonPedido['estado']),
                  fecha: jsonPedido['createdAt'] != null
                      ? DateTime.parse(jsonPedido['createdAt'])
                      : null,
                  platoId: detalle['PlatoId'] ?? 0,
                  cantidad: detalle['cantidad'] ?? 1,
                  total: double.tryParse(detalle['subtotal'].toString()) ?? 0.0,
                  aclaracion: '',
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
      debugPrint('❌ Error en getPedidos: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // ===========================================================================
  // 🚀 INSERTAR PEDIDO (POST /pedidos)
  // ===========================================================================

  Future<int> insertPedido(String mesaId, List<Pedido> carrito) async {
    final url = Uri.parse('$_baseUrl/pedidos');
    debugPrint('🚀 [DataSource] Enviando a $url');

    try {
      final headers = await _getAuthHeaders();

      final List<Map<String, dynamic>> listaProductos = carrito.map((item) {
        return {
          'platoId': item.platoId,
          'cantidad': item.cantidad,
          'aclaracion': item.aclaracion ?? '',
        };
      }).toList();

      final Map<String, dynamic> bodyData = {
        'mesa': mesaId,
        'cliente': 'Cliente App',
        'productos': listaProductos,
      };

      final String jsonBody = jsonEncode(bodyData);
      debugPrint('📦 JSON DATA: $jsonBody');

      final response = await http
          .post(url, headers: headers, body: jsonBody)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is Map) {
          if (json['data'] != null && json['data']['id'] != null) {
            return int.parse(json['data']['id'].toString());
          }
          if (json['id'] != null) {
            return int.parse(json['id'].toString());
          }
        }
        return 1;
      } else if (response.statusCode == 409) {
        final errorJson = jsonDecode(response.body);
        throw Exception(errorJson['error'] ?? 'Stock insuficiente');
      } else {
        throw Exception(
            'Backend rechazó (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Fallo al enviar: $e');
    }
  }

  // ===========================================================================
  // 🗑️ ELIMINAR PEDIDO (DELETE /pedidos/:id)
  // ===========================================================================

  Future<void> deletePedido(int id) async {
    final url = Uri.parse('$_baseUrl/pedidos/$id');
    try {
      await http.delete(url, headers: await _getAuthHeaders());
    } catch (_) {
      // Fail silent: si falla el borrado en servidor, no propagamos el error
    }
  }

  // ===========================================================================
  // 🔄 MODIFICAR PEDIDO (PUT /pedidos/modificar)
  // ===========================================================================

  Future<void> modificarPedido(
      int pedidoId, String mesa, List<Pedido> pedidoModificado) async {
    final url = Uri.parse('$_baseUrl/pedidos/modificar');

    try {
      final headers = await _getAuthHeaders();

      final List<Map<String, dynamic>> listaProductos =
          pedidoModificado.map((item) {
        return {
          'platoId': item.platoId,
          'cantidad': item.cantidad,
          'aclaracion': item.aclaracion ?? '',
        };
      }).toList();

      final Map<String, dynamic> bodyData = {
        'id': pedidoId,
        'mesa': mesa,
        'cliente': 'Cliente App',
        'productos': listaProductos,
      };

      final String jsonBody = jsonEncode(bodyData);
      debugPrint('🔄 [DataSource] Modificando pedido $pedidoId: $jsonBody');

      final response = await http
          .put(url, headers: headers, body: jsonBody)
          .timeout(const Duration(seconds: 10));

      debugPrint('📥 [DataSource] Response Status: ${response.statusCode}');
      debugPrint('📥 [DataSource] Response Body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
            'Error modificando pedido: ${response.statusCode} - ${response.body}');
      }

      debugPrint('✅ Pedido $pedidoId modificado exitosamente');
    } catch (e) {
      debugPrint('❌ Error en modificarPedido: $e');
      throw Exception('Fallo al modificar: $e');
    }
  }

  // ===========================================================================
  // 🔧 HELPERS PRIVADOS
  // ===========================================================================

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
      case 'pagado':
        return EstadoPedido.pagado;
      default:
        return EstadoPedido.pendiente;
    }
  }
}
