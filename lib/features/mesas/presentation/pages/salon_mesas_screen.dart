import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ===============================
// 🔐 AUTENTICACIÓN
// ===============================
// Se usa para:
// - obtener el mozo logueado
// - cerrar sesión
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/pages/login_page.dart';

// ===============================
// 🍽️ MESAS / SALÓN
// ===============================
import '../providers/mesa_provider.dart';
import '../../presentation/models/mesa_ui_model.dart';

import 'mesa_menu_screen.dart';

/// ============================================================================
/// 🖥️ PANTALLA: SalonMesasScreen
/// ============================================================================
///
/// RESPONSABILIDADES:
/// - Mostrar el estado del salón (mesas libres / ocupadas)
/// - Capturar la intención del usuario (tap sobre una mesa)
/// - Disparar casos de uso a través del Provider
/// - Gestionar navegación entre pantallas
///
/// NOTAS DE ARQUITECTURA:
/// - Esta pantalla NO conoce el backend
/// - NO realiza llamadas HTTP
/// - NO maneja tokens ni seguridad
///
/// PATRÓN:
/// - StatefulWidget (por ciclo de vida, no por lógica de negocio)
/// ============================================================================
class SalonMesasScreen extends StatefulWidget {
  const SalonMesasScreen({super.key});

  @override
  /**
   * @description Crea el estado de la pantalla principal de mesas.
   * @returns {State<SalonMesasScreen>} Estado de la pantalla.
   * @throws {Error} No lanza errores por diseno.
   */
  State<SalonMesasScreen> createState() => _SalonMesasScreenState();
}

class _SalonMesasScreenState extends State<SalonMesasScreen> {

  // ==========================================================================
  // 🚀 CICLO DE VIDA
  // ==========================================================================

  @override
  /**
   * @description Inicializa la carga de mesas luego del primer frame.
   * @returns {void} No retorna valor.
   * @throws {Error} No lanza errores por diseno.
   */
  void initState() {
    super.initState();

    // 📌 Al iniciar la pantalla:
    // Se dispara el caso de uso "Cargar Mesas"
    //
    // Usamos addPostFrameCallback para:
    // - evitar errores de contexto
    // - asegurarnos de que el widget ya esté montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MesaProvider>(context, listen: false).cargarMesas();
    });
  }

  // ==========================================================================
  // 🖱️ INTERACCIÓN: TOQUE SOBRE UNA MESA
  // ==========================================================================

  /// Decide qué hacer cuando el usuario toca una mesa.
  ///
  /// - Si está libre → inicia flujo de apertura
  /// - Si está ocupada → navega al menú de la mesa
  ///
  /// NOTA:
  /// La UI NO valida reglas de negocio.
  /// Solo reacciona al estado recibido.
  /**
   * @description Maneja el tap sobre una mesa y navega segun su estado.
   * @param {MesaUiModel} mesa - Mesa seleccionada.
   * @returns {Future<void>} Operacion asincronica sin valor de retorno.
   * @throws {Exception} Error de navegacion o carga.
   */
  Future<void> _onMesaTap(MesaUiModel mesa) async {
    if (mesa.estado == 'libre') {
      _mostrarDialogoAbrir(mesa);
    } else {
      // Navegamos al menú de la mesa ocupada
      // await → esperamos a que el usuario vuelva
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MesaMenuScreen(mesa: mesa),
        ),
      );

      // 🔄 Al volver, sincronizamos estado con el backend
      if (mounted) {
        Provider.of<MesaProvider>(context, listen: false).cargarMesas();
      }
    }
  }

  // ==========================================================================
  // 🔓 CASO DE USO: ABRIR MESA
  // ==========================================================================

  /// Muestra un diálogo de confirmación y,
  /// si el usuario acepta, ejecuta el caso de uso "Abrir Mesa".
  ///
  /// Este método:
  /// - pertenece a la UI
  /// - NO abre mesas directamente
  /// - delega la ejecución al Provider
  /**
   * @description Muestra dialogo para abrir mesa y asignar mozo.
   * @param {MesaUiModel} mesa - Mesa a abrir.
   * @returns {void} No retorna valor.
   * @throws {Error} No lanza errores por diseno.
   */
  void _mostrarDialogoAbrir(MesaUiModel mesa) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final mesaProvider = Provider.of<MesaProvider>(context, listen: false);

    // Obtenemos identidad del mozo desde el contexto autenticado
    final nombreMozo = authProvider.usuario?.nombre ?? "Mozo";
    final idMozo = authProvider.usuario?.id;

    // Seguridad defensiva
    if (idMozo == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("¿Abrir Mesa ${mesa.numero}?"),
        content: Text("Se asignará a: $nombreMozo"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Cerramos el diálogo

              // 1️⃣ Ejecutamos el caso de uso en el Provider
              final exito = await mesaProvider.ocuparMesa(mesa.id, idMozo);

              if (mounted && exito) {

                // 2️⃣ Creamos un modelo temporal para UX inmediata
                // El backend sigue siendo la fuente de verdad
                final mesaActualizada = MesaUiModel(
                  id: mesa.id,
                  numero: mesa.numero,
                  estado: 'ocupada',
                  mozoAsignado: nombreMozo,
                  totalActual: 0.0,
                );

                // 3️⃣ Navegamos al menú y esperamos a que el usuario vuelva
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MesaMenuScreen(mesa: mesaActualizada),
                  ),
                );

                // 4️⃣ Al regresar, sincronizamos nuevamente con backend
                if (mounted) {
                  mesaProvider.cargarMesas();
                }
              } else if (mounted) {
                // Manejo de error simple para UX
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

  // ==========================================================================
  // 🖼️ UI PRINCIPAL
  // ==========================================================================

  @override
  /**
   * @description Construye la UI del salon de mesas.
   * @param {BuildContext} context - Contexto de widgets.
   * @returns {Widget} Arbol de widgets.
   * @throws {Error} No lanza errores por diseno.
   */
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final nombreMozo = authProvider.usuario?.nombre ?? "Desconocido";

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text("Salón Principal"),
            Text(
              "Turno: $nombreMozo",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
            ),
          ],
        ),
        actions: [
          // Logout: responsabilidad de la UI
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await authProvider.logout();
              if (!mounted) return;
              navigator.pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),

      // ==========================================================================
      // 👂 CONSUMER: UI REACTIVA AL ESTADO DEL PROVIDER
      // ==========================================================================

      body: Consumer<MesaProvider>(
        builder: (context, mesaProvider, child) {

          // 1️⃣ Estado: Cargando
          if (mesaProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2️⃣ Estado: Error
          if (mesaProvider.error.isNotEmpty) {
            return Center(child: Text(mesaProvider.error));
          }

          // 3️⃣ Estado: Sin datos
          if (mesaProvider.mesas.isEmpty) {
            return const Center(
              child: Text("No hay mesas registradas en el sistema"),
            );
          }

          // 4️⃣ Estado: Datos disponibles
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: mesaProvider.mesas.length,
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

/// ============================================================================
/// 🎨 COMPONENTE VISUAL: TARJETA DE MESA
/// ============================================================================
///
/// Widget puramente visual.
/// - No conoce Providers
/// - No ejecuta lógica
/// - Solo refleja el estado recibido
class _MesaCard extends StatelessWidget {
  final MesaUiModel mesa;
  final VoidCallback onTap;

  /**
   * @description Crea la tarjeta visual de una mesa.
   * @param {MesaUiModel} mesa - Mesa a renderizar.
   * @param {VoidCallback} onTap - Callback al tocar la tarjeta.
   * @returns { _MesaCard } Instancia del widget.
   * @throws {Error} No lanza errores por diseno.
   */
  const _MesaCard({
    required this.mesa,
    required this.onTap,
  });

  @override
  /**
   * @description Construye la UI de la tarjeta de mesa.
   * @param {BuildContext} context - Contexto de widgets.
   * @returns {Widget} Arbol de widgets.
   * @throws {Error} No lanza errores por diseno.
   */
  Widget build(BuildContext context) {
    final bool esOcupada = mesa.estado == 'ocupada';
    final Color colorFondo =
        esOcupada ? Colors.orange.shade800 : Colors.grey.shade300;
    final Color colorTexto =
        esOcupada ? Colors.white : Colors.black87;

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
              Icon(Icons.table_restaurant_rounded,
                  size: 40, color: colorTexto),
              const SizedBox(height: 8),
              Text(
                "Mesa ${mesa.numero}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorTexto,
                ),
              ),
              const SizedBox(height: 4),
              if (esOcupada)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
