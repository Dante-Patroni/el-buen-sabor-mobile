/// Contrato abstracto de autenticación.
///
/// Define qué puede hacer la capa de auth sin importar
/// si los datos vienen de HTTP, SQLite o un mock de tests.
///
/// Arquitectura:
/// ```
/// AuthProvider → [AuthRepository] → AuthRepositoryImpl → AuthDataSource → Backend
/// ```
abstract class AuthRepository {
  /// Autentica un usuario con legajo y contraseña.
  /// Retorna un Map con 'token' (String) y 'usuario' (Usuario).
  /// Lanza Exception si las credenciales son inválidas o hay error de red.
  Future<Map<String, dynamic>> login(String legajo, String password);
}
