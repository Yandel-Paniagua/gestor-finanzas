import '../models/movimiento.dart';
import '../models/resumen_financiero.dart';

class DashboardService {
  const DashboardService();

  List<Movimiento> movimientosDelMes(
    List<Movimiento> movimientos,
    DateTime mes,
  ) {
    return movimientos.where((movimiento) {
      return movimiento.fecha.year == mes.year &&
          movimiento.fecha.month == mes.month;
    }).toList();
  }

  ResumenFinanciero calcularResumen(
    List<Movimiento> movimientos,
    DateTime mes,
  ) {
    final movimientosFiltrados = movimientosDelMes(movimientos, mes);

    final ingresos = movimientosFiltrados
        .where((movimiento) => movimiento.esIngreso)
        .fold<double>(
          0,
          (total, movimiento) => total + movimiento.monto,
        );

    final gastos = movimientosFiltrados
        .where((movimiento) => movimiento.esGasto)
        .fold<double>(
          0,
          (total, movimiento) => total + movimiento.monto,
        );

    return ResumenFinanciero(
      ingresos: ingresos,
      gastos: gastos,
      balance: ingresos - gastos,
      cantidadIngresos: movimientosFiltrados
          .where((movimiento) => movimiento.esIngreso)
          .length,
      cantidadGastos: movimientosFiltrados
          .where((movimiento) => movimiento.esGasto)
          .length,
    );
  }

  Map<String, double> calcularGastosPorCategoria(
    List<Movimiento> movimientos,
    DateTime mes,
  ) {
    final resultado = <String, double>{};

    for (final movimiento in movimientosDelMes(movimientos, mes)) {
      if (!movimiento.esGasto) {
        continue;
      }

      resultado.update(
        movimiento.categoria,
        (montoActual) => montoActual + movimiento.monto,
        ifAbsent: () => movimiento.monto,
      );
    }

    return resultado;
  }

  List<Movimiento> obtenerMovimientosRecientes(
    List<Movimiento> movimientos, {
    int limite = 5,
  }) {
    final copia = List<Movimiento>.from(movimientos);

    copia.sort((a, b) => b.fecha.compareTo(a.fecha));

    return copia.take(limite).toList();
  }

  double calcularPorcentajePresupuesto({
    required double gastos,
    required double presupuesto,
  }) {
    if (presupuesto <= 0) {
      return 0;
    }

    return (gastos / presupuesto).clamp(0.0, 1.0);
  }
}