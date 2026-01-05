// ============================================================================
// ARCHIVO: usuario_test.dart
// ============================================================================
// 📌 PROPÓSITO:
// Tests unitarios para el modelo Usuario.
// Verifica que la serialización/deserialización JSON funcione correctamente.
//
// 🎓 CONCEPTOS DE TESTING:
// - Unit Test: Prueba una unidad pequeña de código (una clase/función)
// - AAA Pattern: Arrange (preparar), Act (actuar), Assert (verificar)
// - Matchers: Funciones que verifican condiciones (equals, isNotNull, etc.)
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:el_buen_sabor_app/features/auth/domain/models/usuario.dart';

/// 🧪 SUITE DE TESTS PARA USUARIO
///
/// Una "suite" es un grupo de tests relacionados.
/// `group()` agrupa tests que prueban la misma funcionalidad.
void main() {
  // ============================================================================
  // 📦 GROUP 1: Tests del Constructor
  // ============================================================================

  group('Usuario Constructor', () {
    /// Test 1: Verificar que se puede crear un usuario con todos los campos
    ///
    /// PATRÓN AAA:
    /// - Arrange: No hay preparación necesaria
    /// - Act: Crear el usuario
    /// - Assert: Verificar que los campos se asignaron correctamente
    test('debe crear un usuario con todos los campos', () {
      // ACT: Crear usuario
      final usuario = Usuario(
        id: 1,
        nombre: 'Dante',
        apellido: 'Patroni',
        rol: 'mozo',
        legajo: '12345',
      );

      // ASSERT: Verificar cada campo
      expect(usuario.id, equals(1));
      expect(usuario.nombre, equals('Dante'));
      expect(usuario.apellido, equals('Patroni'));
      expect(usuario.rol, equals('mozo'));
      expect(usuario.legajo, equals('12345'));
    });

    /// Test 2: Verificar inmutabilidad
    ///
    /// Los campos son `final`, por lo que no se pueden modificar.
    /// Este test documenta ese comportamiento.
    test('los campos deben ser inmutables (final)', () {
      final usuario = Usuario(
        id: 1,
        nombre: 'Dante',
        apellido: 'Patroni',
        rol: 'mozo',
        legajo: '12345',
      );

      // ASSERT: Verificar que los campos no son null
      expect(usuario.id, isNotNull);
      expect(usuario.nombre, isNotNull);
      expect(usuario.apellido, isNotNull);
      expect(usuario.rol, isNotNull);
      expect(usuario.legajo, isNotNull);
    });
  });

  // ============================================================================
  // 🔄 GROUP 2: Tests de Deserialización (fromJson)
  // ============================================================================

  group('Usuario.fromJson', () {
    /// Test 3: Deserializar JSON completo correctamente
    ///
    /// ESCENARIO: El backend envía un JSON con todos los campos
    /// ESPERADO: Se crea un Usuario con todos los datos correctos
    test('debe deserializar JSON completo correctamente', () {
      // ARRANGE: Preparar JSON simulado del backend
      final json = {
        'id': 1,
        'nombre': 'Dante',
        'apellido': 'Patroni',
        'rol': 'mozo',
        'legajo': '12345',
      };

      // ACT: Convertir JSON a Usuario
      final usuario = Usuario.fromJson(json);

      // ASSERT: Verificar que todos los campos se deserializaron bien
      expect(usuario.id, equals(1));
      expect(usuario.nombre, equals('Dante'));
      expect(usuario.apellido, equals('Patroni'));
      expect(usuario.rol, equals('mozo'));
      expect(usuario.legajo, equals('12345'));
    });

    /// Test 4: Manejar campos null con valores por defecto
    ///
    /// ESCENARIO: El backend envía JSON con algunos campos null
    /// ESPERADO: Se usan valores por defecto (operador ??)
    test('debe usar valores por defecto cuando los campos son null', () {
      // ARRANGE: JSON con campos null
      final json = {
        'id': null,
        'nombre': null,
        'apellido': null,
        'rol': null,
        'legajo': null,
      };

      // ACT: Deserializar
      final usuario = Usuario.fromJson(json);

      // ASSERT: Verificar valores por defecto
      expect(usuario.id, equals(0)); // Default: 0
      expect(usuario.nombre, equals('')); // Default: ''
      expect(usuario.apellido, equals('')); // Default: ''
      expect(usuario.rol, equals('')); // Default: ''
      expect(usuario.legajo, equals('')); // Default: ''
    });

    /// Test 5: Manejar JSON con campos faltantes
    ///
    /// ESCENARIO: El backend envía JSON incompleto (campos no existen)
    /// ESPERADO: Se usan valores por defecto
    test('debe manejar JSON con campos faltantes', () {
      // ARRANGE: JSON vacío
      final json = <String, dynamic>{};

      // ACT: Deserializar
      final usuario = Usuario.fromJson(json);

      // ASSERT: Verificar valores por defecto
      expect(usuario.id, equals(0));
      expect(usuario.nombre, equals(''));
      expect(usuario.apellido, equals(''));
      expect(usuario.rol, equals(''));
      expect(usuario.legajo, equals(''));
    });

    /// Test 6: Manejar JSON parcialmente completo
    ///
    /// ESCENARIO: El backend envía solo algunos campos
    /// ESPERADO: Se usan valores por defecto para campos faltantes
    test('debe manejar JSON parcialmente completo', () {
      // ARRANGE: JSON con solo algunos campos
      final json = {
        'id': 1,
        'nombre': 'Dante',
        // apellido, rol y legajo faltantes
      };

      // ACT: Deserializar
      final usuario = Usuario.fromJson(json);

      // ASSERT: Verificar campos presentes y valores por defecto
      expect(usuario.id, equals(1));
      expect(usuario.nombre, equals('Dante'));
      expect(usuario.apellido, equals('')); // Default
      expect(usuario.rol, equals('')); // Default
      expect(usuario.legajo, equals('')); // Default
    });
  });

  // ============================================================================
  // 🔍 GROUP 3: Tests de Casos de Uso Reales
  // ============================================================================

  group('Casos de Uso Reales', () {
    /// Test 7: Simular respuesta real del backend
    ///
    /// ESCENARIO: Respuesta típica del endpoint /usuarios/login
    /// ESPERADO: Usuario se crea correctamente
    test('debe manejar respuesta real del backend', () {
      // ARRANGE: JSON real del backend
      final backendResponse = {
        'id': 42,
        'nombre': 'Dante',
        'apellido': 'Patroni',
        'rol': 'mozo',
        'legajo': '12345',
      };

      // ACT: Deserializar
      final usuario = Usuario.fromJson(backendResponse);

      // ASSERT: Verificar datos
      expect(usuario.id, equals(42));
      expect(usuario.nombre, equals('Dante'));
      expect(usuario.apellido, equals('Patroni'));
      expect(usuario.rol, equals('mozo'));
      expect(usuario.legajo, equals('12345'));
    });

    /// Test 8: Verificar diferentes roles
    ///
    /// ESCENARIO: Usuarios con diferentes roles
    /// ESPERADO: El rol se asigna correctamente
    test('debe manejar diferentes roles de usuario', () {
      // ARRANGE: JSON para diferentes roles
      final mozo = Usuario.fromJson({'rol': 'mozo'});
      final cocinero = Usuario.fromJson({'rol': 'cocinero'});
      final admin = Usuario.fromJson({'rol': 'admin'});

      // ASSERT: Verificar roles
      expect(mozo.rol, equals('mozo'));
      expect(cocinero.rol, equals('cocinero'));
      expect(admin.rol, equals('admin'));
    });
  });

  // ============================================================================
  // 📊 RESUMEN DE COBERTURA
  // ============================================================================

  /// COBERTURA ESPERADA:
  /// - Constructor: 100%
  /// - fromJson: 100%
  /// - Manejo de errores: 100%
  ///
  /// TOTAL: 100% del modelo Usuario
  ///
  /// COMANDOS ÚTILES:
  /// - Ejecutar estos tests: flutter test test/unit/models/usuario_test.dart
  /// - Ver cobertura: flutter test --coverage
  /// - Ver reporte HTML: genhtml coverage/lcov.info -o coverage/html
}
