import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GraficoCategorias extends StatelessWidget {
  final Map<String, double> gastosPorCategoria;

  const GraficoCategorias({
    super.key,
    required this.gastosPorCategoria,
  });

  @override
  Widget build(BuildContext context) {
    final formatoMoneda = NumberFormat.currency(
      locale: 'es_DO',
      symbol: 'RD\$',
      decimalDigits: 2,
    );

    final categorias = gastosPorCategoria.entries.toList();
    final total = gastosPorCategoria.values.fold<double>(
      0,
      (suma, monto) => suma + monto,
    );

    final colores = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
    ];

    if (categorias.isEmpty || total <= 0) {
      return Container(
        height: 220,
        padding: const EdgeInsets.all(20),
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
        child: const Center(
          child: Text(
            'No hay gastos registrados este mes',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Gastos por categoría',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 210,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 45,
                sectionsSpace: 3,
                sections: List.generate(
                  categorias.length,
                  (index) {
                    final categoria = categorias[index];
                    final porcentaje = categoria.value / total * 100;

                    return PieChartSectionData(
                      value: categoria.value,
                      color: colores[index % colores.length],
                      radius: 60,
                      title: '${porcentaje.toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            categorias.length,
            (index) {
              final categoria = categorias[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: colores[index % colores.length],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        categoria.key,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      formatoMoneda.format(categoria.value),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}