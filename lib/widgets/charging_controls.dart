import 'package:flutter/material.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';

class ChargingControls extends StatelessWidget {
  final HomeProvider provider;

  const ChargingControls({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160, // Altezza fissa per i controlli verticali
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildVerticalSlider(
            "POTENZA",
            provider.wallboxPwr,
            1.0,
            22.0,
            provider.isSimulating ? (v) {} : provider.updateWallboxPwr,
            "kW",
            Colors.cyanAccent,
            Icons.flash_on,
          ),
          _buildVerticalSlider(
            "SOC INIZIALE",
            provider.currentSoc,
            0,
            100,
            provider.isSimulating ? (v) {} : provider.updateCurrentSoc,
            "%",
            Colors.orangeAccent,
            Icons.battery_0_bar,
          ),
          _buildVerticalSlider(
            "SOC FINALE",
            provider.targetSoc,
            0,
            100,
            provider.isSimulating ? (v) {} : provider.updateTargetSoc,
            "%",
            Colors.greenAccent,
            Icons.battery_full,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color.withOpacity(0.7), size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // Slider VERTICALE
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: unit == "kW" ? 210 : 100,
                activeColor: color,
                inactiveColor: color.withOpacity(0.2),
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Valore con glow
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              "${unit == "%" ? value.toInt() : value.toStringAsFixed(1)}$unit",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                shadows: [
                  Shadow(color: color.withOpacity(0.8), blurRadius: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}