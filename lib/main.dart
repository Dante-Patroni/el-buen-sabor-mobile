// ============================================================================
// ARCHIVO: main.dart
// ============================================================================
// 📌 PROPÓSITO:
// Este es el punto de entrada principal de la aplicación Flutter "El Buen Sabor".
// Aquí se inicializa la app, se configuran los providers globales (gestión de estado)
// y se define el widget raíz que contiene toda la aplicación.
//
// 🏗️ ARQUITECTURA:
// - Utiliza el patrón Provider para gestión de estado reactivo
// - Implementa Clean Architecture separando capas (Domain, Data, Presentation)
// - Aplica Dependency Injection para desacoplar componentes
// ============================================================================

library;

import 'package:el_buen_sabor_app/features/mesas/domain/repositories/mesa_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importaciones organizadas por features (características de la app)
import 'features/pedidos/data/datasources/pedido_datasource.dart';
import 'features/pedidos/data/repositories/pedido_repository_impl.dart';
import 'features/pedidos/domain/repositories/pedido_repository.dart';
import 'features/pedidos/presentation/providers/pedido_provider.dart';
import 'features/mesas/presentation/providers/mesa_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/data/datasources/auth_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/mesas/data/datasources/mesa_datasource.dart';
import 'features/mesas/data/repositories/mesa_repository_impl.dart';

/// 🚀 FUNCIÓN MAIN - Punto de entrada de la aplicación
///
/// Esta función se ejecuta primero cuando la app inicia.
///
/// CONCEPTOS CLAVE:
/// - `WidgetsFlutterBinding.ensureInitialized()`: Asegura que el framework
///   de Flutter esté completamente inicializado antes de ejecutar código nativo.
///   Es necesario cuando usamos plugins o código asíncrono antes de runApp().
///
/// - `runApp()`: Infla el widget raíz y lo adjunta a la pantalla.
///   Todo lo que esté dentro de este widget será parte de la aplicación.
void main() {
  // Inicializa el binding de Flutter (necesario para plugins y código async)
  WidgetsFlutterBinding.ensureInitialized();

  // 💉 INYECCIÓN DE DEPENDENCIAS:
  // Creamos una instancia única del repositorio de pedidos.
  // Esto permite compartir la misma instancia en toda la app,
  // evitando múltiples conexiones HTTP y manteniendo consistencia de datos.
  final authDataSource = AuthDataSource();//capa de datos, se comunica con el backend
  final authRepository = AuthRepositoryImpl(authDataSource);//interfaz abstracta, recibe authDataSource. No lo crea
  final pedidoDataSource = PedidoDataSource();
  final pedidoRepository = PedidoRepositoryImpl(pedidoDataSource);//Interfaz abstracta, recibe pedidoDataSource. No lo crea
  final mesaDataSource = MesaDataSource();  //capa de datos, se comunica con el backend
  final mesaRepository = MesaRepositoryImpl(mesaDataSource);

  runApp(ElBuenSaborApp(
    authRepository: authRepository,
    pedidoRepository: pedidoRepository,
    mesaRepository: mesaRepository,
  ));
}

/// 📱 WIDGET RAÍZ DE LA APLICACIÓN
///
/// Este es el widget principal que contiene toda la aplicación.
/// Es un StatelessWidget porque su configuración no cambia durante la ejecución.
///
/// PATRÓN APLICADO: Dependency Injection
/// - Recibe dependencias por constructor en lugar de crearlas internamente
/// - Facilita testing y reutilización de código
/// - Reduce acoplamiento entre componentes
class ElBuenSaborApp extends StatelessWidget {
  final AuthRepository authRepository;
  final PedidoRepository pedidoRepository;
  final MesaRepository mesaRepository;

  const ElBuenSaborApp({
    super.key,
    required this.authRepository,
    required this.pedidoRepository,
    required this.mesaRepository,
  });

  @override
  Widget build(BuildContext context) {
    // 🔄 MULTIPROVIDER - Gestión de Estado Global
    //
    // MultiProvider permite registrar múltiples providers en un solo lugar.
    // Los providers son observables que notifican a los widgets cuando cambian.
    //
    // VENTAJAS:
    // - Estado centralizado y reactivo
    // - Los widgets se reconstruyen automáticamente cuando el estado cambia
    // - Evita prop drilling (pasar datos por muchos niveles)
    return MultiProvider(
      providers: [
        // 🔐 AuthProvider - Maneja autenticación y sesión del usuario
        // ChangeNotifier permite que los widgets escuchen cambios de estado
        //Creo la instancia directamente aquí porque es global y vive durante toda la app
        ChangeNotifierProvider(
            create: (_) => AuthProvider(repository: authRepository)),

        // 🍽️ PedidoProvider - Maneja el carrito y creación de pedidos
        // Recibe el repositorio inyectado para comunicarse con el backend
        // El operador ?? proporciona un valor por defecto si es null
        ChangeNotifierProvider(
          create: (_) => PedidoProvider(
            pedidoRepository: pedidoRepository,
          ),
        ),

        // 🪑 MesaProvider - Maneja el estado de las mesas del restaurante
        ChangeNotifierProvider(create: (_) => MesaProvider(mesaRepository)),
      ],

      // 📲 MATERIALAPP - Configuración de la aplicación
      //
      // MaterialApp es el widget raíz que configura:
      // - Tema visual (colores, tipografía)
      // - Navegación y rutas
      // - Localización
      // - Página inicial (home)
      child: MaterialApp(
        title: 'El Buen Sabor',

        // Oculta el banner de "DEBUG" en la esquina superior derecha
        debugShowCheckedModeBanner: false,

        // 🎨 TEMA - Define la paleta de colores y estilos
        // Material 3 es la última versión del sistema de diseño de Google
        theme: ThemeData(
          // Genera un esquema de colores basado en un color semilla
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true, // Activa Material Design 3
        ),

        // 🏠 PÁGINA INICIAL - Primera pantalla que ve el usuario
        // const: Optimización de rendimiento (widget inmutable en tiempo de compilación)
        home: const LoginPage(),
      ),
    );
  }
}
