// ============================================================================
// ARCHIVO: auth_provider_test.dart
// ============================================================================
// 📌 PROPÓSITO:
// Tests unitarios para AuthProvider usando MOCKS.
// Verifica que la gestión de estado de autenticación funcione correctamente.
//
// 🎓 CONCEPTOS NUEVOS:
// - MOCKS: Objetos falsos que simulan dependencias
// - setUp/tearDown: Código que se ejecuta antes/después de cada test
// - when/thenAnswer: Configurar comportamiento de mocks
// - verify: Verificar que se llamaron métodos del mock
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:el_buen_sabor_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:el_buen_sabor_app/features/auth/data/auth_repository.dart';
import 'package:el_buen_sabor_app/core/services/storage_service.dart';
import 'package:el_buen_sabor_app/features/auth/domain/models/usuario.dart';

// ============================================================================
// 🎭 GENERACIÓN DE MOCKS
// ============================================================================
// Esta anotación le dice a mockito que genere mocks automáticamente.
// Después de agregar esto, ejecuta: flutter pub run build_runner build
@GenerateMocks([AuthRepository, StorageService])
import 'auth_provider_test.mocks.dart';

/// 🧪 SUITE DE TESTS PARA AUTH PROVIDER
void main() {
  // ============================================================================
  // 📦 VARIABLES COMPARTIDAS
  // ============================================================================
  // Estas variables se usan en todos los tests
  late AuthProvider authProvider;
  late MockAuthRepository mockRepository;
  late MockStorageService mockStorage;

  // ============================================================================
  // ⚙️ SETUP - Se ejecuta ANTES de cada test
  // ============================================================================
  setUp(() {
    // Crear mocks frescos para cada test
    mockRepository = MockAuthRepository();
    mockStorage = MockStorageService();

    // Crear AuthProvider con las dependencias mockeadas
    authProvider = AuthProvider(
      repository: mockRepository,
      storage: mockStorage,
    );
  });

  // ============================================================================
  // 🧹 TEARDOWN - Se ejecuta DESPUÉS de cada test
  // ============================================================================
  tearDown(() {
    // Limpiar recursos
    authProvider.dispose();
  });

  // ============================================================================
  // 📊 GROUP 1: Estado Inicial
  // ============================================================================
  group('Estado Inicial', () {
    test('debe tener estado inicial correcto', () {
      // ASSERT: Verificar estado inicial
      expect(authProvider.isLoading, false);
      expect(authProvider.errorMessage, null);
      expect(authProvider.usuario, null);
    });
  });

  // ============================================================================
  // 🔑 GROUP 2: Login Exitoso
  // ============================================================================
  group('Login Exitoso', () {
    test('debe actualizar usuario cuando login es exitoso', () async {
      // ARRANGE: Preparar respuesta del mock
      final usuarioEsperado = Usuario(
        id: 1,
        nombre: 'Dante',
        apellido: 'Patroni',
        rol: 'mozo',
        legajo: '12345',
      );

      // Configurar el mock para retornar datos exitosos
      when(mockRepository.login('12345', 'password123'))
          .thenAnswer((_) async => {
                'token': 'fake_jwt_token',
                'usuario': usuarioEsperado,
              });

      // Configurar el mock de storage
      when(mockStorage.saveToken(any)).thenAnswer((_) async => {});

      // ACT: Ejecutar login
      final resultado = await authProvider.login('12345', 'password123');

      // ASSERT: Verificar resultado
      expect(resultado, true);
      expect(authProvider.usuario, isNotNull);
      expect(authProvider.usuario?.nombre, 'Dante');
      expect(authProvider.isLoading, false);
      expect(authProvider.errorMessage, null);

      // Verificar que se llamaron los métodos correctos
      verify(mockRepository.login('12345', 'password123')).called(1);
      verify(mockStorage.saveToken('fake_jwt_token')).called(1);
    });

    test('debe cambiar isLoading durante el proceso', () async {
      // ARRANGE
      when(mockRepository.login(any, any)).thenAnswer((_) async => {
            'token': 'token',
            'usuario': Usuario(
              id: 1,
              nombre: 'Test',
              apellido: 'User',
              rol: 'mozo',
              legajo: '123',
            ),
          });
      when(mockStorage.saveToken(any)).thenAnswer((_) async => {});

      // Listener para capturar cambios de estado
      bool wasLoading = false;
      authProvider.addListener(() {
        if (authProvider.isLoading) {
          wasLoading = true;
        }
      });

      // ACT
      await authProvider.login('123', 'pass');

      // ASSERT
      expect(wasLoading, true); // Estuvo en loading en algún momento
      expect(authProvider.isLoading, false); // Terminó en false
    });
  });

  // ============================================================================
  // ❌ GROUP 3: Login Fallido
  // ============================================================================
  group('Login Fallido', () {
    test('debe mostrar error cuando credenciales son incorrectas', () async {
      // ARRANGE: Configurar mock para lanzar excepción
      when(mockRepository.login('12345', 'wrong_password'))
          .thenThrow(Exception('Credenciales incorrectas'));

      // ACT: Intentar login con credenciales incorrectas
      final resultado = await authProvider.login('12345', 'wrong_password');

      // ASSERT: Verificar que falló
      expect(resultado, false);
      expect(authProvider.usuario, null);
      expect(authProvider.errorMessage, isNotNull);
      expect(authProvider.errorMessage, contains('Credenciales incorrectas'));
      expect(authProvider.isLoading, false);
    });

    test('debe manejar error de red', () async {
      // ARRANGE: Simular error de red
      when(mockRepository.login(any, any))
          .thenThrow(Exception('Error de conexión: No hay internet'));

      // ACT
      final resultado = await authProvider.login('12345', 'password');

      // ASSERT
      expect(resultado, false);
      expect(authProvider.errorMessage, contains('Error de conexión'));
    });
  });

  // ============================================================================
  // 🚪 GROUP 4: Logout
  // ============================================================================
  group('Logout', () {
    test('debe limpiar usuario y token al hacer logout', () async {
      // ARRANGE: Primero hacer login
      when(mockRepository.login(any, any)).thenAnswer((_) async => {
            'token': 'token',
            'usuario': Usuario(
              id: 1,
              nombre: 'Dante',
              apellido: 'Patroni',
              rol: 'mozo',
              legajo: '12345',
            ),
          });
      when(mockStorage.saveToken(any)).thenAnswer((_) async => {});
      when(mockStorage.deleteToken()).thenAnswer((_) async => {});

      await authProvider.login('12345', 'password');
      expect(authProvider.usuario, isNotNull); // Verificar que hay usuario

      // ACT: Hacer logout
      await authProvider.logout();

      // ASSERT: Verificar que se limpió todo
      expect(authProvider.usuario, null);
      verify(mockStorage.deleteToken()).called(1);
    });
  });

  // ============================================================================
  // 🔔 GROUP 5: NotifyListeners
  // ============================================================================
  group('NotifyListeners', () {
    test('debe notificar listeners cuando cambia el estado', () async {
      // ARRANGE
      int notificationCount = 0;
      authProvider.addListener(() {
        notificationCount++;
      });

      when(mockRepository.login(any, any)).thenAnswer((_) async => {
            'token': 'token',
            'usuario': Usuario(
              id: 1,
              nombre: 'Test',
              apellido: 'User',
              rol: 'mozo',
              legajo: '123',
            ),
          });
      when(mockStorage.saveToken(any)).thenAnswer((_) async => {});

      // ACT
      await authProvider.login('123', 'pass');

      // ASSERT: Debe haber notificado al menos 2 veces
      // (una al empezar loading, otra al terminar)
      expect(notificationCount, greaterThanOrEqualTo(2));
    });
  });
}

// ============================================================================
// 📝 NOTAS IMPORTANTES
// ============================================================================
//
// 1. GENERAR MOCKS:
//    Ejecuta: flutter pub run build_runner build
//    Esto crea el archivo: auth_provider_test.mocks.dart
//
// 2. MODIFICAR AUTH_PROVIDER:
//    Para que estos tests funcionen, AuthProvider debe aceptar
//    dependencias en el constructor:
//
//    class AuthProvider extends ChangeNotifier {
//      final AuthRepository repository;
//      final StorageService storage;
//
//      AuthProvider({
//        AuthRepository? repository,
//        StorageService? storage,
//      }) : repository = repository ?? AuthRepository(),
//           storage = storage ?? StorageService();
//    }
//
// 3. EJECUTAR TESTS:
//    flutter test test/unit/providers/auth_provider_test.dart
//
// ============================================================================
