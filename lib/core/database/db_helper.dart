import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // ⚠️ CAMBIO: Subimos a v5 para forzar que se borre la vieja y se cree esta nueva corregida
    _database = await _initDB('el_buen_sabor_v5.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // ---------------------------------------------------------
    // 1. Tabla PEDIDOS
    // ---------------------------------------------------------
    await db.execute('''
      CREATE TABLE pedidos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mesa TEXT NOT NULL,
        cliente TEXT NOT NULL,
        plato_id INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        estado TEXT NOT NULL,
        total REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // ---------------------------------------------------------
    // 2. Tabla PLATOS
    // ---------------------------------------------------------
    await db.execute('''
      CREATE TABLE platos (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        precio REAL NOT NULL,
        descripcion TEXT, 
        imagen_path TEXT, 
        categoria TEXT,
        es_menu_del_dia INTEGER,          
        
        -- COLUMNAS DE STOCK
        stock_cantidad INTEGER,
        stock_ilimitado INTEGER,
        stock_estado TEXT
      )
    ''');

    // ---------------------------------------------------------
    // 🌱 SEED DATA (Datos de Prueba Offline)
    // ---------------------------------------------------------
    // ⚠️ Actualizado para coincidir con las nuevas columnas
    await db.rawInsert('''
      INSERT INTO platos (
        id, 
        nombre, 
        precio, 
        descripcion,       -- Antes ingrediente_principal
        imagen_path, 
        categoria,         -- Nuevo
        es_menu_del_dia,   -- Nuevo (1 o 0)
        stock_cantidad, 
        stock_ilimitado, 
        stock_estado
      ) 
      VALUES 
      (1, 'Milanesa a Caballo', 1500.0, 'Con papas fritas y huevo', NULL, 'Cocina', 1, 10, 0, 'DISPONIBLE'),
      (2, 'Hamburguesa Doble', 2000.0, 'Doble carne con cheddar', NULL, 'Hamburguesas', 0, 0, 0, 'AGOTADO'),
      (3, 'Ensalada Caesar', 1200.0, 'Con pollo y croutones', NULL, 'Cocina', 0, 50, 1, 'DISPONIBLE')
    ''');
  }
}
