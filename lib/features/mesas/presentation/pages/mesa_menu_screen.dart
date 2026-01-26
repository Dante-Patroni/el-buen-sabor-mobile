import 'package:el_buen_sabor_app/features/pedidos/presentation/providers/pedido_provider.dart';
import 'package:flutter/material.dart';
import '../../presentation/models/mesa_ui_model.dart';
import 'package:provider/provider.dart';
import 'package:el_buen_sabor_app/features/pedidos/presentation/pages/menu_moderno_page.dart';
import 'package:el_buen_sabor_app/features/mesas/presentation/pages/ver_pedido_mesa_screen.dart';
import 'package:el_buen_sabor_app/core/services/storage_service.dart';
import 'package:el_buen_sabor_app/features/pedidos/domain/models/pedido.dart';
// IMPORTS LOGIN
import 'package:el_buen_sabor_app/features/auth/presentation/pages/login_page.dart';
// ✅ IMPORT CORRECTO: Usamos el Provider en lugar de HTTP directo
import '../providers/mesa_provider.dart';

/// Pantalla de menú principal para una mesa específica.
///
/// Esta pantalla permite gestionar todas las operaciones relacionadas con una mesa:
/// - Realizar nuevos pedidos
/// - Ver/modificar pedidos en curso
/// - Cerrar mesa y generar factura
/// - Eliminar pedidos completos
///
/// **Arquitectura:** Sigue el patrón MVVM con Provider para la gestión de estado.

class MesaMenuScreen extends StatefulWidget {
  final MesaUiModel mesa;

  const MesaMenuScreen({super.key, required this.mesa});

  @override
  State<MesaMenuScreen> createState() => _MesaMenuScreenState();
}

class _MesaMenuScreenState extends State<MesaMenuScreen> {
  // ===========================================================================
  // 1. VARIABLES DE ESTADO
  // ===========================================================================
  late MesaUiModel _mesaActual;
  bool _isLoading = false;

// ===========================================================================
  // 2. MÉTODOS DEL CICLO DE VIDA
  // ===========================================================================
  @override
//initState para cargar datos iniciales
  void initState() {
    super.initState();
    _mesaActual = widget.mesa;

// Cargar datos de la mesa después de que el widget se haya renderizado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refrescarDatosMesa();
    });
  }

  // ===========================================================================
  // 3. WIDGET BUILD - INTERFAZ PRINCIPAL
  // ===========================================================================
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mesa ${_mesaActual.numero}"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          // Botón de cierre de sesión
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar Sesión",
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        // Habilita pull-to-refresh para actualizar datos de la mesa
        onRefresh: _refrescarDatosMesa,
        child: SingleChildScrollView(
          // Necesario para RefreshIndicator
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ------------------------------------------------
                // TARJETA DE RESUMEN DE MESA
                // ------------------------------------------------
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long,
                            size: 50, color: Colors.orange),
                        const SizedBox(height: 10),
                        Text(
                          "Total Actual",
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        // Usar Consumer para reactividad: actualiza cuando cambia el total
                        Consumer<MesaProvider>(
                          builder: (_, mesaProvider, __) {
                            final mesa = mesaProvider.mesas.firstWhere(
                              (m) => m.id == widget.mesa.id,
                              orElse: () => widget.mesa,
                            );

                            return Text(
                              "\$${mesa.totalActual.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 5),
                        Text("Mozo: ${_mesaActual.mozoAsignado ?? 'Sin mozo'}"),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: SizedBox(
                                height: 15,
                                width: 15,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // ------------------------------------------------
                // BOTÓN: HACER NUEVO PEDIDO
                // ------------------------------------------------
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final pedidoProvider =
                        Provider.of<PedidoProvider>(context, listen: false);

                    // Inicializar estado para nuevo pedido
                    pedidoProvider.iniciarPedido(_mesaActual.numero.toString());

                    pedidoProvider.setCliente("Mesa ${_mesaActual.numero}");

                    // Navegar a la pantalla de menú
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MenuModernoPage(
                            idMesa: _mesaActual.id,
                            numeroMesa: _mesaActual.numero.toString()),
                      ),
                    ).then((_) {
                      // Al regresar, refrescar datos para mostrar total actualizado
                      _refrescarDatosMesa();
                    });
                  },
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text("HACER PEDIDO / VER CARTA",
                      style: TextStyle(fontSize: 18)),
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // BOTÓN: VER PEDIDO EN CURSO
                // ------------------------------------------------
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VerPedidoMesaScreen(
                          mesaId: _mesaActual.id,
                          mesaNumero: _mesaActual.numero,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text("VER PEDIDO EN CURSO",
                      style: TextStyle(fontSize: 18)),
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // BOTÓN: MODIFICAR PEDIDO EXISTENTE
                // ------------------------------------------------
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VerPedidoMesaScreen(
                          mesaId: _mesaActual.id,
                          mesaNumero: _mesaActual.numero,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("MODIFICAR PEDIDO",
                      style: TextStyle(fontSize: 18)),
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // BOTÓN: ELIMINAR PEDIDO COMPLETO
                // ------------------------------------------------
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.red.shade500,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    _mostrarDialogoEliminarPedidoCompleto(context);
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text("ELIMINAR PEDIDO",
                      style: TextStyle(fontSize: 18)),
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // BOTÓN: CERRAR MESA Y COBRAR
                // ------------------------------------------------
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    _cerrarMesaBackend(context);
                  },
                  icon: const Icon(Icons.point_of_sale),
                  label: const Text("CERRAR MESA Y COBRAR",
                      style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // ===========================================================================
  // 4. MÉTODOS PRINCIPALES (MISMO CÓDIGO, MEJOR ORGANIZACIÓN)
  // ===========================================================================
  /// Refresca los datos de la mesa desde el backend.
  ///
  /// Este método se ejecuta:
  /// 1. Al iniciar la pantalla
  /// 2. Cuando el usuario hace pull-to-refresh
  /// 3. Después de ciertas operaciones como crear pedidos
  Future<void> _refrescarDatosMesa() async {
    // Verificar que el widget aún esté montado antes de actualizar el estado
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Actualizar la lista de mesas desde el proveedor
      await context.read<MesaProvider>().cargarMesas();
    } catch (e) {
      debugPrint("Error refrescando mesa: $e");
    } finally {
      // Solo actualizar el estado si el widget aún está montado
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔴 LOGOUT FUNCIONAL
  /// Cierra la sesión del usuario y redirige a la pantalla de login.
  ///
  /// **Flujo:**
  /// 1. Elimina el token de autenticación del almacenamiento local
  /// 2. Navega a LoginPage y limpia el historial de navegación
  void _logout(BuildContext context) async {
    final storage = StorageService();
    await storage.deleteToken(); // 1. Borrar token

    if (!context.mounted) return;

    // 2. Volver al Login y borrar historial
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  // ---------------------------------------------------------
  // 🟢 LÓGICA DE CIERRE DE MESA Y FACTURAR
  // ---------------------------------------------------------

  /// Cierra la mesa actual y genera la factura correspondiente.
  ///
  /// **Flujo completo:**
  /// 1. Confirmación del usuario mediante diálogo
  /// 2. Procesamiento del cierre a través del Provider
  /// 3. Simulación de generación de factura
  /// 4. Actualización de estados en la aplicación
  /// 5. Navegación de regreso al salón principal
  ///
  /// **Manejo de errores:**
  /// - Errores de conexión se muestran al usuario
  /// - Estados null se manejan apropiadamente
  /// - Verificaciones de mounted previenen crashes
  Future<void> _cerrarMesaBackend(BuildContext context) async {
    // ------------------------------------------------
    // 1. DIÁLOGO DE CONFIRMACIÓN
    // ------------------------------------------------
    bool? confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar Cierre"),
        content: Text(
            "¿Desea cerrar la Mesa ${_mesaActual.numero} y cobrar \$${_mesaActual.totalActual.toStringAsFixed(0)}"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("CERRAR Y COBRAR"),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // ------------------------------------------------
    // 2. MOSTRAR INDICADOR DE CARGA
    // ------------------------------------------------
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      ),
    );

    try {
      // Obtener instancia del proveedor de mesas
      final mesaProvider = Provider.of<MesaProvider>(context, listen: false);

      // Verificación de seguridad: widget podría estar desmontado
      if (!context.mounted) return;

      // ------------------------------------------------
      // 3. PROCESAR CIERRE DE MESA (LÓGICA DE NEGOCIO)
      // ------------------------------------------------
      // Este método internamente llama: Provider → Repository → DataSource → API
      final totalCobrado =
          await mesaProvider.cerrarMesaYFacturar(_mesaActual.id);

      // Verificación de seguridad después de operación async
      if (!context.mounted) return;

      // Cerrar el diálogo de carga
      Navigator.pop(context);

      // Validar respuesta del servidor
      if (totalCobrado == null) {
        _mostrarError(context, "Error al cerrar la mesa. Intente nuevamente.");
        return;
      }

      // ------------------------------------------------
      // 4. SIMULACIÓN DE FACTURACIÓN (EXPERIENCIA DE USUARIO)
      // ------------------------------------------------

      // Mostrar diálogo de "Facturando..." con detalles
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const CircularProgressIndicator(color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text("Generando Factura A...",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              const Text("Conectando con AFIP...",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 15),
              Text("Monto: \$${totalCobrado.toStringAsFixed(0)}",
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );

      // Simular tiempo de procesamiento para realismo
      await Future.delayed(const Duration(seconds: 3));

      // Verificación CRÍTICA después de delay
      if (!context.mounted) return;

      // Cerrar diálogo de facturación
      Navigator.pop(context);

      // 4. Mostrar cartel de Éxito Final
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("¡Factura enviada por mail!"),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // ------------------------------------------------
      // 6. ACTUALIZAR ESTADO DE LA APLICACIÓN
      // ------------------------------------------------
      if (context.mounted) {
        // Refrescar pedidos para remover los pagados
        Provider.of<PedidoProvider>(context, listen: false).inicializarDatos();
      }

      // ------------------------------------------------
      // 7. NAVEGAR DE REGRESO CON RESULTADO
      // ------------------------------------------------
      Navigator.pop(context, true);
    } catch (e) {
      // Manejo de errores inesperados
      if (context.mounted) {
        Navigator.pop(context); // Cerrar loading si sigue abierto
        _mostrarError(context, "Error de conexión: $e");
      }
    }
  }

  // ===========================================================================
  // 5. MÉTODOS AUXILIARES
  // ===========================================================================

  /// Muestra un diálogo de error al usuario.
  ///
  /// **Parámetros:**
  /// - `context`: Contexto de construcción
  /// - `mensaje`: Mensaje de error a mostrar
  void _mostrarError(BuildContext context, String mensaje) {
    if (!context.mounted) return; // ✅ Safety check también aquí
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hubo un problema"),
        content: Text(mensaje),
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 40),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Entendido"),
          ),
        ],
      ),
    );
  }

  /// Muestra diálogo para eliminar todos los pedidos de la mesa actual.
  ///
  /// **Comportamiento:**
  /// - Valida que existan pedidos antes de mostrar el diálogo
  /// - Elimina todos los items del pedido
  /// - Devuelve el stock correspondiente
  /// - Muestra confirmación al usuario
  void _mostrarDialogoEliminarPedidoCompleto(BuildContext context) {
    final provider = Provider.of<PedidoProvider>(context, listen: false);

    // Filtrar pedidos activos de esta mesa
    final pedidosDeMesa = provider.listaPedidos.where((p) {
      return p.mesa == _mesaActual.numero.toString() &&
          p.estado != EstadoPedido.pagado;
    }).toList();

    // Validar que hay pedidos para eliminar
    if (pedidosDeMesa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No hay pedidos para eliminar"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    // Mostrar diálogo de confirmación
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Eliminar Todo el Pedido"),
        content: Text(
            "¿Estás seguro de que deseas eliminar TODOS los ${pedidosDeMesa.length} items del pedido?\n\nSe devolverá el stock."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Eliminar cada pedido individualmente
              for (var pedido in pedidosDeMesa) {
                await provider.borrarPedidoHistorico(pedido.id ?? 0);
              }
              // Mostrar confirmación
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Pedido eliminado exitosamente"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              "Eliminar Todo",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
