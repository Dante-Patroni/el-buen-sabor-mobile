import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pedido_provider.dart';


class NuevoPedidoPage extends StatefulWidget {
  const NuevoPedidoPage({super.key});

  @override
  State<NuevoPedidoPage> createState() => _NuevoPedidoPageState();
}

class _NuevoPedidoPageState extends State<NuevoPedidoPage>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PedidoProvider>(context);

    // 1. OBTENER RUBROS ÚNICOS (Dinámico)
    // Escaneamos todos los platos para ver qué categorías existen (ej: Hamburguesas, Bebidas)
    // Agregamos "Todos" al principio.
    final List<String> rubros = ["Todos"];
    final rubrosDetectados = provider.menuPlatos
        .map((e) => e.categoria)
        .toSet()
        .toList();
    rubros.addAll(rubrosDetectados);

    return DefaultTabController(
      length: rubros.length, // Cuántas pestañas vamos a tener
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Menú"),
              Text(
                "${provider.mesaSeleccionada} - ${provider.clienteActual}",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          // 👇 AQUÍ VUELVEN LAS PESTAÑAS (Scrollable por si son muchas)
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.orange,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            tabs: rubros
                .map((rubro) => Tab(text: rubro.toUpperCase()))
                .toList(),
          ),
        ),

        // 👇 EL CONTENIDO DE CADA PESTAÑA
        body: TabBarView(
          children: rubros.map((rubroActual) {
            // Filtramos la lista según la pestaña donde estemos
            final platosFiltrados = rubroActual == "Todos"
                ? provider.menuPlatos
                : provider.menuPlatos
                      .where((p) => p.categoria == rubroActual)
                      .toList();

            if (platosFiltrados.isEmpty) {
              return const Center(
                child: Text("No hay productos en este rubro"),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 100, top: 10),
              itemCount: platosFiltrados.length,
              itemBuilder: (context, index) {
                final plato = platosFiltrados[index];

                // Lógica de Stock (que ya funcionaba)
                final tieneStock =
                    plato.stock.estado == 'DISPONIBLE' ||
                    plato.stock.estado == 'BAJA' ||
                    (plato.stock.cantidad > 0);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      // FOTO
                      leading: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                          image:
                              plato.imagenPath.isNotEmpty &&
                                  !plato.imagenPath.contains("url-falsa")
                              ? DecorationImage(
                                  image: NetworkImage(plato.imagenPath),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child:
                            plato.imagenPath.isEmpty ||
                                plato.imagenPath.contains("url-falsa")
                            ? const Icon(Icons.restaurant, color: Colors.grey)
                            : null,
                      ),

                      // INFO DEL PLATO
                      title: Text(
                        plato.nombre,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: tieneStock ? Colors.black : Colors.grey,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            plato.descripcion,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "\$${plato.precio.toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),

                      // BOTÓN AGREGAR
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tieneStock
                              ? Colors.orange
                              : Colors.grey[300],
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                        ),
                        onPressed: tieneStock
                            ? () {
                                provider.agregarAlCarrito(plato);
                                ScaffoldMessenger.of(
                                  context,
                                ).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Agregado: ${plato.nombre}"),
                                    duration: const Duration(milliseconds: 800),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            : null,
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),

        // 👇 LA BARRA DE CARRITO (Igual que antes, porque funcionaba bien)
        bottomSheet: provider.carrito.isNotEmpty
            ? Container(
                padding: const EdgeInsets.all(16),
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
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${provider.carrito.length} Items",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Total: \$${provider.totalCarrito.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _mostrarDetalleCarrito(context, provider),
                              icon: const Icon(Icons.list),
                              label: const Text("Ver Detalle"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: provider.isLoading
                                  ? null
                                  : () async {
                                      final exito = await provider
                                          .confirmarPedido();
                                      if (exito && context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "✅ Pedido Confirmado",
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              icon: provider.isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check),
                              label: Text(
                                provider.isLoading
                                    ? "Enviando..."
                                    : "Confirmar",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }

  // Modal del detalle (Sin cambios, funcionaba bien)
  void _mostrarDetalleCarrito(BuildContext context, PedidoProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            children: [
              const Text(
                "Tu Pedido",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.carrito.length,
                  itemBuilder: (context, index) {
                    final item = provider.carrito[index];
                    final platoReal = provider.getPlatoById(item.platoId);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange[100],
                        child: Text(
                          "${item.cantidad}",
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                      title: Text(platoReal.nombre),
                      subtitle: Text(
                        "\$${(item.total * item.cantidad).toStringAsFixed(0)}",
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          provider.quitarDelCarrito(item);
                          Navigator.pop(context);
                          _mostrarDetalleCarrito(context, provider);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
