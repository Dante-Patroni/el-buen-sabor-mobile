/// ARCHIVO: main.dart
/// DESCRIPCIÓN:
/// Punto de entrada de la aplicación Flutter.
///
/// Responsabilidades:
/// 1. Inicializar el entorno de Flutter.
/// 2. Configurar la Inyección de Dependencias (Dependency Injection).
/// 3. Instanciar los Providers globales.
/// 4. Definir el tema visual y la pantalla de inicio.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importamos las capas necesarias para "conectar los cables"
import 'features/pedidos/data/repositories/pedido_repository_impl.dart';
import 'features/pedidos/presentation/providers/pedido_provider.dart';
import 'features/pedidos/presentation/pages/nuevo_pedido_page.dart';

// 1. PUNTO DE ENTRADA
void main() {
  // Asegura que el motor gráfico esté listo antes de tocar BD
  WidgetsFlutterBinding.ensureInitialized();

  // Lanza la aplicación raíz.
  runApp(const ElBuenSaborApp());
}

class ElBuenSaborApp extends StatelessWidget {
  const ElBuenSaborApp({super.key});

  @override
  Widget build(BuildContext context) {
    // [PASO CRÍTICO 1]: Instanciación de la Capa de Datos
    // Aquí nace el objeto que sabe hablar con Node.js.
    // Se crea UNA sola vez en toda la vida de la app (Singleton implícito).
    final pedidoRepository = PedidoRepositoryImpl();

    return MultiProvider(
      providers: [
        // [PASO CRÍTICO 2]: Inyección de Dependencias
        // Creamos el cerebro (Provider) y le "enchufamos" el repositorio.
        // A partir de ahora, el Provider usa 'pedidoRepository' para todo.
        ChangeNotifierProvider(create: (_) => PedidoProvider(pedidoRepository)),
      ],
      child: MaterialApp(
        title: 'El Buen Sabor',
        debugShowCheckedModeBanner: false, // Quitamos la etiqueta DEBUG
        theme: ThemeData(
          // Usamos el color naranja de tu marca
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          useMaterial3: true,
        ),
        // [PASO CRÍTICO 3]: Inicio de la UI
        // Se carga la primera pantalla.
        home: const NuevoPedidoPage(),
      ),
    );
  }
}
