import 'package:flutter/material.dart';
import '../../domain/models/mesa.dart'; // O mesa_model.dart según uses

class MesaItem extends StatelessWidget {
  final Mesa mesa;
  final VoidCallback onTap;

  const MesaItem({super.key, required this.mesa, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOcupada = mesa.estado == 'ocupada';

    // Colores definidos
    final colorFondo = isOcupada ? Colors.deepOrange.shade50 : Colors.white;
    final colorBorde = isOcupada ? Colors.deepOrange : Colors.grey.shade300;
    final colorIcono = isOcupada ? Colors.deepOrange : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(16), // Bordes más redondeados
          border: Border.all(
            color: colorBorde,
            width: isOcupada ? 2 : 1, // Borde más grueso si está ocupada
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fila superior: Ícono y Nombre
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.table_restaurant_rounded,
                  size: 28,
                  color: colorIcono,
                ),
                const SizedBox(width: 8),
                Text(
                  mesa.nombre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800, // Letra más gruesa
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Fila inferior: Estado / Mozo
            if (isOcupada)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person,
                      size: 14,
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      mesa.mozoAsignado ?? "Dante", // Tu lógica de Mozo
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
              )
            else
              const Text(
                "Disponible",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
