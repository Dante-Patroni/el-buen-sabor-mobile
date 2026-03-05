import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_datasource.dart';

/// **AuthRepositoryImpl**
///
/// Implementación concreta del contrato `AuthRepository`.
/// Delega toda la comunicación HTTP al `AuthDataSource`.
///
/// Arquitectura:
/// ```
/// AuthProvider → AuthRepository → [AuthRepositoryImpl] → AuthDataSource → Backend
/// ```
class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource dataSource;

  /**
   * @description Crea el repositorio de autenticacion con su data source.
   * @param {AuthDataSource} dataSource - Fuente de datos HTTP.
   * @returns {AuthRepositoryImpl} Instancia del repositorio.
   * @throws {Error} No lanza errores por diseno.
   */
  AuthRepositoryImpl(this.dataSource);

  @override
  /**
   * @description Delegar login al data source.
   * @param {String} legajo - Legajo del empleado.
   * @param {String} password - Contrasena del usuario.
   * @returns {Future<Map<String, dynamic>>} Token y usuario autenticado.
   * @throws {Exception} Error de autenticacion o red.
   */
  Future<Map<String, dynamic>> login(String legajo, String password) {
    return dataSource.login(legajo, password);
  }
}
