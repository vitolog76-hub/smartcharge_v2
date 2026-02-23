import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:smartcharge_v2/models/charge_session.dart';

// Import per web
import 'dart:html' as html if (dart.library.io) 'dart:io';

class PdfService {
  static Future<void> generateHistoryPdf(
    List<ChargeSession> history, {
    int? filterMonth,
    int? filterYear,
    String userName = "UTENTE",
    String provider = "PRIVATO",
    String carModel = "",
  }) async {
    final pdf = pw.Document();
    
    // Carica il font
    final fontData = await rootBundle.load('fonts/Courier New.ttf');
    final ttf = pw.Font.ttf(fontData);
    
    // Carica il logo
    final ByteData logoData = await rootBundle.load('assets/images/logo.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(logoBytes);
    
    // Filtra i dati
    List<ChargeSession> filteredHistory;
    if (filterMonth != null && filterYear != null) {
      filteredHistory = history.where((s) => 
        s.date.month == filterMonth && s.date.year == filterYear
      ).toList();
    } else if (filterYear != null) {
      filteredHistory = history.where((s) => s.date.year == filterYear).toList();
    } else {
      filteredHistory = List<ChargeSession>.from(history);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(logoImage, ttf, userName, provider, carModel),
        build: (context) => [
          _buildTitle(ttf, filterMonth, filterYear),
          _buildStats(ttf, filteredHistory),
          _buildLineChart(ttf, filteredHistory, filterMonth, filterYear),
          _buildTable(ttf, filteredHistory),
          _buildFooter(ttf),
        ],
      ),
    );

    final pdfBytes = await pdf.save();
    
    if (kIsWeb) {
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'report_ricariche.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/report_ricariche_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(pdfBytes);
      await Share.shareFiles([file.path], text: 'Report Ricariche SmartCharge');
    }
  }

  static pw.Widget _buildHeader(pw.MemoryImage logoImage, pw.Font ttf, String userName, String provider, String carModel) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 40,
              height: 40,
              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(width: 10),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "SMART CHARGE",
                  style: pw.TextStyle(font: ttf, fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue),
                ),
                pw.Text(
                  "Report Ricariche",
                  style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.grey700),
                ),
              ],
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(userName, style: pw.TextStyle(font: ttf, fontSize: 10)),
            pw.Text(provider, style: pw.TextStyle(font: ttf, fontSize: 10)),
            pw.Text(carModel, style: pw.TextStyle(font: ttf, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTitle(pw.Font ttf, int? month, int? year) {
    String title = "RIEPILOGO COMPLETO";
    if (month != null && year != null) {
      final monthName = DateFormat('MMMM', 'it_IT').format(DateTime(year, month));
      title = "RIEPILOGO ${monthName.toUpperCase()} $year";
    } else if (year != null) {
      title = "RIEPILOGO ANNO $year";
    }
    
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 20, bottom: 10),
      child: pw.Text(
        title,
        style: pw.TextStyle(font: ttf, fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildStats(pw.Font ttf, List<ChargeSession> history) {
    if (history.isEmpty) return pw.Container();

    double totalKwh = 0;
    double totalCost = 0;
    for (var s in history) {
      totalKwh += s.kwh;
      totalCost += s.cost;
    }

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 20),
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(ttf, "TOTALE kWh", "${totalKwh.toStringAsFixed(1)} kWh"),
          _buildStatItem(ttf, "TOTALE €", "${totalCost.toStringAsFixed(2)} €"),
          _buildStatItem(ttf, "N. RICARICHE", "${history.length}"),
        ],
      ),
    );
  }

  static pw.Widget _buildStatItem(pw.Font ttf, String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 5),
        pw.Text(value, style: pw.TextStyle(font: ttf, fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
      ],
    );
  }

  // 🔥 GRAFICO A LINEE SEMPLIFICATO (senza CustomPainter)
  static pw.Widget _buildLineChart(pw.Font ttf, List<ChargeSession> history, int? filterMonth, int? filterYear) {
    if (history.isEmpty) return pw.Container();

    // Prepara i dati
    List<MapEntry<String, double>> dataPoints = [];
    
    if (filterMonth != null && filterYear != null) {
      // Raggruppa per giorno
      final Map<int, double> dailyData = {};
      for (var s in history) {
        if (s.date.month == filterMonth && s.date.year == filterYear) {
          dailyData[s.date.day] = (dailyData[s.date.day] ?? 0) + s.kwh;
        }
      }
      final sortedDays = dailyData.keys.toList()..sort();
      for (var day in sortedDays) {
        dataPoints.add(MapEntry("$day", dailyData[day]!));
      }
    } else {
      // Raggruppa per mese
      final Map<String, double> monthlyData = {};
      for (var session in history) {
        final monthKey = DateFormat('MM/yy').format(session.date);
        monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + session.kwh;
      }
      final sortedMonths = monthlyData.keys.toList()..sort();
      for (var month in sortedMonths) {
        dataPoints.add(MapEntry(month, monthlyData[month]!));
      }
    }

    if (dataPoints.isEmpty) return pw.Container();

    // Prendi solo gli ultimi 12 punti se sono troppi
    if (dataPoints.length > 12) {
      dataPoints = dataPoints.sublist(dataPoints.length - 12);
    }

    final maxValue = dataPoints.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          filterMonth != null ? "Andamento Giornaliero (kWh)" : "Andamento Mensile (kWh)",
          style: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          height: 150,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: dataPoints.map((point) {
              final barHeight = (point.value / maxValue) * 120;
              return pw.Expanded(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      height: barHeight,
                      margin: const pw.EdgeInsets.symmetric(horizontal: 2),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue,
                        borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(4),
                          topRight: pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          point.value.toStringAsFixed(0),
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 8),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      point.key,
                      style: pw.TextStyle(font: ttf, fontSize: 7),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  static pw.Widget _buildTable(pw.Font ttf, List<ChargeSession> history) {
    if (history.isEmpty) {
      return pw.Center(child: pw.Text("Nessuna ricarica", style: pw.TextStyle(font: ttf)));
    }

    return pw.TableHelper.fromTextArray(
      headers: ["Data", "kWh", "Costo", "Luogo", "SOC", "Durata"],
      data: history.map((s) {
        final duration = s.endDateTime.difference(s.startDateTime);
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        
        return [
          DateFormat('dd/MM/yyyy').format(s.date),
          "${s.kwh.toStringAsFixed(1)} kWh",
          "${s.cost.toStringAsFixed(2)} €",
          s.location,
          "${s.startSoc.toStringAsFixed(0)}% → ${s.endSoc.toStringAsFixed(0)}%",
          "${hours}h ${minutes}m",
        ];
      }).toList(),
      headerStyle: pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
      cellStyle: pw.TextStyle(font: ttf, fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
      },
    );
  }

  static pw.Widget _buildFooter(pw.Font ttf) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            "Generato il ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
            style: pw.TextStyle(font: ttf, fontSize: 8, color: PdfColors.grey700),
          ),
          pw.Text(
            "SmartCharge v2",
            style: pw.TextStyle(font: ttf, fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }
}