# 📊 Diagramas de Flujo - Casos de Uso de Mesas

## 🔴 PROBLEMA DETECTADO: Inconsistencia Arquitectónica

### Flujo ACTUAL (INCORRECTO) - Refrescar Datos de Mesa

```mermaid
sequenceDiagram
    actor U as Usuario
    participant MM as MesaMenuScreen
    participant HTTP as http.get (DIRECTO)
    participant API as Backend API

    Note over MM,HTTP: ❌ VIOLACIÓN: UI hace llamadas HTTP directas
    U ->> MM: Vuelve de hacer pedido
    MM ->> MM: _refrescarDatosMesa()
    MM ->> HTTP: http.get('/mesas') + token manual
    HTTP ->> API: GET /mesas
    API -->> HTTP: Lista de mesas
    HTTP -->> MM: JSON crudo
    MM ->> MM: Parsea JSON manualmente\nActualiza _mesaActual
    MM -->> U: Muestra total actualizado
```

**Problemas:**
- ❌ La UI conoce detalles de HTTP (`http.get`, headers, tokens)
- ❌ Lógica de parsing en la UI
- ❌ No reutiliza el código del `MesaProvider` que ya existe
- ❌ Si cambia el endpoint, hay que modificar la UI

---

### Flujo CORRECTO según Clean Architecture - Refrescar Datos de Mesa

```mermaid
sequenceDiagram
    actor U as Usuario
    participant MM as MesaMenuScreen
    participant MP as MesaProvider
    participant MR as MesaRepositoryImpl
    participant MD as MesaDataSource
    participant API as Backend API

    Note over MM,MP: ✅ CORRECTO: UI delega al Provider
    U ->> MM: Vuelve de hacer pedido
    MM ->> MP: cargarMesas() o refrescarMesa(idMesa)
    activate MP
    MP ->> MR: getMesas()
    activate MR
    MR ->> MD: getMesasFromApi()
    activate MD
    MD ->> API: GET /mesas (con token)
    API -->> MD: Lista de mesas (JSON)
    deactivate MD
    MD -->> MR: List<MesaModel>
    deactivate MR
    MR -->> MP: List<Mesa> (dominio)
    MP ->> MP: Mapear a MesaUiModel\nBuscar mesa por id\nActualizar estado
    MP ->> MM: notifyListeners()
    deactivate MP
    MM ->> MM: Consumer escucha cambios\nActualiza _mesaActual desde provider.mesas
    MM -->> U: Muestra total actualizado
```

**Ventajas:**
- ✅ La UI solo conoce el Provider
- ✅ Reutiliza la lógica existente
- ✅ Fácil de testear (mock del Provider)
- ✅ Si cambia el endpoint, solo se modifica el DataSource

---

## 📋 CASOS DE USO CORREGIDOS

### 1. Caso de Uso: Cargar Mesas al Entrar al Salón

```mermaid
sequenceDiagram
    actor U as Usuario
    participant S as SalonMesasScreen
    participant MP as MesaProvider
    participant MR as MesaRepositoryImpl
    participant MD as MesaDataSource
    participant API as Backend API

    U ->> S: Abre pantalla de salón
    activate S
    S ->> MP: cargarMesas()
    activate MP
    MP ->> MR: getMesas()
    activate MR
    MR ->> MD: getMesasFromApi()
    activate MD
    MD ->> API: GET /mesas (con token)
    API -->> MD: 200 OK + lista de mesas (JSON)
    deactivate MD
    MD -->> MR: List<MesaModel>
    deactivate MR
    MR -->> MP: List<Mesa> (dominio)
    MP ->> MP: mapear a List<MesaUiModel>\n_actualizar _mesas\n_isLoading=false
    MP ->> S: notifyListeners()
    deactivate MP
    S -->> U: Muestra grid de mesas libres/ocupadas
    deactivate S
```

---

### 2. Caso de Uso: Abrir Mesa (Mesa Libre en Salón)

```mermaid
sequenceDiagram
    actor U as Usuario
    participant S as SalonMesasScreen
    participant D as Diálogo "Abrir Mesa"
    participant AP as AuthProvider
    participant MP as MesaProvider
    participant MR as MesaRepositoryImpl
    participant MD as MesaDataSource
    participant API as Backend API
    participant MM as MesaMenuScreen

    U ->> S: Tap en Mesa (estado = libre)
    S ->> D: _mostrarDialogoAbrir(mesa)
    activate D
    D ->> AP: obtener usuario logueado (idMozo, nombre)
    AP -->> D: datos del mozo
    U ->> D: Confirmar "Abrir Mesa"
    D ->> MP: ocuparMesa(mesa.id, idMozo)
    activate MP
    MP ->> MR: abrirMesa(idMesa, idMozo)
    activate MR
    MR ->> MD: abrirMesa(idMesa, idMozo)
    activate MD
    MD ->> API: POST /mesas/{id}/abrir {idMozo}
    API -->> MD: 200 OK
    deactivate MD
    MR -->> MP: éxito
    deactivate MR
    MP ->> MP: cargarMesas() (refrescar listado)
    MP -->> S: notifyListeners()
    deactivate MP

    D ->> S: Cerrar diálogo
    deactivate D

    S ->> S: Crear MesaUiModel actualizada\n(estado=ocupada, mozoAsignado)
    S ->> MM: Navigator.push(MesaMenuScreen(mesaActualizada))
    activate MM
    MM -->> U: Muestra detalle de la mesa
```

---

### 3. Caso de Uso: Hacer Pedido desde MesaMenuScreen (CORREGIDO)

```mermaid
sequenceDiagram
    actor U as Usuario
    participant MM as MesaMenuScreen
    participant MP as MesaProvider
    participant PP as PedidoProvider
    participant PR as PedidoRepositoryImpl
    participant MMP as MenuModernoPage
    participant API as Backend API

    U ->> MM: Toca botón "HACER PEDIDO / VER CARTA"
    MM ->> PP: iniciarPedido(numeroMesa.toString())
    MM ->> PP: setCliente("Mesa X")
    MM ->> MMP: Navigator.push(MenuModernoPage(idMesa, numeroMesa))
    activate MMP
    U ->> MMP: Añade platos / confirma pedido
    MMP ->> PP: confirmarPedido()
    activate PP
    PP ->> PR: insertPedido(mesaId, carrito)
    activate PR
    PR ->> API: POST /pedidos ... (crear pedido)
    API -->> PR: 200 OK (pedido creado)
    PR -->> PP: éxito
    deactivate PR
    PP ->> PP: inicializarDatos() (refrescar pedidos)
    PP -->> MMP: notifyListeners()
    deactivate PP
    U ->> MMP: Volver atrás
    MMP -->> MM: Navigator.pop()
    deactivate MMP

    Note over MM,MP: ✅ CORRECTO: Usa Provider en lugar de HTTP directo
    MM ->> MP: cargarMesas()
    activate MP
    MP ->> MR: getMesas()
    MP ->> MP: Buscar mesa por id\nActualizar _mesaActual desde provider.mesas
    MP -->> MM: notifyListeners()
    deactivate MP
    MM -->> U: Muestra total actualizado en la tarjeta
```

---

### 4. Caso de Uso: Ver Pedido en Curso de una Mesa

```mermaid
sequenceDiagram
    actor U as Usuario
    participant MM as MesaMenuScreen
    participant VP as VerPedidoMesaScreen
    participant PP as PedidoProvider
    participant PR as PedidoRepositoryImpl
    participant API as Backend API

    U ->> MM: Toca "VER PEDIDO EN CURSO"
    MM ->> VP: Navigator.push(VerPedidoMesaScreen(mesaId, mesaNumero))
    activate VP

    VP ->> PP: (initState) inicializarDatos()
    activate PP
    PP ->> PR: getPedidos()
    activate PR
    PR ->> API: GET /pedidos (con token)
    API -->> PR: lista de pedidos (JSON)
    PR -->> PP: List<Pedido>
    deactivate PR
    PP -->> VP: listaPedidos cargada
    deactivate PP

    VP ->> VP: Filtrar listaPedidos\npor mesaNumero y estado != pagado
    VP -->> U: Lista de items del pedido + totalMesa
    deactivate VP
```

---

### 5. Caso de Uso: Cerrar Mesa y Cobrar (CORREGIDO)

```mermaid
sequenceDiagram
    actor U as Usuario
    participant MM as MesaMenuScreen
    participant D1 as Diálogo Confirmar Cierre
    participant MP as MesaProvider
    participant MR as MesaRepositoryImpl
    participant MD as MesaDataSource
    participant API as Backend API
    participant PP as PedidoProvider
    participant D2 as Diálogo "Facturando..."
    participant S as SalonMesasScreen

    U ->> MM: Toca "CERRAR MESA Y COBRAR"
    MM ->> D1: Mostrar confirmación\n(totalActual de la mesa)
    U ->> D1: Confirmar Cerrar y Cobrar
    D1 ->> MM: return true

    MM ->> MM: Mostrar loading (CircularProgress)

    Note over MM,MP: ✅ CORRECTO: Usa Provider en lugar de HTTP directo
    MM ->> MP: cerrarMesa(mesaId)
    activate MP
    MP ->> MR: cerrarMesa(mesaId)
    activate MR
    MR ->> MD: cerrarMesa(mesaId)
    activate MD
    MD ->> API: POST /mesas/:id/cerrar\nAuthorization: Bearer token
    API -->> MD: 200 OK { totalCobrado }
    deactivate MD
    MR -->> MP: éxito + totalCobrado
    deactivate MR
    MP ->> MP: cargarMesas() (refrescar estado)
    MP -->> MM: notifyListeners()
    deactivate MP

    MM ->> MM: Cerrar loading
    MM ->> D2: Mostrar "Generando Factura A...\nConectando con AFIP..."
    U ->> D2: Esperar (3s)
    MM ->> D2: Cerrar diálogo de facturación
    D2 -->> MM: OK

    MM ->> MM: Mostrar SnackBar "Factura enviada por mail"

    MM ->> PP: inicializarDatos() (refrescar pedidos)
    PP ->> PR: getPedidos()
    PR ->> API: GET /pedidos (...)
    API -->> PR: lista actualizada (sin los pagados)
    PR -->> PP: List<Pedido>
    PP -->> MM: notifyListeners()

    MM ->> S: Navigator.pop(context, true)\nVolver al salón
    S ->> MP: cargarMesas()\npara ver la mesa como libre
    MP ->> MR: getMesas()
    MR ->> MD: getMesasFromApi()
    MD ->> API: GET /mesas ...
    API -->> MD: Lista de mesas
    MD -->> MR: List<MesaModel>
    MR -->> MP: List<Mesa>
    MP -->> S: notifyListeners()
    S -->> U: Grid de mesas actualizado\n(mesa cerrada/libre)
```

---

## 🔧 CAMBIOS NECESARIOS PARA CORREGIR LA ARQUITECTURA

### 1. Agregar método en `MesaRepository` (contrato)

```dart
abstract class MesaRepository {
  Future<List<Mesa>> getMesas();
  Future<void> abrirMesa(int idMesa, int idMozo);
  Future<double> cerrarMesa(int idMesa);
}
```

### 2. Implementar en `MesaDataSource`

```dart
Future<double> cerrarMesa(int idMesa) async {
  final url = Uri.parse('$baseUrl/mesas/$idMesa/cerrar');
  final response = await http.post(
    url,
    headers: await _getAuthHeaders(),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return double.parse(data['totalCobrado'].toString());
  } else {
    throw Exception('Error: ${response.statusCode}');
  }
}
```

### 3. Agregar método en `MesaProvider`

```dart
Future<double?> cerrarMesa(int idMesa) async {
  try {
    final totalCobrado = await _repository.cerrarMesa(idMesa);
    await cargarMesas(); // Refrescar estado de mesas
    return totalCobrado;
  } catch (_) {
    return null;
  }
}
```

### 4. Modificar `MesaMenuScreen` para usar el Provider

```dart
// ❌ ANTES (INCORRECTO):
Future<void> _refrescarDatosMesa() async {
  final response = await http.get(url, headers: {...});
  // parsing manual...
}

// ✅ DESPUÉS (CORRECTO):
Future<void> _refrescarDatosMesa() async {
  final mesaProvider = Provider.of<MesaProvider>(context, listen: false);
  await mesaProvider.cargarMesas();
  
  // Buscar nuestra mesa en la lista del provider
  final mesaActualizada = mesaProvider.mesas
      .firstWhere((m) => m.id == widget.mesa.id);
  
  setState(() {
    _mesaActual = mesaActualizada;
  });
}
```

---

## 🔐 CASOS DE USO DE AUTENTICACIÓN

### 1. Login (Iniciar Sesión)

```mermaid
sequenceDiagram
    actor U as Usuario (Mozo)
    participant LP as LoginPage
    participant AP as AuthProvider
    participant AR as AuthRepository
    participant API as Backend API
    participant SS as StorageService

    U ->> LP: Completa legajo + password<br/>y pulsa "Entrar"
    LP ->> AP: login(legajo, password)
    activate AP
    AP ->> AP: _isLoading = true<br/>_errorMessage = null<br/>notifyListeners()
    
    AP ->> AR: login(legajo, password)
    activate AR
    AR ->> API: POST /usuarios/login<br/>{legajo, password}
    API -->> AR: 200 OK {token, usuario}
    AR -->> AP: {token, Usuario}
    deactivate AR

    AP ->> SS: saveToken(token)
    AP ->> AP: _usuario = Usuario<br/>_isLoading = false
    AP ->> LP: notifyListeners()
    deactivate AP

    LP -->> U: Navega a SalonMesasScreen
```

**Notas:**
- El token se guarda en almacenamiento seguro para mantener sesión
- El usuario queda en memoria para acceso rápido
- Si falla, se muestra mensaje de error en la UI

---

### 2. Logout (Cerrar Sesión)

```mermaid
sequenceDiagram
    actor U as Usuario
    participant S as SalonMesasScreen<br/>(o cualquier pantalla)
    participant AP as AuthProvider
    participant SS as StorageService
    participant LP as LoginPage

    U ->> S: Toca botón "Logout" / "Salir"
    S ->> AP: logout()
    activate AP
    AP ->> SS: deleteToken()
    AP ->> AP: _usuario = null
    AP ->> S: notifyListeners()
    deactivate AP

    S ->> LP: Navigator.pushReplacement(LoginPage)
    LP -->> U: Muestra pantalla de login
```

**Notas:**
- Elimina el token del almacenamiento seguro
- Limpia el usuario de la memoria
- Redirige a la pantalla de login

---

## 🧾 CASOS DE USO DE PEDIDOS

### 3. Inicializar Datos (Cargar Menú + Rubros + Pedidos)

```mermaid
sequenceDiagram
    actor U as Usuario
    participant P as Pantalla de Pedidos<br/>(MenuModernoPage, etc.)
    participant PP as PedidoProvider
    participant PR as PedidoRepositoryImpl
    participant API as Backend API

title 3. Inicializar Datos (Cargar Menú + Rubros + Pedidos)

    U ->> P: Abre pantalla de pedidos
    P ->> PP: inicializarDatos()
    activate PP
    PP ->> PP: _isLoading = true<br/>notifyListeners()

    par Carga en paralelo (o secuencial)
        PP ->> PR: getMenu()
        activate PR
        PR ->> API: GET /platos
        API -->> PR: Lista de platos (JSON)
        PR -->> PP: List<Plato>
        deactivate PR
        PP ->> PP: menuPlatos = lista
    and
        PP ->> PR: getRubros()
        activate PR
        PR ->> API: GET /rubros
        API -->> PR: Lista de rubros (JSON)
        PR -->> PP: List<Rubro>
        deactivate PR
        PP ->> PP: _listaRubros = lista
    and
        PP ->> PR: getPedidos()
        activate PR
        PR ->> API: GET /pedidos
        API -->> PR: Lista de pedidos (estructura padre/detalle)
        PR ->> PR: Aplana estructura<br/>(convierte a List<Pedido>)
        PR -->> PP: List<Pedido> (aplanada)
        deactivate PR
        PP ->> PP: listaPedidos = lista
    end

    PP ->> PP: _isLoading = false<br/>notifyListeners()
    deactivate PP
    P -->> U: Muestra menú, rubros y pedidos históricos
```

**Notas:**
- Carga 3 tipos de datos: menú, rubros y pedidos históricos
- El repositorio aplana la estructura jerárquica de pedidos del backend
- Si hay error, se muestra mensaje y se puede usar caché local (SQLite)

---

### 4. Agregar al Carrito (Lógica Local)

```mermaid
sequenceDiagram
    actor U as Usuario
    participant MMP as MenuModernoPage
    participant PP as PedidoProvider
    title 4. Agregar al Carrito (Lógica Local)
    U ->> MMP: Selecciona plato y cantidad
    MMP ->> PP: agregarAlCarrito(plato, cantidad, aclaracion)
    activate PP
    
    PP ->> PP: Busca si plato ya existe en carrito
    
    alt Si ya existe
        PP ->> PP: Actualiza cantidad del item existente
    else Si es nuevo
        PP ->> PP: Crea nuevo Pedido<br/>con estado = pendiente
        PP ->> PP: carrito.add(nuevoPedido)
    end
    
    PP ->> MMP: notifyListeners()
    deactivate PP
    MMP -->> U: Muestra contador actualizado<br/>y total del carrito
```

**Notas:**
- Es lógica local (no llama al backend aún)
- Si el plato ya está en el carrito, solo actualiza la cantidad
- El pedido se crea con estado `pendiente` por defecto

---

### 5. Confirmar Pedido / Enviar a Cocina

```mermaid
sequenceDiagram
    actor U as Mozo
    participant CP as ConfirmarPedidoScreen
    participant PP as PedidoProvider
    participant PR as PedidoRepositoryImpl
    participant API as Backend API
    title 5. Confirmar Pedido / Enviar a Cocina

    U ->> CP: Revisa carrito y pulsa<br/>"ENVIAR A COCINA"
    CP ->> PP: confirmarPedido()
    activate PP
    
    PP ->> PP: if (carrito.isEmpty) return false
    PP ->> PP: _isLoading = true<br/>notifyListeners()

    PP ->> PR: insertPedido(mesaSeleccionada, carrito)
    activate PR
    
    PR ->> PR: Transforma carrito a JSON<br/>{mesa, cliente, productos[]}
    PR ->> API: POST /pedidos<br/>{mesa, cliente, productos}
    
    alt Éxito (200/201)
        API -->> PR: {id} o {data: {id}}
        PR -->> PP: éxito
        PP ->> PP: carrito.clear()<br/>_isLoading = false
        PP ->> PP: inicializarDatos()<br/>(recarga menú/pedidos)
        PP ->> CP: notifyListeners()
        CP -->> U: Muestra diálogo "¡Pedido enviado a cocina!"
    else Error (409 Stock Insuficiente)
        API -->> PR: 409 {error: "Stock insuficiente"}
        PR -->> PP: Exception("Stock insuficiente")
        PP ->> PP: _errorMessage = error<br/>_isLoading = false
        PP ->> CP: notifyListeners()
        CP -->> U: Muestra SnackBar con error
    else Error de Conexión
        PR -->> PP: Exception("Error de conexión")
        PP ->> PP: _errorMessage = error<br/>_isLoading = false
        PP ->> CP: notifyListeners()
        CP -->> U: Muestra SnackBar con error
    end
    
    deactivate PR
    deactivate PP
```

**Notas:**
- El pedido se crea con estado `pendiente` (automáticamente "enviado a cocina")
- Si hay stock insuficiente, el backend responde 409
- Después de confirmar, se vacía el carrito y se recargan los datos

---

### 6. Borrar Pedido Histórico (Eliminación Optimista)

```mermaid
sequenceDiagram
    actor U as Usuario
    participant HP as Pantalla Historial<br/>(o lista de pedidos)
    participant PP as PedidoProvider
    participant PR as PedidoRepositoryImpl
    participant API as Backend API
    title 6. Borrar Pedido Histórico (Eliminación Optimista)

    U ->> HP: Toca "Eliminar" en un pedido
    HP ->> PP: borrarPedidoHistorico(id)
    activate PP

    Note over PP: Eliminación Optimista:<br/>Primero UI, luego backend
    PP ->> PP: listaPedidos.removeWhere(p.id == id)<br/>notifyListeners()
    HP -->> U: Item desaparece inmediatamente (UX rápida)

    PP ->> PR: deletePedido(id)
    activate PR
    PR ->> API: DELETE /pedidos/{id}
    
    alt Éxito
        API -->> PR: 200 OK
        PR -->> PP: éxito
        deactivate PR
        deactivate PP
        HP -->> U: Lista actualizada (sin cambios visuales)
    else Error
        API -->> PR: Error (404, 500, etc.)
        PR -->> PP: Exception
        deactivate PR
        PP ->> PP: inicializarDatos()<br/>(rollback: recarga desde backend)
        PP ->> HP: notifyListeners()
        deactivate PP
        HP -->> U: Item vuelve a aparecer<br/>(se revierte el cambio)
    end
```

**Notas:**
- **Eliminación optimista**: primero se actualiza la UI, luego se llama al backend
- Si el backend falla, se hace rollback recargando los datos
- Esto hace que la app se sienta más rápida (UX mejorada)

---

## 📊 RESUMEN: Flujo de Información Correcto

```
┌─────────────────────────────────────────────────────────────┐
│                    CAPA DE PRESENTACIÓN                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Pantallas  │  │   Providers  │  │   Widgets    │     │
│  │   (UI)       │  │   (Estado)    │  │   (Visual)   │     │
│  └──────┬───────┘  └──────┬────────┘  └──────────────┘     │
└─────────┼──────────────────┼────────────────────────────────┘
          │                  │
          │  llama métodos   │
          └──────────────────┘
                    │
┌───────────────────▼──────────────────────────────────────────┐
│                    CAPA DE DOMINIO                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Repositories (Contratos/Interfaces)          │   │
│  │  - MesaRepository                                    │   │
│  │  - PedidoRepository                                  │   │
│  └───────────────────┬──────────────────────────────────┘   │
└──────────────────────┼───────────────────────────────────────┘
                       │
                       │  implementa
                       │
┌──────────────────────▼───────────────────────────────────────┐
│                    CAPA DE DATOS                             │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │ RepositoryImpl   │────────▶│   DataSource      │          │
│  │  (Implementación)│         │   (HTTP/API)     │          │
│  └──────────────────┘         └────────┬─────────┘          │
└─────────────────────────────────────────┼────────────────────┘
                                          │
                                          │  HTTP requests
                                          │
┌─────────────────────────────────────────▼──────────────────┐
│                    BACKEND API                               │
│              (Tu servidor Node.js/Express)                   │
└───────────────────────────────────────────────────────────────┘
```

**Regla de Oro:**
- ✅ **UI** solo conoce **Providers**
- ✅ **Providers** solo conocen **Repositories** (interfaces)
- ✅ **Repositories** solo conocen **DataSources**
- ✅ **DataSources** conocen HTTP/API

**NUNCA:**
- ❌ UI haciendo llamadas HTTP directas
- ❌ UI conociendo tokens, headers, URLs
- ❌ Lógica de parsing en la UI

