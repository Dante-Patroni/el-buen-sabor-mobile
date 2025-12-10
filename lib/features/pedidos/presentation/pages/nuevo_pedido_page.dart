import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pedido_provider.dart';
import '../../domain/models/plato.dart';

class NuevoPedidoPage extends StatefulWidget {
  const NuevoPedidoPage({super.key});

  @override
  State<NuevoPedidoPage> createState() => _NuevoPedidoPageState();
}

class _NuevoPedidoPageState extends State<NuevoPedidoPage> {
  final _clienteController = TextEditingController();
  int? _platoSeleccionadoId;

  @override
  void initState() {
    super.initState();
    // Cargamos menú y pedidos viejos al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PedidoProvider>().inicializarDatos();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos al provider
    final provider = Provider.of<PedidoProvider>(context);
    final carrito = provider.carrito;

    return Scaffold(
      appBar: AppBar(
        title: Text("Mesa ${provider.mesaSeleccionada}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. NOMBRE DEL CLIENTE (Opcional)
            TextField(
              controller: _clienteController,
              decoration: const InputDecoration(
                labelText: "Cliente (Opcional)",
                prefixIcon: Icon(Icons.person),
              ),
              onChanged: (val) => provider.setCliente(val),
            ),
            const SizedBox(height: 16),

            // 2. SELECTOR DE PLATOS (Dropdown)
            DropdownButtonFormField<int>(
              value: _platoSeleccionadoId,
              decoration: const InputDecoration(
                labelText: "Agregar Plato",
                border: OutlineInputBorder(),
              ),
              items: provider.menuPlatos.map((plato) {
                return DropdownMenuItem(
                  value: plato.id,
                  child: Text("${plato.nombre} - \$${plato.precio.toInt()}"),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _platoSeleccionadoId = val);
              },
            ),
            const SizedBox(height: 10),

            // 3. BOTÓN AGREGAR AL CARRITO
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _platoSeleccionadoId == null
                    ? null
                    : () {
                        // Buscamos el objeto plato completo
                        final plato = provider.getPlatoById(_platoSeleccionadoId!);
                        if (plato != null) {
                          // 👇 AQUÍ ESTÁ EL CAMBIO: Usamos agregarAlCarrito
                          provider.agregarAlCarrito(plato);
                          setState(() => _platoSeleccionadoId = null); // Reseteamos
                        }
                      },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text("Agregar al Pedido"),
              ),
            ),

            const Divider(thickness: 2, height: 32),

            // 4. LISTA DEL CARRITO (Visualizamos lo que vamos a pedir)
            Expanded(
              child: carrito.isEmpty
                  ? Center(
                      child: Text(
                        "El pedido está vacío",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.builder(
                      itemCount: carrito.length,
                      itemBuilder: (context, index) {
                        final item = carrito[index];
                        return ListTile(
                          leading: const Icon(Icons.fastfood, color: Colors.orange),
                          title: Text(item.nombre),
                          subtitle: Text("\$ ${item.precio.toInt()}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            // 👇 Eliminamos del borrador local
                            onPressed: () => provider.quitarDelCarrito(index),
                          ),
                        );
                      },
                    ),
            ),

            // 5. BOTÓN CONFIRMAR (Enviar a Cocina)
            if (carrito.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          // 👇 AQUÍ CONFIRMAMOS (EBS-16)
                          final exito = await provider.confirmarPedido();
                          if (exito && context.mounted) {
                            Navigator.pop(context); // Volvemos a las mesas
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("¡Pedido enviado a cocina! 🍳")),
                            );
                          }
                        },
                  child: provider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "CONFIRMAR PEDIDO (\$${provider.totalCarrito.toInt()})",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}