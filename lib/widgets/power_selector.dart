import 'package:flutter/material.dart';
import 'package:smartcharge_v2/core/constants.dart';

class PowerSlider extends StatelessWidget {
  final double currentPower;
  final ValueChanged<double> onPowerChanged;

  const PowerSlider({
    super.key, 
    required this.currentPower, 
    required this.onPowerChanged
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Potenza Wallbox", style: TextStyle(color: Colors.white70, fontSize: 13)),
            Text(
              "${currentPower.toStringAsFixed(1)} kW", 
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)
            ),
          ],
        ),
        Slider(
          value: currentPower,
          min: 1.0,
          max: 22.0,
          divisions: 210, // Permette step di 0.1 kW
          activeColor: AppColors.accent,
          inactiveColor: Colors.white10,
          onChanged: (val) => onPowerChanged(double.parse(val.toStringAsFixed(1))),
        ),
      ],
    );
  }
}