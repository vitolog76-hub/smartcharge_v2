import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/charge_session.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateHistoryPdf(
    List<ChargeSession> sessions, {
    int? filterMonth,
    int? filterYear,
    required String userName,
    required String provider,
    required String carModel,
  }) async {
    final pdf = pw.Document();

    // Filtro intelligente
    List<ChargeSession> filtered = sessions.where((s) {
      bool monthMatch = filterMonth == null || s.date.month == filterMonth;
      bool yearMatch = filterYear == null || s.date.year == filterYear;
      return monthMatch && yearMatch;
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // --- HEADER ---
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start, // Corretto qui
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("REPORT RICARICHE SMARTCHARGE", 
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.blue900)),
                  pw.SizedBox(height: 8),
                  pw.Text("Utente/Azienda: $userName", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text("Gestore Energia: $provider"),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end, // FIX: Qui c'era l'errore
                children: [
                  pw.Text("Veicolo: ${carModel.toUpperCase()}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text("Periodo: ${filterMonth ?? 'Tutti'}/${filterYear ?? 'Tutti'}"),
                  pw.Text("Data export: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}"),
                ],
              ),
            ],
          ),
          
          pw.SizedBox(height: 10),
          pw.Divider(thickness: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 20),

          // --- TABELLA DATI ---
          pw.TableHelper.fromTextArray(
            headers: ['Data', 'Tipo/Località', 'kWh', 'Costo (€)'],
            data: filtered.map((s) => [
              DateFormat('dd/MM/yyyy').format(s.date),
              s.location,
              s.kwh.toStringAsFixed(2),
              s.cost.toStringAsFixed(2)
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
            cellAlignment: pw.Alignment.centerLeft,
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5))
            ),
            cellHeight: 30,
            cellStyle: const pw.TextStyle(fontSize: 10),
          ),

          pw.SizedBox(height: 20),
          
          // --- RIEPILOGO FINALE ---
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("TOTALI: ${filtered.length} sessioni"),
                pw.Text(
                  "SPESA TOTALE: ${filtered.fold(0.0, (double sum, item) => sum + item.cost).toStringAsFixed(2)} €",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}