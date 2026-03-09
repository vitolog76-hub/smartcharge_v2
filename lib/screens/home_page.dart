import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';
import 'package:smartcharge_v2/providers/auth_provider.dart';
import 'package:smartcharge_v2/widgets/home/ready_time_card.dart';
import 'package:smartcharge_v2/widgets/home/battery_status_row.dart';
import 'package:smartcharge_v2/widgets/home/stats_row.dart';
import 'package:smartcharge_v2/widgets/home/simulation_button.dart';
import 'package:smartcharge_v2/widgets/home/add_charge_dialog.dart';
import 'package:smartcharge_v2/widgets/charging_controls.dart';
import 'package:smartcharge_v2/widgets/action_buttons.dart';
import 'package:smartcharge_v2/screens/history_page.dart';
import 'package:smartcharge_v2/screens/settings_page.dart';
import 'package:smartcharge_v2/l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static bool _completionDialogShown = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!; // 🔥 NUOVO
    
    return WillPopScope(
      onWillPop: () async {
        final provider = Provider.of<HomeProvider>(context, listen: false);
        await provider.salvaTuttiParametri();
        return true;
      },
      child: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          if (!provider.carsLoaded) {
            return const Scaffold(
              backgroundColor: Color(0xFF0A0F1E),
              body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
            );
          }

          // Dialog di completamento sincronizzato
          if (provider.shouldShowCompletionDialog && !_completionDialogShown) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                _showCompletionDialog(context, provider, l10n); // 🔥 MODIFICATO
              }
            });
          }

          return Scaffold(
            backgroundColor: const Color.fromARGB(255, 3, 3, 50),
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.cyanAccent, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text( // 🔥 MODIFICATO
                  l10n.appTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 2.5,
                    color: Colors.white,
                  ),
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 50,
              leading: IconButton(
                icon: const Icon(Icons.history, color: Colors.white70, size: 22),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistoryPage(
                      history: provider.chargeHistory,
                      contract: provider.myContract,
                      selectedCar: provider.selectedCar,
                      onHistoryChanged: (updatedHistory) {
                        provider.chargeHistory = updatedHistory;
                        provider.saveHistory();
                      },
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white70, size: 22),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsPage(
                          contract: provider.myContract,
                          selectedCar: provider.selectedCar,
                          batteryValue: provider.capacityController.text,
                          authProvider: authProvider,
                          homeProvider: provider,
                        ),
                      ),
                    );
                    await provider.refreshAfterSettings();
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Stack(
              children: [
                // SFONDI GLOW
                Positioned(
                  top: -50,
                  left: -50,
                  child: _buildGlowSphere(200, Colors.blueAccent.withOpacity(0.12)),
                ),
                Positioned(
                  bottom: 100,
                  right: -80,
                  child: _buildGlowSphere(250, Colors.amberAccent.withOpacity(0.07)),
                ),
                
                // CONTENUTO PRINCIPALE
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),

                          // --- SEZIONE SALUTO PERSONALE ---
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, bottom: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${l10n.hello}, ${provider.globalUserName.toUpperCase()}!", // 🔥 MODIFICATO
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    shadows: [
                                      Shadow(color: Colors.blueAccent, blurRadius: 15),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.electric_bolt_rounded, 
                                      color: Colors.cyanAccent.withOpacity(0.6), 
                                      size: 14
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${l10n.contract}: ${provider.myContract.contractName.toUpperCase()}", // 🔥 MODIFICATO
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // --- CARDS PRINCIPALI ---
                          _glassContainer(child: ReadyTimeCard(provider: provider)),
                          const SizedBox(height: 12),
                          
                          BatteryStatusRow(
  provider: provider,
  l10n: l10n, 
),
                          const SizedBox(height: 12),
                          
                          StatsRow(
  provider: provider,
  l10n: l10n, 
),
                          const SizedBox(height: 12),

                          // 🔥 AVVISO DI RALLENTAMENTO RICARICA
                          if (provider.showTaperingWarning)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber.withOpacity(0.15),
                                    Colors.orange.withOpacity(0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.amber.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      provider.targetSoc > 90 
                                          ? Icons.speed_rounded 
                                          : Icons.info_outline_rounded,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          provider.targetSoc > 90 
                                              ? l10n.taperingSignificant // 🔥 MODIFICATO
                                              : l10n.taperingSlowdown, // 🔥 MODIFICATO
                                          style: const TextStyle(
                                            color: Colors.amber,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          provider.targetSoc > 90 
                                              ? l10n.taperingWarning20 // 🔥 MODIFICATO
                                              : l10n.taperingWarning60, // 🔥 MODIFICATO
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 12,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // CONTROLLI RICARICA
                          _glassContainer(
                            blur: 20,
                            opacity: 0.08,
                            child: ChargingControls(provider: provider),
                          ),
                          
                          const SizedBox(height: 12),

                          _buildBatteryCoach(provider, l10n), // 🔥 MODIFICATO

                          const SizedBox(height: 12),
                          
                          // RIGA SIMULAZIONE E INFO AUTO
                          Row(
                            children: [
                              Expanded(
                                flex: 12,
                                child: SimulationButton(
  provider: provider,
  l10n: l10n,
),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 18,
                                child: _buildCarInfo(context, provider),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // PULSANTI AZIONE RAPIDA
                          _glassContainer(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: ActionButtons(
                              onHomeTap: provider.isSimulating 
                                  ? () {} 
                                  : () => _showAddDialog(context, provider, l10n.home, l10n), // 🔥 MODIFICATO
                              onPublicTap: provider.isSimulating 
                                  ? () {} 
                                  : () => _showAddDialog(context, provider, l10n.public, l10n), // 🔥 MODIFICATO
                             l10n: l10n,
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          const SizedBox(height: 30), // Padding finale per lo scroll
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGETS DI SUPPORTO ---

  void _showCompletionDialog(BuildContext context, HomeProvider provider, AppLocalizations l10n) { // 🔥 MODIFICATO
    _completionDialogShown = true;
    
    // Salvataggio dei dati (popola lastSavedEnergy e lastSavedCost)
    provider.saveCurrentCharge();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text( // 🔥 MODIFICATO
            l10n.chargingComplete,
            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 50),
              const SizedBox(height: 16),
              Text(
                '${l10n.finalSoc}: ${provider.currentSoc.toStringAsFixed(1)}%', // 🔥 MODIFICATO
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                '${l10n.energy}: ${provider.lastSavedEnergy.toStringAsFixed(1)} ${l10n.kwh}', // 🔥 MODIFICATO
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${l10n.costEuro}: ${provider.lastSavedCost.toStringAsFixed(2)} ${l10n.euro}', // 🔥 MODIFICATO
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  provider.resetCompletionDialog();
                  Navigator.of(ctx).pop();
                  _completionDialogShown = false;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                  foregroundColor: Colors.cyanAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.close), // 🔥 MODIFICATO (dovrai aggiungere "close" in ARB)
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))} h";
  }

  Widget _glassContainer({required Widget child, double blur = 15, double opacity = 0.05, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlowSphere(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 20)],
      ),
    );
  }

  Widget _buildCarInfo(BuildContext context, HomeProvider provider) {
    return GestureDetector(
      onTap: provider.isSimulating ? null : () => _openCarSelection(context, provider),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.amberAccent.withOpacity(0.15), blurRadius: 15, spreadRadius: 1)],
        ),
        child: _glassContainer(
          opacity: 0.12,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.electric_car_rounded, color: Colors.amberAccent, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      provider.selectedCar.model.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    Text(
                      provider.selectedCar.brand,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.amberAccent.withOpacity(0.6), fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatteryCoach(HomeProvider provider, AppLocalizations l10n) { // 🔥 MODIFICATO
    String title;
    Color accentColor;
    IconData icon;

    // Colori e Titoli cambiano per chimica, ma il TESTO (advice) sarà dinamico
    switch (provider.batteryChemistry) {
      case "LFP":
        title = l10n.batteryCoachLfp; // 🔥 MODIFICATO
        accentColor = Colors.greenAccent;
        icon = Icons.analytics_outlined;
        break;
      case "NMC / NCA":
        title = l10n.batteryCoachNmc; // 🔥 MODIFICATO
        accentColor = Colors.orangeAccent;
        icon = Icons.health_and_safety_outlined;
        break;
      default:
        title = l10n.batteryCoachGeneric; // 🔥 MODIFICATO
        accentColor = Colors.blueAccent;
        icon = Icons.info_outline;
    }

    return _glassContainer(
      opacity: 0.1,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: accentColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(
  provider.getSmartBatteryAdvice(l10n), 
  style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openCarSelection(BuildContext context, HomeProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF121212).withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ListView.builder(
                controller: scrollController,
                itemCount: provider.allCars.length,
                itemBuilder: (context, index) {
                  final car = provider.allCars[index];
                  return ListTile(
                    title: Text(car.model, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(car.brand, style: const TextStyle(color: Colors.white70)),
                    trailing: Text("${car.batteryCapacity} kWh", style: const TextStyle(color: Colors.amberAccent)),
                    onTap: () {
                      provider.selectCar(car);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
void _showAddDialog(BuildContext context, HomeProvider provider, String tipo, AppLocalizations l10n) {
  showDialog(
    context: context, 
    builder: (_) => AddChargeDialog(
      provider: provider, 
      tipo: tipo,
      l10n: l10n, // 🔥 AGGIUNGI QUESTO
    )
  );
} 

class _PulseIcon extends StatefulWidget {
  final Widget child;
  const _PulseIcon({required this.child});
  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: Tween(begin: 0.4, end: 1.0).animate(_controller), child: widget.child);
  }
}