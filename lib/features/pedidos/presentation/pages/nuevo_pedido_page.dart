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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Nuevo Pedido")),
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

            // 🔽 DROPDOWN MEJORADO (Precio + Stock)
            DropdownButtonFormField<int>(
              initialValue: _platoSeleccionado,
              decoration: const InputDecoration(labelText: "Plato"),
              items: provider.menuPlatos.map((p) {
                
                // 1. Cálculos de Seguridad
                final bool hayStock = p.stock.esIlimitado || p.stock.cantidad > 0;
                final bool esBajoStock = !p.stock.esIlimitado && p.stock.cantidad < 5 && hayStock;

                // 2. Texto Informativo (Simple)
                // Si es ilimitado, no mostramos nada. Si hay stock, mostramos cantidad.
                final String infoStock = p.stock.esIlimitado 
                    ? "" 
                    : " (${p.stock.cantidad})"; 
                
                // 3. Etiqueta final
                // Ej: "Milanesa - $1500 (20)" o "Milanesa - $1500 [AGOTADO]"
                String etiqueta = "${p.nombre} - \$${p.precio.toStringAsFixed(0)}";
                
                if (!hayStock) {
                  etiqueta += " [AGOTADO]";
                } else {
                  etiqueta += infoStock;
                }

                // 4. Color Simple (Rojo si es urgente/agotado, Negro si normal)
                final Color colorTexto = (esBajoStock || !hayStock) ? Colors.red : Colors.black;

                return DropdownMenuItem(
                  value: p.id,
                  enabled: hayStock, 
                  // 🏁 UI SIMPLIFICADA AL MÁXIMO (Solo Texto)
                  // Eliminamos Row, Icon y Flexible para evitar el crash gráfico
                  child: Text(
                    etiqueta,
                    style: TextStyle(
                      color: colorTexto,
                      fontWeight: esBajoStock ? FontWeight.bold : FontWeight.normal,
                      // Si está agotado, lo ponemos en cursiva y gris visualmente (aunque el texto sea rojo)
                      fontStyle: !hayStock ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (v) {
                // Doble chequeo por si acaso selecciona uno deshabilitado
                final plato = provider.getPlatoById(v!);
                if (plato != null &&
                    (plato.stock.esIlimitado || plato.stock.cantidad > 0)) {
                  setState(() => _platoSeleccionado = v);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("¡Producto Agotado!")),
                  );
                }
              },
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      if (_platoSeleccionado == null) return;

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

            const Expanded(child: PedidoList()),
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
