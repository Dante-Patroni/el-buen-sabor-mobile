import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart'; // ✅ Import Config
import '../../domain/models/plato.dart';

class DetallePlatoModal extends StatefulWidget {
  final Plato plato;
  // 🆕 NUEVO (opcionales)
  final int cantidadInicial;
  final String aclaracionInicial;
  final String textoBoton;

  /**
   * @description Crea el modal de detalle de plato.
   * @param {Plato} plato - Plato a mostrar.
   * @param {int} cantidadInicial - Cantidad inicial.
   * @param {String} aclaracionInicial - Aclaracion inicial.
   * @param {String} textoBoton - Texto del boton principal.
   * @returns {DetallePlatoModal} Instancia del widget.
   * @throws {Error} No lanza errores por diseno.
   */
  const DetallePlatoModal({
    super.key,
    required this.plato,
    this.cantidadInicial = 1,
    this.aclaracionInicial = "",
    this.textoBoton = "Agregar",
  });

  @override
  /**
   * @description Crea el estado del modal de detalle.
   * @returns {State<DetallePlatoModal>} Estado del widget.
   * @throws {Error} No lanza errores por diseno.
   */
  State<DetallePlatoModal> createState() => _DetallePlatoModalState();
}

class _DetallePlatoModalState extends State<DetallePlatoModal> {
  late int cantidad;
late TextEditingController _aclaracionController;

@override
  /**
   * @description Inicializa la cantidad y el controlador de aclaraciones.
   * @returns {void} No retorna valor.
   * @throws {Error} No lanza errores por diseno.
   */
 void initState() {
  super.initState();
  cantidad = widget.cantidadInicial;
  _aclaracionController =
      TextEditingController(text: widget.aclaracionInicial);
}

@override
  /**
   * @description Libera el controlador de texto de aclaraciones.
   * @returns {void} No retorna valor.
   * @throws {Error} No lanza errores por diseno.
   */
   void dispose() {
    _aclaracionController.dispose();
    super.dispose();
  }




  // 👇 1. FUNCIÓN PARA CORREGIR LA URL (IP DE LA PC)
  /**
   * @description Construye la URL final de la imagen del plato.
   * @param {String} path - Ruta o URL original.
   * @returns {String} URL final para Image.network.
   * @throws {Error} No lanza errores por diseno.
   */
  String _construirUrlImagen(String path) {
    if (path.isEmpty) return "";
    if (path.startsWith("http")) return path;

    final baseUrl = AppConfig.apiBaseUrl.replaceAll("/api", "");
    return "$baseUrl$path".replaceAll("\\", "/");
  }


  /**
   * @description Incrementa la cantidad seleccionada.
   * @returns {void} No retorna valor.
   * @throws {Error} No lanza errores.
   */
  void _incrementar() {
    setState(() => cantidad++);
  }

  /**
   * @description Decrementa la cantidad seleccionada si es mayor a 1.
   * @returns {void} No retorna valor.
   * @throws {Error} No lanza errores.
   */
  void _decrementar() {
    if (cantidad > 1) {
      setState(() => cantidad--);
    }
  }

  @override
  /**
   * @description Construye la UI del modal de detalle de plato.
   * @param {BuildContext} context - Contexto de widgets.
   * @returns {Widget} Arbol de widgets.
   * @throws {Error} No lanza errores por diseno.
   */
  Widget build(BuildContext context) {
    // Preparamos la URL de la imagen
    final urlImagen = _construirUrlImagen(widget.plato.imagenPath);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        // Para que no tape el teclado
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
                    child: const Icon(Icons.broken_image,
                        size: 50, color: Colors.grey),
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
