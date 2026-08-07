import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/movimiento.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/database_service.dart';
import '../widgets/grafico_balance.dart';
import '../widgets/grafico_categorias.dart';

class EstadisticasView extends StatefulWidget {
  const EstadisticasView({super.key});

  @override
  State<EstadisticasView> createState() => _EstadisticasViewState();
}

class _EstadisticasViewState extends State<EstadisticasView> {
  final DashboardService _dashboardService = const DashboardService();

  DateTime _mesSeleccionado = DateTime.now();
  List<Movimiento> _movimientos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
    });

    final usuario = await AuthService.instance.obtenerSesion();

    _movimientos = await DatabaseService.instance.obtenerMovimientosUsuario(
      usuario?.id ?? 1,
      mes: _mesSeleccionado,
    );

    if (!mounted) return;
    setState(() {
      _cargando = false;
    });
  }

  Future<void> _cambiarMes(int cantidad) async {
    setState(() {
      _mesSeleccionado = DateTime(
        _mesSeleccionado.year,
        _mesSeleccionado.month + cantidad,
      );
    });

    await _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    final resumen = _dashboardService.calcularResumen(
      _movimientos,
      _mesSeleccionado,
    );

    final gastosPorCategoria =
        _dashboardService.calcularGastosPorCategoria(
      _movimientos,
      _mesSeleccionado,
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
    ).format(_mesSeleccionado);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Estadísticas'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: ListView(
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
            ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'prevMonth',
            onPressed: () => _cambiarMes(-1),
            backgroundColor: const Color(0xFF1A237E),
            child: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'nextMonth',
            onPressed: () => _cambiarMes(1),
            backgroundColor: const Color(0xFF1A237E),
            child: const Icon(Icons.chevron_right),
          ),
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