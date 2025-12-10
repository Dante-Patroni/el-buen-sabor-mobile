import 'package:el_buen_sabor_app/features/mesas/presentation/pages/mesa_detail_sreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports de Mesas
import '../providers/mesa_provider.dart';
import '../widgets/mesa_item.dart';

// 👇 1. NUEVOS IMPORTS (Para conectar con Pedidos)
import '../../../pedidos/presentation/providers/pedido_provider.dart';
import '../../../pedidos/presentation/pages/nuevo_pedido_page.dart';

class MesasScreen extends StatefulWidget {
  const MesasScreen({super.key});

  @override
  State<MesasScreen> createState() => _MesasScreenState();
}

class _MesasScreenState extends State<MesasScreen> {
  @override
  void initState() {
    super.initState();
    // Cargamos las mesas al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MesaProvider>(context, listen: false).cargarMesas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mesaProvider = Provider.of<MesaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Mesas 🍔'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => mesaProvider.cargarMesas(),
          )
        ],
      ),
      body: mesaProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : mesaProvider.error.isNotEmpty
              ? Center(child: Text('Error: ${mesaProvider.error}'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: mesaProvider.mesas.length,
                    itemBuilder: (context, index) {
                      final mesa = mesaProvider.mesas[index];

                      return MesaItem(
                        mesa: mesa,
                        onTap: () {
                          // 👇 2. LÓGICA DE NAVEGACIÓN INTELIGENTE
                          if (mesa.estado == 'libre') {
                            // A. Si está LIBRE -> Iniciamos Nuevo Pedido

                            // 1. Preparamos el provider (limpiamos carrito, seteamos mesa)
                            context
                                .read<PedidoProvider>()
                                .iniciarPedido(mesa.id.toString());

                            // 2. Navegamos a la pantalla de carga
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NuevoPedidoPage(),
                              ),
                            ).then((_) {
                              // Cuando volvemos, recargamos las mesas por si se ocupó alguna
                              mesaProvider.cargarMesas();
                            });
                          } else {
                            // B. Si NO ESTÁ LIBRE -> Conectamos con mesa ocupada Navegamos a Detalle
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MesaDetailScreen(mesa: mesa),
                              ),
                            ).then((_) {
                              // Cuando volvemos, recargamos las mesas por si hubo cambios
                              mesaProvider.cargarMesas();
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
