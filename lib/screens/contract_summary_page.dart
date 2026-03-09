import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:origo/models/contract_model.dart';
import 'package:origo/providers/home_provider.dart';
import 'package:origo/services/cost_calculator.dart'; 

class ContractSummaryPage extends StatelessWidget {
  const ContractSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();
    final contract = provider.myContract;
    
    // Dati storici
    final double totalKwh = provider.chargeHistory.fold(0.0, (sum, s) => sum + s.kwh);
    final double totalCost = provider.chargeHistory.fold(0.0, (sum, s) => sum + s.cost);
    
    // Recuperiamo i breakdown dal nuovo CostCalculator
    final variableBreakdown = CostCalculator.getPriceBreakdown(contract);
    final fixedBreakdown = CostCalculator.getFixedBreakdown(contract);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("RESOCONTO CONTRATTO", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blueAccent, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(contract),
            const SizedBox(height: 24),
            
            // 1. SEZIONE TRASPARENZA ARERA (Costi Variabili)
            _buildSectionTitle("SCOMPOSIZIONE COSTO VARIABILE", Icons.analytics_outlined),
            _buildVariableDetailCard(variableBreakdown),
            
            const SizedBox(height: 24),
            
            // 2. SEZIONE CONFRONTO GESTORI (Costi Fissi)
            _buildSectionTitle("COSTI FISSI E POTENZA", Icons.account_balance_wallet_outlined),
            _buildFixedDetailCard(fixedBreakdown),
            
            const SizedBox(height: 24),
            
            // 3. RIEPILOGO CONSUMI REALI
            _buildSectionTitle("RIEPILOGO STORICO", Icons.history),
            _buildConsumptionSummary(totalKwh, totalCost),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 14),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        ],
      ),
    );
  }

  Widget _buildVariableDetailCard(Map<String, double> breakdown) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: breakdown.entries.map((entry) {
          final bool isTotal = entry.key.contains("FINITO");
          final bool isIva = entry.key.contains("IVA"); // Identifica la riga IVA

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key, 
                  style: TextStyle(
                    color: isTotal ? Colors.white : (isIva ? Colors.white70 : Colors.white54), 
                    fontSize: 13, 
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    fontStyle: isIva ? FontStyle.italic : FontStyle.normal,
                  )
                ),
                Text(
                  "${entry.value.toStringAsFixed(4)} €/kWh",
                  style: TextStyle(
                    color: isTotal 
                        ? Colors.greenAccent 
                        : (isIva ? Colors.amberAccent.withOpacity(0.8) : Colors.white), 
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, 
                    fontSize: 13
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFixedDetailCard(Map<String, double> breakdown) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: breakdown.entries.map((entry) {
          final bool isTotal = entry.key.contains("TOTALE");
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.key, style: TextStyle(color: isTotal ? Colors.white : Colors.white54, fontSize: 13, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
                Text(
                  "${entry.value.toStringAsFixed(2)} €/mese",
                  style: TextStyle(color: isTotal ? Colors.blueAccent : Colors.white, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: 13),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConsumptionSummary(double kwh, double cost) {
    double avgCost = kwh > 0 ? cost / kwh : 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildSummaryRow("Energia Ricaricata", "${kwh.toStringAsFixed(1)} kWh"),
          _buildSummaryRow("Spesa Variabile Totale", "${cost.toStringAsFixed(2)} €"),
          const Divider(color: Colors.white10, height: 20),
          _buildSummaryRow("Costo Reale Medio", "${avgCost.toStringAsFixed(3)} €/kWh", isBold: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: TextStyle(color: isBold ? Colors.greenAccent : Colors.white, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildHeader(EnergyContract contract) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contract.provider.toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(contract.isMonorario ? "MONORARIO" : "FASCE", style: const TextStyle(color: Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Text("Q1 2026", style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const Icon(Icons.electric_bolt, color: Colors.white10, size: 48)
      ],
    );
  }
}