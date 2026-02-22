import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartcharge_v2/models/charge_session.dart';
import 'history_session_card.dart';

class HistoryMonthFolder extends StatelessWidget {
  final String monthName;
  final List<ChargeSession> sessions;
  final String year;
  final Function(ChargeSession, int) onEdit;
  final Function(int) onDelete;
  final int startIndex;

  const HistoryMonthFolder({
    super.key,
    required this.monthName,
    required this.sessions,
    required this.year,
    required this.onEdit,
    required this.onDelete,
    required this.startIndex,
  });

  @override
  Widget build(BuildContext context) {
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
        size: 18,
      ),
      title: Text(
        monthName,
        style: TextStyle(
          color: isCurrentMonth ? Colors.white : Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
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
      children: List.generate(sessions.length, (index) {
        final session = sessions[index];
        final globalIndex = startIndex + index;
        return HistorySessionCard(
          session: session,
          index: globalIndex,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      }),
    );
  }
}