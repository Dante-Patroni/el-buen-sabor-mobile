import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

// 👇 Importamos el servicio de seguridad y el DB Helper
import '../../../../core/services/storage_service.dart';
import '../../../../core/database/db_helper.dart';
import '../../../../core/config/app_config.dart';

import '../../domain/models/pedido.dart';
import '../../domain/models/plato.dart';
import '../../domain/repositories/pedido_repository.dart';
import '../models/pedido_model.dart';
import '../models/plato_model.dart';
import '../../domain/models/rubro_model.dart'; // ✅ Importamos el nuevo modelo

/// **PedidoRepositoryImpl**
///
/// Implementación concreta del contrato `PedidoRepository`.
/// Encapsula TODA la lógica de acceso a datos (Data Layer).
/// La parte visual (UI) y el Provider NO saben si los datos vienen de internet,
/// de una base de datos local SQLite, o de un archivo de texto. Solo llaman a los métodos.
class PedidoRepositoryImpl implements PedidoRepository {
  final DBHelper _dbHelper = DBHelper.instance;
  final StorageService _storage = StorageService();

  // ⚠️ Tu IP: Asegúrate de que esta IP sea accesible desde tu emulador o dispositivo real.
  // En Android Emulator usa '10.0.2.2' en lugar de localhost, o la IP de tu PC (192.168.x.x) si es un dispositivo físico.
  static const String _baseUrl = AppConfig.apiBaseUrl;

  /// **Helper Privado: _getAuthHeaders**
  /// Recupera el Token JWT guardado en el almacenamiento seguro y lo prepara para enviarlo
  /// en la cabecera (Header) de cada petición HTTP. Sin esto, el backend nos rechazaría (401 Unauthorized).
  Future<Map<String, String>> _getAuthHeaders() async {
    String? token = await _storage.getToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // ===========================================================================
  // 🥘 GET MENU (Patrón "Offline First")
  // ===========================================================================

  /// Descarga la lista de platos.
  ///
  /// **Estrategia Híbrida:**
  /// 1. Intenta conectarse a Internet.
  /// 2. Si hay conexión (200 OK), guarda los datos en la base local (SQLite) y los devuelve.
  /// 3. Si NO hay conexión (catch), devuelve lo que haya guardado en la base local (SQLite).
  /// Esto permite que la app funcione aunque se caiga el wifi.
  @override
  Future<List<Plato>> getMenu() async {
    try {
      final url = Uri.parse(
          '$_baseUrl/platos'); // Utulidad para validar que la URL está bien formada

      // Hacemos el request GET con un tiempo límite (timeout) de 5 segundos
      final response = await http
          .get(url, headers: await _getAuthHeaders())
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // Deserialización: Convertimos el String JSON en Objetos Dart
        final List<dynamic> jsonList = jsonDecode(response.body);
        final platosOnline = jsonList
            .map((j) => PlatoModel.fromJson(j)) // Factory constructor mágico
            .toList();

        // Guardamos en local para la próxima vez
        await _syncMenuLocal(platosOnline);
        return platosOnline;
      } else {
        throw Exception('Error servidor: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("⚠️ Error Menu Online ($e). Usando modo offline.");
      // Fallback a base de datos local
      return await _getLocalMenu();
    }
  }

  // ===========================================================================
  // 🌳 GET RUBROS (Jerarquía)
  // ===========================================================================

  // Future<List<Rubro>> getRubros() async { ... } definimos esto en la interfaz primero?
  // No, Dart es flexible, pero lo ideal es agregarlo a la interfaz abstracta.
  // Por ahora lo metemos directo aquí y luego actualizamos la interfaz si hace falta.
  @override
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
      debugPrint("⚠️ Error cargando rubros: $e");
      return []; // Retornamos lista vacía en vez de romper todo
    }
  }

  // ===========================================================================
  // 📝 GET PEDIDOS (Mapeo Complejo)
  // ===========================================================================

  /// Obtiene el historial de pedidos completados.
  /// El backend devuelve una estructura jerárquica (PedidoPadre -> Lista de Detalles).
  /// Aquí "aplanamos" esa estructura para que sea fácil de mostrar en una lista simple.
  @override
  Future<List<Pedido>> getPedidos() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pedidos'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List<dynamic> jsonList = decoded['data'] ?? [];

        final List<Pedido> listaAplanada = [];

        // 🔄 RECORREMOS LOS TICKETS (PEDIDOS PADRE)
        for (var jsonPedido in jsonList) {
          // Verificamos si tiene detalles (los platos dentro del ticket)
          if (jsonPedido['DetallePedidos'] != null) {
            final detalles = jsonPedido['DetallePedidos'] as List;

            // 🔄 RECORREMOS LOS DETALLES (HIJOS)
            for (var detalle in detalles) {
              // CREAMOS UN PEDIDO VISUAL POR CADA PLATO para mostrarlo en la lista
              listaAplanada.add(
                PedidoModel(
                  id: jsonPedido['id'],
                  mesa: jsonPedido['mesa']?.toString() ?? '',
                  cliente: jsonPedido['cliente']?.toString() ?? 'Anónimo',
                  estado: _mapEstado(jsonPedido['estado']),
                  // Parseamos la fecha ISO-8601 (ej: "2023-12-01T20:00:00Z")
                  fecha: jsonPedido['createdAt'] != null
                      ? DateTime.parse(jsonPedido['createdAt'])
                      : null,

                  platoId: detalle['PlatoId'] ?? 0,
                  cantidad: detalle['cantidad'] ?? 1,
                  // Convertimos a double de forma segura
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

  /// Helper simple para convertir Strings del backend en el Enum `EstadoPedido`.
  EstadoPedido _mapEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'pendiente':
        return EstadoPedido.pendiente;
      case 'en_preparacion':
        return EstadoPedido.enPreparacion;
      // ... (otros casos)
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

  // ===========================================================================
  // 🚀 INSERTAR PEDIDO (POST)
  // ===========================================================================

  /// Envía un nuevo pedido al servidor.
  ///
  /// **Pasos:**
  /// 1. Transforma los objetos `Pedido` del carrito a un JSON que el backend entienda (`Map<String, dynamic>`).
  /// 2. Realiza una petición POST.
  /// 3. Retorna el ID del nuevo pedido o lanza error si falla.
  @override
  Future<int> insertPedido(String mesaId, List<Pedido> carrito) async {
    final url = Uri.parse('$_baseUrl/pedidos');

    // Logs de depuración (útiles mientras desarrollas, quitarlos en producción)
    debugPrint("🚀 [PedidoRepo] Enviando a $url");

    try {
      // 1. Preparar Headers
      final headers = await _getAuthHeaders();

      // 2. Preparar Body (Payload)
      // Usamos .map para transformar la lista de objetos en lista de mapas JSON
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
      debugPrint("📦 JSON DATA: $jsonBody");

      // 3. Enviar Petición
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonBody,
          )
          .timeout(const Duration(seconds: 10));

      // 4. Analizar Resultado
      // [Pressman]: Estándar de codificación seguro. Uso de bloques {} obligatorios.
      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json is Map) {
          // Opción A: Estructura anidada
          if (json['data'] != null && json['data']['id'] != null) {
            return int.parse(json['data']['id'].toString());
          }
          // Opción B: Estructura plana
          if (json['id'] != null) {
            return int.parse(json['id'].toString());
          }
        }
        return 1; // ID genérico de fallback
      } else if (response.statusCode == 409) {
        // Manejo de Stock Insuficiente
        final errorJson = jsonDecode(response.body);
        throw Exception(errorJson['error'] ?? 'Stock insuficiente');
      } else {
        // Error genérico del servidor
        throw Exception(
            'Backend rechazó (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Fallo al enviar: $e');
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
    } catch (_) {
      // Si falla el borrado, por ahora no hacemos nada (Fail Silent)
    }
  }

  // ===========================================================================
  // 🔄 MODIFICAR PEDIDO (PUT Request)
  // ===========================================================================

  /// **modificarPedido**
  ///
  /// Actualiza un pedido existente en el backend.
  ///
  /// **Responsabilidad:**
  /// - Transformar los objetos Dart (`List<Pedido>`) a formato JSON
  /// - Realizar una petición HTTP PUT al endpoint `/pedidos/modificar`
  /// - Manejar la respuesta del servidor y propagar errores si es necesario
  ///
  /// **Arquitectura:**
  /// - **Capa de Datos (Data Layer)**: Este método pertenece al Repository
  /// - **Patrón Repository**: Abstrae la fuente de datos (HTTP, SQLite, etc.)
  /// - **Separación de Responsabilidades**: La UI no sabe que esto es HTTP
  ///
  /// **Flujo de Comunicación:**
  /// ```
  /// UI (Modal) -> Provider -> Repository -> Backend API -> MySQL
  ///                                      <-              <-
  /// ```
  ///
  /// **Parámetros:**
  /// - `pedidoId`: ID del pedido padre a modificar
  /// - `mesa`: Número de mesa (String)
  /// - `pedidoModificado`: Lista actualizada de items del pedido
  ///
  /// **Excepciones:**
  /// - Lanza `Exception` si el servidor responde con error (statusCode != 200/201)
  /// - Lanza `Exception` si hay problemas de red (timeout, sin conexión)
  @override
  Future<void> modificarPedido(
      int pedidoId, String mesa, List<Pedido> pedidoModificado) async {
    // **PASO 1: Construir URL del Endpoint**
    // El backend espera un PUT a /pedidos/modificar
    final url = Uri.parse('$_baseUrl/pedidos/modificar');

    try {
      // **PASO 2: Preparar Headers HTTP**
      // Incluye el token JWT para autenticación y Content-Type para JSON
      final headers = await _getAuthHeaders();

      // **PASO 3: Serialización de Datos (Dart -> JSON)**
      // Transformamos la lista de objetos Pedido a un formato que el backend entienda.
      // Usamos .map() para iterar y crear un Map por cada item.
      final List<Map<String, dynamic>> listaProductos =
          pedidoModificado.map((item) {
        return {
          "platoId": item.platoId,
          "cantidad": item.cantidad,
          "aclaracion": item.aclaracion ?? "",
        };
      }).toList();

      // **PASO 4: Construir el Body (Payload)**
      // Estructura esperada por el backend:
      // {
      //   "id": 123,
      //   "mesa": "2",
      //   "cliente": "Cliente App",
      //   "productos": [
      //     {"platoId": 9, "cantidad": 2, "aclaracion": ""}
      //   ]
      // }
      final Map<String, dynamic> bodyData = {
        "id": pedidoId,
        "mesa": mesa,
        "cliente": "Cliente App",
        "productos": listaProductos,
      };

      // **PASO 5: Convertir Map a String JSON**
      // jsonEncode() serializa el Map a un String JSON válido
      final String jsonBody = jsonEncode(bodyData);
      debugPrint("🔄 [PedidoRepo] Modificando pedido $pedidoId: $jsonBody");

      // **PASO 6: Realizar Petición HTTP PUT**
      // **Conceptos:**
      // - `http.put()`: Método HTTP para actualizar recursos existentes
      // - `timeout()`: Límite de tiempo para evitar esperas infinitas
      // - `await`: Espera la respuesta antes de continuar
      final response = await http
          .put(
            url,
            headers: headers,
            body: jsonBody,
          )
          .timeout(const Duration(seconds: 10));

      // **PASO 7: Logging de Respuesta (Debug)**
      // Útil para diagnosticar problemas de persistencia
      debugPrint("📥 [PedidoRepo] Response Status: ${response.statusCode}");
      debugPrint("📥 [PedidoRepo] Response Body: ${response.body}");

      // **PASO 8: Validación de Respuesta**
      // **HTTP Status Codes:**
      // - 200 OK: Actualización exitosa
      // - 201 Created: Recurso creado (algunos backends usan esto)
      // - 4xx: Error del cliente (datos inválidos, autenticación fallida)
      // - 5xx: Error del servidor (base de datos caída, bug en backend)
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
            'Error modificando pedido: ${response.statusCode} - ${response.body}');
      }

      debugPrint("✅ Pedido $pedidoId modificado y enviado a cocina");
    } catch (e) {
      // **PASO 9: Manejo de Excepciones**
      // Capturamos cualquier error (red, timeout, servidor) y lo propagamos
      // hacia arriba (Provider -> UI) para que el usuario vea el mensaje
      debugPrint("❌ Error en modificarPedido: $e");
      throw Exception('Fallo al modificar: $e');
    }
  }

  /// **Enviar Pedido Modificado a Cocina**
  /// El backend automáticamente maneja cocina, igual que en insertPedido
  /// Esta función es placeholder por si en el futuro se necesita lógica adicional

  @override
  Future<void> updateEstado(int id, EstadoPedido nuevoEstado) async {}

  // ---------------------------------------------------------------------------
  // 💾 MÉTODOS LOCALES (SQLite)
  // ---------------------------------------------------------------------------

  /// Lee el menú guardado en el teléfono.
  Future<List<Plato>> _getLocalMenu() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('platos');
    if (maps.isEmpty) return [];
    return maps.map((map) => PlatoModel.fromMap(map)).toList();
  }

  /// Guarda el menú descargado en el teléfono (sobrescribe lo anterior).
  Future<void> _syncMenuLocal(List<PlatoModel> platos) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Borramos todo lo viejo
      await txn.delete('platos');
      // Insertamos lo nuevo uno por uno
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
