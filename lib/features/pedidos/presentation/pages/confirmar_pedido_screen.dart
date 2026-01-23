import 'package:el_buen_sabor_app/features/mesas/presentation/providers/mesa_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ✅ CORRECCIÓN 1: Usamos el Provider correcto
import '../providers/pedido_provider.dart';

class ConfirmarPedidoScreen extends StatelessWidget {
  const ConfirmarPedidoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ CORRECCIÓN 2: Tipado correcto
    final provider = Provider.of<PedidoProvider>(context);

    // Imprimimos el contenido real si tiene algo

    final carrito = provider.carrito;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Revisar Pedido"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. LISTA DE ÍTEMS
          Expanded(
            child: carrito.isEmpty
                ? const Center(
                    child: Text(
                      "No hay productos cargados",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: carrito.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final item = carrito[index];
                      // ✅ CORRECCIÓN 3: Nombre del método actualizado (getPlatoById)
                      final plato = provider.getPlatoById(item.platoId);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Text(
                              "${item.cantidad}x",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900),
                            ),
                          ),
                          title: Text(
                            plato.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.aclaracion != null &&
                                  item.aclaracion!.isNotEmpty)
                                Text(
                                  "Nota: ${item.aclaracion}",
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[600]),
                                ),
                              Text(
                                  "\$${(item.total * item.cantidad).toStringAsFixed(0)}"),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // ✅ CORRECCIÓN 4: Nombre del método actualizado
                              provider.quitarDelCarrito(item);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 2. TOTAL Y BOTÓN DE CONFIRMAR
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total:",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "\$${provider.totalCarrito.toStringAsFixed(0)}",
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Muestra un Loading si está enviando
                if (provider.isLoading)
                  const CircularProgressIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: carrito.isEmpty
                          ? null
                          : () async {
                              // 🚀 EL MOMENTO DE LA VERDAD
                              // Llamamos al método real que conecta con el Backend
                              final exito = await provider.confirmarPedido();

                              if (context.mounted) {
                                if (exito) {
                                  final mesaProvider =
                                      context.read<MesaProvider>();
                                  await mesaProvider.cargarMesas();

                                  if (context.mounted) {
                                    _mostrarExito(context);
                                  }
                                } else {
                                  // Si falló (ej: Error de conexión o stock)
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content:
                                        Text("Error: ${provider.errorMessage}"),
                                    backgroundColor: Colors.red,
                                  ));
                                }
                              }
                            },
                      child: const Text(
                        "ENVIAR A COCINA",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarExito(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          "¡Pedido enviado a cocina correctamente!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // El provider ya se limpió solo en confirmarPedido()
              Navigator.pop(ctx); // Cierra dialogo
              Navigator.pop(context); // Vuelve al menú
            },
            child: const Text("ACEPTAR"),
          )
        ],
      ),
    );
  }
}
