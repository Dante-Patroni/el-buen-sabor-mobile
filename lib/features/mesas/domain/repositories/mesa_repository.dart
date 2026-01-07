import '../models/mesa.dart';

abstract class MesaRepository {
  Future<List<Mesa>> getMesas();
  Future<void> abrirMesa(int idMesa, int idMozo);
  Future<void> cerrarMesa(int idMesa);
  
  /// Cierra una mesa y procesa la facturación.
  /// 
  /// Este método llama al endpoint `/pedidos/cerrar-mesa` que:
  /// - Cierra todos los pedidos pendientes de la mesa
  /// - Calcula el total a cobrar
  /// - Retorna el monto total cobrado
  /// 
  /// Retorna el total cobrado si tiene éxito, o lanza una excepción si falla.
  /// 
  /// **Arquitectura:** Este método pertenece a la capa de dominio (contrato).
  /// La implementación concreta está en MesaRepositoryImpl.
  Future<double> cerrarMesaYFacturar(int idMesa);
}
