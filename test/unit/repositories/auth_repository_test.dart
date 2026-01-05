// ============================================================================
// ARCHIVO: auth_repository_test.dart
// ============================================================================
// 📌 PROPÓSITO:
// Tests unitarios para AuthRepository usando MOCKS de HTTP.
// Verifica que las llamadas al API funcionen correctamente.
//
// 🎓 CONCEPTOS NUEVOS:
// - Mock de HTTP Client: Simular respuestas del servidor
// - Status Codes: 200 (OK), 401 (Unauthorized), 500 (Error)
// - JSON encoding/decoding en tests
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:el_buen_sabor_app/features/auth/data/auth_repository.dart';
import 'package:el_buen_sabor_app/features/auth/domain/models/usuario.dart';

// Generar mock del cliente HTTP
@GenerateMocks([http.Client])
import 'auth_repository_test.mocks.dart';

void main() {
  late AuthRepository repository;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    // NOTA: AuthRepository necesita aceptar un cliente HTTP en el constructor
    // repository = AuthRepository(client: mockClient);
    repository = AuthRepository();
  });

  group('Login Exitoso', () {
    test('debe retornar token y usuario cuando status es 200', () async {
      // ARRANGE: Preparar respuesta HTTP simulada
      final responseBody = jsonEncode({
        'token': 'fake_jwt_token_12345',
        'usuario': {
          'id': 1,
          'nombre': 'Dante',
          'apellido': 'Patroni',
          'rol': 'mozo',
          'legajo': '12345',
        }
      });

      // Configurar el mock para retornar esta respuesta
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(responseBody, 200));

      // ACT: Llamar al método login
      final result = await repository.login('12345', 'password123');

      // ASSERT: Verificar el resultado
      expect(result['success'], true);
      expect(result['token'], 'fake_jwt_token_12345');
      expect(result['usuario'], isA<Usuario>());
      expect(result['usuario'].nombre, 'Dante');
    });

    test('debe hacer POST a la URL correcta', () async {
      // ARRANGE
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'token': 'token',
              'usuario': {
                'id': 1,
                'nombre': 'Test',
                'apellido': 'User',
                'rol': 'mozo',
                'legajo': '123'
              }
            }),
            200,
          ));

      // ACT
      await repository.login('12345', 'password');

      // ASSERT: Verificar que se llamó con la URL correcta
      verify(mockClient.post(
        argThat(predicate((Uri uri) => uri.path.endsWith('/usuarios/login'))),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).called(1);
    });

    test('debe enviar credenciales en el body', () async {
      // ARRANGE
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'token': 'token',
              'usuario': {
                'id': 1,
                'nombre': 'Test',
                'apellido': 'User',
                'rol': 'mozo',
                'legajo': '123'
              }
            }),
            200,
          ));

      // ACT
      await repository.login('12345', 'mypassword');

      // ASSERT: Verificar que se envió el body correcto
      verify(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: argThat(
          predicate((String body) {
            final decoded = jsonDecode(body);
            return decoded['legajo'] == '12345' &&
                decoded['password'] == 'mypassword';
          }),
          named: 'body',
        ),
      )).called(1);
    });
  });

  group('Login Fallido', () {
    test('debe lanzar excepción cuando status es 401', () async {
      // ARRANGE: Simular respuesta de credenciales incorrectas
      final errorResponse = jsonEncode({
        'mensaje': 'Credenciales incorrectas',
      });

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(errorResponse, 401));

      // ACT & ASSERT: Verificar que lanza excepción
      expect(
        () => repository.login('12345', 'wrong_password'),
        throwsA(isA<Exception>()),
      );
    });

    test('debe incluir mensaje del backend en la excepción', () async {
      // ARRANGE
      final errorResponse = jsonEncode({
        'mensaje': 'Usuario no encontrado',
      });

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(errorResponse, 404));

      // ACT & ASSERT
      try {
        await repository.login('99999', 'password');
        fail('Debería haber lanzado una excepción');
      } catch (e) {
        expect(e.toString(), contains('Usuario no encontrado'));
      }
    });
  });

  group('Errores de Red', () {
    test('debe manejar timeout', () async {
      // ARRANGE: Simular timeout
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenThrow(Exception('Connection timeout'));

      // ACT & ASSERT
      expect(
        () => repository.login('12345', 'password'),
        throwsA(isA<Exception>()),
      );
    });

    test('debe manejar error de conexión', () async {
      // ARRANGE: Simular sin internet
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenThrow(Exception('No internet connection'));

      // ACT & ASSERT
      try {
        await repository.login('12345', 'password');
        fail('Debería haber lanzado una excepción');
      } catch (e) {
        expect(e.toString(), contains('conexión'));
      }
    });
  });

  group('Headers HTTP', () {
    test('debe enviar Content-Type: application/json', () async {
      // ARRANGE
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'token': 'token',
              'usuario': {
                'id': 1,
                'nombre': 'Test',
                'apellido': 'User',
                'rol': 'mozo',
                'legajo': '123'
              }
            }),
            200,
          ));

      // ACT
      await repository.login('12345', 'password');

      // ASSERT: Verificar headers
      verify(mockClient.post(
        any,
        headers: argThat(
          predicate((Map<String, String> headers) =>
              headers['Content-Type'] == 'application/json'),
          named: 'headers',
        ),
        body: anyNamed('body'),
      )).called(1);
    });
  });
}

// ============================================================================
// 📝 NOTAS IMPORTANTES
// ============================================================================
//
// 1. MODIFICAR AUTH_REPOSITORY:
//    Para que estos tests funcionen, AuthRepository debe aceptar
//    un cliente HTTP en el constructor:
//
//    class AuthRepository {
//      final http.Client client;
//
//      AuthRepository({http.Client? client})
//        : client = client ?? http.Client();
//    }
//
// 2. GENERAR MOCKS:
//    flutter pub run build_runner build
//
// 3. EJECUTAR TESTS:
//    flutter test test/unit/repositories/auth_repository_test.dart
//
// ============================================================================
