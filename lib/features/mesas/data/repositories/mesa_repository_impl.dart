import '../../domain/models/mesa.dart';
import '../../domain/repositories/mesa_repository.dart';
import '../datasources/mesa_datasource.dart';

class MesaRepositoryImpl implements MesaRepository {
  final MesaDataSource dataSource;

  MesaRepositoryImpl(this.dataSource);

  @override
  Future<List<Mesa>> getMesas() async {
    final modelos = await dataSource.getMesasFromApi();
    return modelos; // MesaModel ES un Mesa
  }

  @override
  Future<void> abrirMesa(int idMesa, int idMozo) {
    return dataSource.abrirMesa(idMesa, idMozo);
  }

  @override
  Future<void> cerrarMesa(int id) async {
    // 👇 ¡Mira qué limpieza! Delegamos la tarea sucia
    await dataSource.cerrarMesa(id);
  }

  @override
  Future<double> cerrarMesaYFacturar(int idMesa) async {
    /// **Responsabilidad:** Implementar el contrato del repositorio.
    /// 
    /// Este método simplemente delega al DataSource.
    /// No agrega lógica de negocio aquí, solo pasa los datos entre capas.
    /// 
    /// **Arquitectura:** Esta es la capa de datos (implementación).
    /// Separa la lógica de dominio de los detalles de implementación HTTP.
    return await dataSource.cerrarMesaYFacturar(idMesa);
  }
}
