import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartcharge_v2/models/charge_session.dart';

class HistoryEditDialog extends StatefulWidget {
  final ChargeSession session;
  final Function(ChargeSession) onSave;

  const HistoryEditDialog({
    super.key,
    required this.session,
    required this.onSave,
  });

  @override
  State<HistoryEditDialog> createState() => _HistoryEditDialogState();
}

class _HistoryEditDialogState extends State<HistoryEditDialog> {
  late TextEditingController kwhCtrl;
  late TextEditingController startSocCtrl;
  late TextEditingController endSocCtrl;
  late TextEditingController wallboxPowerCtrl;
  late TextEditingController costCtrl;
  late TextEditingController locationCtrl;
  
  late DateTime selectedDate;
  late TimeOfDay selectedStartTime;
  late TimeOfDay selectedEndTime;

  @override
  void initState() {
    super.initState();
    final session = widget.session;
    
    kwhCtrl = TextEditingController(text: session.kwh.toStringAsFixed(1));
    startSocCtrl = TextEditingController(text: session.startSoc.toStringAsFixed(0));
    endSocCtrl = TextEditingController(text: session.endSoc.toStringAsFixed(0));
    wallboxPowerCtrl = TextEditingController(text: session.wallboxPower.toStringAsFixed(1));
    costCtrl = TextEditingController(text: session.cost.toStringAsFixed(2));
    locationCtrl = TextEditingController(text: session.location);
    
    selectedDate = session.date;
    selectedStartTime = TimeOfDay.fromDateTime(session.startDateTime);
    selectedEndTime = TimeOfDay.fromDateTime(session.endDateTime);
  }

  @override
  void dispose() {
    kwhCtrl.dispose();
    startSocCtrl.dispose();
    endSocCtrl.dispose();
    wallboxPowerCtrl.dispose();
    costCtrl.dispose();
    locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        "Modifica Ricarica",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDateTimeSection(),
            const SizedBox(height: 16),
            _buildSocSection(),
            const SizedBox(height: 16),
            _buildEnergySection(),
            const SizedBox(height: 16),
            _buildCostSection(),
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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          child: const Text("SALVA"),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 20),
            title: const Text("Data", style: TextStyle(color: Colors.white38, fontSize: 10)),
            subtitle: Text(
              DateFormat('dd/MM/yyyy').format(selectedDate),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            onTap: _selectDate,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTimeTile("Inizio", selectedStartTime, Icons.timer, _selectStartTime)),
              const SizedBox(width: 8),
              Expanded(child: _buildTimeTile("Fine", selectedEndTime, Icons.timer_off, _selectEndTime)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTile(String label, TimeOfDay time, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.blueAccent, size: 16),
      title: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8)),
      subtitle: Text(
        time.format(context),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSocSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
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
              ),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergySection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextField(
            controller: kwhCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: "ENERGIA (kWh)",
              labelStyle: TextStyle(color: Colors.white38, fontSize: 10),
              suffixText: "kWh",
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: wallboxPowerCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.orangeAccent),
            decoration: const InputDecoration(
              labelText: "POTENZA (kW)",
              labelStyle: TextStyle(color: Colors.white38, fontSize: 10),
              suffixText: "kW",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextField(
            controller: costCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: "COSTO (€)",
              labelStyle: TextStyle(color: Colors.white38, fontSize: 10),
              suffixText: "€",
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: locationCtrl.text,
            dropdownColor: const Color(0xFF1C1C1E),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "LUOGO",
              labelStyle: TextStyle(color: Colors.white38, fontSize: 10),
            ),
            items: const [
              DropdownMenuItem(value: "Home", child: Text("Home")),
              DropdownMenuItem(value: "Pubblica", child: Text("Pubblica")),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  locationCtrl.text = value;
                });
              }
            },
          ),
        ],
      ),
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

  void _handleSave() {
    try {
      final startSoc = double.tryParse(startSocCtrl.text.replaceAll(',', '.')) ?? widget.session.startSoc;
      final endSoc = double.tryParse(endSocCtrl.text.replaceAll(',', '.')) ?? widget.session.endSoc;
      final kwh = double.tryParse(kwhCtrl.text.replaceAll(',', '.')) ?? widget.session.kwh;
      final wallboxPower = double.tryParse(wallboxPowerCtrl.text.replaceAll(',', '.')) ?? widget.session.wallboxPower;
      final cost = double.tryParse(costCtrl.text.replaceAll(',', '.')) ?? widget.session.cost;

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

      // Creazione della sessione aggiornata includendo la fascia
      final updatedSession = ChargeSession(
        id: widget.session.id,
        date: selectedDate,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        startSoc: startSoc,
        endSoc: endSoc,
        kwh: kwh,
        cost: cost,
        location: locationCtrl.text,
        carBrand: widget.session.carBrand,
        carModel: widget.session.carModel,
        wallboxPower: wallboxPower,
        fascia: widget.session.fascia, // 🔥 AGGIUNTO: Manteniamo la fascia originale o potresti ricalcolarla qui
      );

      widget.onSave(updatedSession);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Errore: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

}