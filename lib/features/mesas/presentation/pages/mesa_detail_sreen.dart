import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/mesa.dart';
import '../../../pedidos/presentation/providers/pedido_provider.dart';
import '../../../pedidos/presentation/widgets/pedido_item.dart';

// 1. Cambiamos a StatefulWidget para tener "Ciclo de Vida"
class MesaDetailScreen extends StatefulWidget {
  final Mesa mesa;

  const MesaDetailScreen({super.key, required this.mesa});

  @override
  State<MesaDetailScreen> createState() => _MesaDetailScreenState();
}

class _MesaDetailScreenState extends State<MesaDetailScreen> {
  // 2. INIT STATE: Se ejecuta apenas abres la pantalla
  @override
  void initState() {
    super.initState();
    // Le pedimos al sistema que cargue los datos apenas pueda
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Llamamos al método que descarga los pedidos del Backend
      Provider.of<PedidoProvider>(context, listen: false).inicializarDatos();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos los cambios
    final pedidoProvider = Provider.of<PedidoProvider>(context);

    // 3. DEBUGGING (Para ver en la consola qué está pasando)
    // Esto te ayudará a ver si los IDs coinciden
    debugPrint("🔍 Filtrando mesa ID: ${widget.mesa.id}");

    final pedidosDeEstaMesa = pedidoProvider.listaPedidos.where((pedido) {
      // Imprimimos cada pedido para ver si coincide
      // debugPrint("Comparando con pedido mesa: ${pedido.mesa}");
      return pedido.mesa.toString() == widget.mesa.id.toString();
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Mesa ${widget.mesa.id} - Detalle"),
        actions: [
          // Botón de recarga manual por si acaso
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => pedidoProvider.inicializarDatos(),
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
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    // Usamos widget.mesa para acceder a los datos
                    Text("\$${widget.mesa.totalActual}",
                        style: const TextStyle(
                            fontSize: 24,
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          // --- LISTA ---
          Expanded(
            child: pedidoProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator()) // Mostramos cargando
                : pedidosDeEstaMesa.isEmpty
                    ? const Center(
                        child: Text("No hay platos registrados aún."))
                    : ListView.builder(
                        itemCount: pedidosDeEstaMesa.length,
                        itemBuilder: (context, index) {
                          final pedido = pedidosDeEstaMesa[index];
                          final plato =
                              pedidoProvider.getPlatoById(pedido.platoId);

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
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Agregar productos
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Agregar"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Cerrar Mesa
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: const Text("Cerrar Mesa"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white),
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
