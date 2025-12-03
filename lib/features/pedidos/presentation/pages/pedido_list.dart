import 'package:el_buen_sabor_app/features/pedidos/presentation/widgets/empty_pedidos_widget.dart';
import 'package:el_buen_sabor_app/features/pedidos/presentation/widgets/pedido_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pedido_provider.dart';


class PedidoList extends StatelessWidget {
  const PedidoList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PedidoProvider>(context);
    final pedidos = provider.listaPedidos;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pedidos.isEmpty) {
      return const EmptyPedidosWidget();
    }

    return ListView.builder(
      itemCount: pedidos.length,
      itemBuilder: (context, index) {
        final pedido = pedidos[index];
        final plato = provider.getPlatoById(pedido.platoId);

        return PedidoItem(
          pedido: pedido,
          plato: plato,
          onDelete: () => provider.borrarPedido(pedido.id!),
        );
      },
    );
  }
}
