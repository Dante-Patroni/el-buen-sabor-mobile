import '../../domain/models/mesa.dart';
import '../../domain/repositories/mesa_repository.dart';
import '../datasources/mesa_datasource.dart';

class MesaRepositoryImpl implements MesaRepository {
  final MesaDataSource dataSource;

  MesaRepositoryImpl(this.dataSource);

  @override
  Future<List<Mesa>> getMesas() async {
    return await dataSource.getMesasFromApi();
  }
}