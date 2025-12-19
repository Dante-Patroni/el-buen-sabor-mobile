import 'package:el_buen_sabor_app/features/pedidos/presentation/pages/pedido_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/mesa.dart';


import '../../../pedidos/presentation/providers/pedido_provider.dart';
import '../../../pedidos/presentation/pages/nuevo_pedido_page.dart';
// Asegúrate de tener este import si usas el widget separado,
// o si definiste PedidoList en otro lado.

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
    // 1. Al entrar, le decimos al Provider que descargue los datos frescos del servidor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PedidoProvider>(context, listen: false).inicializarDatos();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 👇 AQUÍ DEFINIMOS EL NOMBRE "pedidoProvider"
    final pedidoProvider = Provider.of<PedidoProvider>(context);

    // 1. Convertimos el ID de la mesa actual a String para comparar
    final mesaIdString = widget.mesa.id.toString();

    // 2. Filtramos la lista global:
    // "Dame solo los pedidos donde el id de mesa coincida con esta pantalla"
    final pedidosDeEstaMesa = pedidoProvider.listaPedidos.where((p) {
      // ✅ Corregido: pedidoProvider
      return p.mesa == mesaIdString;
    }).toList();

    // 3. Calculamos el total sumando solo los pedidos de esta lista filtrada
    double totalMesa = 0;
    for (var p in pedidosDeEstaMesa) {
      // Sumamos solo si no está cancelado
      if (p.estado.name != 'cancelado') totalMesa += p.total;
    }

    return Scaffold(
      appBar: AppBar(title: Text("Mesa ${widget.mesa.nombre}")),
      body: Column(
        children: [
          // -------------------------------------------------------
          // 4. LISTA DE PEDIDOS (FILTRADA)
          // -------------------------------------------------------
          Expanded(
            child:
                pedidoProvider
                    .isLoading // ✅ Corregido: pedidoProvider
                ? const Center(child: CircularProgressIndicator())
                : PedidoList(
                    pedidos: pedidosDeEstaMesa,
                  ), // Pasamos la lista limpia
          ),

          // -------------------------------------------------------
          // 5. SECCIÓN INFERIOR (TOTAL Y BOTONES)
          // -------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // TOTAL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Mesa:",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "\$${totalMesa.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // BOTONES
                Row(
                  children: [
                    // CERRAR MESA
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Aquí iría tu lógica para liberar la mesa (mesaProvider.liberarMesa...)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Funcionalidad Cerrar Mesa: Pendiente",
                              ),
                            ),
                          );
                        },
                        child: const Text("Cerrar Mesa"),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // AGREGAR PEDIDO
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          // 👇 Configuramos el provider para saber a quién cobrarle
                          pedidoProvider.iniciarPedido(
                            mesaIdString,
                          ); // ✅ Corregido
                          pedidoProvider.setCliente(
                            widget.mesa.nombre,
                          ); // ✅ Corregido

                          // Vamos a la pantalla de selección de comida
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NuevoPedidoPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Agregar"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
