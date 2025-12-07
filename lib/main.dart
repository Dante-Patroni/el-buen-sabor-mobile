/// ARCHIVO: main.dart
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importamos las capas necesarias
import 'features/pedidos/data/repositories/pedido_repository_impl.dart';
import 'features/pedidos/presentation/providers/pedido_provider.dart';
// import 'features/pedidos/presentation/pages/nuevo_pedido_page.dart'; // Ya no es la home
import 'features/mesas/presentation/providers/mesa_provider.dart';
import 'features/mesas/presentation/pages/mesas_screen.dart'; // 👈 Importamos la nueva pantalla

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ElBuenSaborApp());
}

class ElBuenSaborApp extends StatelessWidget {
  const ElBuenSaborApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Instancia del Repositorio de Pedidos (Singleton implícito)
    final pedidoRepository = PedidoRepositoryImpl();

    return MultiProvider(
      providers: [
        // 1. Provider de PEDIDOS (Lo mantenemos para cuando entremos a una mesa)
        ChangeNotifierProvider(create: (_) => PedidoProvider(pedidoRepository)),

        // 2. Provider de MESAS (🆕 NUEVO)
        // Este provider se encargará de gestionar el mapa de mesas
        ChangeNotifierProvider(create: (_) => MesaProvider()),
      ],
      child: MaterialApp(
        title: 'El Buen Sabor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true,
        ),
        // [PASO CRÍTICO 3]: Inicio de la UI
        // Cambiamos la entrada principal al Mapa de Mesas
        home: const MesasScreen(), // 👈 ¡Aquí está el cambio clave!
      ),
    );
  }
}