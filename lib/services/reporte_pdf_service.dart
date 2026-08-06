import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/movimiento.dart';
import '../models/resumen_financiero.dart';

class ReportePdfService {
  static Future<Uint8List> generarReporte({
    required String nombreUsuario,
    required DateTime mes,
    required List<Movimiento> movimientos,
    required ResumenFinanciero resumen,
  }) async {
    final documento = pw.Document();

    final formatoMoneda = NumberFormat.currency(
      locale: 'es_DO',
      symbol: 'RD\$ ',
      decimalDigits: 2,
    );

    final formatoFecha = DateFormat('dd/MM/yyyy');

    final nombreMes = DateFormat(
      'MMMM yyyy',
      'es_DO',
    ).format(mes);

    final movimientosDelMes = movimientos.where((movimiento) {
      return movimiento.fecha.year == mes.year &&
          movimiento.fecha.month == mes.month;
    }).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColors.indigo800,
                  width: 2,
                ),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'GESTOR DE FINANZAS',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo800,
                  ),
                ),
                pw.Text(
                  'Reporte financiero',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
          );
        },
        build: (context) {
          return [
            pw.SizedBox(height: 18),

            pw.Text(
              'Reporte financiero mensual',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900,
              ),
            ),
            pw.SizedBox(height: 6),

            pw.Text(
              nombreMes.toUpperCase(),
              style: const pw.TextStyle(
                fontSize: 13,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 16),

            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Usuario',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    nombreUsuario,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Generado: ${formatoFecha.format(DateTime.now())}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Text(
              'Resumen del mes',
              style: pw.TextStyle(
                fontSize: 17,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),

            pw.Row(
              children: [
                pw.Expanded(
                  child: _crearResumenCard(
                    titulo: 'Ingresos',
                    monto: formatoMoneda.format(resumen.ingresos),
                    color: PdfColors.green700,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _crearResumenCard(
                    titulo: 'Gastos',
                    monto: formatoMoneda.format(resumen.gastos),
                    color: PdfColors.red700,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _crearResumenCard(
                    titulo: 'Balance',
                    monto: formatoMoneda.format(resumen.balance),
                    color: resumen.balance >= 0
                        ? PdfColors.indigo800
                        : PdfColors.red700,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            pw.Text(
              'Detalle de movimientos',
              style: pw.TextStyle(
                fontSize: 17,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),

            if (movimientosDelMes.isEmpty)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.grey400,
                  ),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'No hay movimientos registrados en este período.',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                    color: PdfColors.grey700,
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: const [
                  'Fecha',
                  'Tipo',
                  'Categoría',
                  'Descripción',
                  'Monto',
                ],
                data: movimientosDelMes.map((movimiento) {
                  return [
                    formatoFecha.format(movimiento.fecha),
                    movimiento.esIngreso ? 'Ingreso' : 'Gasto',
                    movimiento.categoria,
                    movimiento.descripcion,
                    formatoMoneda.format(movimiento.monto),
                  ];
                }).toList(),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.indigo800,
                ),
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
                cellStyle: const pw.TextStyle(
                  fontSize: 8,
                ),
                cellPadding: const pw.EdgeInsets.all(6),
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                ),
                oddRowDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                ),
              ),
          ];
        },
      ),
    );

    return documento.save();
  }

  static pw.Widget _crearResumenCard({
    required String titulo,
    required String monto,
    required PdfColor color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: color,
          width: 1,
        ),
        borderRadius: pw.BorderRadius.circular(7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            monto,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> compartirReporte({
    required String nombreUsuario,
    required DateTime mes,
    required List<Movimiento> movimientos,
    required ResumenFinanciero resumen,
  }) async {
    final bytes = await generarReporte(
      nombreUsuario: nombreUsuario,
      mes: mes,
      movimientos: movimientos,
      resumen: resumen,
    );

    final mesNumero = mes.month.toString().padLeft(2, '0');

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'reporte_financiero_${mes.year}_$mesNumero.pdf',
    );
  }
}