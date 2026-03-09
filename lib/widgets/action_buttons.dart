import 'package:flutter/material.dart';
import 'package:origo/l10n/app_localizations.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onHomeTap;
  final VoidCallback onPublicTap;
  final AppLocalizations l10n;

  const ActionButtons({
    super.key, 
    required this.onHomeTap, 
    required this.onPublicTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildBtn(
            l10n.addHomeCharge, 
            Colors.blueAccent, 
            Icons.home, 
            onHomeTap
          )
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBtn(
            l10n.addPublicCharge, 
            Colors.greenAccent, 
            Icons.ev_station, 
            onPublicTap
          )
        ),
      ],
    );
  }

  Widget _buildBtn(String label, Color color, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}