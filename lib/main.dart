/// ARCHIVO: main.dart
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/pedidos/data/repositories/pedido_repository_impl.dart';
import 'features/pedidos/presentation/providers/pedido_provider.dart';
import 'features/mesas/presentation/providers/mesa_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Instancia única del repositorio
  final pedidoRepository = PedidoRepositoryImpl();

  runApp(ElBuenSaborApp(pedidoRepository: pedidoRepository));
}

class ElBuenSaborApp extends StatelessWidget {
  // Inyectamos el repo por constructor para seguir buenas prácticas
  final PedidoRepositoryImpl? pedidoRepository;

  const ElBuenSaborApp({super.key, this.pedidoRepository});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // ✅ ESTE ES EL ÚNICO QUE DEBE EXISTIR PARA PEDIDOS
        ChangeNotifierProvider(
          create: (_) => PedidoProvider(
              pedidoRepository: pedidoRepository ?? PedidoRepositoryImpl()),
        ),

        ChangeNotifierProvider(create: (_) => MesaProvider()),
      ],
      child: MaterialApp(
        title: 'El Buen Sabor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true,
        ),
        home: const LoginPage(),
      ),
    );
  }
}
