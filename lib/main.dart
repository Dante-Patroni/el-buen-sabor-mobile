/// ARCHIVO: main.dart
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importamos las capas necesarias
import 'features/pedidos/data/repositories/pedido_repository_impl.dart';
import 'features/pedidos/presentation/providers/pedido_provider.dart';

import 'features/mesas/presentation/providers/mesa_provider.dart';
// import 'features/mesas/presentation/pages/mesas_screen.dart'; // Ya no es la home inicial

// 👇 NUEVOS IMPORTS DE AUTH
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ElBuenSaborApp());
}

class ElBuenSaborApp extends StatelessWidget {
  const ElBuenSaborApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Instancia del Repositorio de Pedidos
    // Instancia del Repositorio de Pedidos

    return MultiProvider(
      providers: [
        // 1. Provider de AUTENTICACIÓN (🔐 NUEVO - El Guardián)
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // 2. Provider de PEDIDOS
        ChangeNotifierProvider(
          create: (_) =>
              PedidoProvider(pedidoRepository: PedidoRepositoryImpl()),
        ),

        // 3. Provider de MESAS
        ChangeNotifierProvider(create: (_) => MesaProvider()),
      ],
      child: MaterialApp(
        title: 'El Buen Sabor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true,
        ),
        // [PASO CRÍTICO]: Inicio de la App
        // Ahora arrancamos en el Login para pedir credenciales
        home: const LoginPage(),
      ),
    );
  }
}
