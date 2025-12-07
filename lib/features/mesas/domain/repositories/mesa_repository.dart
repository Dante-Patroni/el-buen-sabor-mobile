import '../models/mesa.dart';

abstract class MesaRepository {
  Future<List<Mesa>> getMesas();
}