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

  const HistoryPage({
    super.key, 
    required this.history, 
    required this.contract, 
    required this.selectedCar
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int? selectedMonth;
  int? selectedYearForPdf; 

  // Funzione per il tasto PDF nell'AppBar
  void _generateAndSharePdf() {
    _showPdfExportDialog();
  }

  Map<String, double> _getAggregatedMonthlyData() {
    Map<String, double> aggregated = {};
    var sortedHistory = List<ChargeSession>.from(widget.history)..sort((a, b) => a.date.compareTo(b.date));
    for (var session in sortedHistory) {
      String key = DateFormat('MM-yyyy').format(session.date);
      aggregated[key] = (aggregated[key] ?? 0) + session.kwh;
    }
    return aggregated;
  }

  Map<String, Map<String, List<ChargeSession>>> _getGroupedHistory() {
    Map<String, Map<String, List<ChargeSession>>> grouped = {};
    var sortedHistory = List<ChargeSession>.from(widget.history)..sort((a, b) => b.date.compareTo(a.date));

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
            child: widget.history.isEmpty
                ? const Center(child: Text("Nessuna ricarica", style: TextStyle(color: Colors.white24)))
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: groupedHistory.entries.map((yearEntry) {
                      return _buildYearFolder(yearEntry.key, yearEntry.value);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearFolder(String year, Map<String, List<ChargeSession>> months) {
    bool isCurrentYear = year == DateTime.now().year.toString();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isCurrentYear,
        iconColor: Colors.blueAccent,
        collapsedIconColor: Colors.white24,
        title: Text(year, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        children: months.entries.map((monthEntry) {
          return _buildMonthFolder(monthEntry.key, monthEntry.value, year);
        }).toList(),
      ),
    );
  }

  Widget _buildMonthFolder(String monthName, List<ChargeSession> sessions, String year) {
    double totalKwh = sessions.fold(0, (sum, item) => sum + item.kwh);
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
      subtitle: Text(
        "${totalKwh.toStringAsFixed(1)} kWh totali", 
        style: const TextStyle(color: Colors.white24, fontSize: 11)
      ),
      children: sessions.map((session) => _buildSessionCard(session)).toList(),
    );
  }

  Widget _buildSessionCard(ChargeSession session) {
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
    double chartWidth = keys.length * 90.0;
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
                    reservedSize: 38,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index < 0 || index >= keys.length) return const SizedBox();
                      List<String> parts = keys[index].split('-');
                      String month = _getMonthAbbr(parts[0]);
                      String yearShort = parts[1].substring(2);
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 8,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(month, style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.w600)),
                            Text("'$yearShort", style: const TextStyle(color: Colors.white24, fontSize: 9)),
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
                  isCurved: true,
                  color: Colors.blueAccent,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 4, 
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
                  getTooltipItems: (touchedSpots) => touchedSpots.map((s) => LineTooltipItem(
                    "${s.y.toStringAsFixed(1)} kWh", 
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                  )).toList(),
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