import 'package:el_buen_sabor_app/features/pedidos/domain/models/rubro_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/app_config.dart'; // ✅ Import Config
import '../../domain/models/plato.dart';
import '../../presentation/providers/pedido_provider.dart';
import 'confirmar_pedido_screen.dart';
import '../widgets/detalle_plato_modal.dart';

// ✅ Nuevo Diseño "Toast POS Style"
// Sidebar Izquierda (Rubros Padre) + Tabs Superiores (Subrubros) + Grilla (Platos)

class MenuModernoPage extends StatefulWidget {
  final int idMesa;
  final String numeroMesa;

  const MenuModernoPage(
      {super.key, required this.idMesa, required this.numeroMesa});

  @override
  State<MenuModernoPage> createState() => _MenuModernoPageState();
}

class _MenuModernoPageState extends State<MenuModernoPage> {
  // Estado de Selección
  Rubro? _rubroPadreSeleccionado;
  Rubro? _subRubroSeleccionado;

  bool _mostrandoMenuDelDia = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PedidoProvider>(context, listen: false);
      if (provider.menuPlatos.isEmpty || provider.listaRubros.isEmpty) {
        provider.inicializarDatos();
      }
    });
  }

  // --- LÓGICA DE FILTRADO ---

  /// Filtramos los platos según lo seleccionado
  List<Plato> _getPlatosFiltrados(PedidoProvider provider) {
    // 1. Menú del día (Prioridad)
    if (_mostrandoMenuDelDia) {
      return provider.menuPlatos.where((p) => p.esMenuDelDia).toList();
    }

    // 2. Si hay subrubro seleccionado, filtramos por él (usamos el ID)
    if (_subRubroSeleccionado != null) {
      // El Plato debe tener 'rubroId' igual al del subrubro
      return provider.menuPlatos
          .where((p) => p.rubroId == _subRubroSeleccionado!.id)
          .toList();
    }

    // 3. Fallback: Si no hay nada seleccionado, mostramos vacío o todo?
    // Mejor mostramos "Seleccione una categoría"
    return [];
  }

  /// Lógica para abrir el modal (igual que antes)
  void _abrirDetallePlato(
      BuildContext context, Plato plato, int stockDisponible) async {
    print(
        "👉 Tap en plato: ${plato.nombre}. Stock: $stockDisponible. Ilimitado: ${plato.stock.esIlimitado}");

    if (stockDisponible <= 0 && !plato.stock.esIlimitado) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Sin stock disponible para ${plato.nombre}"),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 1),
      ));
      return;
    }

    final resultado = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DetallePlatoModal(plato: plato),
    );

    if (resultado != null && context.mounted) {
      final cant = resultado['cantidad'];
      final aclaracion = resultado['aclaracion'];

      final provider = Provider.of<PedidoProvider>(context, listen: false);
      provider.agregarAlCarrito(plato, cantidad: cant, aclaracion: aclaracion);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Agregado: $cant x ${plato.nombre}"),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 500),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PedidoProvider>(context);

    // Inicialización automática de selección (Si ya cargó datps pero no seleccionamos nada)
    if (provider.listaRubros.isNotEmpty &&
        _rubroPadreSeleccionado == null &&
        !_mostrandoMenuDelDia) {
      // Por defecto seleccionamos el primero (Generalmente "Cocina")
      _rubroPadreSeleccionado = provider.listaRubros.first;
      // Y seleccionamos su primer hijo (ej: "Hamburguesas")
      if (_rubroPadreSeleccionado!.subrubros.isNotEmpty) {
        _subRubroSeleccionado = _rubroPadreSeleccionado!.subrubros.first;
      }
    }

    // Platos a mostrar
    final platosVisibles = _getPlatosFiltrados(provider);

    return Scaffold(
        appBar: AppBar(
          title: Text("Mesa ${widget.numeroMesa} - Menú"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            // Botón Menú del Día (Toggle)
            TextButton.icon(
              icon: const Icon(Icons.star, color: Colors.orange),
              label: Text("Del Día",
                  style: TextStyle(
                      color: _mostrandoMenuDelDia ? Colors.orange : Colors.grey,
                      fontWeight: FontWeight.bold)),
              onPressed: () {
                setState(() {
                  _mostrandoMenuDelDia = !_mostrandoMenuDelDia;
                  // Si activamos menú del día, limpiamos la selección de rubros visualmente
                  if (_mostrandoMenuDelDia) {
                    _rubroPadreSeleccionado = null;
                    _subRubroSeleccionado = null;
                  }
                });
              },
            ),
          ],
        ),
        floatingActionButton: provider.carrito.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ConfirmarPedidoScreen())),
                backgroundColor: Colors.orange.shade800,
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                label: Text("\$${provider.totalCarrito.toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              )
            : null,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------------------------------------------
            // 1. SIDEBAR IZQUIERDA (Rubros Padre: Cocina, Bebidas)
            // -----------------------------------------------------------
            Container(
              width: 100, // Ancho fijo sidebar
              color: Colors.grey[100],
              child: ListView.builder(
                itemCount: provider.listaRubros.length,
                itemBuilder: (context, index) {
                  final rubro = provider.listaRubros[index];
                  final isSelected = _rubroPadreSeleccionado?.id == rubro.id;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _mostrandoMenuDelDia = false;
                        _rubroPadreSeleccionado = rubro;
                        // Al cambiar de padre, seleccionamos automáticamente el primer hijo
                        if (rubro.subrubros.isNotEmpty) {
                          _subRubroSeleccionado = rubro.subrubros.first;
                        } else {
                          _subRubroSeleccionado = null;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 8),
                      decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          border: isSelected
                              ? const Border(
                                  left: BorderSide(
                                      color: Colors.orange, width: 4))
                              : null),
                      child: Column(
                        children: [
                          // Icono dinámico según nombre? Por ahora genérico
                          Icon(
                              rubro.denominacion == "Bebidas"
                                  ? Icons.local_bar
                                  : Icons.restaurant,
                              color: isSelected ? Colors.orange : Colors.grey),
                          const SizedBox(height: 5),
                          Text(
                            rubro.denominacion,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey[700]),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // -----------------------------------------------------------
            // 2. CONTENIDO PRINCIPAL (Tabs + Grid)
            // -----------------------------------------------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 2.A. Pestañas Superiores (Sub-Rubros)
                  if (!_mostrandoMenuDelDia && _rubroPadreSeleccionado != null)
                    Container(
                      height: 50,
                      color: Colors.white,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        scrollDirection: Axis.horizontal,
                        itemCount: _rubroPadreSeleccionado!.subrubros.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final sub = _rubroPadreSeleccionado!.subrubros[index];
                          final isSelected =
                              _subRubroSeleccionado?.id == sub.id;

                          return ChoiceChip(
                            label: Text(sub.denominacion),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _subRubroSeleccionado = sub);
                              }
                            },
                            // Estilos
                            selectedColor: Colors.orange.shade100,
                            backgroundColor: Colors.grey[200],
                            labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.orange.shade900
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            side: BorderSide.none,
                          );
                        },
                      ),
                    ),

                  // Separador Sutil
                  const Divider(height: 1),

                  // 2.B. Grilla de Productos
                  Expanded(
                    child: provider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : platosVisibles.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.restaurant_menu,
                                        size: 50, color: Colors.grey),
                                    SizedBox(height: 10),
                                    Text("Seleccione una categoría",
                                        style: TextStyle(color: Colors.grey))
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: platosVisibles.length,
                                itemBuilder: (context, index) {
                                  final plato = platosVisibles[index];

                                  // Cálculo Stock
                                  int cantEnCarrito = 0;
                                  if (!plato.stock.esIlimitado) {
                                    cantEnCarrito = provider.carrito
                                        .where(
                                            (item) => item.platoId == plato.id)
                                        .fold(0,
                                            (sum, item) => sum + item.cantidad);
                                  }
                                  final stockReal =
                                      plato.stock.cantidad - cantEnCarrito;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: PlatoCard(
                                      plato: plato,
                                      stockDisplay: plato.stock.esIlimitado
                                          ? 9999
                                          : stockReal,
                                      onTap: () => _abrirDetallePlato(
                                          context, plato, stockReal),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            )
          ],
        ));
  }
}

// -------------------------------------------------------
// WIDGET CARD (Redefinido: Horizontal para 1 por fila)
// -------------------------------------------------------
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

  String _construirUrlImagen(String path) {
    if (path.isEmpty) return "";
    if (path.startsWith("http")) return path;
    // Usamos AppConfig
    final baseUrl = AppConfig.apiBaseUrl.replaceAll("/api", "");
    return "$baseUrl$path".replaceAll("\\", "/");
  }

  @override
  Widget build(BuildContext context) {
    final agotado = (!plato.stock.esIlimitado && stockDisplay <= 0);
    final urlFinal = _construirUrlImagen(plato.imagenPath);

    return Opacity(
      opacity: agotado ? 0.6 : 1.0,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 110, // Altura fija para evitar overflow
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Imagen (Izquierda)
                SizedBox(
                  width: 110, // Cuadrado de 110x110
                  child: urlFinal.isNotEmpty
                      ? Image.network(
                          urlFinal,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.fastfood,
                                  color: Colors.white)),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child:
                              const Icon(Icons.fastfood, color: Colors.white)),
                ),

                // 2. Info (Derecha)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Nombre
                        Text(
                          plato.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        // Descripción corta (opcional)
                        /* 
                        if (plato.descripcion.isNotEmpty)
                          Text(plato.descripcion, 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis, 
                              style: TextStyle(fontSize: 10, color: Colors.grey[600])) 
                        */
                        const Spacer(),
                        // Precio y Stock
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "\$${plato.precio.toStringAsFixed(0)}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green,
                                  fontSize: 18),
                            ),
                            if (agotado)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(4),
                                    border:
                                        Border.all(color: Colors.red.shade200)),
                                child: const Text("SIN STOCK",
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              )
                            else if (!plato.stock.esIlimitado)
                              Text(
                                "Stock: $stockDisplay",
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
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
      ),
    );
  }
}
