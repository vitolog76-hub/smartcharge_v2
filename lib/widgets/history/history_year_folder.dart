import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartcharge_v2/models/charge_session.dart';

class HistoryYearFolder extends StatelessWidget {
  final String year;
  final Map<String, List<ChargeSession>> months;
  final Map<String, double>? yearlyTotal;
  final Function(ChargeSession, int) onEdit;
  final Function(int) onDelete;
  final int globalStartIndex;

  const HistoryYearFolder({
    super.key,
    required this.year,
    required this.months,
    required this.yearlyTotal,
    required this.onEdit,
    required this.onDelete,
    required this.globalStartIndex,
  });

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
    int sessionIndex = globalStartIndex;

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
          sessionIndex,
        ),
      );
      sessionIndex += entry.value.length;
    }

    return folders;
  }

  Widget _buildMonthFolder(
    BuildContext context,
    String monthName,
    List<ChargeSession> sessions,
    String year,
    int startIndex,
  ) {
    double totalKwh = sessions.fold(0, (sum, item) => sum + item.kwh);
    double totalCost = sessions.fold(0, (sum, item) => sum + item.cost);
    
    String currentMonthName = DateFormat('MMMM', 'it_IT').format(DateTime.now());
    currentMonthName = currentMonthName[0].toUpperCase() + currentMonthName.substring(1);
    bool isCurrentMonth = (monthName == currentMonthName && year == DateTime.now().year.toString());

    return ExpansionTile(
      key: Key('$year-$monthName'),
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
        return _buildSessionCard(context, session, globalIndex);
      }),
    );
  }

  Widget _buildSessionCard(BuildContext context, ChargeSession session, int index) {
    final duration = session.endDateTime.difference(session.startDateTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final durationStr = '${hours}h ${minutes}m';

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
      onDismissed: (direction) => onDelete(index),
      child: Container(
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
              color: session.location == "Home" 
                ? Colors.blue.withOpacity(0.1) 
                : Colors.green.withOpacity(0.1),
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
                  Text(durationStr, style: const TextStyle(color: Colors.white38, fontSize: 10)),
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                onPressed: () => _showEditDialog(context, session, index),
              ),
              const SizedBox(width: 4),
              Text(
                "${session.cost.toStringAsFixed(2)} €",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, ChargeSession session, int index) {
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
                  // Data
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
                  // Ora inizio/fine
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
                  const SizedBox(height: 16),
                  // SOC
                  Row(
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
                  const SizedBox(height: 16),
                  // kWh e Potenza
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
                  const SizedBox(height: 16),
                  // Costo e Location
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Annulla", style: TextStyle(color: Colors.white38)),
              ),
              ElevatedButton(
                onPressed: () {
                  _saveEditedSession(
                    context,
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: const Text("SALVA"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _saveEditedSession(
    BuildContext context,
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
      
      onEdit(updatedSession, index);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ricarica modificata"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore: $e"), backgroundColor: Colors.red),
      );
    }
  }
}