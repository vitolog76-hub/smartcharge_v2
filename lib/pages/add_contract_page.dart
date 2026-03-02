import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartcharge_v2/models/contract_model.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';

class AddContractPage extends StatefulWidget {
  final EnergyContract? contractToEdit;

  const AddContractPage({super.key, this.contractToEdit});

  @override
  State<AddContractPage> createState() => _AddContractPageState();
}

class _AddContractPageState extends State<AddContractPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _providerController;
  late TextEditingController _f1Controller;
  late TextEditingController _f2Controller;
  late TextEditingController _f3Controller;
  late TextEditingController _fixedFeeController;
  late TextEditingController _powerLimitController;
  late TextEditingController _spreadController;

  bool _isMonorario = true;

  @override
  void initState() {
    super.initState();
    final c = widget.contractToEdit;
    
    _nameController = TextEditingController(text: c?.contractName ?? "");
    _providerController = TextEditingController(text: c?.provider ?? "");
    _f1Controller = TextEditingController(text: c?.f1Price.toString() ?? "");
    _f2Controller = TextEditingController(text: c?.f2Price.toString() ?? "");
    _f3Controller = TextEditingController(text: c?.f3Price.toString() ?? "");
    _fixedFeeController = TextEditingController(text: c?.fixedMonthlyFee?.toString() ?? "6.0");
    _powerLimitController = TextEditingController(text: c?.powerFee?.toString() ?? "6.0");
    _spreadController = TextEditingController(text: c?.spread.toString() ?? "0.0");
    
    _isMonorario = c?.isMonorario ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _providerController.dispose();
    _f1Controller.dispose();
    _f2Controller.dispose();
    _f3Controller.dispose();
    _fixedFeeController.dispose();
    _powerLimitController.dispose();
    _spreadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.contractToEdit != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(isEditing ? "MODIFICA CONTRATTO" : "NUOVO CONTRATTO", 
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 🔥 MODIFICATI: Aggiunto isNumeric: false
            _buildInput("NOME CONTRATTO (es. Casa Octopus)", _nameController, Icons.edit, isNumeric: false),
            _buildInput("GESTORE (es. Octopus Energy)", _providerController, Icons.business, isNumeric: false),
            
            const SizedBox(height: 25),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blueAccent, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Inserisci la 'Materia Energia'. L'app aggiungerà automaticamente perdite di rete, accise e oneri.",
                      style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_isMonorario ? "TARIFFA MONORARIA (F0)" : "TARIFFA A FASCE (F1/F2/F3)", 
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  Switch(
                    value: _isMonorario,
                    onChanged: (v) => setState(() => _isMonorario = v),
                    activeColor: Colors.blueAccent,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
            
            const Text("PREZZI MATERIA PRIMA (€/kWh)", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            if (_isMonorario)
              _buildInput("COSTO MATERIA PRIMA (€/kWh)", _f1Controller, Icons.bolt, hint: "es. 0.11")
            else
              Row(
                children: [
                  Expanded(child: _buildInput("F1 (Materia)", _f1Controller, Icons.wb_sunny_outlined, hint: "0.12")),
                  const SizedBox(width: 10),
                  Expanded(child: _buildInput("F2 (Materia)", _f2Controller, Icons.wb_twilight, hint: "0.11")),
                  const SizedBox(width: 10),
                  Expanded(child: _buildInput("F3 (Materia)", _f3Controller, Icons.nightlight_round, hint: "0.10")),
                ],
              ),

            const SizedBox(height: 20),
            
            _buildInput("SPREAD / COSTI EXTRA (€/kWh)", _spreadController, Icons.add_moderator, hint: "es. 0.02"),
            const Padding(
              padding: EdgeInsets.only(left: 40, top: 4),
              child: Text(
                "💡 Inserisci voci come 'Omega' o 'Margine' se presenti.",
                style: TextStyle(color: Colors.white24, fontSize: 9),
              ),
            ),

            const SizedBox(height: 25),
            const Text("COSTI FISSI E POTENZA", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildInput("FISSO (€/mese)", _fixedFeeController, Icons.calendar_today, hint: "es. 6.0")),
                const SizedBox(width: 10),
                Expanded(child: _buildInput("CONTATORE (kW)", _powerLimitController, Icons.speed, hint: "es. 6.0")),
              ],
            ),
            
            const SizedBox(height: 40),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEditing ? Colors.orangeAccent : Colors.blueAccent, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: _save,
                child: Text(isEditing ? "AGGIORNA CONTRATTO" : "SALVA CONTRATTO", 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 🔥 AGGIORNATO: Aggiunto parametro isNumeric con default true
  Widget _buildInput(String label, TextEditingController ctrl, IconData icon, {String? hint, bool isNumeric = true}) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      keyboardType: isNumeric 
          ? const TextInputType.numberWithOptions(decimal: true) 
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white10, fontSize: 12),
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 10),
        prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
      ),
      validator: (v) => v!.isEmpty ? "Richiesto" : null,
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final homeProv = Provider.of<HomeProvider>(context, listen: false);
      
      final f1Str = _f1Controller.text.replaceAll(',', '.');
      final f1 = double.tryParse(f1Str) ?? 0.0;
      
      final nuovo = EnergyContract(
        id: widget.contractToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        contractName: _nameController.text,
        provider: _providerController.text,
        isMonorario: _isMonorario,
        f1Price: f1,
        f2Price: _isMonorario ? f1 : (double.tryParse(_f2Controller.text.replaceAll(',', '.')) ?? 0.0),
        f3Price: _isMonorario ? f1 : (double.tryParse(_f3Controller.text.replaceAll(',', '.')) ?? 0.0),
        fixedMonthlyFee: double.tryParse(_fixedFeeController.text.replaceAll(',', '.')) ?? 0.0,
        powerFee: double.tryParse(_powerLimitController.text.replaceAll(',', '.')) ?? 0.0,
        spread: double.tryParse(_spreadController.text.replaceAll(',', '.')) ?? 0.0,
      );
      
      homeProv.addOrUpdateContract(nuovo);
      if (widget.contractToEdit == null) {
        homeProv.selectActiveContract(nuovo.id);
      }
      Navigator.pop(context);
    }
  }
}