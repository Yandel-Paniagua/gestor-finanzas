import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GraficoBalance extends StatelessWidget {
  final double ingresos;
  final double gastos;

  const GraficoBalance({
    super.key,
    required this.ingresos,
    required this.gastos,
  });

  @override
  Widget build(BuildContext context) {
    final valorMaximo = ingresos > gastos ? ingresos : gastos;
    final limiteGrafico = valorMaximo <= 0 ? 1000.0 : valorMaximo * 1.25;

    final formatoMoneda = NumberFormat.compactCurrency(
      locale: 'es_DO',
      symbol: 'RD\$',
      decimalDigits: 0,
    );

    return Container(
      height: 310,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
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
            'Ingresos vs. gastos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              _Leyenda(
                texto: 'Ingresos',
                color: Colors.green,
              ),
              SizedBox(width: 18),
              _Leyenda(
                texto: 'Gastos',
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: limiteGrafico,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: limiteGrafico / 4,
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (
                      group,
                      groupIndex,
                      rod,
                      rodIndex,
                    ) {
                      final titulo =
                          group.x == 0 ? 'Ingresos' : 'Gastos';

                      return BarTooltipItem(
                        '$titulo\n${formatoMoneda.format(rod.toY)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 58,
                      interval: limiteGrafico / 4,
                      getTitlesWidget: (valor, meta) {
                        return Text(
                          formatoMoneda.format(valor),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (valor, meta) {
                        String texto = '';

                        if (valor.toInt() == 0) {
                          texto = 'Ingresos';
                        } else if (valor.toInt() == 1) {
                          texto = 'Gastos';
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            texto,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: ingresos,
                        color: Colors.green,
                        width: 42,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: gastos,
                        color: Colors.red,
                        width: 42,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final String texto;
  final Color color;

  const _Leyenda({
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}