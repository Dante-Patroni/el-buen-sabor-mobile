import 'package:flutter/material.dart';
import '../../domain/models/mesa_ui_model.dart';
// Importa aquí tus otras pantallas cuando las tengamos (ej: NuevoPedidoScreen)

class MesaMenuScreen extends StatelessWidget {
  final MesaUiModel mesa;

  const MesaMenuScreen({super.key, required this.mesa});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text("Mesa ${mesa.numero}", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(mesa.estado.toUpperCase(), style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.black87, // Look más "Pro" tipo Toast Dark Mode
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Cabecera con info rápida
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Mozo: ${mesa.mozoAsignado ?? 'Sin Asignar'}", 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Text("Total: \$${mesa.totalActual ?? 0}", 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),

            // GRILLA DE BOTONES (ESTILO TOAST)
            Expanded(
              child: GridView.count(
                crossAxisCount: 2, // 2 columnas de botones grandes
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3, // Botones más rectangulares
                children: [
                  _BotonMenu(
                    icon: Icons.restaurant_menu,
                    label: "Hacer Pedido",
                    color: Colors.orange.shade700,
                    onTap: () {
                      // AQUÍ IREMOS A LA PANTALLA DE PRODUCTOS (CATEGORÍAS)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Próximamente: Catálogo de Productos")),
                      );
                    },
                  ),
                  _BotonMenu(
                    icon: Icons.receipt_long,
                    label: "Ver Cuenta",
                    color: Colors.blue.shade700,
                    onTap: () {
                      // AQUÍ IREMOS AL DETALLE DE LO CONSUMIDO
                    },
                  ),
                  _BotonMenu(
                    icon: Icons.people,
                    label: "Comensales",
                    color: Colors.purple.shade600,
                    onTap: () {
                      // Lógica para contar cubiertos (opcional)
                    },
                  ),
                  _BotonMenu(
                    icon: Icons.point_of_sale,
                    label: "Cobrar / Cerrar",
                    color: Colors.red.shade700,
                    onTap: () {
                      // AQUÍ LLAMAREMOS AL PROCESO DE PAGO
                      Navigator.pop(context, 'cerrar'); // Ejemplo de retorno
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar para los botones bonitos
class _BotonMenu extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BotonMenu({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}