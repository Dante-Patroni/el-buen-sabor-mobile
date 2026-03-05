// ============================================================================
// ARCHIVO: db_helper.dart
// ============================================================================
// 📌 PROPÓSITO:
// Gestiona la base de datos local SQLite de la aplicación.
// Permite almacenar datos offline para que la app funcione sin conexión.
//
// 🏗️ PATRÓN APLICADO: Singleton
// Solo existe UNA instancia de DBHelper en toda la aplicación.
// Esto evita múltiples conexiones a la base de datos y garantiza consistencia.
//
// 📚 CONCEPTOS CLAVE:
// - SQLite: Base de datos relacional ligera embebida en la app
// - Offline-First: Los datos se guardan localmente primero
// - Schema: Estructura de tablas y columnas definida en código
// ============================================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 🗄️ HELPER DE BASE DE DATOS LOCAL
///
/// Esta clase maneja todas las operaciones con la base de datos SQLite local.
/// Implementa el patrón Singleton para garantizar una única instancia.
///
/// RESPONSABILIDADES:
/// - Crear y actualizar el esquema de la base de datos
/// - Proporcionar acceso a la instancia de Database
/// - Manejar migraciones de versiones
/// - Insertar datos de prueba (seed data)
///
/// 💡 ¿POR QUÉ USAR BASE DE DATOS LOCAL?
/// - Funcionalidad offline (sin internet)
/// - Caché de datos para mejorar rendimiento
/// - Reducir llamadas al servidor
/// - Mejor experiencia de usuario (datos instantáneos)
class DBHelper {
  // ============================================================================
  // 🔒 PATRÓN SINGLETON - Una única instancia
  // ============================================================================

  /// Instancia única de DBHelper (Singleton)
  /// `static final`: Se crea una sola vez y nunca cambia
  /// `_init()`: Constructor privado que se llama solo una vez
  static final DBHelper instance = DBHelper._init();

  /// Instancia de la base de datos SQLite
  /// `static`: Compartida por todas las instancias (aunque solo hay una)
  /// Nullable porque se inicializa de forma lazy (cuando se necesita)
  static Database? _database;

  /**
   * @description Constructor privado para inicializar el singleton de DBHelper.
   * @returns {DBHelper} Instancia creada internamente.
   * @throws {Error} No lanza errores por diseno.
   */
  DBHelper._init();

  // ============================================================================
  // 📂 GETTER DE BASE DE DATOS - Lazy Initialization
  // ============================================================================

  /**
   * @description Obtiene la instancia SQLite con inicializacion lazy.
   * @returns {Future<Database>} Instancia de base de datos.
   * @throws {Exception} Error al abrir o crear la base de datos.
   */
  Future<Database> get database async {
    // Si ya existe la base de datos, retornarla
    if (_database != null) return _database!;

    // Si no existe, crearla por primera vez
    // ⚠️ VERSIÓN DE BASE DE DATOS:
    // Se usa v6 para forzar recreación con el esquema corregido.
    // En producción, usar migraciones en lugar de borrar la DB.
    _database = await _initDB('el_buen_sabor_v6.db');
    return _database!;
  }

  // ============================================================================
  // 🏗️ INICIALIZACIÓN DE BASE DE DATOS
  // ============================================================================

  /**
   * @description Inicializa y abre la base de datos SQLite.
   * @param {String} filePath - Nombre del archivo de base de datos.
   * @returns {Future<Database>} Instancia abierta o creada.
   * @throws {Exception} Error al abrir la base de datos.
   */
  Future<Database> _initDB(String filePath) async {
    // Obtiene la ruta del directorio de bases de datos del dispositivo
    // En Android: /data/data/<package>/databases/
    // En iOS: Library/Application Support/
    final dbPath = await getDatabasesPath();

    // Combina la ruta del directorio con el nombre del archivo
    // Ejemplo: /data/data/com.example.app/databases/el_buen_sabor_v6.db
    final path = join(dbPath, filePath);

    // Abre (o crea) la base de datos
    // - path: Ubicación del archivo
    // - version: Número de versión del esquema (para migraciones)
    // - onCreate: Callback que se ejecuta solo la primera vez (crea tablas)
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // ============================================================================
  // 📋 CREACIÓN DEL ESQUEMA - Tablas y Estructura
  // ============================================================================

  /**
   * @description Crea el esquema inicial de la base de datos.
   * @param {Database} db - Instancia de SQLite.
   * @param {int} version - Version del esquema.
   * @returns {Future<void>} Operacion asincronica sin valor de retorno.
   * @throws {Exception} Error al crear tablas o seed data.
   */
  Future _createDB(Database db, int version) async {
    // -------------------------------------------------------------------------
    // 📦 TABLA: pedidos
    // -------------------------------------------------------------------------
    // Almacena los pedidos creados por los usuarios
    // Cada fila representa un pedido individual
    await db.execute('''
      CREATE TABLE pedidos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,  -- ID único autoincrementable
        mesa TEXT NOT NULL,                    -- Número/nombre de la mesa
        cliente TEXT NOT NULL,                 -- Nombre del cliente
        plato_id INTEGER NOT NULL,             -- ID del plato pedido (FK)
        fecha TEXT NOT NULL,                   -- Fecha del pedido (formato ISO)
        estado TEXT NOT NULL,                  -- Estado: 'pendiente', 'pagado', etc.
        total REAL NOT NULL DEFAULT 0.0        -- Precio total del pedido
      )
    ''');

    // -------------------------------------------------------------------------
    // 🍽️ TABLA: platos
    // -------------------------------------------------------------------------
    // Almacena el catálogo de platos/productos del restaurante
    // Se sincroniza con el backend pero también funciona offline
    await db.execute('''
      CREATE TABLE platos (
        id INTEGER PRIMARY KEY,                -- ID del plato (mismo que en backend)
        nombre TEXT NOT NULL,                  -- Nombre del plato
        precio REAL NOT NULL,                  -- Precio en pesos
        descripcion TEXT,                      -- Descripción del plato
        imagen_path TEXT,                      -- Ruta de la imagen (local o URL)
        categoria TEXT,                        -- Categoría: 'Cocina', 'Hamburguesas', etc.
        es_menu_del_dia INTEGER,               -- Boolean: 1 = sí, 0 = no
        rubro_id INTEGER,                      -- ID del rubro/categoría (FK)
        
        -- 📊 COLUMNAS DE CONTROL DE STOCK
        stock_cantidad INTEGER,                -- Cantidad disponible
        stock_ilimitado INTEGER,               -- Boolean: 1 = stock ilimitado
        stock_estado TEXT                      -- 'DISPONIBLE', 'AGOTADO', 'PAUSADO'
      )
    ''');

    // -------------------------------------------------------------------------
    // 🌱 SEED DATA - Datos de Prueba para Modo Offline
    // -------------------------------------------------------------------------
    // Inserta datos de ejemplo para que la app funcione sin backend
    // En producción, estos datos vendrían del servidor
    //
    // 💡 NOTA: Los valores deben coincidir con el esquema definido arriba
    await db.rawInsert('''
      INSERT INTO platos (
        id, 
        nombre, 
        precio, 
        descripcion,       -- Antes era 'ingrediente_principal'
        imagen_path, 
        categoria,         -- Nueva columna
        es_menu_del_dia,   -- Nueva columna (1 o 0)
        stock_cantidad, 
        stock_ilimitado, 
        stock_estado
      ) 
      VALUES 
      -- Plato 1: Milanesa a Caballo (Menú del día)
      (1, 'Milanesa a Caballo', 1500.0, 'Con papas fritas y huevo', NULL, 'Cocina', 1, 10, 0, 'DISPONIBLE'),
      
      -- Plato 2: Hamburguesa Doble (Agotado)
      (2, 'Hamburguesa Doble', 2000.0, 'Doble carne con cheddar', NULL, 'Hamburguesas', 0, 0, 0, 'AGOTADO'),
      
      -- Plato 3: Ensalada Caesar (Stock ilimitado)
      (3, 'Ensalada Caesar', 1200.0, 'Con pollo y croutones', NULL, 'Cocina', 0, 50, 1, 'DISPONIBLE')
    ''');
  }

  // ============================================================================
  // 🔮 MÉTODOS FUTUROS (ejemplos de operaciones CRUD)
  // ============================================================================

  // Future<List<Map<String, dynamic>>> getPedidos() async {
  //   final db = await database;
  //   return await db.query('pedidos');
  // }
  //
  // Future<int> insertPedido(Map<String, dynamic> pedido) async {
  //   final db = await database;
  //   return await db.insert('pedidos', pedido);
  // }
  //
  // Future<int> updatePedido(int id, Map<String, dynamic> pedido) async {
  //   final db = await database;
  //   return await db.update('pedidos', pedido, where: 'id = ?', whereArgs: [id]);
  // }
  //
  // Future<int> deletePedido(int id) async {
  //   final db = await database;
  //   return await db.delete('pedidos', where: 'id = ?', whereArgs: [id]);
  // }
}
