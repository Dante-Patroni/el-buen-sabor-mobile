import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/mesa.dart';
import '../providers/mesa_provider.dart';

import '../../../pedidos/presentation/providers/pedido_provider.dart';
import '../../../pedidos/presentation/widgets/pedido_item.dart';
import '../../../pedidos/presentation/pages/nuevo_pedido_page.dart';

class MesaDetailScreen extends StatefulWidget {
  final Mesa mesa;
  const MesaDetailScreen({super.key, required this.mesa});

  @override
  State<MesaDetailScreen> createState() => _MesaDetailScreenState();
}

class _MesaDetailScreenState extends State<MesaDetailScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Cargamos pedidos
      Provider.of<PedidoProvider>(context, listen: false).inicializarDatos();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Providers
    final pedidoProvider = Provider.of<PedidoProvider>(context);
    final mesaProvider = Provider.of<MesaProvider>(context); // Para tener acceso a las funciones

    // 2. FILTRADO: Obtenemos los pedidos de ESTA mesa
    final pedidosDeEstaMesa = pedidoProvider.listaPedidos.where((pedido) {
      return pedido.mesa.toString() == widget.mesa.id.toString();
    }).toList();

    // 3. 🧮 CÁLCULO LOCAL DEL TOTAL (Infalible)
    // Sumamos: Precio del plato * Cantidad (asumimos cantidad 1 si no hay campo cantidad)
    double totalCalculado = 0.0;
    for (var pedido in pedidosDeEstaMesa) {
      final plato = pedidoProvider.getPlatoById(pedido.platoId);
      if (plato != null) {
        totalCalculado += plato.precio;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Mesa ${widget.mesa.id} - Detalle"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
               pedidoProvider.inicializarDatos();
               mesaProvider.cargarMesas();
            },
          )
        ],
      ),
      body: Column(
        children: [
          // --- CABECERA ---
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Cliente: ${widget.mesa.nombre}",
                        style: const TextStyle(fontSize: 16)),
                    Text("Estado: ${widget.mesa.estado}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("TOTAL:",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    
                    // 👇 AQUÍ MOSTRAMOS EL TOTAL CALCULADO AL MOMENTO
                    Text("\$${totalCalculado.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 24,
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          // --- LISTA DE PEDIDOS ---
          Expanded(
            child: pedidoProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : pedidosDeEstaMesa.isEmpty
                    ? const Center(child: Text("No hay platos registrados aún."))
                    : ListView.builder(
                        itemCount: pedidosDeEstaMesa.length,
                        itemBuilder: (context, index) {
                          final pedido = pedidosDeEstaMesa[index];
                          final plato = pedidoProvider.getPlatoById(pedido.platoId);

                          return PedidoItem(
                            pedido: pedido,
                            plato: plato,
                            onDelete: null,
                          );
                        },
                      ),
          ),

          // --- BOTONES ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // 🟢 AGREGAR
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final pProvider = context.read<PedidoProvider>();
                      pProvider.iniciarPedido(widget.mesa.id.toString());
                      pProvider.setCliente(widget.mesa.nombre);

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NuevoPedidoPage()),
                      ).then((_) {
                        pProvider.inicializarDatos();
                        if (context.mounted) {
                           context.read<MesaProvider>().cargarMesas();
                        }
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Agregar"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                
                // 🔴 CERRAR MESA
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Confirmar Cierre"),
                          // Usamos también el total calculado aquí
                          content: Text("¿Deseas cerrar la mesa?\n\nTotal Final: \$${totalCalculado.toStringAsFixed(2)}"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              onPressed: () async {
                                Navigator.pop(ctx); 
                                try {
                                  // Llamamos al método cerrar del Provider
                                  await context.read<MesaProvider>().cerrarMesa(widget.mesa.id);
                                  
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("✅ Mesa cerrada")));
                                    Navigator.pop(context); // Vuelve al mapa
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    // Aquí verás el error en rojo si falla
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                                  }
                                }
                              },
                              child: const Text("Confirmar"),
                            )
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: const Text("Cerrar Mesa"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}