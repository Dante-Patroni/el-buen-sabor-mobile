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
  /**
   * @description Autentica un usuario con legajo y contrasena.
   * @param {String} legajo - Legajo del empleado.
   * @param {String} password - Contrasena del usuario.
   * @returns {Future<Map<String, dynamic>>} Token y usuario autenticado.
   * @throws {Exception} Credenciales invalidas o error de red.
   */
  Future<Map<String, dynamic>> login(String legajo, String password);
}
