import 'package:flutter/material.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';

class StatsRow extends StatelessWidget {
  final HomeProvider provider;

  const StatsRow({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            "COSTO",
            "${provider.estimatedCost.toStringAsFixed(2)} €",
            Colors.greenAccent,
            Icons.euro,
          ),
          _buildStatItem(
            "DURATA",
            "${provider.duration.inHours}h ${provider.duration.inMinutes % 60}m",
            Colors.blueAccent,
            Icons.timer,
          ),
          _buildStatItem(
            "INIZIO",
            provider.startTimeDisplay,
            Colors.orangeAccent,
            Icons.schedule,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color.withOpacity(0.7), size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 8)],
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 9),
        ),
      ],
    );
  }
}