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

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<Map<String, dynamic>> login(String legajo, String password) {
    return dataSource.login(legajo, password);
  }
}
