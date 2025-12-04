import 'package:flutter/material.dart';
import '../../domain/models/pedido.dart';
import '../../domain/models/plato.dart';

class PedidoItem extends StatelessWidget {
  final Pedido pedido;
  final Plato? plato;
  final VoidCallback? onDelete;

  const PedidoItem({
    super.key,
    required this.pedido,
    required this.plato,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          plato?.nombre ?? "Plato desconocido",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Mesa: ${pedido.mesa}   |   Cliente: ${pedido.cliente}",
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
