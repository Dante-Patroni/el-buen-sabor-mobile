import 'package:el_buen_sabor_app/features/pedidos/presentation/providers/pedido_provider.dart';
import 'package:flutter/material.dart';
import '../../domain/models/mesa_ui_model.dart';
// 👇 Imports correctos
import 'package:provider/provider.dart';
import 'package:el_buen_sabor_app/features/pedidos/presentation/pages/menu_moderno_page.dart';
import 'package:el_buen_sabor_app/features/mesas/presentation/pages/ver_pedido_mesa_screen.dart';

class MesaMenuScreen extends StatelessWidget {
  final MesaUiModel mesa;

  const MesaMenuScreen({super.key, required this.mesa});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ✅ AQUI: Mostramos el NÚMERO ("5"), no el ID
        title: Text("Mesa ${mesa.numero}"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TARJETA DE RESUMEN
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long,
                        size: 50, color: Colors.orange),
                    const SizedBox(height: 10),
                    Text(
                      "Total Actual",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    Text(
                      "\$${mesa.totalActual ?? 0.toStringAsFixed(0)}",
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text("Mozo: ${mesa.mozoAsignado}"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // BOTÓN 1: HACER PEDIDO
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // 👇 Configuración correcta del Provider
                final pedidoProvider =
                    Provider.of<PedidoProvider>(context, listen: false);
                pedidoProvider.iniciarPedido(mesa.id.toString());
                pedidoProvider.setCliente("Mesa ${mesa.numero}");

                // 👇 Navegamos a la pantalla ANTIGUA (que el usuario prefiere)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MenuModernoPage(
                        idMesa: mesa.id, numeroMesa: mesa.numero.toString()),
                  ),
                );
              },
              icon: const Icon(Icons.restaurant_menu),
              label: const Text("HACER PEDIDO / VER CARTA",
                  style: TextStyle(fontSize: 18)),
            ),

            const SizedBox(height: 20),

            // BOTÓN EXTRA: VER PEDIDO (LO QUE YA SE PIDIÓ)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VerPedidoMesaScreen(
                      mesaId: mesa.id,
                      mesaNumero: mesa.numero,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.visibility),
              label: const Text("VER PEDIDO EN CURSO",
                  style: TextStyle(fontSize: 18)),
            ),

            const SizedBox(height: 20),

            // BOTÓN 2: CERRAR MESA (Ejemplo futuro)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // Aquí iría la lógica de cerrar mesa / cobrar
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Función Cerrar Mesa: Próximamente")));
              },
              icon: const Icon(Icons.point_of_sale),
              label: const Text("CERRAR MESA Y COBRAR",
                  style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
