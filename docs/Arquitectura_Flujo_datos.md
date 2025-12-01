🧠 Arquitectura y Flujo de Datos - El Buen Sabor App

Este documento describe el ciclo de vida completo de una petición en la aplicación móvil, desde la inicialización de la UI hasta la persistencia en el Backend.

Tecnologías: Flutter (Frontend) + Node.js/Express (Backend) + MySQL/MongoDB (Base de Datos).
Arquitectura: Clean Architecture + Provider + Repository Pattern.

🏁 FASE 0: El Arranque (Initialization)

Configuración inicial antes de la interacción del usuario.

main.dart: Punto de entrada.

Repositorio: Se instancia ApiPedidoRepository. Se configura la _baseUrl apuntando al servidor.

Inyección de Dependencias: Se crea PedidoProvider y se le inyecta la instancia del repositorio.

MaterialApp: Se lanza la pantalla inicial NuevoPedidoPage.

⚡ FASE 1: La Petición (Frontend Request)

El usuario abre la pantalla y esta solicita datos.

NuevoPedidoPage (UI):

En el initState, ejecuta Future.microtask.

Llama a context.read<PedidoProvider>().inicializarDatos().

PedidoProvider (ViewModel):

Establece _isLoading = true y notifica a la UI (Spinner ⏳).

Ejecuta _repository.getMenu() y _repository.getPedidos() en paralelo (Future.wait).

🌉 FASE 2: El Puente (Saliendo del Celular)

El dato viaja por la red.

ApiPedidoRepository (Data Layer):

Construye la URL: http://192.168.18.3:3000/api/pedidos.

Ejecuta: http.get(url).

Abre conexión TCP/IP hacia el Backend.

🧠 FASE 3: El Procesamiento (Backend Node.js)

El servidor recibe, procesa y responde.

app.js: Express recibe el GET /api/pedidos.

pedidoRoutes.js: Enruta la petición al controlador.

PedidoController.listar: Solicita los datos al servicio.

PedidoService.listarPedidos: Ejecuta la consulta a la base de datos.

Query: SELECT * FROM Pedidos ORDER BY createdAt DESC.

MySQL: Retorna las filas.

Backend: Devuelve un JSON [{"id":1, ...}, ...] con código 200 OK.

📦 FASE 4: El Retorno (Deserialización)

Transformación de datos crudos a objetos Dart.

ApiPedidoRepository: Recibe el response.body (String JSON).

Decodificación: jsonDecode convierte el String a List<dynamic>.

Mapeo (Mapping):

Se itera la lista y se llama a PedidoModel.fromJson(map).

Se convierten fechas (String ISO8601 -> DateTime).

Se convierten estados (String -> Enum).

Retorno: Devuelve List<Pedido> al Provider.

🎨 FASE 5: La Pintura (Renderizado UI)

Actualización de la pantalla para el usuario.

PedidoProvider:

Recibe la lista de objetos.

La asigna a la variable privada _listaPedidos.

Establece _isLoading = false.

Ejecuta notifyListeners().

NuevoPedidoPage:

Escucha el cambio (gracias a context.watch).

Reconstruye el widget (build).

El ListView.builder renderiza cada Card con la información del pedido.

Autor: Equipo de Desarrollo El Buen Sabor
Fecha: Noviembre 2025