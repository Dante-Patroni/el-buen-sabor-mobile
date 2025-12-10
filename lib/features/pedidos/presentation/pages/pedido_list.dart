import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pedido_provider.dart';
import '../widgets/pedido_item.dart';
import '../widgets/empty_pedidos_widget.dart';

class PedidoList extends StatelessWidget {
  const PedidoList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PedidoProvider>(context);
    // Nota: Aquí mostramos el historial del Backend, no el carrito actual
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
          // 👇 AQUÍ ESTÁ EL CAMBIO: borrarPedidoHistorico
          onDelete: () => provider.borrarPedidoHistorico(pedido.id!),
        );
      },
    );
  }
}