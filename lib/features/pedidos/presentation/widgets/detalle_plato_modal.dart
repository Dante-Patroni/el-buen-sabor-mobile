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

  // 👇 1. FUNCIÓN PARA CORREGIR LA URL (IP DE LA PC)
  String _construirUrlImagen(String path) {
    if (path.isEmpty) return "";
    if (path.startsWith("http")) return path;

    // ⚠️ REEMPLAZA ESTO CON TU IP REAL (ej: 192.168.0.15)
    const String ipDeTuPC = "192.168.18.3"; 

    return "http://$ipDeTuPC:3000$path".replaceAll("\\", "/");
  }

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
    // Preparamos la URL de la imagen
    final urlImagen = _construirUrlImagen(widget.plato.imagenPath);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView( // Para que no tape el teclado
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // 👇 2. IMAGEN GRANDE (HERO) AL PRINCIPIO
            if (urlImagen.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  urlImagen,
                  height: 200, // Altura fija grande
                  fit: BoxFit.cover, // Llena el espacio sin deformarse
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: Colors.grey[100],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 3. HEADER (Título y Precio)
            // Ya no necesitamos la imagen chiquita aquí
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.plato.nombre,
                    style: const TextStyle(
                        fontSize: 22, // Título más grande
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "\$${widget.plato.precio.toStringAsFixed(0)}",
                  style: const TextStyle(
                      fontSize: 22,
                      color: Colors.green,
                      fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Descripción (if any)
            if (widget.plato.descripcion.isNotEmpty) ...[
              Text(
                widget.plato.descripcion,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 20),
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
                      Navigator.pop(context, {
                        'cantidad': cantidad,
                        'aclaracion': _aclaracionController.text.trim(),
                      });
                    },
                    child: Text(
                      "Agregar \$${(widget.plato.precio * cantidad).toStringAsFixed(0)}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            // Espacio para el teclado
            Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom)),
          ],
        ),
      ),
    );
  }
}