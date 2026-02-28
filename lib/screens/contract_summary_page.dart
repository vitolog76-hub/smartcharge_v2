import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartcharge_v2/models/contract_model.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';

class ContractSummaryPage extends StatelessWidget {
  const ContractSummaryPage({super.key});

  // --- LOGICA DI CALCOLO FISCALE ---
  double _calculateVariablePrice(double basePrice, EnergyContract contract, double totalKwh, int giorni) {
    if (basePrice > 0.20) return basePrice;

    double imponibileSenzaAccise = basePrice;
    if (contract.transportFee != null) imponibileSenzaAccise += contract.transportFee!;
    if (contract.systemCharges != null) imponibileSenzaAccise += contract.systemCharges!;

    double acciseMediePerKwh = 0;
    double consumoMensileStimato = giorni > 0 ? (totalKwh / giorni) * 30 : totalKwh;

    if (consumoMensileStimato > 150) {
      double kwhEccedenti = consumoMensileStimato - 150;
      double totaleAcciseMese = kwhEccedenti * 0.0227;
      acciseMediePerKwh = totaleAcciseMese / consumoMensileStimato;
    }
    
    double imponibileFinito = imponibileSenzaAccise + acciseMediePerKwh;
    double prezzoFinito = imponibileFinito;
    if (contract.vat != null) {
      prezzoFinito = imponibileFinito * (1 + contract.vat! / 100);
    }
    return prezzoFinito;
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 ASCOLTO ATTIVO: La pagina si ricostruisce ad ogni notifica del provider
    final provider = context.watch<HomeProvider>();
    final contract = provider.myContract;
    
    final double totalKwh = provider.chargeHistory.fold(0.0, (sum, s) => sum + s.kwh);
    final double totalCost = provider.chargeHistory.fold(0.0, (sum, s) => sum + s.cost);
    
    int totalDays = 30;
    if (provider.chargeHistory.isNotEmpty) {
      DateTime firstCharge = provider.chargeHistory.last.startDateTime;
      DateTime lastCharge = provider.chargeHistory.first.startDateTime;
      totalDays = lastCharge.difference(firstCharge).inDays;
      if (totalDays < 1) totalDays = 1;
    }

    double fixedMonthlyCost = contract.fixedMonthlyFee ?? 0;
    double powerCost = (contract.powerFee ?? 0) * 3;
    double totalFixedMonthly = fixedMonthlyCost + powerCost;
    double avgVariableCostPerKwh = totalKwh > 0 ? totalCost / totalKwh : 0;

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
            const SizedBox(height: 20),
            _buildVariableTariffSection(contract, totalKwh, totalDays),
            const SizedBox(height: 20),
            _buildFixedCostsSection(totalFixedMonthly, totalFixedMonthly * 12, contract.fixedMonthlyFee, contract.powerFee),
            const SizedBox(height: 20),
            _buildConsumptionSummary(totalKwh, totalCost, avgVariableCostPerKwh),
          ],
        ),
      ),
    );
  }

  Widget _buildVariableTariffSection(EnergyContract contract, double totalKwh, int giorni) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: contract.isMonorario ? Colors.blueAccent.withOpacity(0.2) : Colors.greenAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: contract.isMonorario ? Colors.blueAccent : Colors.yellowAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                contract.isMonorario ? "TARIFFA MONORARIA" : "TARIFFA A FASCE", 
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTariffRow("F1", contract.f1Pure ?? contract.f1Price, _calculateVariablePrice(contract.f1Price, contract, totalKwh, giorni), Colors.blueAccent),
          if (!contract.isMonorario) ...[
            const Divider(color: Colors.white10),
            _buildTariffRow("F2", contract.f2Pure ?? contract.f2Price, _calculateVariablePrice(contract.f2Price, contract, totalKwh, giorni), Colors.orangeAccent),
            const Divider(color: Colors.white10),
            _buildTariffRow("F3", contract.f3Pure ?? contract.f3Price, _calculateVariablePrice(contract.f3Price, contract, totalKwh, giorni), Colors.greenAccent),
          ],
        ],
      ),
    );
  }

  Widget _buildTariffRow(String label, double puro, double totale, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14))),
          Expanded(child: Text("${puro.toStringAsFixed(3)} €", style: const TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center)),
          Expanded(child: Text("${totale.toStringAsFixed(3)} €", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildFixedCostsSection(double monthly, double yearly, double? fixedMonthlyFee, double? powerFee) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildFixedRow("Quota Fissa Mensile", fixedMonthlyFee ?? 0),
          _buildFixedRow("Quota Potenza (3kW)", (powerFee ?? 0) * 3),
          const Divider(color: Colors.white10, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallStat("COSTO MENSILE", "${monthly.toStringAsFixed(2)} €"),
              _buildSmallStat("COSTO ANNUALE", "${yearly.toStringAsFixed(2)} €"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFixedRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text("${value.toStringAsFixed(2)} €", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildConsumptionSummary(double kwh, double cost, double avgCost) {
    String displayAvg = kwh > 0 ? "${avgCost.toStringAsFixed(3)} €/kWh" : "---";

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
          _buildSummaryRow("Costo Reale Medio", displayAvg, isBold: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(value, style: TextStyle(color: isBold ? Colors.greenAccent : Colors.white, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHeader(EnergyContract contract) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contract.provider.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(contract.userName.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2)),
          ],
        ),
        Icon(
          contract.isMonorario ? Icons.looks_one : Icons.looks_3, 
          color: Colors.white10, 
          size: 40
        )
      ],
    );
  }
}