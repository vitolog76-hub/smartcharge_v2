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
    
    // Calcola direttamente se è in attesa
    final now = DateTime.now();
    final startTime = provider.calculatedStartDateTime;
    final bool isScheduled = isSimulating && startTime.isAfter(now);

    // DEBUG: stampa i valori per capire
    print('📊 SIM BUTTON - isSimulating: $isSimulating');
    print('📊 SIM BUTTON - startTime: $startTime');
    print('📊 SIM BUTTON - now: $now');
    print('📊 SIM BUTTON - isScheduled: $isScheduled');

    // --- LOGICA DI STATO PER IL FEEDBACK ---
    Color accentColor;
    String statusText;
    IconData statusIcon;

    if (!isSimulating) {
      // Stato Spento (pronto per avviare)
      accentColor = Colors.cyanAccent;
      statusText = "AVVIA";
      statusIcon = Icons.play_arrow_rounded;
    } else if (isScheduled) {
      // Stato IN ATTESA (programmato)
      accentColor = Colors.orangeAccent;
      statusText = "⏰ ${provider.startTimeDisplay}";
      statusIcon = Icons.access_time_filled_rounded;
    } else {
      // Stato In Carica (Attivo)
      accentColor = Colors.redAccent;
      statusText = "⏹️ STOP";
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
            // 1. NEON GLOW AMBIENTALE
            IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: accentColor.withOpacity(0.9), blurRadius: 30, spreadRadius: 1),
                    BoxShadow(color: accentColor.withOpacity(0.4), blurRadius: 60, spreadRadius: 10),
                    BoxShadow(color: accentColor.withOpacity(0.2), blurRadius: 100, spreadRadius: 20),
                  ],
                ),
              ),
            ),

            // 2. VETRO FROSTED
            IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2.0),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.transparent,
                          accentColor.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 3. RIFLESSO GLOSSY
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.48, 0.52, 1.0],
                    colors: [
                      Colors.white.withOpacity(0.35),
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 4. CONTENUTO (Testo e Icona)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  statusIcon,
                  color: Colors.white,
                  size: 32,
                  shadows: [
                    Shadow(color: accentColor, blurRadius: 20),
                    const Shadow(color: Colors.white, blurRadius: 5),
                  ],
                ),
                const SizedBox(width: 15),
                Text(
                  statusText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                    shadows: [
                      Shadow(color: accentColor, blurRadius: 15),
                      Shadow(color: accentColor, blurRadius: 35),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGICA GESTIONE CLICK ---
  void _handleSimulation(BuildContext context) {
    if (provider.isSimulating) {
      // Se è in simulazione (sia in carica che in attesa), ferma tutto
      if (provider.isChargingReal && provider.currentSoc > 20) {
        _showInterruptDialog(context);
      } else {
        provider.stopSimulation();
      }
    } else {
      // Avvia simulazione
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
              side: BorderSide(color: Colors.white.withOpacity(0.2))
          ),
          title: const Text("INTERROMPI", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900)),
          content: Text("Hai caricato fino al ${captureSoc.toStringAsFixed(1)}%. Salvare?", style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () { provider.stopSimulation(); Navigator.pop(ctx); }, child: const Text("SCARTA", style: TextStyle(color: Colors.redAccent))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent.withOpacity(0.3), side: const BorderSide(color: Colors.blueAccent)),
              onPressed: () { provider.stopSimulation(); Navigator.pop(ctx); _showAddDialog(context, "Home", captureSoc); },
              child: const Text("SALVA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, String tipo, double customEndSoc) {
    showDialog(context: context, builder: (_) => AddChargeDialog(provider: provider, tipo: tipo, customEndSoc: customEndSoc));
  }
}