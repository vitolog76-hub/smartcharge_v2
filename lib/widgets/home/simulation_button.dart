import 'package:flutter/material.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';
import 'package:smartcharge_v2/widgets/home/add_charge_dialog.dart';

class SimulationButton extends StatelessWidget {
  final HomeProvider provider;

  const SimulationButton({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40, // 🔥 RIDOTTO da 56 a 40
      child: ElevatedButton.icon(
        onPressed: () => _handleSimulation(context),
        icon: Icon(provider.isSimulating ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 16), // 🔥 RIDOTTO
        label: Text(
          provider.isSimulating ? "STOP" : "AVVIA",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), // 🔥 RIDOTTO
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: provider.isSimulating ? Colors.redAccent : Colors.blueAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _handleSimulation(BuildContext context) {
    if (provider.isSimulating) {
      if (provider.isChargingReal && provider.currentSoc > 20) {
        _showInterruptDialog(context);
      } else {
        provider.stopSimulation();
      }
    } else {
      provider.startSimulation();
    }
  }

  void _showInterruptDialog(BuildContext context) {
    final captureSoc = provider.currentSoc;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "RICARICA INTERROTTA",
          style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)
        ),
        content: Text(
          "Hai caricato fino al ${captureSoc.toStringAsFixed(1)}%. Vuoi salvare?"
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.stopSimulation();
              Navigator.pop(ctx);
            },
            child: const Text("SCARTA", style: TextStyle(color: Colors.redAccent))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              provider.stopSimulation();
              Navigator.pop(ctx);
              _showAddDialog(context, "Home", captureSoc);
            },
            child: const Text("SALVA")
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, String tipo, double customEndSoc) {
    showDialog(
      context: context,
      builder: (_) => AddChargeDialog(
        provider: provider,
        tipo: tipo,
        customEndSoc: customEndSoc,
      ),
    );
  }
}