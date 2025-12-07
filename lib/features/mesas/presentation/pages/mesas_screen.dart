import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mesa_provider.dart';
import '../widgets/mesa_item.dart';

class MesasScreen extends StatefulWidget {
  const MesasScreen({super.key});

  @override
  State<MesasScreen> createState() => _MesasScreenState();
}

class _MesasScreenState extends State<MesasScreen> {
  @override
  void initState() {
    super.initState();
    // Cargamos los datos apenas se renderiza la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MesaProvider>(context, listen: false).cargarMesas();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos cambios en el provider
    final provider = Provider.of<MesaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Mesas 🍔'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.cargarMesas(), // Recarga manual
          )
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error.isNotEmpty
              ? Center(child: Text('Error: ${provider.error}'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 columnas
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1, // Forma cuadrada
                    ),
                    itemCount: provider.mesas.length,
                    itemBuilder: (context, index) {
                      final mesa = provider.mesas[index];
                      return MesaItem(
                        mesa: mesa,
                        onTap: () {
                          // Aquí iría la navegación al detalle (EBS-16)
                          //debugPrint("Tocaste ${mesa.nombre}");
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
