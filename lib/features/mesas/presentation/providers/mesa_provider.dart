import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 👇 1. Imports Correctos
import '../../../../core/services/storage_service.dart'; // Tu servicio de SecureStorage
import '../../domain/models/mesa_ui_model.dart'; // El modelo que usa la pantalla

class MesaProvider extends ChangeNotifier {
  // 👇 2. Variables de Configuración (Faltaban en tu código)
  // Ajusta la IP si usas celular físico (ej: 192.168.1.X)
  final String _baseUrl = 'http://192.168.18.3:3000/api/mesas'; 
  final StorageService _storage = StorageService();

  // 👇 3. Estado
  List<MesaUiModel> _mesas = []; // Usamos MesaUiModel para la UI
  bool _isLoading = false;
  String _error = '';

  List<MesaUiModel> get mesas => _mesas;
  bool get isLoading => _isLoading;
  String get error => _error;

  // ==========================================
  // 📥 1. CARGAR MESAS (GET)
  // ==========================================
  Future<void> cargarMesas() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storage.getToken();
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // 👇 TRANSFORMACIÓN DE DATOS (Adapter Logic)
    // ... dentro del map ...
        _mesas = data.map((itemJson) {
          
          String? nombreMozo;
          
          // Lógica de Mozo (Más robusta)
          if (itemJson['mozo'] != null && itemJson['mozo'] is Map) {
            final m = itemJson['mozo'];
            nombreMozo = "${m['nombre']} ${m['apellido']}";
          } else if (itemJson['mozoAsignado'] != null) {
            nombreMozo = itemJson['mozoAsignado'].toString();
          } else {
            // Si está ocupada pero no vino mozo, ponemos un texto por defecto
            nombreMozo = "Sin Asignar"; 
          }

          // Lógica de Número (Si numero es null, usamos el ID)
          int numeroMesa = 0;
          if (itemJson['numero'] != null) {
             numeroMesa = int.tryParse(itemJson['numero'].toString()) ?? 0;
          } else {
             // Fallback: Si numero es null, usamos el ID
             numeroMesa = itemJson['id']; 
          }

          return MesaUiModel(
            id: itemJson['id'],
            numero: numeroMesa, // 👈 Usamos la variable calculada arriba
            estado: itemJson['estado'] ?? 'libre',
            totalActual: double.tryParse((itemJson['totalActual'] ?? 0).toString()),
            mozoAsignado: nombreMozo,
          );
          
        }).toList();

      } else {
        _error = "Error cargando mesas";
      }
    } catch (e) {
      _error = "Error de conexión";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // 🔓 2. ABRIR MESA (POST) - ¡Fundamental para el flujo!
  // ==========================================
  Future<bool> ocuparMesa(int idMesa, int idMozo) async {
    try {
      final token = await _storage.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/$idMesa/abrir'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'idMozo': idMozo}),
      );

      if (response.statusCode == 200) {
        await cargarMesas(); // Recargamos para ver el cambio a NARANJA
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 🔒 3. CERRAR MESA (POST)
  // ==========================================
  Future<bool> cerrarMesa(int idMesa) async {
    try {
      final token = await _storage.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/$idMesa/cerrar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await cargarMesas(); // Recargamos para ver el cambio a GRIS (Libre)
        return true;
      }
      return false;
    } catch (e) {
      return false; // Retornamos false en vez de rethrow para manejarlo suave en la UI
    }
  }
}