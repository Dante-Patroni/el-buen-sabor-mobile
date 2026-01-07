import 'package:el_buen_sabor_app/features/pedidos/presentation/providers/pedido_provider.dart';
import 'package:flutter/material.dart';
import '../../presentation/models/mesa_ui_model.dart';
import 'package:provider/provider.dart';
import 'package:el_buen_sabor_app/features/pedidos/presentation/pages/menu_moderno_page.dart';
import 'package:el_buen_sabor_app/features/mesas/presentation/pages/ver_pedido_mesa_screen.dart';
import 'package:el_buen_sabor_app/core/services/storage_service.dart';
// IMPORTS LOGIN
import 'package:el_buen_sabor_app/features/auth/presentation/pages/login_page.dart';
// ✅ IMPORT CORRECTO: Usamos el Provider en lugar de HTTP directo
import '../providers/mesa_provider.dart';

class MesaMenuScreen extends StatefulWidget {
  final MesaUiModel mesa;

  const MesaMenuScreen({super.key, required this.mesa});

  @override
  State<MesaMenuScreen> createState() => _MesaMenuScreenState();
}

class _MesaMenuScreenState extends State<MesaMenuScreen> {
  late MesaUiModel _mesaActual;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mesaActual = widget.mesa;
    _refrescarDatosMesa(); // Refrescar al entrar por si acaso
  }

  // 🔄 REFRESCAR DATOS (Para ver el Total actualizado)
  /// 
  /// **ANTES (INCORRECTO):** Hacía llamadas HTTP directas desde la UI.
  /// Esto violaba Clean Architecture porque la UI conocía detalles de HTTP.
  /// 
  /// **AHORA (CORRECTO):** Usa el MesaProvider que sigue Clean Architecture.
  /// 
  /// **Flujo:**
  /// 1. Obtiene el MesaProvider del contexto
  /// 2. Llama a `cargarMesas()` que pasa por todas las capas (Provider → Repository → DataSource → API)
  /// 3. Busca la mesa actualizada en la lista del Provider
  /// 4. Actualiza el estado local con los datos frescos
  /// 
  /// **Ventajas:**
  /// - ✅ La UI no conoce detalles de HTTP
  /// - ✅ Reutiliza la lógica existente
  /// - ✅ Fácil de testear (mock del Provider)
  /// - ✅ Si cambia el endpoint, solo se modifica el DataSource
  Future<void> _refrescarDatosMesa() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // ✅ CORRECTO: Obtenemos el Provider del contexto
      final mesaProvider = Provider.of<MesaProvider>(context, listen: false);
      
      // ✅ CORRECTO: Usamos el método del Provider que sigue Clean Architecture
      // Este método internamente llama: Provider → Repository → DataSource → API
      await mesaProvider.cargarMesas();

      if (mounted) {
        // Buscamos nuestra mesa en la lista actualizada del Provider
        final mesaActualizada = mesaProvider.mesas.firstWhere(
          (m) => m.id == widget.mesa.id,
          orElse: () => _mesaActual, // Si no la encuentra, mantenemos la actual
        );

        setState(() {
          // Actualizamos el estado local con los datos frescos del Provider
          _mesaActual = mesaActualizada;
        });
      }
    } catch (e) {
      debugPrint("Error refrescando mesa: $e");
      // Si hay error, el Provider ya maneja el estado de error internamente
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔴 LOGOUT FUNCIONAL
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
  // 🟢 LÓGICA DE CIERRE DE MESA (CORREGIDA - Usa Clean Architecture)
  // ---------------------------------------------------------
  /// 
  /// **ANTES (INCORRECTO):** Hacía llamadas HTTP directas desde la UI.
  /// Esto violaba Clean Architecture porque la UI conocía detalles de HTTP, tokens, URLs.
  /// 
  /// **AHORA (CORRECTO):** Usa el MesaProvider que sigue Clean Architecture.
  /// 
  /// **Flujo:**
  /// 1. Muestra diálogo de confirmación (UI)
  /// 2. Llama a `mesaProvider.cerrarMesaYFacturar()` que pasa por todas las capas
  /// 3. Muestra simulación de facturación (UI)
  /// 4. Refresca datos de pedidos y mesas
  /// 5. Vuelve al salón
  /// 
  /// **Arquitectura:** La UI solo maneja la presentación (diálogos, animaciones).
  /// Toda la lógica de negocio y comunicación con el backend está en el Provider.
  Future<void> _cerrarMesaBackend(BuildContext context) async {
    // 1. CONFIRMACIÓN (UI)
    bool? confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar Cierre"),
        content: Text(
            "¿Desea cerrar la Mesa ${_mesaActual.numero} y cobrar \$${_mesaActual.totalActual?.toStringAsFixed(0)}?"),
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

    // 2. LOADING (Diálogo de espera - UI)
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      ),
    );

    try {
      // ✅ CORRECTO: Obtenemos el Provider del contexto
      final mesaProvider = Provider.of<MesaProvider>(context, listen: false);

      // 🛑 SAFETY CHECK: Si cerramos pantalla mientras cargaba
      if (!context.mounted) return;

      // ✅ CORRECTO: Usamos el método del Provider que sigue Clean Architecture
      // Este método internamente llama: Provider → Repository → DataSource → API
      final totalCobrado = await mesaProvider.cerrarMesaYFacturar(_mesaActual.id);

      // 🛑 SAFETY CHECK
      if (!context.mounted) return;

      // CERRAR EL LOADING
      Navigator.pop(context);

      // Verificamos si hubo error (el Provider retorna null si falla)
      if (totalCobrado == null) {
        // El Provider ya maneja el error internamente, pero mostramos mensaje al usuario
        _mostrarError(context, "Error al cerrar la mesa. Intente nuevamente.");
        return;
      }

      // ---------------------------------------------------
      // ✨ SIMULACIÓN DE FACTURACIÓN (UI)
      // ---------------------------------------------------

      // 1. Mostrar diálogo de "Facturando..."
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

      // 2. Esperar 3 segundos (Suspenso)
      await Future.delayed(const Duration(seconds: 3));

      // 🛑 SAFETY CHECK: Vital después del delay
      if (!context.mounted) return;

      // 3. Cerrar el diálogo de "Facturando..."
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

      // 🔄 REFRESCAR EL DATOS DE PEDIDOS (Para que desaparezcan los pagados)
      if (context.mounted) {
        Provider.of<PedidoProvider>(context, listen: false)
            .inicializarDatos();
      }

      // 5. Volver al mapa de mesas (y recargar)
      Navigator.pop(context, true);
    } catch (e) {
      // Manejo de errores de conexión/crashes
      if (context.mounted) {
        Navigator.pop(context); // Cerrar loading si sigue abierto
        _mostrarError(context, "Error de conexión: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mesa ${_mesaActual.numero}"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          // 🚪 BOTÓN DE LOGOUT
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar Sesión",
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        // 👈 Pull to Refresh Extra
        onRefresh: _refrescarDatosMesa,
        child: SingleChildScrollView(
          // Necesario para RefreshIndicator
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TARJETA DE RESUMEN
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
                        Text(
                          "\$${_mesaActual.totalActual?.toStringAsFixed(0) ?? '0'}",
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold),
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

                // BOTÓN 1: HACER PEDIDO
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final pedidoProvider =
                        Provider.of<PedidoProvider>(context, listen: false);

                    // ✅ Usamos el NÚMERO visual para coincidir con el backend
                    pedidoProvider.iniciarPedido(_mesaActual.numero.toString());

                    pedidoProvider.setCliente("Mesa ${_mesaActual.numero}");

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MenuModernoPage(
                            idMesa: _mesaActual.id,
                            numeroMesa: _mesaActual.numero.toString()),
                      ),
                    ).then((_) {
                      // 👇 CRUCIAL: AL VOLVER, REFRESCAR EL TOTAL
                      _refrescarDatosMesa();
                    });
                  },
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text("HACER PEDIDO / VER CARTA",
                      style: TextStyle(fontSize: 18)),
                ),

                const SizedBox(height: 20),

                // BOTÓN EXTRA: VER PEDIDO
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

                // BOTÓN 2: CERRAR MESA CONECTADO
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

  // Función auxiliar para mostrar alertas de error
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
}
