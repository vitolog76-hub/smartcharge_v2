import 'package:flutter/material.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';

class ChargingControls extends StatelessWidget {
  final HomeProvider provider;

  const ChargingControls({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Ridotto padding verticale da 16 a 8 per salvare spazio
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            // Manteniamo spaceAround per distribuire, ma con meno padding esterno respira meglio
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
          );
        },
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
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                "${unit == "%" ? value.toInt() : value.toStringAsFixed(1)} $unit",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4), // Ridotto da 8 a 4 per compattare verticalmente
        Row(
          children: [
            _buildSmallButton(Icons.remove, color, onDecrement),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2.5, // Ridotto da 4.0 a 2.5 (giusto compromesso)
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8), // Ridotto da 10 a 8
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: color,
                  inactiveTrackColor: color.withOpacity(0.1),
                  thumbColor: color,
                  valueIndicatorColor: color,
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  onChanged: onChanged,
                ),
              ),
            ),
            _buildSmallButton(Icons.add, color, onIncrement),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallButton(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 32, // Ridotto da 36 a 32 per salvare altezza
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 16), // Ridotto size da 18 a 16
        ),
      ),
    );
  }
}