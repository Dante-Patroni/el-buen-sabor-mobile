import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('el_buen_sabor_v1.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. Tabla PEDIDOS (Espejo de pedido.js)
    await db.execute('''
      CREATE TABLE pedidos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente TEXT NOT NULL,
        plato_id INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        estado TEXT NOT NULL
      )
    ''');

    // 2. Tabla PLATOS (Espejo de plato.js) - ¡NUEVO!
    await db.execute('''
      CREATE TABLE platos (
        id INTEGER PRIMARY KEY, -- No es autoincrement porque viene del backend
        nombre TEXT NOT NULL,
        precio REAL NOT NULL,
        ingrediente_principal TEXT
      )
    ''');

    // --- SEED DATA (Datos de prueba iniciales) ---
    // Insertamos platos "falsos" para que cuando corras la app no esté vacía.
    await db.rawInsert('''
      INSERT INTO platos (id, nombre, precio, ingrediente_principal) VALUES 
      (1, 'Milanesa a Caballo', 1500.0, 'Carne'),
      (2, 'Hamburguesa Doble', 2000.0, 'Carne'),
      (3, 'Ensalada Caesar', 1200.0, 'Pollo')
    ''');
  }
}