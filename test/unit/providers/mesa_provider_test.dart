import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:el_buen_sabor_app/features/mesas/domain/models/mesa.dart';
import 'package:el_buen_sabor_app/features/mesas/domain/repositories/mesa_repository.dart';
import 'package:el_buen_sabor_app/features/mesas/presentation/providers/mesa_provider.dart';
import 'package:el_buen_sabor_app/features/mesas/presentation/models/mesa_ui_model.dart';

import 'mesa_provider_test.mocks.dart';

@GenerateMocks([MesaRepository])
void main() {
  late MockMesaRepository repository;
  late MesaProvider provider;

  setUp(() {
    repository = MockMesaRepository();
    provider = MesaProvider(repository);
  });

  test('cargarMesas carga mesas correctamente', () async {
    final mesasDominio = [
      Mesa(
        id: 1,
        nombre: 'Mesa 1',
        estado: 'libre',
        totalActual: 0,
        itemsPendientes: 0,
      ),
    ];

    when(repository.getMesas()).thenAnswer((_) async => mesasDominio);

    await provider.cargarMesas();

    expect(provider.isLoading, false);
    expect(provider.error, '');
    expect(provider.mesas.length, 1);
    expect(provider.mesas.first, isA<MesaUiModel>());

    verify(repository.getMesas()).called(1);
  });

  test('cerrarMesa llama al repository y recarga mesas', () async {
    when(repository.cerrarMesa(1)).thenAnswer((_) async => 0.0);
    when(repository.getMesas()).thenAnswer((_) async => []);

    await provider.cerrarMesa(1);

    verify(repository.cerrarMesa(1)).called(1);
    verify(repository.getMesas()).called(1);
  });
}
