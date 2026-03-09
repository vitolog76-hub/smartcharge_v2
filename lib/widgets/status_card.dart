import 'package:flutter/material.dart';
import 'package:smartcharge_v2/core/constants.dart';
import 'package:smartcharge_v2/l10n/app_localizations.dart';

class StatusCard extends StatelessWidget {
  final Duration duration;
  final double energy;
  final double power;
  final AppLocalizations l10n;

  const StatusCard({
    super.key, 
    required this.duration, 
    required this.energy, 
    required this.power,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      blurRadius: 12,
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
              _buildSmallStat(
                l10n.energy, 
                "${energy.toStringAsFixed(1)} ${l10n.kwh}"
              ),
              const SizedBox(width: 12),
              _buildSmallStat(
                l10n.power, 
                "${power.toStringAsFixed(1)} kW"
              ),
            ],
          ),
        ],
      ),
    );
  }

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