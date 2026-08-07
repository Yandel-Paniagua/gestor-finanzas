import 'package:shared_preferences/shared_preferences.dart';

class PresupuestoService {
  static final PresupuestoService instance = PresupuestoService._init();

  PresupuestoService._init();

  String _crearClave(int usuarioId, DateTime mes) {
    final mesFormateado = mes.month.toString().padLeft(2, '0');
    return 'presupuesto_${usuarioId}_${mes.year}_$mesFormateado';
  }

  Future<void> guardarPresupuesto({
    required int usuarioId,
    required DateTime mes,
    required double monto,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final clave = _crearClave(usuarioId, mes);

    await prefs.setDouble(clave, monto);
  }

  Future<double> obtenerPresupuesto({
    required int usuarioId,
    required DateTime mes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final clave = _crearClave(usuarioId, mes);

    return prefs.getDouble(clave) ?? 0;
  }

  Future<void> eliminarPresupuesto({
    required int usuarioId,
    required DateTime mes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final clave = _crearClave(usuarioId, mes);

    await prefs.remove(clave);
  }
}