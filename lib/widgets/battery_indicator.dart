import 'package:flutter/material.dart';

class BatteryIndicator extends StatelessWidget {
  final double percent;

  const BatteryIndicator({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    Color batteryColor = _getBatteryColor(percent);

    return Container(
      height: 45,
      width: double.infinity, // Si adatta allo spazio dell'Expanded
      child: Stack(
        alignment: Alignment.centerLeft,
        clipBehavior: Clip.none,
        children: [
          // SFONDO E BORDO (Guscio batteria)
          Container(
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10, width: 2),
            ),
          ),
          
          // RIEMPIMENTO ELETTRIZZANTE
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: FractionallySizedBox(
              widthFactor: percent / 100, // Riempimento reale millimetrico
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      batteryColor.withOpacity(0.9),
                      batteryColor,
                      batteryColor.withOpacity(0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: batteryColor.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // BECCUCCIO (Polo positivo a destra)
          Positioned(
            right: -6,
            child: Container(
              width: 5,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
              ),
            ),
          ),

          // TESTO ORIZZONTALE TECH
          Center(
            child: Text(
              "${percent.toInt()}%",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 0.5,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBatteryColor(double p) {
    if (p > 75) return const Color(0xFF00E676); // Verde neon
    if (p > 25) return const Color(0xFFFFAB40); // Arancio neon
    return const Color(0xFFFF5252); // Rosso neon
  }
}