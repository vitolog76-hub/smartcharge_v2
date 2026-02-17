import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onHomeTap;
  final VoidCallback onPublicTap;

  const ActionButtons({
    super.key, 
    required this.onHomeTap, 
    required this.onPublicTap
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // BOTTONE HOME
        Expanded(
          child: _buildBtn(
            "INSERISCI\nRICARICA HOME", 
            Colors.blueAccent, 
            Icons.home, 
            onHomeTap
          )
        ),
        const SizedBox(width: 12),
        // BOTTONE PUBBLICA
        Expanded(
          child: _buildBtn(
            "INSERISCI\nRICARICA PUBBLICA", 
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded( // Permette al testo di andare a capo se non c'è spazio
              child: Text(
                label,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: color,
                  fontSize: 9.5, // Leggermente più piccolo per stare su due righe
                  fontWeight: FontWeight.w900,
                  height: 1.1, // Distanza tra le righe ridotta
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}