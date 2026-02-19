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
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text(
              "SMART CHARGE",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.black,
            elevation: 0,
            toolbarHeight: 40,
            leading: IconButton(
              icon: const Icon(Icons.history, color: Colors.white70, size: 20),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoryPage(
                    history: provider.chargeHistory,
                    contract: provider.myContract,
                    selectedCar: provider.selectedCar,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white70, size: 20),
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
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  ReadyTimeCard(provider: provider),
                  const SizedBox(height: 8),
                  BatteryStatusRow(provider: provider),
                  const SizedBox(height: 8),
                  StatsRow(provider: provider),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ChargingControls(provider: provider),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: SimulationButton(provider: provider),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _buildCarInfo(context, provider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(16),
                    ),
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
        );
      },
    );
  }

  Widget _buildCarInfo(BuildContext context, HomeProvider provider) {
    return GestureDetector(
      onTap: provider.isSimulating ? null : () => _openCarSelection(context, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.directions_car, color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.selectedCar.model,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    provider.selectedCar.brand,
                    style: const TextStyle(color: Colors.white38, fontSize: 8),
                  ),
                ],
              ),
            ),
            Text(
              "${provider.capacityController.text} kWh",
              style: const TextStyle(color: Colors.white70, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  void _openCarSelection(BuildContext context, HomeProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: Colors.blueAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.directions_car, color: Colors.white70),
                          title: Text(
                            "${car.brand} ${car.model}",
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: Text(
                            "${car.batteryCapacity} kWh",
                            style: const TextStyle(color: Colors.white70),
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
    );
  }

  void _showAddDialog(BuildContext context, HomeProvider provider, String tipo) {
    showDialog(
      context: context,
      builder: (_) => AddChargeDialog(provider: provider, tipo: tipo),
    );
  }
}