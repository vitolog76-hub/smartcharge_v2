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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static bool _completionDialogShown = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
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
              backgroundColor: Color(0xFF050507),
              body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
            );
          }

          if (provider.shouldShowCompletionDialog && !_completionDialogShown) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                _showCompletionDialog(context, provider);
              }
            });
          }

          return Scaffold(
            backgroundColor: const Color(0xFF050507),
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.cyanAccent, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  "SMART CHARGE",
                  style: TextStyle(
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
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _glassContainer(child: ReadyTimeCard(provider: provider)),
                        const SizedBox(height: 12),
                        BatteryStatusRow(provider: provider),
                        const SizedBox(height: 12),
                        StatsRow(provider: provider),
                        const SizedBox(height: 12),
                        Expanded(
                          flex: 4,
                          child: _glassContainer(
                            blur: 20,
                            opacity: 0.08,
                            child: ChargingControls(provider: provider),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 12,
                              child: _glassContainer(child: SimulationButton(provider: provider)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 18,
                              child: _buildCarInfo(context, provider),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _glassContainer(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ActionButtons(
                            onHomeTap: provider.isSimulating ? () {} : () => _showAddDialog(context, provider, "Home"),
                            onPublicTap: provider.isSimulating ? () {} : () => _showAddDialog(context, provider, "Pubblica"),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildEditCapacityTile(context, provider),
                      ],
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

  Widget _buildEditCapacityTile(BuildContext context, HomeProvider provider) {
    return GestureDetector(
      onTap: () => _showEditCapacityDialog(context, provider),
      child: _glassContainer(
        opacity: 0.1,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const _PulseIcon(
              child: Icon(Icons.bolt_rounded, color: Colors.cyanAccent, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${provider.capacityController.text} kWh",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      shadows: [Shadow(color: Colors.blueAccent, blurRadius: 8)],
                    ),
                  ),
                  const Text(
                    "CAPACITÀ BATTERIA ATTUALE",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_note_rounded, color: Colors.white.withOpacity(0.3), size: 22),
          ],
        ),
      ),
    );
  }

  void _showEditCapacityDialog(BuildContext context, HomeProvider provider) {
    final TextEditingController tempController = TextEditingController(text: provider.capacityController.text);
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: const Text(
            "SET CAPACITÀ",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5),
          ),
          content: TextField(
            controller: tempController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              suffixText: "kWh",
              suffixStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CHIUDI", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                if (tempController.text.isNotEmpty) {
                  provider.capacityController.text = tempController.text;
                  provider.notifyListeners();
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                foregroundColor: Colors.cyanAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.cyanAccent),
                ),
              ),
              child: const Text("AGGIORNA", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, HomeProvider provider) {
    _completionDialogShown = true;
    provider.saveCurrentCharge();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '⚡ Ricarica Completata!',
            style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 50),
              const SizedBox(height: 16),
              Text(
                'SOC finale: ${provider.targetSoc.toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Text(
                'Energia: ${provider.energyNeeded.toStringAsFixed(1)} kWh',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Text(
                'Durata: ${_formatDuration(provider.duration)}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                provider.resetCompletionDialog();
                Navigator.of(ctx).pop();
                _completionDialogShown = false;
              },
              child: const Text('OK', style: TextStyle(color: Colors.cyanAccent)),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return '$hours:$minutes h';
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

  void _openCarSelection(BuildContext context, HomeProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF121212).withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                  const Text("SELEZIONA VEICOLO", style: TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: provider.allCars.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final car = provider.allCars[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.05))),
                          child: ListTile(
                            leading: const Icon(Icons.directions_car, color: Colors.white70),
                            title: Text("${car.brand} ${car.model}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            trailing: Text("${car.batteryCapacity} kWh", style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                            onTap: () { 
                              provider.selectCar(car); 
                              Navigator.pop(context); 
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, HomeProvider provider, String tipo) {
    showDialog(context: context, builder: (_) => AddChargeDialog(provider: provider, tipo: tipo));
  }
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