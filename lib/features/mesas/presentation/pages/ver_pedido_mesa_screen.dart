import 'package:el_buen_sabor_app/features/mesas/presentation/providers/mesa_provider.dart';
import 'package:el_buen_sabor_app/features/pedidos/domain/models/pedido.dart';
import 'package:el_buen_sabor_app/features/pedidos/presentation/providers/pedido_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_config.dart';
import '../widgets/modificar_pedido_modal.dart';

class VerPedidoMesaScreen extends StatefulWidget {
  final int mesaId;
  final int mesaNumero;

  const VerPedidoMesaScreen({
    super.key,
    required this.mesaId,
    required this.mesaNumero,
  });

  @override
  State<VerPedidoMesaScreen> createState() => _VerPedidoMesaScreenState();
}

class _VerPedidoMesaScreenState extends State<VerPedidoMesaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PedidoProvider>(context, listen: false).inicializarDatos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pedidos Mesa ${widget.mesaNumero}"),
      ),
      body: Consumer<PedidoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final pedidosMesa = provider.listaPedidos.where((p) {
            final esMesa = p.mesa == widget.mesaNumero.toString();
            final noPagado = p.estado != EstadoPedido.pagado;
            return esMesa && noPagado;
          }).toList();

          if (pedidosMesa.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "No hay pedidos registrados\npara la mesa ${widget.mesaNumero}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final double totalMesa = pedidosMesa.fold(0.0, (sum, item) {
            return sum + item.total;
          });

          return Column(
            children: [
              // LISTA DE ITEMS
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pedidosMesa.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidosMesa[index];
                    final plato = provider.getPlatoById(pedido.platoId);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: plato.imagenPath.isNotEmpty
                              ? NetworkImage(
                                  '${AppConfig.apiBaseUrl.replaceAll("/api", "")}${plato.imagenPath}')
                              : null,
                          child: plato.imagenPath.isEmpty
                              ? Text(plato.nombre[0])
                              : null,
                        ),
                        title: Text(
                          plato.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Cant: ${pedido.cantidad} x \$${plato.precio}"),
                            if (pedido.aclaracion != null &&
                                pedido.aclaracion!.isNotEmpty)
                              Text(
                                "Nota: ${pedido.aclaracion}",
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey),
                              ),
                            Text(
                              "Estado: ${pedido.estado.name.toUpperCase()}",
                              style: TextStyle(
                                color: _getColorEstado(pedido.estado),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ICONO EDITAR (LÁPIZ)
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.blue, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                // Capturar referencias ANTES del async
                                final pedidoProvider =
                                    context.read<PedidoProvider>();
                                final mesaProvider =
                                    context.read<MesaProvider>();

                                await showDialog(
                                  context: context,
                                  builder: (_) => ModificarPedidoModal(
                                    pedidoId: pedido.id ?? 0,
                                    mesaNumero: widget.mesaNumero.toString(),
                                    itemsPedido: pedidosMesa,
                                  ),
                                );

                                if (!mounted) return;

                                // Recargar AMBOS providers para actualizar pedidos Y totales de mesa
                                await pedidoProvider.inicializarDatos();
                                await mesaProvider.cargarMesas();
                              },
                            ),
                            const SizedBox(width: 4),
                            // ICONO ELIMINAR (TRASH)
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                final parentContext = context;

                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Eliminar Item"),
                                    content: const Text(
                                        "¿Eliminar este item del pedido?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text("Cancelar"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          Navigator.pop(ctx);

                                          await provider.borrarPedidoHistorico(
                                              pedido.id ?? 0);

                                          if (parentContext.mounted) {
                                            parentContext
                                                .read<MesaProvider>()
                                                .cargarMesas();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text(
                                          "Eliminar",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            // PRECIO DEL ITEM
                            Text(
                              "\$${pedido.total.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // RESUMEN TOTAL
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Pedido:",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "\$${totalMesa.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getColorEstado(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return Colors.orange;
      case EstadoPedido.enPreparacion:
        return Colors.blue;
      case EstadoPedido.entregado:
      case EstadoPedido.pagado:
        return Colors.green;
      case EstadoPedido.rechazado:
      case EstadoPedido.cancelado:
        return Colors.red;
    }
  }
}
