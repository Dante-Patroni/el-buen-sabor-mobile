// ============================================================================
// ARCHIVO: usuario.dart
// ============================================================================
// 📌 PROPÓSITO:
// Define el modelo de dominio Usuario que representa a un empleado del restaurante.
//
// 🏗️ CAPA: Domain (Clean Architecture)
// Este modelo pertenece a la capa de dominio, que contiene la lógica de negocio
// pura e independiente de frameworks o tecnologías externas.
//
// 💡 CONCEPTO CLAVE: Modelo de Dominio
// - Representa una entidad del negocio (en este caso, un usuario/empleado)
// - Es inmutable (todas las propiedades son final)
// - No depende de detalles de implementación (base de datos, API, etc.)
// ============================================================================

/// 👤 MODELO DE DOMINIO: Usuario
///
/// Representa a un empleado del restaurante "El Buen Sabor".
/// Contiene la información esencial del usuario autenticado.
///
/// INMUTABILIDAD:
/// Todas las propiedades son `final`, lo que significa que no pueden cambiar
/// después de crear la instancia. Esto previene bugs y hace el código más predecible.
///
/// VENTAJAS DE LA INMUTABILIDAD:
/// - Thread-safe (seguro en concurrencia)
/// - Más fácil de razonar sobre el código
/// - Previene modificaciones accidentales
/// - Facilita el testing
///
/// ROLES POSIBLES:
/// - 'mozo' o 'waiter': Atiende mesas y toma pedidos
/// - 'cocinero' o 'chef': Prepara los platos
/// - 'admin': Administrador del sistema
class Usuario {
  /// ID único del usuario en la base de datos
  final int id;

  /// Nombre del empleado
  final String nombre;

  /// Apellido del empleado
  final String apellido;

  /// Rol del usuario en el sistema (mozo, cocinero, admin)
  /// Determina qué funcionalidades puede acceder
  final String rol;

  /// Legajo o número de empleado
  /// Se usa como identificador para el login
  final String legajo;

  /// Constructor con parámetros nombrados requeridos
  ///
  /// SINTAXIS DART:
  /// - `required`: Obliga a pasar el parámetro (no puede ser null)
  /// - `this.propiedad`: Sintaxis corta para asignar al campo de la clase
  ///
  /// EJEMPLO DE USO:
  /// ```dart
  /// final usuario = Usuario(
  ///   id: 1,
  ///   nombre: 'Dante',
  ///   apellido: 'Patroni',
  ///   rol: 'mozo',
  ///   legajo: '12345',
  /// );
  /// ```
  Usuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.rol,
    required this.legajo,
  });

  // ============================================================================
  // 🔄 SERIALIZACIÓN - Conversión JSON ↔ Objeto Dart
  // ============================================================================

  /// Factory constructor para crear un Usuario desde JSON
  ///
  /// PATRÓN: Factory Constructor
  /// Un factory constructor puede retornar una instancia existente o crear una nueva.
  /// Se usa comúnmente para deserialización (JSON → Objeto).
  ///
  /// FLUJO DE DESERIALIZACIÓN:
  /// 1. Backend envía JSON: {"id": 1, "nombre": "Dante", ...}
  /// 2. http package lo convierte a `Map<String, dynamic>`
  /// 3. Este método convierte el Map a un objeto Usuario
  ///
  /// OPERADOR ??:
  /// Proporciona un valor por defecto si el campo es null.
  /// Ejemplo: json['id'] ?? 0 → Si 'id' es null, usa 0
  ///
  /// PARÁMETROS:
  /// - json: Mapa con los datos del usuario recibidos del backend
  ///
  /// RETORNA: Nueva instancia de Usuario
  ///
  /// EJEMPLO DE JSON ESPERADO:
  /// ```json
  /// {
  ///   "id": 1,
  ///   "nombre": "Dante",
  ///   "apellido": "Patroni",
  ///   "rol": "mozo",
  ///   "legajo": "12345"
  /// }
  /// ```
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? 0, // ID del usuario (default: 0)
      nombre: json['nombre'] ?? '', // Nombre (default: string vacío)
      apellido: json['apellido'] ?? '', // Apellido (default: string vacío)
      rol: json['rol'] ?? '', // Rol (default: string vacío)
      legajo: json['legajo'] ?? '', // Legajo (default: string vacío)
    );
  }

  // ============================================================================
  // 🔮 MÉTODOS FUTUROS (ejemplos de extensiones útiles)
  // ============================================================================

  // /// Convierte el Usuario a JSON (para enviar al backend)
  // Map<String, dynamic> toJson() {
  //   return {
  //     'id': id,
  //     'nombre': nombre,
  //     'apellido': apellido,
  //     'rol': rol,
  //     'legajo': legajo,
  //   };
  // }
  //
  // /// Retorna el nombre completo del usuario
  // String get nombreCompleto => '$nombre $apellido';
  //
  // /// Verifica si el usuario es mozo
  // bool get esMozo => rol.toLowerCase() == 'mozo' || rol.toLowerCase() == 'waiter';
  //
  // /// Verifica si el usuario es administrador
  // bool get esAdmin => rol.toLowerCase() == 'admin';
  //
  // /// Crea una copia del usuario con campos modificados (útil para inmutabilidad)
  // Usuario copyWith({
  //   int? id,
  //   String? nombre,
  //   String? apellido,
  //   String? rol,
  //   String? legajo,
  // }) {
  //   return Usuario(
  //     id: id ?? this.id,
  //     nombre: nombre ?? this.nombre,
  //     apellido: apellido ?? this.apellido,
  //     rol: rol ?? this.rol,
  //     legajo: legajo ?? this.legajo,
  //   );
  // }
}
