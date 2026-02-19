import 'package:flutter/material.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';

class ChargingControls extends StatelessWidget {
  final HomeProvider provider;

  const ChargingControls({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSliderRow(
            label: "POTENZA",
            value: provider.wallboxPwr,
            min: 1.0,
            max: 22.0,
            unit: "kW",
            color: Colors.blueAccent,
            icon: Icons.flash_on,
            onChanged: provider.isSimulating ? (v) {} : provider.updateWallboxPwr,
            onIncrement: () {
              if (provider.wallboxPwr + 0.1 <= 22.0) {
                provider.updateWallboxPwr(provider.wallboxPwr + 0.1);
              }
            },
            onDecrement: () {
              if (provider.wallboxPwr - 0.1 >= 1.0) {
                provider.updateWallboxPwr(provider.wallboxPwr - 0.1);
              }
            },
          ),
          const SizedBox(height: 16),
          _buildSliderRow(
            label: "SOC INIZIALE",
            value: provider.currentSoc,
            min: 0,
            max: 100,
            unit: "%",
            color: Colors.orangeAccent,
            icon: Icons.battery_0_bar,
            onChanged: provider.isSimulating ? (v) {} : provider.updateCurrentSoc,
            onIncrement: () {
              if (provider.currentSoc + 1 <= 100) {
                provider.updateCurrentSoc(provider.currentSoc + 1);
              }
            },
            onDecrement: () {
              if (provider.currentSoc - 1 >= 0) {
                provider.updateCurrentSoc(provider.currentSoc - 1);
              }
            },
          ),
          const SizedBox(height: 16),
          _buildSliderRow(
            label: "SOC FINALE",
            value: provider.targetSoc,
            min: 0,
            max: 100,
            unit: "%",
            color: Colors.greenAccent,
            icon: Icons.battery_full,
            onChanged: provider.isSimulating ? (v) {} : provider.updateTargetSoc,
            onIncrement: () {
              if (provider.targetSoc + 1 <= 100) {
                provider.updateTargetSoc(provider.targetSoc + 1);
              }
            },
            onDecrement: () {
              if (provider.targetSoc - 1 >= 0) {
                provider.updateTargetSoc(provider.targetSoc - 1);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required Color color,
    required IconData icon,
    required Function(double) onChanged,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label e icona
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            // Valore
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                "${unit == "%" ? value.toInt() : value.toStringAsFixed(1)}$unit",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Slider e pulsanti
        Row(
          children: [
            // Pulsante -
            InkWell(
              onTap: onDecrement,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(
                  Icons.remove,
                  color: color,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Slider - FLUIDO senza divisions
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                  activeTrackColor: color,
                  inactiveTrackColor: color.withOpacity(0.2),
                  thumbColor: color,
                  overlayColor: color.withOpacity(0.2),
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: null, // 🔥 NESSUNA DIVISIONE = FLUIDO
                  onChanged: onChanged,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Pulsante +
            InkWell(
              onTap: onIncrement,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(
                  Icons.add,
                  color: color,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}