import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HistoryChart extends StatelessWidget {
  final List<String> keys;
  final List<double> values;
  final double maxKwh;

  const HistoryChart({
    super.key,
    required this.keys,
    required this.values,
    required this.maxKwh,
  });

  String _getMonthAbbr(String monthNum) {
    const months = ["GEN", "FEB", "MAR", "APR", "MAG", "GIU", "LUG", "AGO", "SET", "OTT", "NOV", "DIC"];
    return months[int.parse(monthNum) - 1];
  }

  @override
  Widget build(BuildContext context) {
    double chartWidth = keys.length * 60.0;
    if (chartWidth < MediaQuery.of(context).size.width) {
      chartWidth = MediaQuery.of(context).size.width;
    }

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
                getDrawingHorizontalLine: (value) => 
                  FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
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
                      child: Text(
                        "${value.toInt()}kWh",
                        style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
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
                      final day = key.substring(0, 2);
                      final monthYear = key.substring(3);
                      final parts = monthYear.split('-');
                      final month = _getMonthAbbr(parts[0]);
                      final yearShort = parts[1].substring(2);

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
                      strokeColor: Colors.blueAccent,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent.withOpacity(0.2), Colors.blueAccent.withOpacity(0.0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
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
}