import 'package:flutter/material.dart';
import 'package:smartcharge_v2/core/constants.dart';

class StatusCard extends StatelessWidget {
  final Duration duration;
  final double energy;
  final double power;

  const StatusCard({
    super.key, 
    required this.duration, 
    required this.energy, 
    required this.power
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Rimosso width: double.infinity per permettere l'affiancamento
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.accent.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // RIGA 1: Icona + Tempo (Glow)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                "${duration.inHours}h ${duration.inMinutes % 60}m",
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: AppColors.accent,
                  shadows: [
                    Shadow(
                      color: AppColors.accent.withOpacity(0.7),
                      blurRadius: 12, // EFFETTO GLOW
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // RIGA 2: Statistiche piccole affiancate
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSmallStat("ENERGIA", "${energy.toStringAsFixed(1)} kWh"),
              const SizedBox(width: 12),
              _buildSmallStat("POTENZA", "${power.toStringAsFixed(1)} kW"),
            ],
          ),
        ],
      ),
    );
  }

  // Mantenuta la tua funzione originale ma resa più compatta
  Widget _buildSmallStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 7)),
        Text(
          value, 
          style: const TextStyle(
            color: Colors.white70, 
            fontWeight: FontWeight.bold, 
            fontSize: 11
          )
        ),
      ],
    );
  }
}