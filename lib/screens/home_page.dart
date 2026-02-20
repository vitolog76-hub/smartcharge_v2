import 'dart:ui'; // Fondamentale per l'effetto Glass/Blur
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        if (!provider.carsLoaded) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
          );
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
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              Positioned(top: -50, left: -50, child: _buildGlowSphere(200, Colors.blueAccent.withOpacity(0.12))),
              Positioned(bottom: 100, right: -80, child: _buildGlowSphere(250, Colors.amberAccent.withOpacity(0.07))),

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
                            flex: 1, // Mantiene il pulsante simulazione compatto
                            child: _glassContainer(child: SimulationButton(provider: provider)),
                          ),
                          const SizedBox(width: 12),
                          // --- PULSANTE AUTO PIÙ GRANDE (Flex 3) ---
                          Expanded(
                            flex: 3, 
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
          boxShadow: [
            BoxShadow(
              color: Colors.amberAccent.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: _glassContainer(
          opacity: 0.15,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Padding aumentato
          child: Row(
            children: [
              const Icon(Icons.electric_car_rounded, color: Colors.amberAccent, size: 28), // Icona più grande
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      provider.selectedCar.model.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.amberAccent, 
                        fontSize: 14, // Font aumentato
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      provider.selectedCar.brand,
                      style: TextStyle(color: Colors.amberAccent.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withOpacity(0.1),
                  border: Border.all(color: Colors.amberAccent.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${provider.capacityController.text} kWh",
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
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
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    "SELEZIONA VEICOLO",
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
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
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.directions_car, color: Colors.white70),
                            title: Text(
                              "${car.brand} ${car.model}",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            trailing: Text(
                              "${car.batteryCapacity} kWh",
                              style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                            ),
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
    showDialog(
      context: context,
      builder: (_) => AddChargeDialog(provider: provider, tipo: tipo),
    );
  }
}