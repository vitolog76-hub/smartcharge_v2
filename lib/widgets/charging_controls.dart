import 'package:flutter/material.dart';
import 'package:smartcharge_v2/core/constants.dart';

class ChargingControls extends StatelessWidget {
  final double wallboxPwr;
  final double currentSoc;
  final double targetSoc;
  final Function(double) onPwrChanged;
  final Function(double) onCurrentSocChanged;
  final Function(double) onTargetSocChanged;

  const ChargingControls({
    super.key,
    required this.wallboxPwr,
    required this.currentSoc,
    required this.targetSoc,
    required this.onPwrChanged,
    required this.onCurrentSocChanged,
    required this.onTargetSocChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Passiamo 'context' come primo argomento a ogni controllo
          _buildVerticalControl(context, "Potenza", wallboxPwr, 0.5, 7.4, 0.1, onPwrChanged, "kW", Colors.cyanAccent),
          _buildVerticalControl(context, "SoC Iniziale", currentSoc, 0, 100, 1, onCurrentSocChanged, "%", Colors.orangeAccent),
          _buildVerticalControl(context, "SoC Finale", targetSoc, 0, 100, 1, onTargetSocChanged, "%", Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _buildVerticalControl(
    BuildContext context, // AGGIUNTO BuildContext qui
    String label, 
    double value, 
    double min, 
    double max, 
    double step, 
    Function(double) onChanged, 
    String unit,
    Color color
  ) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 8, color: Colors.white54, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildStepBtn(Icons.add, () {
          if (value + step <= max) onChanged(double.parse((value + step).toStringAsFixed(1)));
        }, color),
        SizedBox(
          height: 100,
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              // Ora context è definito e l'errore sparisce
              data: SliderTheme.of(context).copyWith(
                thumbColor: color,
                activeTrackColor: color,
                inactiveTrackColor: color.withOpacity(0.1),
                overlayColor: color.withOpacity(0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 4,
              ),
              child: Slider(
                value: value, 
                min: min, 
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        _buildStepBtn(Icons.remove, () {
          if (value - step >= min) onChanged(double.parse((value - step).toStringAsFixed(1)));
        }, color),
        const SizedBox(height: 10),
        Text(
          "${unit == "%" ? value.toInt() : value.toStringAsFixed(1)} $unit",
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            shadows: [Shadow(color: color.withOpacity(0.8), blurRadius: 10)],
          ),
        ),
      ],
    );
  }

  Widget _buildStepBtn(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.05),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, size: 18, color: color.withOpacity(0.7)),
      ),
    );
  }
}