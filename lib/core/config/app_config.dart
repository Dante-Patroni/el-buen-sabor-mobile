// ============================================================================
// ARCHIVO: app_config.dart
// ============================================================================
// 📌 PROPÓSITO:
// Centraliza todas las configuraciones globales de la aplicación.
// Esto incluye URLs del backend, claves API, timeouts, y otras constantes.
//
// 🎯 VENTAJAS DE CENTRALIZAR CONFIGURACIÓN:
// - Un solo lugar para cambiar URLs (desarrollo, staging, producción)
// - Evita hardcodear valores en múltiples archivos
// - Facilita el mantenimiento y despliegue
// - Permite cambiar fácilmente entre entornos
// ============================================================================

/// 🔧 CLASE DE CONFIGURACIÓN GLOBAL
///
/// Esta clase contiene constantes estáticas que se usan en toda la aplicación.
/// No se instancia (no tiene constructor), solo se accede a sus propiedades estáticas.
///
/// PATRÓN: Configuration Object
/// - Agrupa configuraciones relacionadas
/// - Proporciona acceso global mediante static
/// - Inmutable (const) para prevenir modificaciones accidentales
class AppConfig {
  /// 🌐 URL BASE DEL API BACKEND
  ///
  /// Esta es la dirección del servidor backend de "El Buen Sabor".
  ///
  /// FORMATO: http://[IP]:[PUERTO]/api
  /// - IP: 192.168.18.3 (dirección local de red Wi-Fi)
  /// - Puerto: 3000 (puerto donde corre el servidor Node.js/Express)
  /// - Ruta base: /api (prefijo de todas las rutas del API)
  ///
  /// 💡 BUENAS PRÁCTICAS:
  /// - En producción, usar HTTPS para seguridad
  /// - Considerar usar variables de entorno (.env) para diferentes ambientes
  /// - Ejemplos de ambientes:
  ///   * Desarrollo: http://localhost:3000/api
  ///   * Staging: https://staging.elbuensabor.com/api
  ///   * Producción: https://api.elbuensabor.com/api
  ///
  /// 📱 USO EN LA APP:
  /// Todos los repositories y datasources usan esta URL como base
  /// para construir endpoints completos. Ejemplo:
  /// - Login: ${AppConfig.apiBaseUrl}/auth/login
  /// - Mesas: ${AppConfig.apiBaseUrl}/mesas
  /// - Pedidos: ${AppConfig.apiBaseUrl}/pedidos
  static const String apiBaseUrl = 'http://192.168.18.3:3000/api';

  // 🔮 FUTURAS CONFIGURACIONES (ejemplos):
  // static const int timeoutSeconds = 30;
  // static const String appVersion = '1.0.0';
  // static const bool enableLogging = true;
  // static const int maxRetries = 3;
}
