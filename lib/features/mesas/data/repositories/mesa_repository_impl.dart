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
  Future<double> cerrarMesa(int idMesa) {
    return dataSource.cerrarMesa(idMesa);
  }
}
