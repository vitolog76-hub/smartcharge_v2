import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';
import 'package:smartcharge_v2/providers/auth_provider.dart';
import 'package:smartcharge_v2/widgets/home/ready_time_card.dart';
import 'package:smartcharge_v2/widgets/home/battery_status_row.dart';
import 'package:smartcharge_v2/widgets/home/stats_row.dart';
import 'package:smartcharge_v2/widgets/home/car_info_row.dart';
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
          appBar: _buildAppBar(context, provider, authProvider),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  ReadyTimeCard(provider: provider),
                  const SizedBox(height: 8),
                  BatteryStatusRow(provider: provider),
                  const SizedBox(height: 8),
                  StatsRow(provider: provider),
                  const SizedBox(height: 8),
                  Expanded(child: ChargingControls(provider: provider)),
                  const SizedBox(height: 8),
                  SimulationButton(provider: provider),
                  const SizedBox(height: 8),
                  ActionButtons(
                    onHomeTap: provider.isSimulating ? () {} : () => _showAddDialog(context, provider, "Home"),
                    onPublicTap: provider.isSimulating ? () {} : () => _showAddDialog(context, provider, "Pubblica"),
                  ),
                  const SizedBox(height: 8),
                  CarInfoRow(provider: provider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, HomeProvider provider, AuthProvider authProvider) {
    return AppBar(
      title: const Text("SMART CHARGE", style: TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.history, color: Colors.blueAccent),
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
          icon: const Icon(Icons.settings, color: Colors.blueAccent),
          onPressed: () async {
            final updated = await Navigator.push(
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
            if (updated == true) {
              await provider.refreshAfterSettings();
            }
          },
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context, HomeProvider provider, String tipo) {
    showDialog(
      context: context,
      builder: (_) => AddChargeDialog(provider: provider, tipo: tipo),
    );
  }
}