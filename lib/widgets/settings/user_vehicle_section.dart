import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:origo/l10n/app_localizations.dart';
import 'package:origo/models/car_model.dart';
import 'expandable_section.dart';

class UserVehicleSection extends StatelessWidget {
  final TextEditingController nameController;
  final CarModel selectedCar;
  final TextEditingController batteryController;
  final String selectedBatteryType;
  final Function(String) onBatteryTypeChanged;
  final bool isExpanded;
  final Animation<double> animation;
  final VoidCallback onToggle;

  const UserVehicleSection({
    super.key,
    required this.nameController,
    required this.selectedCar,
    required this.batteryController,
    required this.selectedBatteryType,
    required this.onBatteryTypeChanged,
    required this.isExpanded,
    required this.animation,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return ExpandableSection(
      title: "DATI UTENTE E VEICOLO",
      icon: Icons.directions_car,
      isExpanded: isExpanded,
      animation: animation,
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserField(l10n),
            const SizedBox(height: 16),
            _buildCarField(l10n),
            const SizedBox(height: 16),
            _buildBatteryField(l10n),
            const SizedBox(height: 16),
            _buildChemistryField(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildUserField(AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_outline, color: Colors.blueAccent),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.userName.toUpperCase(),
                style: const TextStyle(color: Colors.blueAccent, fontSize: 10),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCarField(AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.directions_car, color: Colors.greenAccent),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.selectedCar.toUpperCase(),
                style: const TextStyle(color: Colors.greenAccent, fontSize: 10),
              ),
              const SizedBox(height: 4),
              Text(
                selectedCar.model.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBatteryField(AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.bolt, color: Colors.orangeAccent),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.batteryCapacity.toUpperCase(),
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 10),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: batteryController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const Text("kWh", style: TextStyle(color: Colors.white38)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChemistryField(AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.science, color: Colors.purple),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.batteryChemistry.toUpperCase(),
                style: const TextStyle(color: Colors.purple, fontSize: 10),
              ),
              const SizedBox(height: 4),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedBatteryType,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0F172A),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: "NMC / NCA", child: Text("NMC / NCA")),
                    DropdownMenuItem(value: "LFP", child: Text("LFP")),
                    DropdownMenuItem(value: "UNKNOWN", child: Text("Sconosciuta")),
                  ],
                  onChanged: (val) => onBatteryTypeChanged(val!),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}