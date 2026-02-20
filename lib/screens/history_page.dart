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
  }

  @override
  void didUpdateWidget(HistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.history != oldWidget.history) {
      _localHistory = List.from(widget.history);
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
      key: Key(session.date.toString() + index.toString()),
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
        final removedIndex = index;
        
        final updatedHistory = List<ChargeSession>.from(_localHistory)..removeAt(removedIndex);
        _localHistory = updatedHistory;
        
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
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
        title: Text(
          "${session.kwh.toStringAsFixed(1)} kWh",
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white),
        ),
        subtitle: Text(
          DateFormat('dd MMM yyyy', 'it_IT').format(session.date),
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        trailing: Text(
          "${session.cost.toStringAsFixed(2)} €",
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
        ),
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
                isCurved: false, // 🔥 LINEA DRITTA, NON SPLINE
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
                        "${day} $month $year\n${touchedSpot.y.toStringAsFixed(1)} kWh",
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