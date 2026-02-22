import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartcharge_v2/models/charge_session.dart';
import 'history_edit_dialog.dart';

class HistorySessionCard extends StatelessWidget {
  final ChargeSession session;
  final int index;
  final Function(ChargeSession, int) onEdit;
  final Function(int) onDelete;

  const HistorySessionCard({
    super.key,
    required this.session,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
                icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => HistoryEditDialog(
                      session: session,
                      onSave: (updated) => onEdit(updated, index),
                    ),
                  );
                },
              ),
              Text(
                "${session.cost.toStringAsFixed(2)} €",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}