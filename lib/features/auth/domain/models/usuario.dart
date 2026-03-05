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

  /**
   * @description Crea una instancia inmutable de Usuario.
   * @param {int} id - Identificador unico del usuario.
   * @param {String} nombre - Nombre del empleado.
   * @param {String} apellido - Apellido del empleado.
   * @param {String} rol - Rol del usuario (mozo, cocinero, admin).
   * @param {String} legajo - Legajo o numero de empleado.
   * @returns {Usuario} Instancia creada.
   * @throws {Error} No lanza errores por diseno.
   */
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

  /**
   * @description Crea un Usuario a partir de un mapa JSON.
   * @param {Map<String, dynamic>} json - Datos del usuario desde backend.
   * @returns {Usuario} Instancia construida.
   * @throws {Error} No lanza errores por diseno; usa defaults.
   */
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
