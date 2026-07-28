import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  DatabaseService._init();

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

  Future<void> getDB() async {}
}
