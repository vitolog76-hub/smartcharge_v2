import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';
import 'package:smartcharge_v2/models/charge_session.dart';
import 'package:smartcharge_v2/models/contract_model.dart';
import 'package:smartcharge_v2/services/charge_engine.dart';
import 'package:smartcharge_v2/services/cost_calculator.dart'; 

class AddChargeDialog extends StatefulWidget {
  final HomeProvider provider;
  final String tipo;
  final double? customEndSoc;

  const AddChargeDialog({
    super.key,
    required this.provider,
    required this.tipo,
    this.customEndSoc,
  });

  @override
  State<AddChargeDialog> createState() => _AddChargeDialogState();
}

class _AddChargeDialogState extends State<AddChargeDialog> {
  late DateTime selectedDate;
  late TimeOfDay selectedStartTime;
  late TimeOfDay selectedEndTime;
  late TextEditingController startSocCtrl;
  late TextEditingController endSocCtrl;
  late TextEditingController kwhCtrl;
  late TextEditingController wallboxPowerCtrl;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    selectedStartTime = const TimeOfDay(hour: 8, minute: 0);
    selectedEndTime = TimeOfDay.now();
    
    startSocCtrl = TextEditingController(text: widget.provider.currentSoc.toStringAsFixed(0));
    endSocCtrl = TextEditingController(text: (widget.customEndSoc ?? widget.provider.targetSoc).toStringAsFixed(0));
    
    // Inizializziamo i kWh basandoci sul SOC iniziale/finale
    final initialKwh = _calculateKwhValue(
      double.tryParse(startSocCtrl.text) ?? 0, 
      double.tryParse(endSocCtrl.text) ?? 0
    );
    kwhCtrl = TextEditingController(text: initialKwh.toStringAsFixed(1));
    
    wallboxPowerCtrl = TextEditingController(text: widget.provider.wallboxPwr.toStringAsFixed(1));
  }

  @override
  void dispose() {
    startSocCtrl.dispose();
    endSocCtrl.dispose();
    kwhCtrl.dispose();
    wallboxPowerCtrl.dispose();
    super.dispose();
  }

  void _updateEndTimeFromKwh() {
  final kwh = double.tryParse(kwhCtrl.text.replaceAll(',', '.')) ?? 0;
  final power = double.tryParse(wallboxPowerCtrl.text.replaceAll(',', '.')) ?? widget.provider.wallboxPwr;

  if (kwh > 0 && power > 0) {
    final hoursNeeded = kwh / power;
    final minutesNeeded = (hoursNeeded * 60).round();
    
    // Partiamo da un DateTime fittizio con l'ora di inizio selezionata
    final startRef = DateTime(2024, 1, 1, selectedStartTime.hour, selectedStartTime.minute);
    final endRef = startRef.add(Duration(minutes: minutesNeeded));
    
    setState(() {
      selectedEndTime = TimeOfDay.fromDateTime(endRef);
    });
  }
}

  double _calculateKwhValue(double start, double end) {
    final batteryCap = widget.provider.currentBatteryCap;
    if (end > start && batteryCap > 0) {
      return ((end - start) / 100) * batteryCap;
    }
    return 0;
  }

  void _updateKwhFromSoc() {
    final start = double.tryParse(startSocCtrl.text.replaceAll(',', '.')) ?? 0;
    final end = double.tryParse(endSocCtrl.text.replaceAll(',', '.')) ?? 0;
    final calculated = _calculateKwhValue(start, end);
    if (calculated >= 0) {
      setState(() {
        kwhCtrl.text = calculated.toStringAsFixed(1);
      });
    }
  }

  void _updateSocFromKwh() {
    final start = double.tryParse(startSocCtrl.text.replaceAll(',', '.')) ?? 0;
    final kwh = double.tryParse(kwhCtrl.text.replaceAll(',', '.')) ?? 0;
    final batteryCap = widget.provider.currentBatteryCap;

    if (kwh > 0 && batteryCap > 0) {
      final addedSoc = (kwh / batteryCap) * 100;
      final newEndSoc = (start + addedSoc).clamp(0.0, 100.0);
      setState(() {
        endSocCtrl.text = newEndSoc.toStringAsFixed(0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        "Registra Ricarica ${widget.tipo}",
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Data e Ora
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDateTile(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildStartTimeTile()),
                      const SizedBox(width: 8),
                      Expanded(child: _buildEndTimeTile()),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // SOC e kWh
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startSocCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.blueAccent),
                          decoration: const InputDecoration(
                            labelText: "SOC INIZIALE %",
                            labelStyle: TextStyle(color: Colors.white38, fontSize: 10),
                            suffixText: "%",
                            suffixStyle: TextStyle(color: Colors.white38),
                          ),
                          onChanged: (_) => _updateKwhFromSoc(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: endSocCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.greenAccent),
                          decoration: const InputDecoration(
                            labelText: "SOC FINALE %",
                            labelStyle: TextStyle(color: Colors.white38, fontSize: 10),
                            suffixText: "%",
                            suffixStyle: TextStyle(color: Colors.white38),
                          ),
                          onChanged: (_) => _updateKwhFromSoc(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
  controller: kwhCtrl,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  onChanged: (_) {
    _updateSocFromKwh();      // Sincronizza il SOC finale
    _updateEndTimeFromKwh();  // 🔥 Sincronizza l'orario di fine
  },
  decoration: const InputDecoration(
    labelText: "ENERGIA (kWh)",
    labelStyle: TextStyle(color: Colors.white38, fontSize: 10),
    suffixText: "kWh",
  ),
),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Potenza Wallbox
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: wallboxPowerCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.orangeAccent),
                decoration: const InputDecoration(
                  labelText: "POTENZA WALLBOX (kW)",
                  labelStyle: TextStyle(color: Colors.white38, fontSize: 10),
                  suffixText: "kW",
                  suffixStyle: TextStyle(color: Colors.white38),
                ),
              ),
            ),
            // 🔥 DURATA STIMATA RIMOSSA COME RICHIESTO
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annulla", style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
          child: const Text("SALVA"),
        ),
      ],
    );
  }

  // --- WIDGETS DI SUPPORTO ---

  Widget _buildDateTile() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 20),
      title: const Text("Data", style: TextStyle(color: Colors.white38, fontSize: 10)),
      subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: const TextStyle(color: Colors.white, fontSize: 14)),
      onTap: _selectDate,
    );
  }

  Widget _buildStartTimeTile() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.timer, color: Colors.blueAccent, size: 16),
      title: const Text("Inizio", style: TextStyle(color: Colors.white38, fontSize: 8)),
      subtitle: Text(selectedStartTime.format(context), style: const TextStyle(color: Colors.white, fontSize: 12)),
      onTap: _selectStartTime,
    );
  }

  Widget _buildEndTimeTile() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.timer_off, color: Colors.orangeAccent, size: 16),
      title: const Text("Fine", style: TextStyle(color: Colors.white38, fontSize: 8)),
      subtitle: Text(selectedEndTime.format(context), style: const TextStyle(color: Colors.white, fontSize: 12)),
      onTap: _selectEndTime,
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2024), lastDate: DateTime.now());
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: selectedStartTime);
    if (picked != null) setState(() => selectedStartTime = picked);
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: selectedEndTime);
    if (picked != null) setState(() => selectedEndTime = picked);
  }

  void _handleSave() {
  try {
    final startSoc = double.tryParse(startSocCtrl.text.replaceAll(',', '.')) ?? 0;
    final endSoc = double.tryParse(endSocCtrl.text.replaceAll(',', '.')) ?? 0;
    final kwh = double.tryParse(kwhCtrl.text.replaceAll(',', '.')) ?? 0;
    final wallboxPower = double.tryParse(wallboxPowerCtrl.text.replaceAll(',', '.')) ?? 3.7;

    // Capiamo se è una ricarica domestica o pubblica
    final bool isHome = widget.tipo.toLowerCase().contains("home") || widget.tipo.toLowerCase().contains("casa");

    // Costruiamo i DateTime
    DateTime startDT = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day,
      selectedStartTime.hour, selectedStartTime.minute,
    );

    DateTime endDT = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day,
      selectedEndTime.hour, selectedEndTime.minute,
    );

    if (endDT.isBefore(startDT)) {
      endDT = endDT.add(const Duration(days: 1));
    }

    // Calcolo costo e fascia (solo se casa, altrimenti usiamo dati manuali se presenti)
    final double finalCost = CostCalculator.calculate(
      totalKwh: kwh,
      wallboxPower: wallboxPower,
      startTime: selectedStartTime,
      date: selectedDate,
      contract: widget.provider.myContract,
    );

    final String fasciaEtichetta = CostCalculator.getFasciaLabel(
      totalKwh: kwh,
      wallboxPower: wallboxPower,
      startTime: selectedStartTime,
      date: selectedDate,
      isMonorario: widget.provider.myContract.isMonorario,
    );

    // Creazione della sessione con i nuovi campi "Prezzi al momento"
    final session = ChargeSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: selectedDate,
      startDateTime: startDT,
      endDateTime: endDT,
      startSoc: startSoc,
      endSoc: endSoc,
      kwh: kwh,
      cost: finalCost,
      location: widget.tipo,
      carBrand: widget.provider.selectedCar.brand,
      carModel: widget.provider.selectedCar.model,
      wallboxPower: wallboxPower,
      fascia: isHome ? fasciaEtichetta : "Public",
      // 🔥 NUOVI CAMPI PER IL CONFRONTO:
      contractId: isHome ? widget.provider.activeContractId : "PUBLIC_GENERIC",
      f1PriceAtTime: isHome ? widget.provider.myContract.f1Price : (finalCost / kwh),
      f2PriceAtTime: isHome ? widget.provider.myContract.f2Price : (finalCost / kwh),
      f3PriceAtTime: isHome ? widget.provider.myContract.f3Price : (finalCost / kwh),
    );

    widget.provider.addChargeSession(session);
    Navigator.pop(context);
  } catch (e) {
    print("Errore nel salvataggio: $e");
  }
}
}