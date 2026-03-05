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
  static const String _sessionExpiredMessage =
      'Sesión expirada. Iniciá sesión nuevamente.';

  final DBHelper _dbHelper = DBHelper.instance;
  final StorageService _storage = StorageService();

  // ---------------------------------------------------------------------------
  // 🔐 HELPER PRIVADO: JWT Auth Headers
  // ---------------------------------------------------------------------------

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
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
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
   * @description Extrae un mensaje de error legible desde el body.
   * @param {String} body - Cuerpo de la respuesta HTTP.
   * @param {String} fallback - Mensaje por defecto.
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

  // ===========================================================================
  // 🥘 MENÚ (GET /platos) — Estrategia Offline-First
  // ===========================================================================

  /// Descarga la lista de platos desde el backend.
  /// Si la conexión falla, retorna los platos guardados localmente en SQLite.
  /**
   * @description Obtiene el menu desde backend con fallback offline.
   * @param {bool} forceOnline - Si es true, falla si no puede obtener del backend.
   * @returns {Future<List<PlatoModel>>} Lista de platos.
   * @throws {Exception} Error de sesion o backend.
   */
  Future<List<PlatoModel>> getMenu({bool forceOnline = false}) async {
    try {
      final url = Uri.parse('$_baseUrl/platos');
      final response = await http
          .get(url, headers: await _getAuthHeaders())
          .timeout(const Duration(seconds: 5));
      _throwIfUnauthorized(response);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final platos = jsonList.map((j) => PlatoModel.fromJson(j)).toList();
        await _syncMenuLocal(platos);
        return platos;
      } else {
        throw Exception(
          _extractBackendMessage(
            response.body,
            fallback: 'Error servidor: ${response.statusCode}',
          ),
        );
      }
    } on Exception catch (e) {
      if (e.toString().contains(_sessionExpiredMessage)) {
        rethrow;
      }
      if (forceOnline) {
        throw Exception('No se pudo actualizar el menu desde el servidor.');
      }
      debugPrint('⚠️ Error Menu Online ($e). Usando modo offline.');
      return await _getLocalMenu();
    } catch (e) {
      if (forceOnline) {
        throw Exception('No se pudo actualizar el menu desde el servidor.');
      }
      debugPrint('⚠️ Error Menu Online ($e). Usando modo offline.');
      return await _getLocalMenu();
    }
  }

  /// Lee el menú guardado en SQLite (fallback offline).
  /**
   * @description Lee el menu desde SQLite como fallback offline.
   * @returns {Future<List<PlatoModel>>} Lista de platos locales.
   * @throws {Exception} Error de lectura en SQLite.
   */
  Future<List<PlatoModel>> _getLocalMenu() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('platos');
    if (maps.isEmpty) return [];
    return maps.map((map) => PlatoModel.fromMap(map)).toList();
  }

  /// Guarda el menú descargado en SQLite (sobrescribe lo anterior).
  /**
   * @description Sincroniza el menu en SQLite.
   * @param {List<PlatoModel>} platos - Platos descargados.
   * @returns {Future<void>} Operacion asincronica sin valor de retorno.
   * @throws {Exception} Error de escritura en SQLite.
   */
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

  /**
   * @description Obtiene rubros desde el backend.
   * @returns {Future<List<Rubro>>} Lista de rubros.
   * @throws {Exception} Error de red o backend.
   */
  Future<List<Rubro>> getRubros() async {
    try {
      final url = Uri.parse('$_baseUrl/rubros');
      final response = await http.get(url, headers: await _getAuthHeaders());
      _throwIfUnauthorized(response);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((j) => Rubro.fromJson(j)).toList();
      } else {
        throw Exception(
          _extractBackendMessage(
            response.body,
            fallback: 'Error cargando rubros: ${response.statusCode}',
          ),
        );
      }
    } on Exception catch (e) {
      if (e.toString().contains(_sessionExpiredMessage)) {
        rethrow;
      }
      debugPrint('⚠️ Error cargando rubros: $e');
      return [];
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
  /**
   * @description Obtiene pedidos y los transforma a una lista plana.
   * @returns {Future<List<PedidoModel>>} Lista de pedidos.
   * @throws {Exception} Error de red o backend.
   */
  Future<List<PedidoModel>> getPedidos() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pedidos'),
        headers: await _getAuthHeaders(),
      );
      _throwIfUnauthorized(response);

      if (response.statusCode == 200) {
        return _parsePedidosFromResponseBody(response.body);
      } else {
        throw Exception(
          _extractBackendMessage(
            response.body,
            fallback: 'Error al cargar pedidos: ${response.statusCode}',
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error en getPedidos: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  /**
   * @description Obtiene pedidos filtrados por mesa.
   * @param {String} mesa - Numero o id de mesa.
   * @returns {Future<List<PedidoModel>>} Lista de pedidos de la mesa.
   * @throws {Exception} Error de red o backend.
   */
  Future<List<PedidoModel>> getPedidosPorMesa(String mesa) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pedidos/mesa/$mesa'),
        headers: await _getAuthHeaders(),
      ); 
      _throwIfUnauthorized(response);

      if (response.statusCode == 200) {
        return _parsePedidosFromResponseBody(response.body);
      }

      throw Exception(
        _extractBackendMessage(
          response.body,
          fallback: 'Error al cargar pedidos de mesa: ${response.statusCode}',
        ),
      );
    } catch (e) {
      debugPrint('❌ Error en getPedidosPorMesa($mesa): $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // ===========================================================================
  // 🚀 INSERTAR PEDIDO (POST /pedidos)
  // ===========================================================================

  /**
   * @description Inserta un pedido con items en el backend.
   * @param {String} mesaId - Identificador de mesa.
   * @param {List<Pedido>} carrito - Items del pedido.
   * @returns {Future<int>} Id del pedido creado.
   * @throws {Exception} Error de red, backend o validacion.
   */
  Future<int> insertPedido(String mesaId, List<Pedido> carrito) async {
    final url = Uri.parse('$_baseUrl/pedidos');
    debugPrint('🚀 [DataSource] Enviando a $url');

    try {
      if (carrito.isEmpty) {
        throw Exception('No hay productos para enviar.');
      }
      final headers = await _getAuthHeaders();
      final clientePedido = carrito.first.cliente.trim().isNotEmpty
          ? carrito.first.cliente.trim()
          : 'Cliente Anónimo';

      final List<Map<String, dynamic>> listaProductos = carrito.map((item) {
        return {
          'platoId': item.platoId,
          'cantidad': item.cantidad,
          'aclaracion': item.aclaracion ?? '',
        };
      }).toList();

      final Map<String, dynamic> bodyData = {
        'mesa': mesaId,
        'cliente': clientePedido,
        'productos': listaProductos,
      };

      final String jsonBody = jsonEncode(bodyData);
      debugPrint('📦 JSON DATA: $jsonBody');

      final response = await http
          .post(url, headers: headers, body: jsonBody)
          .timeout(const Duration(seconds: 10));
      _throwIfUnauthorized(response);

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
        throw Exception(_extractBackendMessage(
          response.body,
          fallback: 'Backend rechazó (${response.statusCode})',
        ));
      }
    } catch (e) {
      throw Exception('Fallo al enviar: $e');
    }
  }

  // ===========================================================================
  // 🗑️ ELIMINAR PEDIDO (DELETE /pedidos/:id)
  // ===========================================================================

  /**
   * @description Elimina un pedido completo por id.
   * @param {int} id - Id del pedido.
   * @returns {Future<void>} Operacion asincronica sin valor de retorno.
   * @throws {Exception} Error de red o backend.
   */
  Future<void> deletePedido(int id) async {
    final url = Uri.parse('$_baseUrl/pedidos/$id');
    try {
      final response = await http.delete(url, headers: await _getAuthHeaders());
      _throwIfUnauthorized(response);
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          _extractBackendMessage(
            response.body,
            fallback: 'Error al eliminar pedido (${response.statusCode})',
          ),
        );
      }
    } catch (e) {
      throw Exception('No se pudo eliminar el pedido: $e');
    }
  }

  // ===========================================================================
  // 🔄 MODIFICAR PEDIDO (PUT /pedidos/modificar)
  // ===========================================================================

  /**
   * @description Modifica un pedido completo en el backend.
   * @param {int} pedidoId - Id del pedido.
   * @param {String} mesa - Numero o id de mesa.
   * @param {List<Pedido>} pedidoModificado - Items modificados.
   * @returns {Future<void>} Operacion asincronica sin valor de retorno.
   * @throws {Exception} Error de red, backend o validacion.
   */
  Future<void> modificarPedido(
      int pedidoId, String mesa, List<Pedido> pedidoModificado) async {
    final url = Uri.parse('$_baseUrl/pedidos/modificar');

    try {
      if (pedidoModificado.isEmpty) {
        throw Exception('El pedido no puede quedar sin productos.');
      }
      final headers = await _getAuthHeaders();
      final clientePedido = pedidoModificado.first.cliente.trim().isNotEmpty
          ? pedidoModificado.first.cliente.trim()
          : 'Cliente Anónimo';

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
        'cliente': clientePedido,
        'productos': listaProductos,
      };

      final String jsonBody = jsonEncode(bodyData);
      debugPrint('🔄 [DataSource] Modificando pedido $pedidoId: $jsonBody');

      final response = await http
          .put(url, headers: headers, body: jsonBody)
          .timeout(const Duration(seconds: 10));
      _throwIfUnauthorized(response);

      debugPrint('📥 [DataSource] Response Status: ${response.statusCode}');
      debugPrint('📥 [DataSource] Response Body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(_extractBackendMessage(
          response.body,
          fallback: 'Error modificando pedido: ${response.statusCode}',
        ));
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

  /**
   * @description Mapea un estado crudo a EstadoPedido.
   * @param {String?} estado - Estado en string.
   * @returns {EstadoPedido} Estado normalizado.
   * @throws {Error} No lanza errores por diseno.
   */
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

  /**
   * @description Parsea la respuesta de pedidos a una lista plana.
   * @param {String} body - Cuerpo de la respuesta HTTP.
   * @returns {List<PedidoModel>} Lista de pedidos.
   * @throws {Error} No lanza errores por diseno.
   */
  List<PedidoModel> _parsePedidosFromResponseBody(String body) {
    final decoded = jsonDecode(body);
    final List<dynamic> jsonList = decoded is Map<String, dynamic>
        ? (decoded['data'] as List<dynamic>? ?? [])
        : (decoded as List<dynamic>? ?? []);
    final List<PedidoModel> listaAplanada = [];

    for (var jsonPedido in jsonList) {
      final detallesRaw = jsonPedido['DetallePedidos'] ?? jsonPedido['detallePedidos'];
      if (detallesRaw == null) continue;

      final detalles = detallesRaw as List;
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
            platoId: detalle['PlatoId'] ?? detalle['platoId'] ?? 0,
            cantidad: detalle['cantidad'] ?? 1,
            total: double.tryParse(detalle['subtotal'].toString()) ?? 0.0,
            aclaracion: detalle['aclaracion']?.toString() ?? '',
          ),
        );
      }
    }
    return listaAplanada;
  }
}
