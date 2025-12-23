import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/plato.dart';
import '../../presentation/providers/pedido_provider.dart';
import 'confirmar_pedido_screen.dart';
import '../widgets/detalle_plato_modal.dart';

/// **MenuModernoPage**
///
/// Esta es las pantalla principal de selección de productos.
/// Utiliza un diseño de **Grid** (Cuadrícula) y **Chips** de categorías para navegar.
///
/// **Conceptos Clave:**
/// - `StatefulWidget`: Usamos esto porque la pantalla tiene estado interno propio (qué categoría está seleccionada, si filtros activos) que cambia con el tiempo.
/// - `Consumer` o `Provider.of`: Para escuchar y acceder a los datos globales del `PedidoProvider`.
class MenuModernoPage extends StatefulWidget {
  final int idMesa;
  final String numeroMesa;

  // El constructor recibe parámetros inmutables del padre (ej: desde dónde venimos)
  const MenuModernoPage(
      {super.key, required this.idMesa, required this.numeroMesa});

  @override
  State<MenuModernoPage> createState() => _MenuModernoPageState();
}

class _MenuModernoPageState extends State<MenuModernoPage> {
  // -- ESTADO LOCAL DE LA PANTALLA --
  // Estas variables controlan EXCLUSIVAMENTE cómo se ve esta pantalla ahora mismo.
  // No son datos del negocio (eso está en el Provider), son datos de la "Vista".

  String categoriaSeleccionada = "Todos";
  int?
      subRubroSeleccionado; // If we have subcategories logic, we need to see if Provider supports it.
  // PedidoProvider basically gives us a flat list of 'menuPlatos'.
  // We need to organize them.

  bool mostrandoMenuDelDia = false;

  /// **initState**: El "constructor" del Estado. Se ejecuta UNA sola vez cuando la pantalla nace.
  /// Aquí es el lugar perfecto para pedir datos iniciales.
  @override
  void initState() {
    super.initState();

    // `addPostFrameCallback` asegura que el código corra DESPUÉS de que la pantalla se dibuje por primera vez.
    // Esto evita errores de "setState() called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PedidoProvider>(context, listen: false);
      // Solo cargamos si la lista está vacía, para ahorrar datos.
      if (provider.menuPlatos.isEmpty) {
        provider.inicializarDatos();
      }
    });
  }

  // -- LÓGICA DE FILTRADO VISUAL --
  // Transformamos los datos crudos del Provider en datos listos para mostrar.

  /// Extrae la lista única de categorías (Strings) a partir de los platos.
  /// Usa un `Set` para eliminar duplicados automáticamente.
  List<String> getRubros(List<Plato> platos) {
    final rubros = platos.map((e) => e.categoria).toSet().toList();
    rubros.sort(); // Orden alfabético
    return ["Todos", ...rubros]; // Agregamos "Todos" al principio
  }

  /// Filtra la lista completa de platos según lo que el usuario seleccionó (Categoría o Menú del día).
  List<Plato> getPlatosVisibles(List<Plato> todos) {
    if (mostrandoMenuDelDia) {
      return todos.where((p) => p.esMenuDelDia).toList();
    }
    if (categoriaSeleccionada == "Todos") {
      return todos;
    }
    // `.where` funciona como el SQL "WHERE". Filtra la lista.
    return todos.where((p) => p.categoria == categoriaSeleccionada).toList();
  }

  /// Lógica para abrir el modal (popup) inferior.
  /// Es `async` porque esperamos a que el usuario termine de elegir cantidad en el modal.
  void _abrirDetallePlato(
      BuildContext context, Plato plato, int stockDisponible) async {
    // ... Copy logic from deleted file, adapted ...
    // Check stock, show modal, add to cart
    // Validación preventiva de stock
    if (stockDisponible <= 0 && !plato.stock.esIlimitado) {
      // SnackBar es la barrita negra con mensaje temporal abajo.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Sin stock disponible"), backgroundColor: Colors.red));
      return;
    }

    // We need to re-create DetallePlatoModal. For now, let's assume we will.
    // Mostramos el modal y esperamos el resultado (await).
    // El resultado será un Mapa con { cantidad, aclaracion } o null si cerró sin agregar.
    final resultado = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled:
          true, // Permite que el modal ocupe más pantalla si es necesario
      backgroundColor: Colors.transparent,
      builder: (context) => DetallePlatoModal(plato: plato),
    );

    // [Pressman]: Programación Defensiva. 
// Verificamos 'context.mounted' en lugar de 'mounted' para garantizar 
// que el contexto de este widget específico sigue vivo tras la espera asíncrona.

if (resultado != null && context.mounted) {
      final cant = resultado['cantidad'];
      final aclaracion = resultado['aclaracion'];

      // Agregamos al carrito global
      final provider = Provider.of<PedidoProvider>(context, listen: false);
      provider.agregarAlCarrito(plato, cantidad: cant, aclaracion: aclaracion);

      // Feedback visual de éxito
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Agregado: $cant x ${plato.nombre}"),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 500),
      ));
}
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el Provider. Cada vez que `notifyListeners()` se llame en el Provider, este método `build` se ejecutará de nuevo.
    final pedidoProvider = Provider.of<PedidoProvider>(context);

    // Si está cargando y no tenemos nada mostrar -> Spinner
    if (pedidoProvider.isLoading && pedidoProvider.menuPlatos.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Calculamos los datos a mostrar en ESTE renderizado
    final rubros = getRubros(pedidoProvider.menuPlatos);
    final platosVisibles = getPlatosVisibles(pedidoProvider.menuPlatos);

    return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Mesa ${widget.numeroMesa}"),
              const Text("Menú Nuevo", style: TextStyle(fontSize: 12)),
            ],
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        // Botón Flotante (FAB) que aparece solo si hay cosas en el carrito
        floatingActionButton: pedidoProvider.carrito.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ConfirmarPedidoScreen())),
                backgroundColor: Colors.orange.shade800,
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                label: Text(
                    "\$${pedidoProvider.totalCarrito.toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              )
            : null,
        body: Column(
          children: [
            // 1. SELECTOR HORIZONTAL DE CATEGORÍAS
            SizedBox(
              height: 60,
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                scrollDirection: Axis.horizontal, // Scroll horizontal
                itemCount: rubros.length + 1, // +1 por el botón "Menú del Día"
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 10), // Espacio entre ítems
                itemBuilder: (context, index) {
                  // El primer ítem (índice 0) es especial: Menú del Día
                  if (index == 0) {
                    return _CategoriaChip(
                      label: "⭐ Menú del Día",
                      activo: mostrandoMenuDelDia,
                      onTap: () => setState(() {
                        mostrandoMenuDelDia = true;
                        categoriaSeleccionada = "";
                      }),
                      colorActivo: Colors.orange,
                    );
                  }
                  // Los demás son categorías normales
                  final cat = rubros[index - 1];
                  final isActive =
                      !mostrandoMenuDelDia && categoriaSeleccionada == cat;
                  return _CategoriaChip(
                    label: cat,
                    activo: isActive,
                    onTap: () => setState(() {
                      mostrandoMenuDelDia = false;
                      categoriaSeleccionada = cat;
                    }),
                  );
                },
              ),
            ),

            // 2. GRILLA DE PRODUCTOS (GRID)
            Expanded(
              child: platosVisibles.isEmpty
                  ? const Center(
                      child: Text("No hay productos en esta categoría"))
                  : GridView.builder(
                      padding: const EdgeInsets.all(10),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Dos columnas
                        childAspectRatio:
                            0.75, // Relación de aspecto (Alto vs Ancho)
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: platosVisibles.length,
                      itemBuilder: (context, index) {
                        final plato = platosVisibles[index];
                        // Cálculo de Stock en tiempo real restando lo que ya tengo en el carrito
                        int cantEnCarrito = 0;
                        if (!plato.stock.esIlimitado) {
                          cantEnCarrito = pedidoProvider.carrito
                              .where((item) => item.platoId == plato.id)
                              .fold(0, (sum, item) => sum + item.cantidad);
                        }
                        final stockReal = plato.stock.cantidad - cantEnCarrito;

                        return PlatoCard(
                          plato: plato,
                          stockDisplay:
                              plato.stock.esIlimitado ? 9999 : stockReal,
                          onTap: () =>
                              _abrirDetallePlato(context, plato, stockReal),
                        );
                      },
                    ),
            ),
          ],
        ));
  }
}

// ... WIDGETS PRIVADOS AUXILIARES (Para mantener el código ordenado) ...

/// Chip o Botón de Categoría.
class _CategoriaChip extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;
  final Color colorActivo;

  const _CategoriaChip(
      {required this.label,
      required this.activo,
      required this.onTap,
      this.colorActivo = Colors.blue});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(
            milliseconds: 200), // Animación suave de cambio color
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? colorActivo : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: activo ? colorActivo : Colors.grey.shade400, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                color: activo ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

/// Tarjeta visual del producto.
class PlatoCard extends StatelessWidget {
  final Plato plato;
  final int stockDisplay;
  final VoidCallback onTap;

  const PlatoCard({
    super.key,
    required this.plato,
    required this.stockDisplay,
    required this.onTap,
  });

  // 👇 1. FUNCIÓN MÁGICA: Corrige la URL para que funcione en el Emulador
String _construirUrlImagen(String path) {
    if (path.isEmpty) return "";

    // Si ya viene con http completo, lo dejamos (ej: imagen externa)
    if (path.startsWith("http")) return path;

    // 👇 CAMBIA ESTO POR TU IP REAL QUE VISTE EN IPCONFIG
    // Ejemplo: "192.168.1.12" (Manten el puerto 3000)
    const String ipDeTuPC = "192.168.18.3"; // <--- ¡PON TU NÚMERO AQUÍ!
    
    // Tu backend devuelve "/uploads/...", así que concatenamos:
    // http://192.168.1.12:3000/uploads/foto.jpg
    return "http://$ipDeTuPC:3000$path".replaceAll("\\", "/");
  }

  @override
  Widget build(BuildContext context) {
    final agotado = (!plato.stock.esIlimitado && stockDisplay <= 0);
    
    // Obtenemos la URL corregida
    final urlFinal = _construirUrlImagen(plato.imagenPath);

    return Opacity(
      opacity: agotado ? 0.6 : 1.0,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: InkWell(
          onTap: agotado ? null : onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🖼️ IMAGEN CON GESTIÓN DE CARGA Y ERROR
              Expanded(
                flex: 3,
                child: urlFinal.isNotEmpty
                    ? Image.network(
                        urlFinal,
                        fit: BoxFit.cover,
                        // Si falla (ej: 404), mostramos ícono
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: Colors.grey,
                          child: Center(
                              child: Icon(Icons.broken_image,
                                  color: Colors.white)),
                        ),
                        // Mientras carga, mostramos spinner chiquito
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      )
                    // Si no tiene path configurado
                    : const ColoredBox(
                        color: Colors.grey,
                        child: Center(
                            child: Icon(Icons.fastfood, color: Colors.white)),
                      ),
              ),
              
              // 📝 TEXTOS Y PRECIO (Esto queda igual que antes)
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(plato.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("\$${plato.precio.toStringAsFixed(0)}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green,
                                  fontSize: 16)),
                          if (agotado)
                            const Text("AGOTADO",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
