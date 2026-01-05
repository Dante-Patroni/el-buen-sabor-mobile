import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 🔧 Configuración centralizada de la app (URLs, entornos, etc.)
import '../../../../core/config/app_config.dart';

// 🔐 Servicio de almacenamiento seguro (JWT)
import '../../../../core/services/storage_service.dart';

// 🎨 Modelo adaptado a la UI (no es el modelo del backend)
import '../../domain/models/mesa_ui_model.dart';

/// ============================================================================
/// 📌 PROVIDER: MesaProvider
/// ============================================================================
///
/// RESPONSABILIDAD PRINCIPAL:
/// - Manejar el estado de las mesas del salón
/// - Comunicarse con el backend
/// - Transformar datos crudos (JSON) en modelos para la UI
///
/// PATRÓN:
/// - ChangeNotifier (State Management)
///
/// IMPORTANTE:
/// - Este Provider NO dibuja UI
/// - NO contiene lógica de navegación
/// - NO valida reglas de negocio complejas
/// ============================================================================
class MesaProvider extends ChangeNotifier {
  // ==========================================================================
  // 🌐 CONFIGURACIÓN Y DEPENDENCIAS
  // ==========================================================================

  /// URL base del recurso "mesas" en el backend
  /// Se obtiene desde AppConfig para permitir:
  /// - cambio de entorno (dev / prod)
  /// - evitar URLs hardcodeadas
  final String _baseUrl = '${AppConfig.apiBaseUrl}/mesas';

  /// Servicio de almacenamiento seguro
  /// Se usa para recuperar el JWT antes de cada request
  final StorageService _storage = StorageService();

  // ==========================================================================
  // 🧠 ESTADO INTERNO DEL PROVIDER
  // ==========================================================================

  /// Lista de mesas adaptadas para la UI
  /// Nunca exponemos la lista original del backend
  List<MesaUiModel> _mesas = [];

  /// Indica si hay una operación en curso (loading spinner)
  bool _isLoading = false;

  /// Mensaje de error genérico para mostrar en UI
  String _error = '';

  // ==========================================================================
  // 🔍 GETTERS PÚBLICOS (Estado Inmutable hacia la UI)
  // ==========================================================================

  List<MesaUiModel> get mesas => _mesas;
  bool get isLoading => _isLoading;
  String get error => _error;

  // ==========================================================================
  // 📥 CASO DE USO: CARGAR MESAS
  // ==========================================================================
  ///
  /// FLUJO:
  /// 1. Marca loading
  /// 2. Obtiene token JWT
  /// 3. Llama al backend
  /// 4. Convierte JSON → MesaUiModel
  /// 5. Notifica a la UI
  ///
  Future<void> cargarMesas() async {
    // 1️⃣ Cambiamos el estado a "cargando"
    _isLoading = true;
    notifyListeners(); // La UI muestra loader

    try {
      // 2️⃣ Recuperamos el token almacenado tras el login
      final token = await _storage.getToken();

      // 3️⃣ Request HTTP al backend
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // 4️⃣ Respuesta exitosa
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // 5️⃣ ADAPTADOR: JSON → Modelo de UI
        _mesas = data.map((itemJson) {
          // ----------------------------
          // 👤 LÓGICA DE MOZO ASIGNADO
          // ----------------------------
          String? nombreMozo;

          if (itemJson['mozo'] != null && itemJson['mozo'] is Map) {
            final m = itemJson['mozo'];
            nombreMozo = "${m['nombre']} ${m['apellido']}";
          } else if (itemJson['mozoAsignado'] != null) {
            nombreMozo = itemJson['mozoAsignado'].toString();
          } else {
            nombreMozo = "Sin Asignar";
          }

          // ----------------------------
          // 🔢 LÓGICA DE NÚMERO DE MESA
          // ----------------------------
          int numeroMesa;

          if (itemJson['numero'] != null) {
            numeroMesa = int.tryParse(itemJson['numero'].toString()) ?? 0;
          } else {
            // Fallback defensivo
            numeroMesa = itemJson['id'];
          }

          // ----------------------------
          // 🧱 CONSTRUCCIÓN DEL MODELO UI
          // ----------------------------
          return MesaUiModel(
            id: itemJson['id'],
            numero: numeroMesa,
            estado: itemJson['estado'] ?? 'libre',
            totalActual: double.tryParse(
              (itemJson['totalActual'] ?? 0).toString(),
            ),
            mozoAsignado: nombreMozo,
          );
        }).toList();
      } else {
        _error = "Error cargando mesas";
      }
    } catch (e) {
      // Error de red, token inválido, backend caído, etc.
      _error = "Error de conexión";
    } finally {
      // 6️⃣ Finaliza la carga y notifica a la UI
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================================================
  // 🔓 CASO DE USO: ABRIR / OCUPAR MESA
  // ==========================================================================
  ///
  /// Retorna:
  /// - true  → operación exitosa
  /// - false → error (la UI decide qué hacer)
  ///
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
        // Refrescamos estado para reflejar cambio visual
        await cargarMesas();
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // ==========================================================================
  // 🔒 CASO DE USO: CERRAR MESA
  // ==========================================================================
  ///
  /// Se mantiene la lógica simétrica a "ocuparMesa"
  ///
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
        await cargarMesas();
        return true;
      }

      return false;
    } catch (e) {
      // No lanzamos excepción: la UI maneja el resultado
      return false;
    }
  }
}
