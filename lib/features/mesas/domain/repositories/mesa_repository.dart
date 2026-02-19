import '../models/mesa.dart';

abstract class MesaRepository {
  Future<List<Mesa>> getMesas();

  Future<void> abrirMesa(int idMesa, int idMozo);
  
 /// Cierra la mesa y retorna el total cobrado.
  Future<double> cerrarMesa(int idMesa);
}
  
