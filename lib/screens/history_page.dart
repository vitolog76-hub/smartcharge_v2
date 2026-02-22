import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:smartcharge_v2/core/constants.dart';
import 'package:smartcharge_v2/models/charge_session.dart';
import 'package:smartcharge_v2/models/contract_model.dart';
import 'package:smartcharge_v2/models/car_model.dart';
import 'package:smartcharge_v2/services/pdf_service.dart';
import 'package:google_fonts/google_fonts.dart';

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
  int? selectedMonth;
  int? selectedYearForPdf;
  
  late List<ChargeSession> _localHistory;

  @override
  void initState() {
    super.initState();
    _localHistory = List.from(widget.history);
    debugPrint('📊 HistoryPage caricata con ${_localHistory.length} sessioni');
  }

  @override
  void didUpdateWidget(HistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.history != oldWidget.history) {
      _localHistory = List.from(widget.history);
      debugPrint('📊 HistoryPage aggiornata: ${_localHistory.length} sessioni');
    }
  }

  void _generateAndSharePdf() {
    _showPdfExportDialog();
  }

  // Calcola totali per anno
  Map<String, Map<String, double>> _getYearlyTotals() {
    Map<String, Map<String, double>> yearlyTotals = {};
    
    for (var session in _localHistory) {
      String year = DateFormat('yyyy').format(session.date);
      if (!yearlyTotals.containsKey(year)) {
        yearlyTotals[year] = {'kwh': 0, 'cost': 0};
      }
      yearlyTotals[year]!['kwh'] = (yearlyTotals[year]!['kwh'] ?? 0) + session.kwh;
      yearlyTotals[year]!['cost'] = (yearlyTotals[year]!['cost'] ?? 0) + session.cost;
    }
    
    return yearlyTotals;
  }

  Map<String, double> _getAggregatedMonthlyData() {
    Map<String, double> aggregated = {};
    
    // Trova il mese corrente
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    
    // Genera 5 mesi totali: corrente, 2 prima, 2 dopo
    for (int i = -2; i <= 2; i++) {
      final date = DateTime(currentMonth.year, currentMonth.month + i, 1);
      final monthKey = DateFormat('MM-yyyy').format(date);
      
      // Suddividi in 1° e 15°
      final firstDayKey = "01-$monthKey";  // 1° del mese
      final fifteenthKey = "15-$monthKey"; // 15° del mese
      
      aggregated[firstDayKey] = 0.0;
      aggregated[fifteenthKey] = 0.0;
    }
    
    // Popola con i dati reali
    for (var session in _localHistory) {
      final day = session.date.day;
      final monthKey = DateFormat('MM-yyyy').format(session.date);
      
      // Assegna al punto più vicino (1° o 15°)
      if (day <= 15) {
        final firstDayKey = "01-$monthKey";
        aggregated[firstDayKey] = (aggregated[firstDayKey] ?? 0) + session.kwh;
      } else {
        final fifteenthKey = "15-$monthKey";
        aggregated[fifteenthKey] = (aggregated[fifteenthKey] ?? 0) + session.kwh;
      }
    }
    
    // Ordina le chiavi cronologicamente
    final sortedKeys = aggregated.keys.toList()..sort((a, b) {
      final aParts = a.substring(3).split('-');
      final bParts = b.substring(3).split('-');
      final aDate = DateTime(int.parse(aParts[1]), int.parse(aParts[0]), int.parse(a.substring(0,2)));
      final bDate = DateTime(int.parse(bParts[1]), int.parse(bParts[0]), int.parse(b.substring(0,2)));
      return aDate.compareTo(bDate);
    });
    
    // Ricostruisci la mappa ordinata
    final Map<String, double> sortedAggregated = {};
    for (var key in sortedKeys) {
      sortedAggregated[key] = aggregated[key]!;
    }
    
    return sortedAggregated;
  }

  Map<String, Map<String, List<ChargeSession>>> _getGroupedHistory() {
    Map<String, Map<String, List<ChargeSession>>> grouped = {};
    var sortedHistory = List<ChargeSession>.from(_localHistory)..sort((a, b) => b.date.compareTo(a.date));

    for (var session in sortedHistory) {
      String year = DateFormat('yyyy').format(session.date);
      String month = DateFormat('MMMM', 'it_IT').format(session.date);
      month = month[0].toUpperCase() + month.substring(1);
      
      if (!grouped.containsKey(year)) grouped[year] = {};
      if (!grouped[year]!.containsKey(month)) grouped[year]![month] = [];
      grouped[year]![month]!.add(session);
    }
    return grouped;
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
            onPressed: _generateAndSharePdf,
            tooltip: "Esporta PDF",
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeaderChart(chartKeys, chartValues, maxKwh, context),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), 
            child: Divider(color: Colors.white10, thickness: 1)
          ),
          Expanded(
            child: _localHistory.isEmpty
                ? const Center(child: Text("Nessuna ricarica", style: TextStyle(color: Colors.white24)))
                : ListView(
                    key: ValueKey(_localHistory.length),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: groupedHistory.entries.map((yearEntry) {
                      return _buildYearFolder(
                        yearEntry.key, 
                        yearEntry.value,
                        yearlyTotals[yearEntry.key]
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearFolder(
    String year, 
    Map<String, List<ChargeSession>> months,
    Map<String, double>? yearlyTotal
  ) {
    bool isCurrentYear = year == DateTime.now().year.toString();
    double totalKwh = yearlyTotal?['kwh'] ?? 0;
    double totalCost = yearlyTotal?['cost'] ?? 0;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isCurrentYear,
        iconColor: Colors.blueAccent,
        collapsedIconColor: Colors.white24,
        title: Row(
          children: [
            Text(year, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (totalKwh > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: Text(
                  "${totalKwh.toStringAsFixed(1)} kWh  •  ${totalCost.toStringAsFixed(2)} €",
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        children: months.entries.map((monthEntry) {
          return _buildMonthFolder(monthEntry.key, monthEntry.value, year);
        }).toList(),
      ),
    );
  }

  Widget _buildMonthFolder(String monthName, List<ChargeSession> sessions, String year) {
    double totalKwh = sessions.fold(0, (sum, item) => sum + item.kwh);
    double totalCost = sessions.fold(0, (sum, item) => sum + item.cost);
    String currentMonthName = DateFormat('MMMM', 'it_IT').format(DateTime.now());
    currentMonthName = currentMonthName[0].toUpperCase() + currentMonthName.substring(1);
    
    bool isCurrentMonth = (monthName == currentMonthName && year == DateTime.now().year.toString());

    return ExpansionTile(
      initiallyExpanded: isCurrentMonth,
      leading: Icon(
        Icons.calendar_today, 
        color: isCurrentMonth ? Colors.blueAccent : Colors.white24, 
        size: 18
      ),
      title: Text(
        monthName, 
        style: TextStyle(
          color: isCurrentMonth ? Colors.white : Colors.white70, 
          fontSize: 16, 
          fontWeight: FontWeight.w600
        )
      ),
      subtitle: Row(
        children: [
          Text(
            "${totalKwh.toStringAsFixed(1)} kWh",
            style: const TextStyle(color: Colors.blueAccent, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Text(
            "${totalCost.toStringAsFixed(2)} €",
            style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
          ),
        ],
      ),
      children: sessions.asMap().entries.map((entry) {
        int idx = entry.key;
        ChargeSession session = entry.value;
        return _buildSessionCard(session, idx);
      }).toList(),
    );
  }

  Widget _buildSessionCard(ChargeSession session, int index) {
    return Dismissible(
      key: Key('${session.id}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 30,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1C1C1E),
              title: const Text(
                "Conferma",
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                "Eliminare questa ricarica?",
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("ANNULLA"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    "ELIMINA",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        final updatedHistory = List<ChargeSession>.from(_localHistory)..removeAt(index);
        setState(() {
          _localHistory = updatedHistory;
        });
        
        if (widget.onHistoryChanged != null) {
          widget.onHistoryChanged!(updatedHistory);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ricarica eliminata"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: _buildSessionCardContent(session),
    );
  }

  Widget _buildSessionCardContent(ChargeSession session) {
    // Formatta la durata
    final duration = session.endDateTime.difference(session.startDateTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final durationStr = '${hours}h ${minutes}m';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: session.location == "Home" ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                session.location == "Home" ? Icons.home_filled : Icons.bolt,
                color: session.location == "Home" ? Colors.blueAccent : Colors.greenAccent,
                size: 18,
              ),
            ),
            title: Row(
              children: [
                Text(
                  "${session.kwh.toStringAsFixed(1)} kWh",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  ),
                  child: Text(
                    "${session.wallboxPower.toStringAsFixed(1)} kW",
                    style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd MMM yyyy', 'it_IT').format(session.date),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.timer, size: 10, color: Colors.white38),
                    const SizedBox(width: 4),
                    Text(
                      durationStr,
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.percent, size: 10, color: Colors.white38),
                    const SizedBox(width: 4),
                    Text(
                      '${session.startSoc.toStringAsFixed(0)}% → ${session.endSoc.toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${session.cost.toStringAsFixed(2)} €",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  session.carModel,
                  style: const TextStyle(color: Colors.white24, fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPdfExportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Esporta Report", 
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            const Text(
              "Scegli il periodo da includere nel PDF", 
              style: TextStyle(color: Colors.white38, fontSize: 14)
            ),
            const SizedBox(height: 24),
            _buildExportOption(
              Icons.calendar_view_month, 
              "Mese Corrente", 
              () {
                Navigator.pop(context);
                _generatePdf(DateTime.now().month, DateTime.now().year);
              }
            ),
            _buildExportOption(
              Icons.calendar_today, 
              "Anno Corrente", 
              () {
                Navigator.pop(context);
                _generatePdf(null, DateTime.now().year);
              }
            ),
            _buildExportOption(
              Icons.all_inclusive, 
              "Tutto lo Storico", 
              () {
                Navigator.pop(context);
                _generatePdf(null, null);
              },
              isLast: true
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(IconData icon, String title, VoidCallback onTap, {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: Colors.blueAccent),
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white12, size: 14),
          onTap: onTap,
        ),
        if (!isLast) const Divider(color: Colors.white10, indent: 40),
      ],
    );
  }

  void _generatePdf(int? month, int? year) {
    PdfService.generateHistoryPdf(
      widget.history,
      filterMonth: month,
      filterYear: year,
      userName: widget.contract.userName.isEmpty ? "UTENTE" : widget.contract.userName.toUpperCase(), 
      provider: widget.contract.provider.isEmpty ? "PRIVATO" : widget.contract.provider.toUpperCase(),
      carModel: "${widget.selectedCar.brand} ${widget.selectedCar.model}".toUpperCase(),
    );
  }

  // Aggiungi questo metodo nella classe _HistoryPageState
void _showEditDialog(ChargeSession session, int index) {
  // Controller per i campi modificabili
  final kwhCtrl = TextEditingController(text: session.kwh.toStringAsFixed(1));
  final startSocCtrl = TextEditingController(text: session.startSoc.toStringAsFixed(0));
  final endSocCtrl = TextEditingController(text: session.endSoc.toStringAsFixed(0));
  final wallboxPowerCtrl = TextEditingController(text: session.wallboxPower.toStringAsFixed(1));
  final costCtrl = TextEditingController(text: session.cost.toStringAsFixed(2));
  final locationCtrl = TextEditingController(text: session.location);
  
  DateTime selectedDate = session.date;
  TimeOfDay selectedStartTime = TimeOfDay.fromDateTime(session.startDateTime);
  TimeOfDay selectedEndTime = TimeOfDay.fromDateTime(session.endDateTime);
  
  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Modifica Ricarica",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Data e Ora
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 20),
                        title: const Text("Data", style: TextStyle(color: Colors.white38, fontSize: 10)),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy').format(selectedDate),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.timer, color: Colors.blueAccent, size: 16),
                              title: const Text("Inizio", style: TextStyle(color: Colors.white38, fontSize: 8)),
                              subtitle: Text(
                                selectedStartTime.format(context),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: ctx,
                                  initialTime: selectedStartTime,
                                );
                                if (picked != null) {
                                  setState(() {
                                    selectedStartTime = picked;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.timer_off, color: Colors.orangeAccent, size: 16),
                              title: const Text("Fine", style: TextStyle(color: Colors.white38, fontSize: 8)),
                              subtitle: Text(
                                selectedEndTime.format(context),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: ctx,
                                  initialTime: selectedEndTime,
                                );
                                if (picked != null) {
                                  setState(() {
                                    selectedEndTime = picked;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // SOC
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startSocCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.blueAccent),
                          decoration: const InputDecoration(
                            labelText: "SOC INIZIALE %",
                            labelStyle: TextStyle(color: Colors.white38, fontSize: 10),
                            suffixText: "%",
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: endSocCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.greenAccent),
                          decoration: const InputDecoration(
                            labelText: "SOC FINALE %",
                            labelStyle: TextStyle(color: Colors.white38, fontSize: 10),
                            suffixText: "%",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // kWh e Potenza
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: kwhCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          labelText: "ENERGIA (kWh)",
                          labelStyle: TextStyle(color: Colors.white38, fontSize: 10),
                          suffixText: "kWh",
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: wallboxPowerCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.orangeAccent),
                        decoration: const InputDecoration(
                          labelText: "POTENZA (kW)",
                          labelStyle: TextStyle(color: Colors.white38, fontSize: 10),
                          suffixText: "kW",
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Costo e Location
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: costCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          labelText: "COSTO (€)",
                          labelStyle: TextStyle(color: Colors.white38, fontSize: 10),
                          suffixText: "€",
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: locationCtrl.text,
                        dropdownColor: const Color(0xFF1C1C1E),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "LUOGO",
                          labelStyle: TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                        items: const [
                          DropdownMenuItem(value: "Home", child: Text("Home")),
                          DropdownMenuItem(value: "Pubblica", child: Text("Pubblica")),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              locationCtrl.text = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annulla", style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: () {
                _saveEditedSession(
                  session,
                  index,
                  selectedDate,
                  selectedStartTime,
                  selectedEndTime,
                  startSocCtrl.text,
                  endSocCtrl.text,
                  kwhCtrl.text,
                  wallboxPowerCtrl.text,
                  costCtrl.text,
                  locationCtrl.text,
                );
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text("SALVA"),
            ),
          ],
        );
      },
    ),
  );
}

void _saveEditedSession(
  ChargeSession oldSession,
  int index,
  DateTime newDate,
  TimeOfDay newStartTime,
  TimeOfDay newEndTime,
  String startSocStr,
  String endSocStr,
  String kwhStr,
  String wallboxPowerStr,
  String costStr,
  String locationStr,
) {
  try {
    final startSoc = double.tryParse(startSocStr.replaceAll(',', '.')) ?? oldSession.startSoc;
    final endSoc = double.tryParse(endSocStr.replaceAll(',', '.')) ?? oldSession.endSoc;
    final kwh = double.tryParse(kwhStr.replaceAll(',', '.')) ?? oldSession.kwh;
    final wallboxPower = double.tryParse(wallboxPowerStr.replaceAll(',', '.')) ?? oldSession.wallboxPower;
    final cost = double.tryParse(costStr.replaceAll(',', '.')) ?? oldSession.cost;
    
    final startDateTime = DateTime(
      newDate.year,
      newDate.month,
      newDate.day,
      newStartTime.hour,
      newStartTime.minute,
    );
    
    final endDateTime = DateTime(
      newDate.year,
      newDate.month,
      newDate.day,
      newEndTime.hour,
      newEndTime.minute,
    );
    
    final updatedSession = ChargeSession(
      id: oldSession.id,
      date: newDate,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      startSoc: startSoc,
      endSoc: endSoc,
      kwh: kwh,
      cost: cost,
      location: locationStr,
      carBrand: oldSession.carBrand,
      carModel: oldSession.carModel,
      wallboxPower: wallboxPower,
    );
    
    setState(() {
      _localHistory[index] = updatedSession;
    });
    
    if (widget.onHistoryChanged != null) {
      widget.onHistoryChanged!(_localHistory);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Ricarica modificata con successo!"),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Errore: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  Widget _buildHeaderChart(List<String> keys, List<double> values, double maxKwh, BuildContext context) {
    double chartWidth = keys.length * 60.0;
    if (chartWidth < MediaQuery.of(context).size.width) chartWidth = MediaQuery.of(context).size.width;

    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 25, bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Container(
          width: chartWidth,
          padding: const EdgeInsets.only(right: 20, left: 10),
          child: LineChart(
            LineChartData(
              minY: 0, 
              maxY: maxKwh,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxKwh / 4,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxKwh / 4,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text("${value.toInt()}kWh", style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index < 0 || index >= keys.length) return const SizedBox();
                      
                      final key = keys[index];
                      // Formato: "01-MM-yyyy" o "15-MM-yyyy"
                      final day = key.substring(0, 2);
                      final monthYear = key.substring(3);
                      final parts = monthYear.split('-');
                      final month = _getMonthAbbr(parts[0]);
                      final yearShort = parts[1].substring(2);
                      
                      // Evidenzia il mese corrente
                      final now = DateTime.now();
                      final currentMonthKey = DateFormat('MM-yyyy').format(now);
                      final isCurrentMonth = monthYear == currentMonthKey;
                      
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 8,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              day,
                              style: TextStyle(
                                color: isCurrentMonth ? Colors.blueAccent : Colors.white54,
                                fontSize: 10,
                                fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            Text(
                              month,
                              style: TextStyle(
                                color: isCurrentMonth ? Colors.blueAccent : Colors.white38,
                                fontSize: 9,
                                fontWeight: isCurrentMonth ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            Text(
                              "'$yearShort",
                              style: TextStyle(
                                color: isCurrentMonth ? Colors.white54 : Colors.white24,
                                fontSize: 7,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(keys.length, (i) => FlSpot(i.toDouble(), values[i])),
                  isCurved: false,
                  color: Colors.blueAccent,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 3, 
                      color: Colors.black, 
                      strokeWidth: 2, 
                      strokeColor: Colors.blueAccent
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true, 
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent.withOpacity(0.2), Colors.blueAccent.withOpacity(0.0)], 
                      begin: Alignment.topCenter, 
                      end: Alignment.bottomCenter
                    )
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: const Color(0xFF1C1C1E),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((touchedSpot) {
                      final spotIndex = touchedSpot.spotIndex;
                      if (spotIndex >= 0 && spotIndex < keys.length) {
                        final key = keys[spotIndex];
                        final day = key.substring(0, 2);
                        final monthYear = key.substring(3);
                        final parts = monthYear.split('-');
                        final month = _getMonthAbbr(parts[0]);
                        final year = parts[1];
                        
                        return LineTooltipItem(
                          "$day $month $year\n${touchedSpot.y.toStringAsFixed(1)} kWh",
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        );
                      }
                      return null;
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthAbbr(String monthNum) {
    const months = ["GEN", "FEB", "MAR", "APR", "MAG", "GIU", "LUG", "AGO", "SET", "OTT", "NOV", "DIC"];
    return months[int.parse(monthNum) - 1];
  }
}