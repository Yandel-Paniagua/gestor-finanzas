import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movimiento.dart';
import '../models/usuario.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  DatabaseService._init();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gestor_finanzas.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE movimientos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuarioId INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        monto REAL NOT NULL,
        categoria TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        fecha TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // ── USUARIOS ──────────────────────────────────────────
  Future<List<Usuario>> obtenerUsuarios() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('usuarios') ?? '[]';
    List<dynamic> lista = jsonDecode(data);
    return lista
        .map((m) => Usuario.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> insertarUsuario(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    List<Usuario> usuarios = await obtenerUsuarios();
    int nuevoId = usuarios.isEmpty
        ? 1
        : usuarios.map((u) => u.id!).reduce((a, b) => a > b ? a : b) + 1;
    usuario.id = nuevoId;
    usuarios.add(usuario);
    await prefs.setString(
      'usuarios',
      jsonEncode(usuarios.map((u) => u.toMap()).toList()),
    );
  }

  Future<Usuario?> buscarUsuario(String email, String password) async {
    List<Usuario> usuarios = await obtenerUsuarios();
    try {
      return usuarios.firstWhere(
        (u) => u.email == email && u.password == password,
      );
    } catch (e) {
      return null;
    }
  }

  Future<bool> emailExiste(String email) async {
    List<Usuario> usuarios = await obtenerUsuarios();
    return usuarios.any((u) => u.email == email);
  }

  // ── MOVIMIENTOS ──────────────────────────────────────
  Future<Movimiento> insertarMovimiento(Movimiento movimiento) async {
    final db = await database;
    final id = await db.insert('movimientos', movimiento.toMap());
    return movimiento.copyWith(id: id);
  }

  Future<int> actualizarMovimiento(Movimiento movimiento) async {
    final db = await database;
    if (movimiento.id == null) return 0;
    return await db.update(
      'movimientos',
      movimiento.toMap(),
      where: 'id = ?',
      whereArgs: [movimiento.id],
    );
  }

  Future<int> eliminarMovimiento(int id) async {
    final db = await database;
    return await db.delete(
      'movimientos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Movimiento>> obtenerMovimientosUsuario(
    int usuarioId, {
    String? tipo,
    String? categoria,
    DateTime? mes,
    String? busqueda,
  }) async {
    final db = await database;
    final whereClauses = <String>['usuarioId = ?'];
    final whereArgs = <dynamic>[usuarioId];

    if (tipo != null && tipo.isNotEmpty) {
      whereClauses.add('tipo = ?');
      whereArgs.add(tipo);
    }

    if (categoria != null && categoria.isNotEmpty) {
      whereClauses.add('categoria = ?');
      whereArgs.add(categoria);
    }

    if (mes != null) {
      final inicioMes = DateTime(mes.year, mes.month, 1);
      final inicioSiguienteMes = DateTime(mes.year, mes.month + 1, 1);
      whereClauses.add('fecha >= ?');
      whereArgs.add(inicioMes.toIso8601String());
      whereClauses.add('fecha < ?');
      whereArgs.add(inicioSiguienteMes.toIso8601String());
    }

    if (busqueda != null && busqueda.trim().isNotEmpty) {
      whereClauses.add('(descripcion LIKE ? OR categoria LIKE ?)');
      final termino = '%${busqueda.trim()}%';
      whereArgs.addAll([termino, termino]);
    }

    final maps = await db.query(
      'movimientos',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'fecha DESC',
    );

    return maps.map((map) => Movimiento.fromMap(map)).toList();
  }

  // ── CATEGORÍAS (estáticas para web) ───────────────────
  List<Map<String, dynamic>> obtenerCategorias() {
    return [
      {'id': 1, 'nombre': 'Salario', 'icono': 'work', 'tipo': 'ingreso'},
      {'id': 2, 'nombre': 'Freelance', 'icono': 'computer', 'tipo': 'ingreso'},
      {
        'id': 3,
        'nombre': 'Inversiones',
        'icono': 'trending_up',
        'tipo': 'ingreso',
      },
      {'id': 4, 'nombre': 'Otros', 'icono': 'attach_money', 'tipo': 'ingreso'},
      {
        'id': 5,
        'nombre': 'Alimentación',
        'icono': 'restaurant',
        'tipo': 'gasto',
      },
      {
        'id': 6,
        'nombre': 'Transporte',
        'icono': 'directions_car',
        'tipo': 'gasto',
      },
      {'id': 7, 'nombre': 'Vivienda', 'icono': 'home', 'tipo': 'gasto'},
      {'id': 8, 'nombre': 'Salud', 'icono': 'local_hospital', 'tipo': 'gasto'},
      {'id': 9, 'nombre': 'Educación', 'icono': 'school', 'tipo': 'gasto'},
      {
        'id': 10,
        'nombre': 'Entretenimiento',
        'icono': 'movie',
        'tipo': 'gasto',
      },
      {'id': 11, 'nombre': 'Ropa', 'icono': 'checkroom', 'tipo': 'gasto'},
      {'id': 12, 'nombre': 'Otros', 'icono': 'more_horiz', 'tipo': 'gasto'},
    ];
  }

  Future<void> getDB() async {
    await database;
  }
}
