import 'dart:convert'; // Para jsonDecode y jsonEncode
import 'package:http/http.dart' as http; // Para hacer peticiones HTTP
import 'package:el_buen_sabor_app/core/database/db_helper.dart';
import '../../domain/models/pedido.dart';
import '../../domain/models/plato.dart';
import '../../domain/repositories/pedido_repository.dart';
import '../models/pedido_model.dart';
import '../models/plato_model.dart';

class PedidoRepositoryImpl implements PedidoRepository {
  // Arquitectura híbrida: API REST + Base de datos local
  final DBHelper _dbHelper =
      DBHelper.instance; // Singleton - Instancio base de datols local

  // ⚠️ Asegúrate que esta sea la IP de tu PC
  //Dirección IP local del servidor Node.js
  static const String _baseUrl = 'http://192.168.18.3:3000/api';

  @override
  // Obtener el menú de platos desde la API REST
  Future<List<Plato>> getMenu() async {
     print("🔄 [DEBUG REPO] getMenu() INICIANDO");
  print("🌐 URL: $_baseUrl/platos");
    // Convertimos el String 'http://192.../api/platos' en un objeto URI que Dart entiende.
    final url = Uri.parse('$_baseUrl/platos');
     print("📡 [DEBUG] Haciendo petición GET a: $url");
    try {
      final response = await http.get(url); // ESPERA QUE EL SERVIDOR RESPONDA
     print("📥 [DEBUG] Status Code: ${response.statusCode}");
    print("📦 [DEBUG] Response Body length: ${response.body.length}");
      if (response.statusCode == 200) {
        // Decodificamos la respuesta JSON en una lista de MAPAS
        final List<dynamic> jsonList = jsonDecode(response.body);
        print("✅ [DEBUG] Platos recibidos: ${jsonList.length}");
 if (jsonList.isNotEmpty) {
        print("🍽️ [DEBUG] Primer plato: ${jsonList[0]}");
      }
        

        // Mapeo (Traducción 2: Estructura Cruda -> Objetos Dart)
        // Aquí ocurre la magia de la Fábrica.
        // .map: Recorre cada item de la lista cruda.
        // .fromJson: Convierte cada item en una instancia real de la clase Plato.
        // .toList: Empaqueta todo en una lista final de Platos.
        return jsonList.map((j) => PlatoModel.fromJson(j)).toList();
      } else {
        throw Exception('Error menú: ${response.statusCode}');
      }
    } catch (e) {
      // Si se corta el WiFi o el servidor está apagado, caemos aquí.
      throw Exception('Error conexión menú: $e');
    }
  }

  @override
  // Insertar un nuevo pedido en la API REST
  Future<int> insertPedido(Pedido pedido) async {
    final url = Uri.parse('$_baseUrl/pedidos');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          // Convertimos el pedido a JSON a String para enviarlo
          "mesa": pedido.mesa,
          "cliente": pedido.cliente,
          "platoId": pedido.platoId,
        }),
      );
      print("📥 [DEBUG] Status Code: ${response.statusCode}");
    print("📥 [DEBUG] Body: ${response.body}");

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        // ⬅️ Para verificar QUÉ trae exactamente
      print("📦 [DEBUG] JSON decodificado: $json");
        return json['id']; // Retornamos el ID del nuevo pedido creado
      } else {
        throw Exception(
          'Error crear pedido: ${response.statusCode}',
        ); //Ej. 409 Stock insuficiente
      }
    } catch (e) {
      throw Exception('Error conexión crear: $e');
    }
  }

  // --- LISTAR PEDIDOS (GET) ---
  @override
  Future<List<Pedido>> getPedidos() async {
    // [A] URL del endpoint
    final url = Uri.parse('$_baseUrl/pedidos');
    try {
      // [B] Petición GET
      final response = await http.get(url);

      // [C] Validación de respuesta
      if (response.statusCode == 200) {
        // [D] Decodificación (JSON String -> List<dynamic>)
        final List<dynamic> jsonList = jsonDecode(response.body);
        // [E] Conversión (List<dynamic> -> List<Pedido>)
        // ¡OJO! Aquí usamos PedidoModel.fromJson
        // Es vital que  PedidoModel tenga este constructor bien hecho.
        return jsonList.map((j) => PedidoModel.fromJson(j)).toList();
      } else {
        // Si el backend da 500 o 404, lanzamos error
        throw Exception('Error al cargar pedidos: ${response.statusCode}');
      }
    } catch (e) {
      print("Error obteniendo pedidos: $e");
      // [F] Estrategia de Fallo Silencioso
      // Si no hay internet, devolvemos una lista vacía [] para que la pantalla no se ponga roja.
      // En una app real, aquí intentaríamos cargar desde SQLite (Cache).
      return [];
    }
  }

  // IMPLEMENTACIÓN DEL DELETE
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

  // IMPLEMENTACIÓN DEL UPDATE
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
