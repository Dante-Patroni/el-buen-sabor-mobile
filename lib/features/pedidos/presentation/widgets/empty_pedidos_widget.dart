import 'package:flutter/material.dart';

class EmptyPedidosWidget extends StatelessWidget {
  const EmptyPedidosWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.inbox, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            "No hay pedidos todavía",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
