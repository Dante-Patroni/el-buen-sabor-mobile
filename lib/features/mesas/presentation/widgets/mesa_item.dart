import 'package:flutter/material.dart';
import '../../domain/models/mesa.dart';

class MesaItem extends StatelessWidget {
  final Mesa mesa;
  final VoidCallback onTap;

  const MesaItem({
    super.key, 
    required this.mesa, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    // 🎨 Lógica de Diseño según Estado
    final isOcupada = mesa.estado == 'ocupada';
    
    // Colores: Naranja si ocupada, Gris si libre
    final colorFondo = isOcupada ? Colors.deepOrange.shade100 : Colors.grey.shade200;
    final colorBorde = isOcupada ? Colors.deepOrange : Colors.grey;
    final colorIcono = isOcupada ? Colors.deepOrange : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorBorde, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(2, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_restaurant_rounded, 
              size: 32, 
              color: colorIcono
            ),
            const SizedBox(height: 8),
            Text(
              mesa.nombre,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            
            // Si está ocupada, mostramos el dinero. Si no, "Libre".
            if (isOcupada)
              Text(
                '\$ ${mesa.totalActual.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.deepOrange,
                ),
              )
            else
              Text(
                "Libre",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic
                ),
              ),
          ],
        ),
      ),
    );
  }
}