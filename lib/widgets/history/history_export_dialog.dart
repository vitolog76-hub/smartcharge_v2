import 'package:flutter/material.dart';

class HistoryExportDialog extends StatelessWidget {
  final Function(int?, int?) onExport;

  const HistoryExportDialog({
    super.key,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Esporta Report",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Scegli il periodo da includere nel PDF",
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildOption(
            context,
            Icons.calendar_view_month,
            "Mese Corrente",
            () {
              Navigator.pop(context);
              onExport(DateTime.now().month, DateTime.now().year);
            },
          ),
          _buildOption(
            context,
            Icons.calendar_today,
            "Anno Corrente",
            () {
              Navigator.pop(context);
              onExport(null, DateTime.now().year);
            },
          ),
          _buildOption(
            context,
            Icons.all_inclusive,
            "Tutto lo Storico",
            () {
              Navigator.pop(context);
              onExport(null, null);
            },
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool isLast = false}) {
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
}