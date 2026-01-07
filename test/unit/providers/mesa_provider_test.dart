import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:el_buen_sabor_app/features/mesas/domain/models/mesa.dart';
import 'package:el_buen_sabor_app/features/mesas/domain/repositories/mesa_repository.dart';
import 'package:el_buen_sabor_app/features/mesas/presentation/providers/mesa_provider.dart';
import 'package:el_buen_sabor_app/features/mesas/presentation/models/mesa_ui_model.dart';

// 👇 genera MockMesaRepository se pone una sola vez  
//@GenerateMocks([MesaRepository])
import 'mesa_provider_test.mocks.dart';

void main() {
  late MockMesaRepository repository;
  late MesaProvider provider;

  setUp(() {
    repository = MockMesaRepository();
    provider = MesaProvider(repository);
  });

  test('cargarMesas carga mesas correctamente', () async {
    // ARRANGE
    final mesasDominio = [
      Mesa(
        id: 1,
        nombre: 'Mesa 1',
        estado: 'libre',
        totalActual: 0.0,
        itemsPendientes: 0,
      ),
      Mesa(
        id: 2,
        nombre: 'Mesa 2',
        estado: 'ocupada',
        totalActual: 1200,
        itemsPendientes: 1,
        mozoAsignado: 'Dante',
      ),
    ];

    when(repository.getMesas()).thenAnswer((_) async => mesasDominio);

    // ACT
    await provider.cargarMesas();

    // ASSERT
    expect(provider.isLoading, false);
    expect(provider.error, '');
    expect(provider.mesas.length, 2);

    expect(provider.mesas.first, isA<MesaUiModel>());
    expect(provider.mesas.first.estado, 'libre');

    expect(provider.mesas.last.estado, 'ocupada');
    expect(provider.mesas.last.mozoAsignado, 'Dante');

    verify(repository.getMesas()).called(1);
  });

  test('cerrarMesa llama al repository y recarga mesas', () async {
  // arrange
  when(repository.cerrarMesa(1))
      .thenAnswer((_) async {});
  when(repository.getMesas())
      .thenAnswer((_) async => []);

  // act
  await provider.cerrarMesa(1);

  // assert
  verify(repository.cerrarMesa(1)).called(1);
  verify(repository.getMesas()).called(1);
});

}