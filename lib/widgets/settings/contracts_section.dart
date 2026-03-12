import 'package:flutter/material.dart';
import 'package:origo/l10n/app_localizations.dart';
import 'package:origo/models/contract_model.dart';
import 'package:origo/providers/home_provider.dart';
import 'package:origo/screens/contract_summary_page.dart';
import 'package:origo/pages/add_contract_page.dart';
import 'package:provider/provider.dart';
import 'expandable_section.dart';

class ContractsSection extends StatelessWidget {
  final TextEditingController providerController;
  final TextEditingController f1Controller;
  final bool isMonorario;
  final Function(EnergyContract) onContractSelected;
  final bool isExpanded;
  final Animation<double> animation;
  final VoidCallback onToggle;

  const ContractsSection({
    super.key,
    required this.providerController,
    required this.f1Controller,
    required this.isMonorario,
    required this.onContractSelected,
    required this.isExpanded,
    required this.animation,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return ExpandableSection(
      title: "GESTIONE CONTRATTI ENERGIA",
      icon: Icons.pie_chart,
      isExpanded: isExpanded,
      animation: animation,
      onTap: onToggle,
      child: Consumer<HomeProvider>(
        builder: (context, homeProv, child) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.yourPlans.toUpperCase(),
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.pie_chart, color: Colors.cyanAccent),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ContractSummaryPage()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.cyanAccent),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddContractPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ...homeProv.allContracts.map((contract) => 
                _buildContractTile(context, contract, homeProv)
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContractTile(BuildContext context, EnergyContract contract, HomeProvider homeProv) {
    final isSelected = contract.id == homeProv.activeContractId;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.cyanAccent : Colors.white10,
        ),
        color: isSelected ? Colors.cyanAccent.withOpacity(0.1) : null,
      ),
      child: ListTile(
        title: Text(
          contract.contractName,
          style: TextStyle(
            color: isSelected ? Colors.cyanAccent : Colors.white,
          ),
        ),
        subtitle: Text(
          "${contract.provider} • ${contract.f1Price}€/kWh",
          style: const TextStyle(color: Colors.white38),
        ),
        selected: isSelected,
        onTap: () {
          homeProv.selectActiveContract(contract.id);
          onContractSelected(contract);
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white38),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddContractPage(contractToEdit: contract),
                  ),
                );
              },
            ),
            if (homeProv.allContracts.length > 1)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => homeProv.deleteContract(contract.id),
              ),
          ],
        ),
      ),
    );
  }
}