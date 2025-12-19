import 'package:el_buen_sabor_app/features/pedidos/presentation/widgets/empty_pedidos_widget.dart';
import 'package:el_buen_sabor_app/features/pedidos/presentation/widgets/pedido_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pedido_provider.dart';
import '../../domain/models/pedido.dart'; // Asegúrate de importar esto

class PedidoList extends StatelessWidget {
  // 👇 1. AHORA RECIBIMOS LA LISTA DESDE EL PADRE
  final List<Pedido> pedidos;

  const PedidoList({super.key, required this.pedidos});

  @override
  Widget build(BuildContext context) {
    // Necesitamos el provider solo para funciones como borrar o buscar platos
    final provider = Provider.of<PedidoProvider>(context, listen: false);

    // 👇 2. SI LA LISTA QUE RECIBIMOS ESTÁ VACÍA...
    if (pedidos.isEmpty) {
      return const EmptyPedidosWidget();
    }

    // 👇 3. DIBUJAMOS LA LISTA QUE NOS PASARON
    return ListView.builder(
      itemCount: pedidos.length,
      itemBuilder: (context, index) {
        final pedido = pedidos[index];

        // Buscamos el nombre del plato
        final plato = provider.getPlatoById(pedido.platoId);

        return PedidoItem(
          pedido: pedido,
          plato: plato,
          onDelete: () => provider.borrarPedidoHistorico(pedido.id!),
        );
      },
    );
  }
}
