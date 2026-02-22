import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';
import 'package:smartcharge_v2/models/charge_session.dart';
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
  late TextEditingController priceCtrl;
  late TextEditingController wallboxPowerCtrl;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    selectedStartTime = const TimeOfDay(hour: 8, minute: 0);
    selectedEndTime = TimeOfDay.now();
    
    startSocCtrl = TextEditingController(text: widget.provider.currentSoc.toStringAsFixed(0));
    endSocCtrl = TextEditingController(text: widget.provider.targetSoc.toStringAsFixed(0));
    kwhCtrl = TextEditingController(text: "10.0");
    wallboxPowerCtrl = TextEditingController(text: widget.provider.wallboxPwr.toStringAsFixed(1));
    
    priceCtrl = TextEditingController(
      text: widget.tipo == "Home" 
          ? widget.provider.myContract.f1Price.toStringAsFixed(2)
          : "0.65"
    );
  }

  @override
  void dispose() {
    startSocCtrl.dispose();
    endSocCtrl.dispose();
    kwhCtrl.dispose();
    priceCtrl.dispose();
    wallboxPowerCtrl.dispose();
    super.dispose();
  }

  double get _calculatedKwh {
    final startSoc = double.tryParse(startSocCtrl.text.replaceAll(',', '.')) ?? 0;
    final endSoc = double.tryParse(endSocCtrl.text.replaceAll(',', '.')) ?? 0;
    final batteryCap = widget.provider.currentBatteryCap;
    
    if (startSoc > 0 && endSoc > 0 && batteryCap > 0 && endSoc > startSoc) {
      return ((endSoc - startSoc) / 100) * batteryCap;
    }
    return 0;
  }

  void _updateKwhFromSoc() {
    final calculated = _calculatedKwh;
    if (calculated > 0) {
      kwhCtrl.text = calculated.toStringAsFixed(1);
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true), // 🔥 PERMETTE DECIMALI
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true), // 🔥 PERMETTE DECIMALI
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true), // 🔥 PERMETTE DECIMALI
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: "ENERGIA (kWh)",
                      labelStyle: const TextStyle(color: Colors.white38, fontSize: 10),
                      suffixText: "kWh",
                      suffixStyle: const TextStyle(color: Colors.white38),
                      hintText: _calculatedKwh > 0 ? "Calcolato: ${_calculatedKwh.toStringAsFixed(1)} kWh" : null,
                      hintStyle: const TextStyle(color: Colors.blueAccent, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Potenza e Prezzo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: wallboxPowerCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true), // 🔥 PERMETTE DECIMALI
                    style: const TextStyle(color: Colors.orangeAccent),
                    decoration: const InputDecoration(
                      labelText: "POTENZA WALLBOX (kW)",
                      labelStyle: TextStyle(color: Colors.white38, fontSize: 10),
                      suffixText: "kW",
                      suffixStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true), // 🔥 PERMETTE DECIMALI
                    style: const TextStyle(color: Colors.greenAccent),
                    decoration: InputDecoration(
                      labelText: widget.tipo == "Home" ? "TARIFFA (€/kWh)" : "PREZZO (€/kWh)",
                      labelStyle: const TextStyle(color: Colors.white38, fontSize: 10),
                      suffixText: "€/kWh",
                      suffixStyle: const TextStyle(color: Colors.white38),
                    ),
                  ),
                ],
              ),
            ),
            
            if (_calculatedKwh > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "DURATA STIMATA:",
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                    Text(
                      _formatDuration(_calculateDuration()),
                      style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
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

  Widget _buildDateTile() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 20),
      title: const Text(
        "Data",
        style: TextStyle(color: Colors.white38, fontSize: 10),
      ),
      subtitle: Text(
        DateFormat('dd/MM/yyyy').format(selectedDate),
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      onTap: _selectDate,
    );
  }

  Widget _buildStartTimeTile() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.timer, color: Colors.blueAccent, size: 16),
      title: const Text(
        "Inizio",
        style: TextStyle(color: Colors.white38, fontSize: 8),
      ),
      subtitle: Text(
        selectedStartTime.format(context),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      onTap: _selectStartTime,
    );
  }

  Widget _buildEndTimeTile() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.timer_off, color: Colors.orangeAccent, size: 16),
      title: const Text(
        "Fine",
        style: TextStyle(color: Colors.white38, fontSize: 8),
      ),
      subtitle: Text(
        selectedEndTime.format(context),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      onTap: _selectEndTime,
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedStartTime,
    );
    if (picked != null) {
      setState(() {
        selectedStartTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedEndTime,
    );
    if (picked != null) {
      setState(() {
        selectedEndTime = picked;
      });
    }
  }

  Duration _calculateDuration() {
    final kwh = double.tryParse(kwhCtrl.text.replaceAll(',', '.')) ?? 0;
    final power = double.tryParse(wallboxPowerCtrl.text.replaceAll(',', '.')) ?? widget.provider.wallboxPwr;
    
    if (kwh > 0 && power > 0) {
      final hours = kwh / power;
      return Duration(minutes: (hours * 60).round());
    }
    return Duration.zero;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  void _handleSave() {
    try {
      // 🔥 SOSTITUISCE VIRGOLE CON PUNTI PER IL PARSING
      final startSoc = double.tryParse(startSocCtrl.text.replaceAll(',', '.')) ?? widget.provider.currentSoc;
      final endSoc = double.tryParse(endSocCtrl.text.replaceAll(',', '.')) ?? widget.provider.targetSoc;
      final kwh = double.tryParse(kwhCtrl.text.replaceAll(',', '.')) ?? 10.0;
      final wallboxPower = double.tryParse(wallboxPowerCtrl.text.replaceAll(',', '.')) ?? widget.provider.wallboxPwr;
      final price = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 
                    (widget.tipo == "Home" ? widget.provider.myContract.f1Price : 0.65);
      
      // Validazione base
      if (kwh <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Inserisci un valore valido per kWh"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      double finalCost;
      if (widget.tipo == "Home") {
        finalCost = CostCalculator.calculate(
          kwh,
          selectedStartTime,
          selectedDate,
          widget.provider.myContract,
        );
      } else {
        finalCost = kwh * price;
      }

      // Combina data e ora
      final startDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedStartTime.hour,
        selectedStartTime.minute,
      );
      
      final endDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedEndTime.hour,
        selectedEndTime.minute,
      );

      final session = ChargeSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: selectedDate,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        startSoc: startSoc,
        endSoc: endSoc,
        kwh: kwh,
        cost: finalCost,
        location: widget.tipo,
        carBrand: widget.provider.selectedCar.brand,
        carModel: widget.provider.selectedCar.model,
        wallboxPower: wallboxPower,
      );

      debugPrint('💾 Salvataggio sessione manuale:');
      debugPrint('   ID: ${session.id}');
      debugPrint('   Data: $selectedDate');
      debugPrint('   Ora: ${selectedStartTime.format(context)} - ${selectedEndTime.format(context)}');
      debugPrint('   SOC: $startSoc% → $endSoc%');
      debugPrint('   kWh: $kwh');
      debugPrint('   Costo: $finalCost €');
      debugPrint('   Potenza: $wallboxPower kW');

      widget.provider.addChargeSession(session);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ricarica registrata con successo!"),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      debugPrint('❌ Errore salvataggio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Errore: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}