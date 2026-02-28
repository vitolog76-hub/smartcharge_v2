import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';
import 'package:smartcharge_v2/widgets/home/add_charge_dialog.dart';

class SimulationButton extends StatelessWidget {
  final HomeProvider provider;
  const SimulationButton({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final bool isSimulating = provider.isSimulating;
    
    // Calcolo stato temporale
    final now = DateTime.now();
    final startTime = provider.calculatedStartDateTime;
    final bool isScheduled = isSimulating && startTime.isAfter(now);

    // --- LOGICA DI STATO ---
    Color accentColor;
    String statusText;
    IconData statusIcon;

    if (!isSimulating) {
      accentColor = Colors.cyanAccent;
      statusText = "AVVIA";
      statusIcon = Icons.play_arrow_rounded;
    } else if (isScheduled) {
      accentColor = Colors.orangeAccent;
      statusText = provider.startTimeDisplay; // Solo orario per risparmiare spazio
      statusIcon = Icons.access_time_filled_rounded;
    } else {
      accentColor = Colors.redAccent;
      statusText = "STOP";
      statusIcon = Icons.stop_rounded;
    }

    return GestureDetector(
      onTap: () => _handleSimulation(context),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 75,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. NEON GLOW
            IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: accentColor.withOpacity(0.6), blurRadius: 20, spreadRadius: 1),
                  ],
                ),
              ),
            ),

            // 2. VETRO FROSTED
            IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.15),
                          accentColor.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 3. CONTENUTO (Fix per l'overflow dei 140px)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    statusIcon,
                    color: Colors.white,
                    size: 22, // Ridotto da 32
                    shadows: [Shadow(color: accentColor, blurRadius: 10)],
                  ),
                  const SizedBox(width: 8), // Ridotto da 15
                  Flexible(
                    child: Text(
                      statusText,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14, // Ridotto da 20
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5, // Ridotto da 4.0
                        shadows: [
                          Shadow(color: accentColor, blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSimulation(BuildContext context) {
    if (provider.isSimulating) {
      // Se sta caricando davvero (oltre il check temporale) chiediamo conferma
      if (provider.isChargingReal) {
        _showInterruptDialog(context);
      } else {
        // Se è solo programmata (arancione), ferma subito senza dialogo
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
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AlertDialog(
          backgroundColor: const Color(0xFF0A0A0A).withOpacity(0.95),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: BorderSide(color: Colors.white.withOpacity(0.1))
          ),
          title: const Text("INTERROMPI", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900, fontSize: 16)),
          content: Text("Ricarica al ${captureSoc.toStringAsFixed(1)}%. Vuoi salvare la sessione nello storico?", style: const TextStyle(color: Colors.white70, fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () { 
                provider.stopSimulation(); 
                Navigator.pop(ctx); 
              }, 
              child: const Text("SCARTA", style: TextStyle(color: Colors.redAccent))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                side: const BorderSide(color: Colors.blueAccent)
              ),
              onPressed: () { 
                provider.stopSimulation(); 
                Navigator.pop(ctx); 
                _showAddDialog(context, "Home", captureSoc); 
              },
              child: const Text("SALVA", style: TextStyle(color: Colors.white))
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, String tipo, double customEndSoc) {
    showDialog(
      context: context, 
      builder: (_) => AddChargeDialog(
        provider: provider, 
        tipo: tipo, 
        customEndSoc: customEndSoc
      )
    );
  }
}