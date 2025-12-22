import 'package:flutter/material.dart';
import '../../domain/models/plato.dart';

class DetallePlatoModal extends StatefulWidget {
  final Plato plato;
  const DetallePlatoModal({super.key, required this.plato});

  @override
  State<DetallePlatoModal> createState() => _DetallePlatoModalState();
}

class _DetallePlatoModalState extends State<DetallePlatoModal> {
  int cantidad = 1;
  final TextEditingController _aclaracionController = TextEditingController();

  @override
  void dispose() {
    _aclaracionController.dispose();
    super.dispose();
  }

  void _incrementar() {
    setState(() => cantidad++);
  }

  void _decrementar() {
    if (cantidad > 1) {
      setState(() => cantidad--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[200],
                    image: widget.plato.imagenPath.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(widget.plato.imagenPath),
                            fit: BoxFit.cover)
                        : null),
                child: widget.plato.imagenPath.isEmpty
                    ? const Icon(Icons.fastfood)
                    : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.plato.nombre,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("\$${widget.plato.precio.toStringAsFixed(0)}",
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),

          // Descripción (if any)
          if (widget.plato.descripcion.isNotEmpty) ...[
            Text("Descripción",
                style: TextStyle(
                    color: Colors.grey[600], fontWeight: FontWeight.bold)),
            Text(widget.plato.descripcion),
            const SizedBox(height: 15),
          ],

          // Aclaración
          TextField(
            controller: _aclaracionController,
            decoration: const InputDecoration(
              labelText: "Aclaración al cocinero (Opcional)",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.comment),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          // Cantidad y Botón
          Row(
            children: [
              // Selector Cantidad
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    IconButton(
                        onPressed: _decrementar,
                        icon: const Icon(Icons.remove)),
                    Text("$cantidad",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                        onPressed: _incrementar, icon: const Icon(Icons.add)),
                  ],
                ),
              ),
              const SizedBox(width: 15),

              // Botón Agregar
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    // Return data
                    Navigator.pop(context, {
                      'cantidad': cantidad,
                      'aclaracion': _aclaracionController.text.trim(),
                    });
                  },
                  child: Text(
                      "Agregar \$${(widget.plato.precio * cantidad).toStringAsFixed(0)}"),
                ),
              ),
            ],
          ),

          // Keyboard spacer
          Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom)),
        ],
      ),
    );
  }
}
