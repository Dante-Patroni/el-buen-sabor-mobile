# 🍽️ El Buen Sabor - Aplicación Móvil

Aplicación móvil Flutter para la gestión de pedidos en el restaurante "El Buen Sabor". Permite a los mozos gestionar mesas, tomar pedidos y coordinar con la cocina de manera eficiente.

## 📋 Descripción

**El Buen Sabor** es una aplicación móvil desarrollada en Flutter que digitaliza el proceso de atención en un restaurante. Los empleados (mozos) pueden:

- 🔐 Autenticarse de forma segura con su legajo
- 🪑 Visualizar y gestionar el estado de las mesas
- 📝 Tomar pedidos de los clientes
- 🍔 Consultar el menú disponible con stock en tiempo real
- 💰 Procesar pagos y cerrar mesas
- 📱 Trabajar offline con sincronización automática

---

## 🏗️ Arquitectura

El proyecto implementa **Clean Architecture** con el patrón **Ports & Adapters (Hexagonal)**, organizado de forma homogénea en los tres módulos principales (`auth`, `mesas`, `pedidos`).

### Estructura de Directorios

```
lib/
├── core/                          # Configuración y servicios compartidos
│   ├── config/                    # Configuración global (AppConfig)
│   ├── database/                  # Base de datos local SQLite (DBHelper)
│   └── services/                  # StorageService (tokens JWT seguros)
│
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── models/usuario.dart
│   │   │   └── repositories/auth_repository.dart      ← interfaz abstracta
│   │   ├── data/
│   │   │   ├── datasources/auth_datasource.dart        ← HTTP
│   │   │   └── repositories/auth_repository_impl.dart  ← delgado
│   │   └── presentation/
│   │       ├── pages/login_page.dart
│   │       └── providers/auth_provider.dart
│   │
│   ├── mesas/
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   └── repositories/mesa_repository.dart       ← interfaz abstracta
│   │   ├── data/
│   │   │   ├── datasources/mesa_datasource.dart        ← HTTP
│   │   │   └── repositories/mesa_repository_impl.dart  ← delgado
│   │   └── presentation/
│   │
│   └── pedidos/
│       ├── domain/
│       │   ├── models/
│       │   └── repositories/pedido_repository.dart     ← interfaz abstracta
│       ├── data/
│       │   ├── datasources/pedido_datasource.dart      ← HTTP + SQLite
│       │   └── repositories/pedido_repository_impl.dart ← delgado
│       └── presentation/
│
└── main.dart                      # DI: instancia DataSource → Impl → Provider
```

### Flujo de Datos (igual en los 3 módulos)

```
UI  →  Provider  →  Repository (abstracto)
                          ↓
                   RepositoryImpl       ← delgado, solo delega
                          ↓
                     DataSource         ← HTTP / SQLite
                          ↓
                      Backend API
```

### Capas

| Capa | Responsabilidad | No depende de |
|---|---|---|
| **Domain** | Entidades + contratos abstractos | Frameworks, HTTP, DB |
| **Data** | DataSource (HTTP/SQLite) + RepositoryImpl | UI, Provider |
| **Presentation** | Provider (estado) + Pages (UI) | DataSource directamente |

---

## 🎨 Patrones de Diseño

| Patrón | Aplicación |
|---|---|
| **Repository Pattern** | `AuthRepository`, `MesaRepository`, `PedidoRepository` (interfaces abstractas) |
| **Provider + ChangeNotifier** | `AuthProvider`, `MesaProvider`, `PedidoProvider` |
| **Dependency Injection** | `main.dart` instancia DataSource → Impl y los inyecta en Providers |
| **Factory Constructor** | `Usuario.fromJson()`, `Mesa.fromJson()`, `PedidoModel.fromJson()` |
| **Singleton** | `DBHelper`, `StorageService` |

---

## 🚀 Tecnologías

- **Framework**: Flutter 3.x / Dart 3.x
- **Gestión de Estado**: Provider + ChangeNotifier
- **Base de Datos Local**: SQLite (`sqflite`) — estrategia offline-first para menú
- **Almacenamiento Seguro**: `flutter_secure_storage` (tokens JWT)
- **HTTP Client**: `http` package
- **Testing**: `flutter_test` + `mockito` + `build_runner`
- **Backend**: Node.js + Express (repositorio separado)

---

## 📱 Características

### 🔐 Autenticación
- Login con legajo y contraseña
- Almacenamiento seguro de tokens JWT
- Logout con limpieza de datos

### 🪑 Gestión de Mesas
- Visualización del salón en tiempo real
- Estados: Libre, Ocupada, Reservada
- Cierre de mesas con procesamiento de pago

### 📝 Gestión de Pedidos
- Menú categorizado por rubros
- Carrito de compras interactivo
- Control de stock en tiempo real
- Confirmación y envío al backend
- Modificación y eliminación de pedidos históricos

### 📊 Modo Offline
- Caché de menú en SQLite
- Sincronización automática con el backend

---

## 🧪 Testing

El proyecto incluye tests unitarios y un widget test base.

```bash
# Ejecutar todos los tests
flutter test

# Análisis estático
flutter analyze

# Regenerar mocks (tras cambios en interfaces)
dart run build_runner build --delete-conflicting-outputs
```

### Cobertura de Tests (archivos existentes)

| Módulo | Archivo |
|---|---|
| Auth - Repository | `test/unit/repositories/auth_repository_test.dart` |
| Auth - Provider | `test/unit/providers/auth_provider_test.dart` |
| Mesas - Provider | `test/unit/providers/mesa_provider_test.dart` |
| Pedidos - Provider | `test/unit/providers/pedido_provider_test.dart` |
| Usuario - Model | `test/unit/models/usuario_test.dart` |
| Widget (smoke) | `test/widget_test.dart` |

---

## 🛠️ Instalación y Configuración

### Prerrequisitos

- Flutter SDK 3.0 o superior
- Dart SDK 3.0 o superior
- Android Studio / VS Code
- Dispositivo Android/iOS o emulador

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/tu-usuario/el_buen_sabor_app.git
   cd el_buen_sabor_app
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar la URL del backend**

   Editar `lib/core/config/app_config.dart`:
   ```dart
   static const String apiBaseUrl = 'http://TU_IP:3000/api';
   ```

4. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

### Configuración para Testing en Red Local

1. Asegúrate de que el dispositivo y la PC estén en la misma red
2. Obtén la IP local de tu PC: `ipconfig` (Windows) o `ifconfig` (Linux/Mac)
3. Actualiza `apiBaseUrl` con tu IP local
4. Configura el firewall para permitir conexiones en el puerto 3000

---

## 🔒 Seguridad

- **Tokens JWT**: Almacenados de forma encriptada usando `flutter_secure_storage`
  - Android: KeyStore con AES
  - iOS: Keychain
- **HTTPS**: Recomendado para producción
- **Validación**: En cliente y servidor

---

## 📚 Estructura de Datos

### Usuario
```json
{ "id": 1, "nombre": "Dante", "apellido": "Patroni", "rol": "mozo", "legajo": "12345" }
```

### Mesa
```json
{ "id": 1, "numero": "1", "capacidad": 4, "estado": "libre", "mozo_id": null }
```

### Pedido
```json
{ "id": 1, "mesa_id": 1, "plato_id": 5, "cantidad": 2, "estado": "pendiente", "total": 3000.0 }
```

### Plato
```json
{
  "id": 1, "nombre": "Milanesa a Caballo", "precio": 1500.0,
  "categoria": "Cocina", "rubro_id": 2,
  "stock": { "cantidad": 10, "ilimitado": false, "estado": "DISPONIBLE" }
}
```

---

## 🤝 Contribución

Desarrollado como proyecto de la materia **Programación Web II** — IUA (Instituto Universitario Aeronáutico), 4to Cuatrimestre.

**Desarrollador**: Dante Patroni

---

## 🔗 Enlaces

- [Backend API - El Buen Sabor](https://github.com/tu-usuario/backend-el-buen-sabor)
- [Documentación de Flutter](https://docs.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)

---

**Última actualización**: Febrero 2026
