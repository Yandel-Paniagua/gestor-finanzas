import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/movimiento.dart';
import '../models/resumen_financiero.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/reporte_pdf_service.dart';
import '../widgets/resumen_card.dart';

class ReportesView extends StatefulWidget {
  const ReportesView({super.key});

  @override
  State<ReportesView> createState() => _ReportesViewState();
}

class _ReportesViewState extends State<ReportesView> {
  final DashboardService _dashboardService = const DashboardService();

  DateTime _mesSeleccionado = DateTime.now();
  ResumenFinanciero _resumen = ResumenFinanciero.vacio();

  List<Movimiento> _movimientos = [];
  String _nombreUsuario = 'Usuario';

  bool _cargando = true;
  bool _generandoPdf = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final usuario = await AuthService.instance.obtenerSesion();

    _nombreUsuario = usuario?.nombre ?? 'Usuario';

    // Datos temporales hasta conectar SQLite con el Integrante 2.
    _movimientos = _obtenerDatosPrueba();

    _actualizarResumen();

    if (!mounted) {
      return;
    }

    setState(() {
      _cargando = false;
    });
  }

  List<Movimiento> _obtenerDatosPrueba() {
    final ahora = DateTime.now();
    final usuarioId = 1;

    return [
      Movimiento(
        id: 1,
        usuarioId: usuarioId,
        tipo: 'ingreso',
        monto: 45000,
        categoria: 'Salario',
        descripcion: 'Salario mensual',
        fecha: DateTime(ahora.year, ahora.month, 1),
      ),
      Movimiento(
        id: 2,
        usuarioId: usuarioId,
        tipo: 'ingreso',
        monto: 8500,
        categoria: 'Freelance',
        descripcion: 'Proyecto adicional',
        fecha: DateTime(ahora.year, ahora.month, 5),
      ),
      Movimiento(
        id: 3,
        usuarioId: usuarioId,
        tipo: 'gasto',
        monto: 12500,
        categoria: 'Vivienda',
        descripcion: 'Pago de alquiler',
        fecha: DateTime(ahora.year, ahora.month, 2),
      ),
      Movimiento(
        id: 4,
        usuarioId: usuarioId,
        tipo: 'gasto',
        monto: 6200,
        categoria: 'Alimentación',
        descripcion: 'Compra del supermercado',
        fecha: DateTime(ahora.year, ahora.month, 7),
      ),
      Movimiento(
        id: 5,
        usuarioId: usuarioId,
        tipo: 'gasto',
        monto: 3500,
        categoria: 'Transporte',
        descripcion: 'Combustible y transporte',
        fecha: DateTime(ahora.year, ahora.month, 10),
      ),
      Movimiento(
        id: 6,
        usuarioId: usuarioId,
        tipo: 'gasto',
        monto: 1800,
        categoria: 'Entretenimiento',
        descripcion: 'Salida de fin de semana',
        fecha: DateTime(ahora.year, ahora.month, 12),
      ),
    ];
  }

  void _actualizarResumen() {
    _resumen = _dashboardService.calcularResumen(
      _movimientos,
      _mesSeleccionado,
    );
  }

  void _cambiarMes(int cantidad) {
    setState(() {
      _mesSeleccionado = DateTime(
        _mesSeleccionado.year,
        _mesSeleccionado.month + cantidad,
      );

      _actualizarResumen();
    });
  }

  Future<void> _generarPdf() async {
    setState(() {
      _generandoPdf = true;
    });

    try {
      await ReportePdfService.compartirReporte(
        nombreUsuario: _nombreUsuario,
        mes: _mesSeleccionado,
        movimientos: _movimientos,
        resumen: _resumen,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar el PDF: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _generandoPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final movimientosDelMes = _dashboardService.movimientosDelMes(
      _movimientos,
      _mesSeleccionado,
    )..sort((a, b) => b.fecha.compareTo(a.fecha));

    final formatoMoneda = NumberFormat.currency(
      symbol: 'RD\$',
      decimalDigits: 2,
    );

    final formatoFecha = DateFormat('dd/MM/yyyy');

    final nombreMes = _obtenerNombreMes(_mesSeleccionado);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Reportes'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Reporte financiero mensual',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Selecciona un mes y genera tu reporte en PDF.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),

                _SelectorMesReporte(
                  mes: nombreMes,
                  anterior: () => _cambiarMes(-1),
                  siguiente: () => _cambiarMes(1),
                ),
                const SizedBox(height: 18),

                ResumenCard(
                  titulo: 'Ingresos del período',
                  monto: _resumen.ingresos,
                  icono: Icons.arrow_downward,
                  color: Colors.green,
                ),
                const SizedBox(height: 12),

                ResumenCard(
                  titulo: 'Gastos del período',
                  monto: _resumen.gastos,
                  icono: Icons.arrow_upward,
                  color: Colors.red,
                ),
                const SizedBox(height: 12),

                ResumenCard(
                  titulo: 'Balance del período',
                  monto: _resumen.balance,
                  icono: Icons.account_balance_wallet,
                  color: _resumen.balance >= 0
                      ? const Color(0xFF1A237E)
                      : Colors.red,
                ),
                const SizedBox(height: 22),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Movimientos incluidos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF1A237E,
                              ).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${movimientosDelMes.length}',
                              style: const TextStyle(
                                color: Color(0xFF1A237E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (movimientosDelMes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 25),
                          child: Center(
                            child: Text(
                              'No hay movimientos para este mes.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...movimientosDelMes.map((movimiento) {
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
                                color: ingreso
                                    ? Colors.green
                                    : Colors.red,
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
                                color: ingreso
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                SizedBox(
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed:
                        _generandoPdf ? null : _generarPdf,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _generandoPdf
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.picture_as_pdf),
                    label: Text(
                      _generandoPdf
                          ? 'Generando reporte...'
                          : 'Generar reporte PDF',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
    );
  }

  String _obtenerNombreMes(DateTime fecha) {
    const meses = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];

    return '${meses[fecha.month - 1]} ${fecha.year}';
  }
}

class _SelectorMesReporte extends StatelessWidget {
  final String mes;
  final VoidCallback anterior;
  final VoidCallback siguiente;

  const _SelectorMesReporte({
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
              mes,
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