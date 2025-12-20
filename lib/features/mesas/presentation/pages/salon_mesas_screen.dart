import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Imports de tus capas
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/pages/login_page.dart';
import '../providers/mesa_provider.dart'; // 👈 Asegúrate de este import
import '../../domain/models/mesa_ui_model.dart';
import 'mesa_menu_screen.dart';
class SalonMesasScreen extends StatefulWidget {
  const SalonMesasScreen({super.key});

  @override
  State<SalonMesasScreen> createState() => _SalonMesasScreenState();
}

class _SalonMesasScreenState extends State<SalonMesasScreen> {

  @override
  void initState() {
    super.initState();
    // ⚡ AL INICIAR: Pedimos la lista REAL al Backend
    // Usamos addPostFrameCallback para evitar errores de construcción
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MesaProvider>(context, listen: false).cargarMesas();
    });
  }

  // Lógica al tocar una mesa
  Future<void> _onMesaTap(MesaUiModel mesa) async {
    if (mesa.estado == 'libre') {
      _mostrarDialogoAbrir(mesa);
    } else {
      // ✅ Si está ocupada, vamos al Menú Estilo Toast
      // Usamos 'await' para esperar a que el usuario termine de hacer cosas en el menú
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MesaMenuScreen(mesa: mesa),
        ),
      );

      // 🔄 AL VOLVER: Recargamos las mesas
      // Por si el usuario cerró la mesa o cambió el total desde el menú
      if (mounted) {
        Provider.of<MesaProvider>(context, listen: false).cargarMesas();
      }
    }
  }

  // A. ABRIR MESA (Conectado al Backend)
  void _mostrarDialogoAbrir(MesaUiModel mesa) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final mesaProvider = Provider.of<MesaProvider>(context, listen: false);
    
    final nombreMozo = authProvider.usuario?.nombre ?? "Mozo";
    final idMozo = authProvider.usuario?.id;

    if (idMozo == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("¿Abrir Mesa ${mesa.numero}?"),
        content: Text("Se asignará a: $nombreMozo"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Cerramos el diálogo
              
              // 1. Backend
              final exito = await mesaProvider.ocuparMesa(mesa.id, idMozo);
              
              if (mounted && exito) {
                 // Objeto temporal para no esperar recarga
                  final mesaActualizada = MesaUiModel(
                    id: mesa.id,
                    numero: mesa.numero,
                    estado: 'ocupada',
                    mozoAsignado: nombreMozo,
                    totalActual: 0.0
                  );

                  // 2. Navegamos y ESPERAMOS (await) a que vuelva
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MesaMenuScreen(mesa: mesaActualizada),
                    ),
                  );

                  // 3. Al volver, recargamos el mapa por seguridad
                  if (mounted) {
                     mesaProvider.cargarMesas();
                  }
              } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error al abrir la mesa")),
                  );
              }
            },
            child: const Text("Abrir Mesa"),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final nombreMozo = authProvider.usuario?.nombre ?? "Desconocido";

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text("Salón Principal"),
            Text("Turno: $nombreMozo", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w300)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              authProvider.logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          )
        ],
      ),
      // 👇 CONSUMER: Aquí ocurre la magia. Escucha al Provider.
      body: Consumer<MesaProvider>(
        builder: (context, mesaProvider, child) {
          
          // 1. Cargando...
          if (mesaProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error
          if (mesaProvider.error.isNotEmpty) {
            return Center(child: Text(mesaProvider.error)); // Muestra si falló la conexión
          }

          // 3. Lista Vacía (Si no ejecutaste el SQL Insert, verás esto o solo 1 mesa)
          if (mesaProvider.mesas.isEmpty) {
            return const Center(child: Text("No hay mesas registradas en el sistema"));
          }

          // 4. GRILLA REAL
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: mesaProvider.mesas.length, // Usa la cantidad REAL de la BD
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final mesa = mesaProvider.mesas[index];
              return _MesaCard(
                mesa: mesa,
                onTap: () => _onMesaTap(mesa),
              );
            },
          );
        },
      ),
    );
  }
}

// Widget Tarjeta Visual (Sin cambios lógicos, solo visuales)
class _MesaCard extends StatelessWidget {
  final MesaUiModel mesa;
  final VoidCallback onTap;
  const _MesaCard({required this.mesa, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool esOcupada = mesa.estado == 'ocupada';
    final Color colorFondo = esOcupada ? Colors.orange.shade800 : Colors.grey.shade300;
    final Color colorTexto = esOcupada ? Colors.white : Colors.black87;

    return Material(
      color: colorFondo,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.table_restaurant_rounded, size: 40, color: colorTexto),
              const SizedBox(height: 8),
              Text(
                "Mesa ${mesa.numero}", 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorTexto)
              ),
              const SizedBox(height: 4),
              if (esOcupada)
                 Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Mozo: ${mesa.mozoAsignado}",
                    style: TextStyle(fontSize: 12, color: colorTexto),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Text(
                  "LIBRE", 
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600)
                ),
            ],
          ),
        ),
      ),
    );
  }
}