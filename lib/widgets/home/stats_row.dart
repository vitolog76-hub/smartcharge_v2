import 'package:flutter/material.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';
import 'package:smartcharge_v2/services/cost_calculator.dart';
import 'package:smartcharge_v2/l10n/app_localizations.dart';

class StatsRow extends StatelessWidget {
  final HomeProvider provider;
  final AppLocalizations l10n;

  const StatsRow({
    super.key, 
    required this.provider,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calcoliamo il costo totale reale usando la variabile corretta del provider
    final double costoTotaleReale = CostCalculator.calculate(
      totalKwh: provider.energyNeeded,
      wallboxPower: provider.wallboxPwr,
      startTime: TimeOfDay.now(),
      date: DateTime.now(),
      contract: provider.myContract,
    );

    // 2. Calcoliamo il prezzo unitario finito (Materia + Spread + Perdite + Accise + IVA)
    final double prezzoUnitarioFinito = CostCalculator.getVariableKwhPrice(
      provider.myContract.f1Price,
      provider.myContract.spread,
      vat: provider.myContract.vat ?? 10.0,
    );

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
          // --- COLONNA COSTO ---
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.euro, color: Colors.greenAccent, size: 16),
                const SizedBox(height: 4),
                Text(
                  "${costoTotaleReale.toStringAsFixed(2)} €",
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    shadows: [Shadow(color: Colors.greenAccent, blurRadius: 8)],
                  ),
                ),
                Text(
                  "${l10n.finalPrice}: ${prezzoUnitarioFinito.toStringAsFixed(3)}/kWh",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.greenAccent.withOpacity(0.5), 
                    fontSize: 7,
                    fontWeight: FontWeight.w500
                  ),
                ),
                Text(
                  l10n.cost,
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
              ],
            ),
          ),
          
          // --- COLONNA DURATA ---
          Expanded(
            child: _buildStatItem(
              l10n.duration,
              "${provider.duration.inHours}h ${provider.duration.inMinutes % 60}m",
              Colors.blueAccent,
              Icons.timer,
            ),
          ),
          
          // --- COLONNA INIZIO ---
          Expanded(
            child: _buildStatItem(
              l10n.start,
              provider.startTimeDisplay,
              Colors.orangeAccent,
              Icons.schedule,
            ),
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
        const SizedBox(height: 10), 
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 9),
        ),
      ],
    );
  }
}