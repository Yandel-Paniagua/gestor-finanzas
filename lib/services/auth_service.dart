import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  String _encriptar(String password) {
    final bytes = utf8.encode(password);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  Future<String?> registrar(
    String nombre,
    String email,
    String password,
  ) async {
    final existe = await DatabaseService.instance.emailExiste(email);
    if (existe) return 'El email ya está registrado';

    final usuario = Usuario(
      nombre: nombre,
      email: email,
      password: _encriptar(password),
    );

    await DatabaseService.instance.insertarUsuario(usuario);
    return null;
  }

  Future<Usuario?> login(String email, String password) async {
    final usuario = await DatabaseService.instance.buscarUsuario(
      email,
      _encriptar(password),
    );
    if (usuario == null) return null;
    await _guardarSesion(usuario);
    return usuario;
  }

  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('usuarioId');
    await prefs.remove('usuarioNombre');
    await prefs.remove('usuarioEmail');
  }

  Future<void> _guardarSesion(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('usuarioId', usuario.id!);
    await prefs.setString('usuarioNombre', usuario.nombre);
    await prefs.setString('usuarioEmail', usuario.email);
  }

  Future<Usuario?> obtenerSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('usuarioId');
    if (id == null) return null;
    return Usuario(
      id: id,
      nombre: prefs.getString('usuarioNombre') ?? '',
      email: prefs.getString('usuarioEmail') ?? '',
      password: '',
    );
  }
}
