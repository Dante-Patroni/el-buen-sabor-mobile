import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/plato.dart';
import '../providers/pedido_provider.dart';

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
    // Inicializamos datos al cargar la pantalla
    Future.microtask(() => 
      context.read<PedidoProvider>().inicializarDatos()
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PedidoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("El Buen Sabor - Mozos"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. INPUT CLIENTE
            TextField(
              controller: _clienteController,
              decoration: const InputDecoration(
                labelText: "Nombre del Cliente",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),

            // 2. DROPDOWN DE PLATOS
            Text("Seleccionar Plato:", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (provider.menuPlatos.isEmpty)
              const Text("⚠️ El menú está vacío o no cargó.")
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    hint: const Text("Elige una opción..."),
                    value: _platoSeleccionadoId,
                    // Aseguramos que el valor seleccionado exista en la lista actual
                    // Si no existe (ej: menú cambió), lo ponemos null para evitar crash
                    items: provider.menuPlatos.map((Plato plato) {
                      return DropdownMenuItem<int>(
                        value: plato.id,
                        child: Text("${plato.nombre} - \$${plato.precio}"),
                      );
                    }).toList(),
                    onChanged: (int? nuevoValor) {
                      setState(() {
                        _platoSeleccionadoId = nuevoValor;
                      });
                    },
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 3. BOTÓN ENVIAR
            ElevatedButton.icon(
              onPressed: provider.isLoading 
                  ? null 
                  : () async {
                      if (_clienteController.text.isEmpty || _platoSeleccionadoId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Faltan datos")),
                        );
                        return;
                      }

                      final exito = await provider.agregarPedido(
                        _clienteController.text,
                        _platoSeleccionadoId!,
                      );

                      if (exito && mounted) {
                        _clienteController.clear();
                        setState(() { _platoSeleccionadoId = null; });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("✅ Pedido enviado!"), backgroundColor: Colors.green),
                        );
                      }
                    },
              icon: const Icon(Icons.send),
              label: const Text("CONFIRMAR PEDIDO"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),

            const Divider(height: 40),

            // 4. LISTA DE PEDIDOS (Historial)
            Expanded(
              child: provider.listaPedidos.isEmpty
                  ? const Center(child: Text("No hay pedidos recientes"))
                  : ListView.builder(
                      itemCount: provider.listaPedidos.length,
                      itemBuilder: (context, index) {
                        final pedido = provider.listaPedidos[index];
                        
                        // 🛠️ CORRECCIÓN CLAVE: firstWhere con cast seguro
                        // Buscamos el plato en la lista del menú.
                        Plato plato;
                        try {
                          plato = provider.menuPlatos.firstWhere(
                            (p) => p.id == pedido.platoId,
                          );
                        } catch (e) {
                          // Si no lo encuentra (ej: plato borrado o ID viejo), usamos uno dummy
                          plato = Plato(id: 0, nombre: "Plato Desconocido", precio: 0, ingredientePrincipal: "");
                        }

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text("${pedido.id}")),
                            title: Text(pedido.cliente),
                            subtitle: Text("Plato: ${plato.nombre}\nEstado: ${pedido.estado.name}"),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final exito = await provider.borrarPedido(pedido.id!);
                                if (exito && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Pedido eliminado")),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}