import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/movimiento.dart';
import '../services/dashboard_service.dart';
import '../widgets/grafico_balance.dart';
import '../widgets/grafico_categorias.dart';

class EstadisticasView extends StatelessWidget {
  const EstadisticasView({super.key});

  List<Movimiento> _obtenerDatosPrueba() {
    final ahora = DateTime.now();

    return [
      Movimiento(
        id: 1,
        usuarioId: 1,
        tipo: 'ingreso',
        monto: 45000,
        categoria: 'Salario',
        descripcion: 'Salario mensual',
        fecha: DateTime(ahora.year, ahora.month, 1),
      ),
      Movimiento(
        id: 2,
        usuarioId: 1,
        tipo: 'ingreso',
        monto: 8500,
        categoria: 'Freelance',
        descripcion: 'Proyecto adicional',
        fecha: DateTime(ahora.year, ahora.month, 5),
      ),
      Movimiento(
        id: 3,
        usuarioId: 1,
        tipo: 'gasto',
        monto: 12500,
        categoria: 'Vivienda',
        descripcion: 'Pago de alquiler',
        fecha: DateTime(ahora.year, ahora.month, 2),
      ),
      Movimiento(
        id: 4,
        usuarioId: 1,
        tipo: 'gasto',
        monto: 6200,
        categoria: 'Alimentación',
        descripcion: 'Supermercado',
        fecha: DateTime(ahora.year, ahora.month, 7),
      ),
      Movimiento(
        id: 5,
        usuarioId: 1,
        tipo: 'gasto',
        monto: 3500,
        categoria: 'Transporte',
        descripcion: 'Combustible',
        fecha: DateTime(ahora.year, ahora.month, 10),
      ),
      Movimiento(
        id: 6,
        usuarioId: 1,
        tipo: 'gasto',
        monto: 1800,
        categoria: 'Entretenimiento',
        descripcion: 'Salida',
        fecha: DateTime(ahora.year, ahora.month, 12),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    const dashboardService = DashboardService();
    final mesActual = DateTime.now();
    final movimientos = _obtenerDatosPrueba();

    final resumen = dashboardService.calcularResumen(
      movimientos,
      mesActual,
    );

    final gastosPorCategoria =
        dashboardService.calcularGastosPorCategoria(
      movimientos,
      mesActual,
    );

    final porcentajeAhorro = resumen.ingresos <= 0
        ? 0.0
        : (resumen.balance / resumen.ingresos) * 100;

    String categoriaMayor = 'Sin datos';
    double montoCategoriaMayor = 0;

    if (gastosPorCategoria.isNotEmpty) {
      final mayor = gastosPorCategoria.entries.reduce(
        (actual, siguiente) =>
            actual.value >= siguiente.value ? actual : siguiente,
      );

      categoriaMayor = mayor.key;
      montoCategoriaMayor = mayor.value;
    }

    final formatoMoneda = NumberFormat.currency(
      locale: 'es_DO',
      symbol: 'RD\$',
      decimalDigits: 2,
    );

    final nombreMes = DateFormat(
      'MMMM yyyy',
      'es_DO',
    ).format(mesActual);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Estadísticas'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            nombreMes.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _IndicadorCard(
                  titulo: 'Movimientos',
                  valor:
                      '${resumen.cantidadIngresos + resumen.cantidadGastos}',
                  icono: Icons.receipt_long,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _IndicadorCard(
                  titulo: 'Ahorro',
                  valor: '${porcentajeAhorro.toStringAsFixed(1)}%',
                  icono: Icons.savings,
                  color: porcentajeAhorro >= 0
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _DatoDestacado(
            titulo: 'Categoría con mayor gasto',
            valor: categoriaMayor,
            detalle: formatoMoneda.format(montoCategoriaMayor),
            icono: Icons.trending_up,
          ),
          const SizedBox(height: 20),

          GraficoBalance(
            ingresos: resumen.ingresos,
            gastos: resumen.gastos,
          ),
          const SizedBox(height: 20),

          GraficoCategorias(
            gastosPorCategoria: gastosPorCategoria,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _IndicadorCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _IndicadorCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 125,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 28),
          const Spacer(),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 21,
            ),
          ),
          Text(
            titulo,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatoDestacado extends StatelessWidget {
  final String titulo;
  final String valor;
  final String detalle;
  final IconData icono;

  const _DatoDestacado({
    required this.titulo,
    required this.valor,
    required this.detalle,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            child: Icon(
              icono,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
                Text(
                  valor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            detalle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}