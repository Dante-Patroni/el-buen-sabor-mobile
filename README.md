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

El proyecto implementa **Clean Architecture** con separación en tres capas:

```
lib/
├── core/                          # Configuración y servicios compartidos
│   ├── config/                    # Configuración global (URLs, constantes)
│   ├── database/                  # Base de datos local SQLite
│   └── services/                  # Servicios compartidos (almacenamiento seguro)
│
├── features/                      # Características organizadas por dominio
│   ├── auth/                      # Autenticación
│   │   ├── domain/               # Modelos de dominio
│   │   ├── data/                 # Repositorios e implementaciones
│   │   └── presentation/         # UI y gestión de estado
│   │
│   ├── mesas/                     # Gestión de mesas
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   └── pedidos/                   # Gestión de pedidos
│       ├── domain/
│       ├── data/
│       └── presentation/
│
└── main.dart                      # Punto de entrada de la aplicación
```

### Capas de Clean Architecture

#### 🎯 Domain Layer (Dominio)
- **Propósito**: Lógica de negocio pura
- **Contenido**: Modelos de dominio, interfaces de repositorios
- **Dependencias**: Ninguna (independiente de frameworks)
- **Ejemplo**: `Usuario`, `Mesa`, `Pedido`

#### 📦 Data Layer (Datos)
- **Propósito**: Comunicación con fuentes de datos
- **Contenido**: Implementaciones de repositorios, datasources, modelos de datos
- **Dependencias**: Domain layer, packages HTTP/SQLite
- **Ejemplo**: `AuthRepository`, `MesaDatasource`

#### 🎨 Presentation Layer (Presentación)
- **Propósito**: UI y gestión de estado
- **Contenido**: Páginas, widgets, providers
- **Dependencias**: Domain y Data layers
- **Ejemplo**: `LoginPage`, `AuthProvider`

---

## 🎨 Patrones de Diseño

### 1. **Singleton**
Garantiza una única instancia de servicios críticos:
- `DBHelper` - Gestión de base de datos
- `StorageService` - Almacenamiento seguro

### 2. **Repository Pattern**
Abstrae el origen de los datos:
- `AuthRepository` - Autenticación
- `MesaRepository` - Gestión de mesas
- `PedidoRepository` - Gestión de pedidos

### 3. **Provider + ChangeNotifier**
Gestión de estado reactivo:
- `AuthProvider` - Estado de autenticación
- `MesaProvider` - Estado de mesas
- `PedidoProvider` - Estado del carrito y pedidos

### 4. **Factory Constructor**
Deserialización de JSON:
- `Usuario.fromJson()`
- `Mesa.fromJson()`
- `Plato.fromJson()`

### 5. **Dependency Injection**
Inyección de dependencias en `main.dart` con `MultiProvider`

---

## 🚀 Tecnologías

- **Framework**: Flutter 3.x
- **Lenguaje**: Dart 3.x
- **Gestión de Estado**: Provider
- **Base de Datos Local**: SQLite (sqflite)
- **Almacenamiento Seguro**: flutter_secure_storage
- **HTTP Client**: http package
- **Backend**: Node.js + Express (repositorio separado)

---

## 📱 Características

### 🔐 Autenticación
- Login con legajo y contraseña
- Almacenamiento seguro de tokens JWT
- Persistencia de sesión entre reinicios
- Logout con limpieza de datos

### 🪑 Gestión de Mesas
- Visualización del salón en tiempo real
- Estados: Libre, Ocupada, Reservada
- Asignación de mesas a mozos
- Cierre de mesas con procesamiento de pago

### 📝 Gestión de Pedidos
- Menú categorizado por rubros
- Carrito de compras interactivo
- Personalización de platos
- Control de stock en tiempo real
- Confirmación y envío al backend

### 📊 Modo Offline
- Base de datos local SQLite
- Sincronización automática con el backend
- Datos de prueba (seed data) para desarrollo
- Caché de menú y pedidos

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

Para probar en un dispositivo físico conectado por Wi-Fi:

1. Asegúrate de que el dispositivo y la PC estén en la misma red
2. Obtén la IP local de tu PC:
   - Windows: `ipconfig`
   - Linux/Mac: `ifconfig`
3. Actualiza `apiBaseUrl` con tu IP local
4. Configura el firewall para permitir conexiones en el puerto 3000

---

## 📚 Estructura de Datos

### Usuario
```dart
{
  "id": 1,
  "nombre": "Dante",
  "apellido": "Patroni",
  "rol": "mozo",
  "legajo": "12345"
}
```

### Mesa
```dart
{
  "id": 1,
  "numero": "1",
  "capacidad": 4,
  "estado": "libre", // libre, ocupada, reservada
  "mozo_id": null
}
```

### Pedido
```dart
{
  "id": 1,
  "mesa_id": 1,
  "plato_id": 5,
  "cantidad": 2,
  "estado": "pendiente", // pendiente, en_preparacion, listo, entregado, pagado
  "total": 3000.0,
  "fecha": "2025-12-29T09:00:00Z"
}
```

### Plato
```dart
{
  "id": 1,
  "nombre": "Milanesa a Caballo",
  "precio": 1500.0,
  "descripcion": "Con papas fritas y huevo",
  "categoria": "Cocina",
  "rubro_id": 2,
  "stock": {
    "cantidad": 10,
    "ilimitado": false,
    "estado": "DISPONIBLE" // DISPONIBLE, AGOTADO, PAUSADO
  }
}
```

---

## 🔒 Seguridad

- **Tokens JWT**: Almacenados de forma encriptada usando `flutter_secure_storage`
- **Encriptación nativa**: 
  - Android: KeyStore con AES
  - iOS: Keychain
- **HTTPS**: Recomendado para producción
- **Validación**: Validación de formularios en cliente y servidor

---

## 🧪 Testing

```bash
# Análisis estático
flutter analyze

# Tests unitarios
flutter test

# Tests de integración
flutter test integration_test/
```

---

## 📖 Documentación del Código

El código incluye comentarios profesionales y educativos que explican:

- ✅ Arquitectura Clean Architecture
- ✅ Patrones de diseño aplicados
- ✅ Gestión de estado con Provider
- ✅ Comunicación con APIs REST
- ✅ Almacenamiento local y seguro
- ✅ Flujos de datos entre capas

**Archivos con documentación completa:**
- `lib/main.dart`
- `lib/core/config/app_config.dart`
- `lib/core/database/db_helper.dart`
- `lib/core/services/storage_service.dart`
- `lib/features/auth/domain/models/usuario.dart`
- `lib/features/auth/data/auth_repository.dart`
- `lib/features/auth/presentation/providers/auth_provider.dart`

---

## 🤝 Contribución

Este proyecto fue desarrollado como parte del curso de Programación Web II en la Universidad IUA.

### Equipo de Desarrollo
- **Desarrollador**: Dante Patroni
- **Institución**: IUA (Instituto Universitario Aeronáutico)
- **Curso**: Programación Web II - 4to Cuatrimestre

---

## 📄 Licencia

Este proyecto es de uso educativo.

---

## 🔗 Enlaces Relacionados

- [Backend API - El Buen Sabor](https://github.com/tu-usuario/backend-el-buen-sabor)
- [Documentación de Flutter](https://docs.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)
- [SQLite para Flutter](https://pub.dev/packages/sqflite)

---

## 📞 Contacto

Para preguntas o sugerencias sobre el proyecto, contactar a través del repositorio de GitHub.

---

**Última actualización**: Diciembre 2025
