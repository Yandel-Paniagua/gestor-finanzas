import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/movimiento.dart';
import '../models/resumen_financiero.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/database_service.dart';
import '../services/presupuesto_service.dart';
import '../widgets/grafico_balance.dart';
import '../widgets/grafico_categorias.dart';
import '../widgets/resumen_card.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final DashboardService _dashboardService = const DashboardService();

  DateTime _mesSeleccionado = DateTime.now();
  ResumenFinanciero _resumen = ResumenFinanciero.vacio();

  List<Movimiento> _movimientos = [];
  Map<String, double> _gastosPorCategoria = {};

  double _presupuesto = 0;
  int _usuarioId = 1;
  String _nombreUsuario = 'Usuario';

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDashboard();
  }

  Future<void> _cargarDashboard() async {
    setState(() {
      _cargando = true;
    });

    final usuario = await AuthService.instance.obtenerSesion();

    _usuarioId = usuario?.id ?? 1;
    _nombreUsuario = usuario?.nombre ?? 'Usuario';

    _movimientos = await DatabaseService.instance.obtenerMovimientosUsuario(
      _usuarioId,
      mes: _mesSeleccionado,
    );

    _presupuesto = await PresupuestoService.instance.obtenerPresupuesto(
      usuarioId: _usuarioId,
      mes: _mesSeleccionado,
    );

    _actualizarCalculos();

    if (!mounted) {
      return;
    }

    setState(() {
      _cargando = false;
    });
  }

  void _actualizarCalculos() {
    _resumen = _dashboardService.calcularResumen(
      _movimientos,
      _mesSeleccionado,
    );

    _gastosPorCategoria = _dashboardService.calcularGastosPorCategoria(
      _movimientos,
      _mesSeleccionado,
    );
  }


  Future<void> _mostrarPresupuesto() async {
    final controlador = TextEditingController(
      text: _presupuesto > 0
          ? _presupuesto.toStringAsFixed(2)
          : '',
    );
    final parentContext = context;

    final resultado = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Presupuesto mensual'),
          content: TextField(
            controller: controlador,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Monto del presupuesto',
              prefixText: 'RD\$ ',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final texto = controlador.text
                    .trim()
                    .replaceAll(',', '')
                    .replaceAll('RD\$ ', '')
                    .replaceAll('RD\$', '');

                final monto = double.tryParse(texto);

                if (monto == null || monto <= 0) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Ingresa un monto válido'),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop(monto);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    controlador.dispose();

    if (resultado == null) {
      return;
    }

    await PresupuestoService.instance.guardarPresupuesto(
      usuarioId: _usuarioId,
      mes: _mesSeleccionado,
      monto: resultado,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _presupuesto = resultado;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Presupuesto guardado correctamente'),
      ),
    );
  }

  Future<void> _cambiarMes(int cantidad) async {
    final nuevoMes = DateTime(
      _mesSeleccionado.year,
      _mesSeleccionado.month + cantidad,
    );

    final presupuesto =
        await PresupuestoService.instance.obtenerPresupuesto(
      usuarioId: _usuarioId,
      mes: nuevoMes,
    );

    _movimientos = await DatabaseService.instance.obtenerMovimientosUsuario(
      _usuarioId,
      mes: nuevoMes,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _mesSeleccionado = nuevoMes;
      _presupuesto = presupuesto;
      _actualizarCalculos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatoMes = DateFormat(
      'MMMM yyyy',
      'es_DO',
    ).format(_mesSeleccionado);

    final movimientosRecientes =
        _dashboardService.obtenerMovimientosRecientes(
      _dashboardService.movimientosDelMes(
        _movimientos,
        _mesSeleccionado,
      ),
    );

    final porcentajePresupuesto =
        _dashboardService.calcularPorcentajePresupuesto(
      gastos: _resumen.gastos,
      presupuesto: _presupuesto,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: _cargarDashboard,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _cargarDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Hola, $_nombreUsuario',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Este es el resumen de tus finanzas',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 22),

                  _SelectorMes(
                    mes: formatoMes,
                    anterior: () => _cambiarMes(-1),
                    siguiente: () => _cambiarMes(1),
                  ),
                  const SizedBox(height: 18),

                  ResumenCard(
                    titulo: 'Ingresos',
                    monto: _resumen.ingresos,
                    icono: Icons.arrow_downward,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),

                  ResumenCard(
                    titulo: 'Gastos',
                    monto: _resumen.gastos,
                    icono: Icons.arrow_upward,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),

                  ResumenCard(
                    titulo: 'Balance disponible',
                    monto: _resumen.balance,
                    icono: Icons.account_balance_wallet,
                    color: _resumen.balance >= 0
                        ? const Color(0xFF1A237E)
                        : Colors.red,
                  ),
                  const SizedBox(height: 20),

                  _PresupuestoCard(
                    presupuesto: _presupuesto,
                    gastos: _resumen.gastos,
                    porcentaje: porcentajePresupuesto,
                    editarPresupuesto: _mostrarPresupuesto,
                  ),
                  const SizedBox(height: 20),

                  GraficoBalance(
                    ingresos: _resumen.ingresos,
                    gastos: _resumen.gastos,
                  ),
                  const SizedBox(height: 20),

                  GraficoCategorias(
                    gastosPorCategoria: _gastosPorCategoria,
                  ),
                  const SizedBox(height: 20),

                  _MovimientosRecientes(
                    movimientos: movimientosRecientes,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _SelectorMes extends StatelessWidget {
  final String mes;
  final VoidCallback anterior;
  final VoidCallback siguiente;

  const _SelectorMes({
    required this.mes,
    required this.anterior,
    required this.siguiente,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: anterior,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              mes.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
          ),
          IconButton(
            onPressed: siguiente,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _PresupuestoCard extends StatelessWidget {
  final double presupuesto;
  final double gastos;
  final double porcentaje;
  final VoidCallback editarPresupuesto;

  const _PresupuestoCard({
    required this.presupuesto,
    required this.gastos,
    required this.porcentaje,
    required this.editarPresupuesto,
  });

  @override
  Widget build(BuildContext context) {
    final formatoMoneda = NumberFormat.currency(
      locale: 'es_DO',
      symbol: 'RD\$',
      decimalDigits: 2,
    );

    final restante = presupuesto - gastos;
    final excedido = presupuesto > 0 && restante < 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Presupuesto mensual',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: editarPresupuesto,
                icon: const Icon(Icons.edit),
                color: const Color(0xFF1A237E),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (presupuesto <= 0)
            Column(
              children: [
                const Text(
                  'Todavía no has establecido un presupuesto.',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: editarPresupuesto,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar presupuesto'),
                  ),
                ),
              ],
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatoMoneda.format(gastos),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formatoMoneda.format(presupuesto),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            LinearProgressIndicator(
              value: porcentaje,
              minHeight: 12,
              borderRadius: BorderRadius.circular(10),
              color: excedido ? Colors.red : Colors.orange,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 10),

            Text(
              excedido
                  ? 'Presupuesto excedido por ${formatoMoneda.format(restante.abs())}'
                  : 'Disponible: ${formatoMoneda.format(restante)}',
              style: TextStyle(
                color: excedido ? Colors.red : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MovimientosRecientes extends StatelessWidget {
  final List<Movimiento> movimientos;

  const _MovimientosRecientes({
    required this.movimientos,
  });

  @override
  Widget build(BuildContext context) {
    final formatoMoneda = NumberFormat.currency(
      locale: 'es_DO',
      symbol: 'RD\$',
      decimalDigits: 2,
    );

    final formatoFecha = DateFormat(
      'dd/MM/yyyy',
      'es_DO',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Movimientos recientes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (movimientos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No hay movimientos registrados',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...movimientos.map((movimiento) {
              final ingreso = movimiento.esIngreso;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: ingreso
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  child: Icon(
                    ingreso
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: ingreso ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  movimiento.descripcion.isEmpty
                      ? movimiento.categoria
                      : movimiento.descripcion,
                ),
                subtitle: Text(
                  '${movimiento.categoria} • '
                  '${formatoFecha.format(movimiento.fecha)}',
                ),
                trailing: Text(
                  '${ingreso ? '+' : '-'}'
                  '${formatoMoneda.format(movimiento.monto)}',
                  style: TextStyle(
                    color: ingreso ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}