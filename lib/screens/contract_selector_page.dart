import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';
import 'package:smartcharge_v2/models/contract_model.dart';
import 'package:smartcharge_v2/screens/bill_scanner_page.dart';

class ContractSelectorPage extends StatelessWidget {
  const ContractSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "I TUOI CONTRATTI",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined, color: Colors.blueAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BillScannerPage(provider: context.read<HomeProvider>())),
              );
            },
          ),
        ],
      ),
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          final contracts = provider.allContracts;
          final activeId = provider.activeContractId;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contracts.length,
            itemBuilder: (context, index) {
              final contract = contracts[index];
              final isActive = contract.id == activeId;

              return _buildContractCard(context, contract, isActive, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildContractCard(BuildContext context, EnergyContract contract, bool isActive, HomeProvider provider) {
    return GestureDetector(
      onTap: () => provider.selectActiveContract(contract.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.blueAccent.withOpacity(0.5) : Colors.white10,
            width: isActive ? 2 : 1,
          ),
          color: isActive ? Colors.blueAccent.withOpacity(0.05) : Colors.white.withOpacity(0.03),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contract.contractName.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              contract.provider,
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (isActive)
                        const Icon(Icons.check_circle, color: Colors.blueAccent, size: 28)
                      else
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 20),
                          onPressed: () => _confirmDelete(context, provider, contract),
                        ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPriceInfo("F1", contract.f1Price, Colors.blueAccent),
                      _buildPriceInfo("F2", contract.f2Price, Colors.orangeAccent),
                      _buildPriceInfo("F3", contract.f3Price, Colors.greenAccent),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInfo(String label, double price, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          "${price.toStringAsFixed(3)}€",
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, HomeProvider provider, EnergyContract contract) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text("Elimina Contratto", style: TextStyle(color: Colors.white)),
        content: Text("Vuoi davvero eliminare '${contract.contractName}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ANNULLA")),
          TextButton(
            onPressed: () {
              provider.deleteContract(contract.id);
              Navigator.pop(context);
            },
            child: const Text("ELIMINA", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}