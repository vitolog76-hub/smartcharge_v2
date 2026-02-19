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
  late TextEditingController kwhCtrl;
  late TextEditingController priceCtrl;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    
    kwhCtrl = TextEditingController(text: "10.0");
    priceCtrl = TextEditingController(
      text: widget.tipo == "Home" 
          ? widget.provider.myContract.f1Price.toStringAsFixed(2)
          : "0.65"
    );
  }

  @override
  void dispose() {
    kwhCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        "Registra ${widget.tipo}",
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDateTile(),
            const SizedBox(height: 10),
            TextField(
              controller: kwhCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "kWh CARICATI",
                labelStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.greenAccent),
              decoration: const InputDecoration(
                labelText: "PREZZO (€/kWh)",
                labelStyle: TextStyle(color: Colors.white38),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annulla"),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          child: const Text("Salva"),
        ),
      ],
    );
  }

  Widget _buildDateTile() {
    return ListTile(
      leading: const Icon(Icons.calendar_today, color: Colors.blueAccent),
      title: const Text(
        "Data",
        style: TextStyle(color: Colors.white38, fontSize: 10),
      ),
      subtitle: Text(
        DateFormat('dd/MM/yyyy').format(selectedDate),
        style: const TextStyle(color: Colors.white),
      ),
      onTap: _selectDate,
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

  void _handleSave() {
    final finalKwh = double.tryParse(kwhCtrl.text) ?? 10.0;
    
    double finalCost;
    if (widget.tipo == "Home") {
      finalCost = CostCalculator.calculate(
        finalKwh,
        TimeOfDay.now(),
        selectedDate,
        widget.provider.myContract,
      );
    } else {
      finalCost = finalKwh * (double.tryParse(priceCtrl.text) ?? 0.65);
    }

    final session = ChargeSession(
      date: selectedDate,
      kwh: finalKwh,
      cost: finalCost,
      location: widget.tipo,
      startTime: TimeOfDay.now(),
      endTime: TimeOfDay.now(),
    );

    widget.provider.addChargeSession(session);
    Navigator.pop(context);
  }
}