import 'package:el_buen_sabor_app/features/pedidos/presentation/pages/pedido_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pedido_provider.dart';


class NuevoPedidoPage extends StatefulWidget {
  const NuevoPedidoPage({super.key});

  @override
  State<NuevoPedidoPage> createState() => _NuevoPedidoPageState();
}

class _NuevoPedidoPageState extends State<NuevoPedidoPage> {
  final _mesaController = TextEditingController();
  final _clienteController = TextEditingController();
  int? _platoSeleccionado;
    bool _inicializado = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarInicial();
    });
  }

  Future<void> _cargarInicial() async {
    final provider = context.read<PedidoProvider>();
    await provider.inicializarDatos();

    if (mounted) {
      setState(() {
        _inicializado = true;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PedidoProvider>(context);

 // 🔄 Pantalla de carga inicial
    if (!_inicializado) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nuevo Pedido"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- FORMULARIO ---
            TextField(
              controller: _mesaController,
              decoration: const InputDecoration(labelText: "Mesa"),
            ),
            TextField(
              controller: _clienteController,
              decoration: const InputDecoration(labelText: "Cliente"),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              value: _platoSeleccionado,
              items: provider.menuPlatos
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.nombre),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _platoSeleccionado = v),
              decoration: const InputDecoration(labelText: "Plato"),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      final ok = await provider.agregarPedido(
                        _mesaController.text,
                        _clienteController.text,
                        _platoSeleccionado!,
                      );

                      if (ok) {
                        _mesaController.clear();
                        _clienteController.clear();
                        setState(() => _platoSeleccionado = null);
                      }
                    },
              child: provider.isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Guardar Pedido"),
            ),

            const SizedBox(height: 24),

            const Expanded(
              child: PedidoList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mesaController.dispose();
    _clienteController.dispose();
    super.dispose();
  }
}
