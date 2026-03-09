import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:origo/l10n/app_localizations.dart';

class HistoryExportDialog extends StatelessWidget {
  final Function(int?, int?) onExport;

  const HistoryExportDialog({
    super.key,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.exportReport,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.exportSubtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildOption(
            context,
            Icons.calendar_view_month,
            "${l10n.currentMonth} (${DateFormat('MMMM').format(now)})",
            () {
              Navigator.pop(context);
              onExport(now.month, now.year);
            },
          ),
          _buildOption(
            context,
            Icons.calendar_today,
            "${l10n.currentYear} (${now.year})",
            () {
              Navigator.pop(context);
              onExport(null, now.year);
            },
          ),
          _buildOption(
            context,
            Icons.all_inclusive,
            l10n.allHistory,
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