import 'package:el_buen_sabor_app/features/pedidos/presentation/widgets/detalle_plato_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../pedidos/domain/models/pedido.dart';
import '../../../pedidos/presentation/providers/pedido_provider.dart';
import '../../../../core/config/app_config.dart';

/// **ModificarPedidoModal**
///
/// Widget de diálogo modal que permite modificar un pedido existente.
///
/// **Responsabilidades:**
/// - Mostrar la lista de items del pedido actual
/// - Permitir editar cantidad y aclaraciones de cada item
/// - Enviar las modificaciones al backend a través del PedidoProvider
/// - Mantener una copia local de los items para edición sin afectar el estado global
///
/// **Arquitectura:**
/// - **Capa de Presentación**: Este widget pertenece a la capa de presentación (UI)
/// - **Patrón State Management**: Utiliza Provider para acceder al estado global
/// - **Inmutabilidad**: Trabaja con copias de los datos para evitar mutaciones accidentales
///
/// **Flujo de Datos:**
/// 1. Recibe la lista de items del pedido desde el widget padre
/// 2. Crea una copia profunda (deep copy) para trabajar localmente
/// 3. El usuario modifica cantidades/aclaraciones
/// 4. Al confirmar, envía los cambios al PedidoProvider
/// 5. El Provider se comunica con el Repository para persistir en el backend
///
/// **Conceptos Clave:**
/// - **Deep Copy**: `itemsModificados = widget.itemsPedido.map((p) => p.copyWith()).toList()`
///   Esto crea nuevas instancias de cada Pedido, evitando modificar los objetos originales.
/// - **Optimistic UI**: Muestra cambios inmediatamente, luego sincroniza con el servidor.
/// - **Async/Await**: Maneja operaciones asíncronas de red de forma secuencial y legible.
class ModificarPedidoModal extends StatefulWidget {
  /// ID del pedido padre que se está modificando
  final int pedidoId;

  /// Número de mesa asociada al pedido
  final String mesaNumero;

  /// Lista de items (platos) que componen el pedido
  final List<Pedido> itemsPedido;

  /**
   * @description Crea el modal para modificar un pedido existente.
   * @param {int} pedidoId - ID del pedido padre.
   * @param {String} mesaNumero - Numero de mesa.
   * @param {List<Pedido>} itemsPedido - Items del pedido.
   * @returns {ModificarPedidoModal} Instancia del widget.
   * @throws {Error} No lanza errores por diseno.
   */
  const ModificarPedidoModal({
    super.key,
    required this.pedidoId,
    required this.mesaNumero,
    required this.itemsPedido,
  });

  @override
  /**
   * @description Crea el estado asociado al modal de modificacion.
   * @returns {State<ModificarPedidoModal>} Estado del modal.
   * @throws {Error} No lanza errores por diseno.
   */
  State<ModificarPedidoModal> createState() => _ModificarPedidoModalState();
}

class _ModificarPedidoModalState extends State<ModificarPedidoModal> {
  /// Lista local de items modificables.
  /// Se inicializa como copia profunda de `widget.itemsPedido` para evitar
  /// mutaciones del estado global hasta que el usuario confirme los cambios.
  late List<Pedido> itemsModificados;

  @override
  /**
   * @description Inicializa la copia local de items modificables.
   * @returns {void} No retorna valor.
   * @throws {Error} No lanza errores por diseno.
   */
  void initState() {
    super.initState();

    // **PATRÓN: Deep Copy (Copia Profunda)**
    // Creamos nuevas instancias de cada Pedido usando copyWith().
    // Esto garantiza que las modificaciones locales no afecten el estado global
    // hasta que el usuario presione "Guardar Cambios".
    itemsModificados = widget.itemsPedido.map((p) => p.copyWith()).toList();
  }

  @override
  /**
   * @description Construye la UI del modal de modificacion de pedido.
   * @param {BuildContext} context - Contexto de widgets.
   * @returns {Widget} Arbol de widgets.
   * @throws {Error} No lanza errores por diseno.
   */
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Modificar Pedido",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // LISTA DE ITEMS
            SizedBox(
              height: 300,
              child: itemsModificados.isEmpty
                  ? const Center(
                      child: Text("No hay items en este pedido"),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: itemsModificados.length,
                      itemBuilder: (context, index) {
                        final item = itemsModificados[index];
                        final provider = context.read<PedidoProvider>();
                        final plato = provider.getPlatoById(item.platoId);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // IMAGEN
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: plato.imagenPath.isNotEmpty
                                      ? NetworkImage(
                                          '${AppConfig.apiBaseUrl.replaceAll("/api", "")}${plato.imagenPath}')
                                      : null,
                                  child: plato.imagenPath.isEmpty
                                      ? Text(plato.nombre[0])
                                      : null,
                                ),
                                const SizedBox(width: 12),

                                // INFORMACIÓN
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plato.nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        "Cant: ${item.cantidad} x \$${plato.precio}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      if (item.aclaracion != null &&
                                          item.aclaracion!.isNotEmpty)
                                        Text(
                                          "Nota: ${item.aclaracion}",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.blue,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // BOTONES DE ACCIÓN
                                Column(
                                  children: [
                                    // EDITAR
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue, size: 20),
                                      onPressed: () {
                                        _mostrarDialogoEditar(context, index);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ==========================================
            // BOTÓN GUARDAR CAMBIOS
            // ==========================================
            // **Responsabilidad**: Persistir las modificaciones del pedido en el backend
            // **Patrón**: Async/Await con manejo de estados (loading, success, error)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                // Deshabilitar botón si no hay items (validación básica)
                onPressed: itemsModificados.isEmpty
                    ? null
                    : () async {
                        // **PASO 1: Confirmación del Usuario**
                        // Mostramos un diálogo de confirmación antes de enviar al backend.
                        // Esto previene modificaciones accidentales y mejora la UX.
                        final confirmar = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Confirmar Modificación"),
                            content: const Text(
                              "¿Deseas enviar esta modificación a la cocina?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text("Cancelar"),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  "Enviar a Cocina",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );

                        // **PASO 2: Validación de Confirmación**
                        // Si el usuario cancela, detenemos la ejecución inmediatamente
                        if (confirmar != true) return;

                        // **PASO 3: Debug Logging (Desarrollo)**
                        // Logs para facilitar debugging durante desarrollo.
                        // En producción, estos deberían ser removidos o usar un logger condicional.
                        debugPrint(
                            "📤 [ModificarPedidoModal] Enviando modificación:");
                        debugPrint("   - pedidoId: ${widget.pedidoId}");
                        debugPrint("   - mesaNumero: ${widget.mesaNumero}");
                        debugPrint(
                            "   - itemsModificados.length: ${itemsModificados.length}");
                        for (var i = 0; i < itemsModificados.length; i++) {
                          final item = itemsModificados[i];
                          debugPrint(
                              "   - Item $i: platoId=${item.platoId}, cantidad=${item.cantidad}, aclaracion='${item.aclaracion}'");
                        }

                        // **PASO 4: Mostrar Indicador de Carga**
                        // **Patrón**: Loading State
                        // Mostramos un CircularProgressIndicator mientras esperamos la respuesta del servidor.
                        // `barrierDismissible: false` previene que el usuario cierre el diálogo tocando fuera.
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        // **PASO 5: Llamada al Provider (State Management)**
                        // El Provider actúa como intermediario entre la UI y el Repository.
                        // Esto mantiene la separación de responsabilidades (Clean Architecture).
                        // ignore: use_build_context_synchronously
                        final provider = context.read<PedidoProvider>();
                        final exito = await provider.modificarPedido(
                          widget.pedidoId,
                          widget.mesaNumero,
                          itemsModificados,
                        );

                        // **PASO 6: Cerrar Loading**
                        // Cerramos el diálogo de carga independientemente del resultado
                        if (context.mounted) {
                          Navigator.pop(context);
                        }

                        // **PASO 7: Feedback al Usuario**
                        // **Patrón**: User Feedback con SnackBar
                        // Mostramos el resultado de la operación al usuario
                        if (exito) {
                          if (context.mounted) {
                            Navigator.pop(context); // Cerrar modal
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "✅ Pedido modificado y enviado a cocina"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          // **Manejo de Errores**
                          // Si falla, mostramos el mensaje de error del Provider
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text("❌ Error: ${provider.errorMessage}"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: const Text(
                  "Guardar Cambios",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog para editar cantidad y aclaración
  /// Sigue el mismo patrón que DetallePlatoModal para asegurar persistencia
  /**
   * @description Muestra el dialogo para editar un item del pedido.
   * @param {BuildContext} context - Contexto de widgets.
   * @param {int} index - Indice del item a editar.
   * @returns {Future<void>} Operacion asincronica sin valor de retorno.
   * @throws {Exception} Error al abrir el modal o actualizar item.
   */
  Future<void> _mostrarDialogoEditar(BuildContext context, int index) async {
    final item = itemsModificados[index];
    final provider = context.read<PedidoProvider>();
    final plato = provider.getPlatoById(item.platoId);
    final resultado = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DetallePlatoModal(
        plato: plato,
        cantidadInicial: item.cantidad,
        aclaracionInicial: item.aclaracion ?? "",
        textoBoton: "Actualizar",
      ),
    );

    if (resultado != null) {
      setState(() {
        itemsModificados[index] = item.copyWith(
          cantidad: resultado['cantidad'],
          aclaracion: resultado['aclaracion'],
        );
      });
    }
  }
}
