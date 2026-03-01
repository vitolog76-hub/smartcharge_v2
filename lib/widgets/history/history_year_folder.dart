import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartcharge_v2/models/charge_session.dart';
import 'history_edit_dialog.dart';

class HistoryYearFolder extends StatelessWidget {
  final String year;
  final Map<String, List<ChargeSession>> months;
  final Map<String, double>? yearlyTotal;
  
  final Function(ChargeSession) onEdit; 
  final Function(String) onDelete; 

  const HistoryYearFolder({
    super.key,
    required this.year,
    required this.months,
    required this.yearlyTotal,
    required this.onEdit,
    required this.onDelete,
  });

  // --- HELPER PER I COLORI DELLE FASCE ---
  Color _getFasciaColor(String fascia) {
    if (fascia.contains('F1')) return Colors.blueAccent;
    if (fascia.contains('F2')) return Colors.orangeAccent;
    if (fascia.contains('F3')) return Colors.greenAccent;
    if (fascia.contains('Mista')) return Colors.deepPurpleAccent;
    return Colors.white24; 
  }

  @override
  Widget build(BuildContext context) {
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
            Text(
              year, 
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
            ),
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
        children: _buildMonthFolders(context),
      ),
    );
  }

  List<Widget> _buildMonthFolders(BuildContext context) {
    final List<Widget> folders = [];

    final monthOrder = [
      "Gennaio", "Febbraio", "Marzo", "Aprile", "Maggio", "Giugno",
      "Luglio", "Agosto", "Settembre", "Ottobre", "Novembre", "Dicembre"
    ];
    
    final sortedEntries = months.entries.toList()
      ..sort((a, b) => monthOrder.indexOf(a.key).compareTo(monthOrder.indexOf(b.key)));

    for (var entry in sortedEntries) {
      folders.add(
        _buildMonthFolder(
          context,
          entry.key,
          entry.value,
          year,
        ),
      );
    }

    return folders;
  }

  Widget _buildMonthFolder(
    BuildContext context,
    String monthName,
    List<ChargeSession> sessions,
    String year,
  ) {
    double totalKwh = sessions.fold(0, (sum, item) => sum + item.kwh);
    double totalCost = sessions.fold(0, (sum, item) => sum + item.cost);
    
    String currentMonthName = DateFormat('MMMM', 'it_IT').format(DateTime.now());
    currentMonthName = currentMonthName[0].toUpperCase() + currentMonthName.substring(1);
    bool isCurrentMonth = (monthName == currentMonthName && year == DateTime.now().year.toString());

    return ExpansionTile(
      key: Key('${year}_$monthName'),
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
      children: sessions.map((session) => _buildSessionCard(context, session)).toList(),
    );
  }

  Widget _buildSessionCard(BuildContext context, ChargeSession session) {
    final duration = session.endDateTime.difference(session.startDateTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final durationStr = '${hours}h ${minutes}m';

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1C1C1E),
              title: const Text("Conferma", style: TextStyle(color: Colors.white)),
              content: const Text("Eliminare questa ricarica?", style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("ANNULLA"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("ELIMINA", style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) => onDelete(session.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // ICONA
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: session.location == "Home" 
                    ? Colors.blue.withOpacity(0.1) 
                    : Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  session.location == "Home" ? Icons.home_filled : Icons.bolt,
                  color: session.location == "Home" ? Colors.blueAccent : Colors.greenAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // CONTENUTO CENTRALE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // RIGA kWh e kW
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${session.kwh.toStringAsFixed(1)} kWh",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${session.wallboxPower.toStringAsFixed(1)} kW",
                            style: const TextStyle(color: Colors.blueAccent, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // DATA
                    Text(
                      DateFormat('dd MMM yyyy', 'it_IT').format(session.date),
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    
                    // RIGA DURATA e SOC
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 12, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text(durationStr, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.percent, size: 12, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text(
                          '${session.startSoc.toStringAsFixed(0)}% → ${session.endSoc.toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // TRAILING (MATITA + FASCIA + COSTO)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => HistoryEditDialog(
                          session: session,
                          onSave: onEdit,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  
                  // BADGE FASCIA (Sopra il prezzo)
                  if (session.fascia != "N/D") 
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getFasciaColor(session.fascia).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _getFasciaColor(session.fascia).withOpacity(0.3)),
                      ),
                      child: Text(
                        session.fascia,
                        style: TextStyle(
                          color: _getFasciaColor(session.fascia), 
                          fontSize: 9, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),

                  // PREZZO
                  Text(
                    "${session.cost.toStringAsFixed(2)}€",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}