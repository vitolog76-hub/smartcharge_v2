import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartcharge_v2/core/constants.dart';
import 'package:smartcharge_v2/models/charge_session.dart';
import 'package:smartcharge_v2/models/contract_model.dart';
import 'package:smartcharge_v2/models/car_model.dart';
import 'package:smartcharge_v2/services/pdf_service.dart';
import 'package:smartcharge_v2/widgets/history/history_chart.dart';
import 'package:smartcharge_v2/widgets/history/history_year_folder.dart';
import 'package:smartcharge_v2/widgets/history/history_export_dialog.dart';

class HistoryPage extends StatefulWidget {
  final List<ChargeSession> history;
  final EnergyContract contract;
  final CarModel selectedCar;
  final Function(List<ChargeSession>)? onHistoryChanged;

  const HistoryPage({
    super.key, 
    required this.history, 
    required this.contract, 
    required this.selectedCar,
    this.onHistoryChanged,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late List<ChargeSession> _localHistory;

  @override
  void initState() {
    super.initState();
    _localHistory = List.from(widget.history);
  }

  @override
  void didUpdateWidget(HistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.history != oldWidget.history) {
      _localHistory = List.from(widget.history);
    }
  }

  // --- LOGICA DI AGGREGAZIONE DATI ---

  Map<String, Map<String, double>> _getYearlyTotals() {
    Map<String, Map<String, double>> yearlyTotals = {};
    for (var session in _localHistory) {
      String year = DateFormat('yyyy').format(session.date);
      yearlyTotals.putIfAbsent(year, () => {'kwh': 0, 'cost': 0});
      yearlyTotals[year]!['kwh'] = (yearlyTotals[year]!['kwh'] ?? 0) + session.kwh;
      yearlyTotals[year]!['cost'] = (yearlyTotals[year]!['cost'] ?? 0) + session.cost;
    }
    return yearlyTotals;
  }

  Map<String, double> _getAggregatedMonthlyData() {
    Map<String, double> aggregated = {};
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    
    for (int i = -2; i <= 2; i++) {
      final date = DateTime(currentMonth.year, currentMonth.month + i, 1);
      final monthKey = DateFormat('MM-yyyy').format(date);
      aggregated["01-$monthKey"] = 0.0;
      aggregated["15-$monthKey"] = 0.0;
    }
    
    for (var session in _localHistory) {
      final day = session.date.day;
      final monthKey = DateFormat('MM-yyyy').format(session.date);
      final key = day <= 15 ? "01-$monthKey" : "15-$monthKey";
      aggregated[key] = (aggregated[key] ?? 0) + session.kwh;
    }
    
    final sortedKeys = aggregated.keys.toList()..sort((a, b) {
      final aDate = _parseKeyToDate(a);
      final bDate = _parseKeyToDate(b);
      return aDate.compareTo(bDate);
    });
    
    return {for (var key in sortedKeys) key: aggregated[key]!};
  }

  DateTime _parseKeyToDate(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
  }

  Map<String, Map<String, List<ChargeSession>>> _getGroupedHistory() {
    Map<String, Map<String, List<ChargeSession>>> grouped = {};
    var sorted = List<ChargeSession>.from(_localHistory)..sort((a, b) => b.date.compareTo(a.date));

    for (var session in sorted) {
      String year = DateFormat('yyyy').format(session.date);
      String month = DateFormat('MMMM', 'it_IT').format(session.date);
      month = month[0].toUpperCase() + month.substring(1);
      
      grouped.putIfAbsent(year, () => {});
      grouped[year]!.putIfAbsent(month, () => []);
      grouped[year]![month]!.add(session);
    }
    return grouped;
  }

  // --- GESTIONE AZIONI (FIXED) ---

  // Ora accettiamo l'oggetto sessione direttamente
  void _onEditSession(ChargeSession updatedSession) {
    setState(() {
      final index = _localHistory.indexWhere((s) => s.id == updatedSession.id);
      if (index != -1) {
        _localHistory[index] = updatedSession;
      }
    });
    widget.onHistoryChanged?.call(_localHistory);
  }

  // Ora accettiamo l'ID stringa, non più l'indice
  void _onDeleteSessionById(String sessionId) {
    setState(() {
      _localHistory.removeWhere((session) => session.id == sessionId);
    });
    widget.onHistoryChanged?.call(_localHistory);
  }

  // --- PDF & EXPORT ---

  void _showExportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => HistoryExportDialog(onExport: _generatePdf),
    );
  }

  void _generatePdf(int? month, int? year) {
    PdfService.generateHistoryPdf(
      _localHistory,
      filterMonth: month,
      filterYear: year,
      userName: widget.contract.userName.isEmpty ? "UTENTE" : widget.contract.userName.toUpperCase(),
      provider: widget.contract.provider.isEmpty ? "PRIVATO" : widget.contract.provider.toUpperCase(),
      carModel: "${widget.selectedCar.brand} ${widget.selectedCar.model}".toUpperCase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthlyData = _getAggregatedMonthlyData();
    final chartKeys = monthlyData.keys.toList();
    final chartValues = monthlyData.values.toList();
    final groupedHistory = _getGroupedHistory();
    final yearlyTotals = _getYearlyTotals();

    double maxKwh = chartValues.isEmpty ? 50 : chartValues.reduce((a, b) => a > b ? a : b);
    maxKwh = (maxKwh / 10).ceil() * 10.0 + 20;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("CRONOLOGIA RICARICHE", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.accent, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.accent),
            onPressed: _showExportDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          HistoryChart(keys: chartKeys, values: chartValues, maxKwh: maxKwh),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Divider(color: Colors.white10, thickness: 1),
          ),
          Expanded(
            child: _localHistory.isEmpty
                ? const Center(child: Text("Nessuna ricarica", style: TextStyle(color: Colors.white24)))
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: groupedHistory.entries.map((entry) {
                      // NOTA: yearIndex non serve più con la logica degli ID!
                      return HistoryYearFolder(
                        year: entry.key,
                        months: entry.value,
                        yearlyTotal: yearlyTotals[entry.key],
                        onEdit: _onEditSession,           // Passiamo la nuova funzione
                        onDelete: _onDeleteSessionById,  // Passiamo la nuova funzione
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}