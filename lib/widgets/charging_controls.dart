import 'package:flutter/material.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';

class ChargingControls extends StatelessWidget {
  final HomeProvider provider;

  const ChargingControls({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Padding ridotto leggermente per guadagnare spazio
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            // Evita l'overflow rendendo il contenuto scorrevole se necessario
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 2), // Ridotto da 4 a 2
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
                const SizedBox(height: 2), // Ridotto da 4 a 2
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14), // Ridotto leggermente
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10, // Ridotto per salvare spazio
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(
                "${unit == "%" ? value.toInt() : value.toStringAsFixed(1)}$unit",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildSmallButton(Icons.remove, color, onDecrement),
            const SizedBox(width: 4),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 1.5, // Più sottile
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  activeTrackColor: color,
                  inactiveTrackColor: color.withOpacity(0.1),
                  thumbColor: color,
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  onChanged: onChanged,
                ),
              ),
            ),
            const SizedBox(width: 4),
            _buildSmallButton(Icons.add, color, onIncrement),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 12),
      ),
    );
  }
}