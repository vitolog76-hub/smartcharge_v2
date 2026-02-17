import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcharge_v2/core/constants.dart';
import 'package:smartcharge_v2/models/contract_model.dart';
import 'package:smartcharge_v2/models/charge_session.dart';
import 'package:smartcharge_v2/models/car_model.dart';
import 'package:smartcharge_v2/services/sync_service.dart';

class SettingsPage extends StatefulWidget {
  final EnergyContract contract;
  final CarModel selectedCar;
  final String batteryValue;

  const SettingsPage({
    super.key, 
    required this.contract,
    required this.selectedCar,
    required this.batteryValue,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _idController;
  late TextEditingController _nameController; // CONTROLLER AGGIUNTO
  late TextEditingController _providerController;
  late TextEditingController _f1Controller;
  late TextEditingController _f2Controller;
  late TextEditingController _f3Controller;
  
  bool _isSyncing = false;
  late bool _isMonorario;

  @override
  void initState() {
    super.initState();
    _providerController = TextEditingController(text: widget.contract.provider);
    _nameController = TextEditingController(text: widget.contract.userName); // INIZIALIZZAZIONE NOME
    _f1Controller = TextEditingController(text: widget.contract.f1Price.toString());
    _f2Controller = TextEditingController(text: widget.contract.f2Price.toString());
    _f3Controller = TextEditingController(text: widget.contract.f3Price.toString());
    _idController = TextEditingController();
    
    _idController.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_sync_id', _idController.text.trim());
    });

    _isMonorario = widget.contract.isMonorario;
    _loadSyncId();
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose(); // DISPOSE AGGIUNTO
    _providerController.dispose();
    _f1Controller.dispose();
    _f2Controller.dispose();
    _f3Controller.dispose();
    super.dispose();
  }

  _loadSyncId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _idController.text = prefs.getString('user_sync_id') ?? "";
    });
  }

  void _saveAll() async {
    String userId = _idController.text.trim();
    if (userId.isEmpty) {
      _showInfoDialog("ATTENZIONE", "Inserisci un ID per la sincronizzazione.");
      return;
    }

    setState(() => _isSyncing = true);
    
    widget.contract.provider = _providerController.text;
    widget.contract.userName = _nameController.text; // SALVATAGGIO NOME NEL MODELLO
    widget.contract.isMonorario = _isMonorario;
    widget.contract.f1Price = double.tryParse(_f1Controller.text) ?? 0.0;
    
    if (_isMonorario) {
      widget.contract.f2Price = widget.contract.f1Price;
      widget.contract.f3Price = widget.contract.f1Price;
    } else {
      widget.contract.f2Price = double.tryParse(_f2Controller.text) ?? 0.0;
      widget.contract.f3Price = double.tryParse(_f3Controller.text) ?? 0.0;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('energy_contract', jsonEncode(widget.contract.toJson()));
    await prefs.setString('user_sync_id', userId);

    List<ChargeSession> history = [];
    final String? historyData = prefs.getString('charge_history');
    if (historyData != null) {
      try {
        Iterable l = jsonDecode(historyData);
        history = List<ChargeSession>.from(l.map((model) => ChargeSession.fromJson(model)));
      } catch (e) { debugPrint("Errore: $e"); }
    }

    await SyncService().uploadData(userId, history, widget.contract);
    setState(() => _isSyncing = false);
    if (mounted) Navigator.pop(context);
  }

  void _importFromCloud(String userId) async {
    if (userId.isEmpty) {
      _showErrorDialog("ATTENZIONE", "Inserisci un ID prima di scaricare.");
      return;
    }
    setState(() => _isSyncing = true);
    try {
      bool exists = await SyncService().checkIfUserExists(userId);
      if (exists) {
        bool? confirm = await _showConfirmDialog();
        if (confirm == true) {
          var data = await SyncService().downloadAllData(userId);
          if (data != null) {
            final prefs = await SharedPreferences.getInstance();
            if (data['history'] != null) await prefs.setString('charge_history', jsonEncode(data['history']));
            if (data['contract'] != null) {
              await prefs.setString('energy_contract', jsonEncode(data['contract']));
              EnergyContract imported = EnergyContract.fromJson(data['contract']);
              setState(() {
                _providerController.text = imported.provider;
                _nameController.text = imported.userName; // AGGIORNAMENTO NOME DA CLOUD
                _f1Controller.text = imported.f1Price.toString();
                _f2Controller.text = imported.f2Price.toString();
                _f3Controller.text = imported.f3Price.toString();
                _isMonorario = imported.isMonorario;
              });
            }
            _showErrorDialog("SUCCESSO", "Dati recuperati dal Cloud!");
          }
        }
      } else {
        _showErrorDialog("NON TROVATO", "Nessun dato per questo ID.");
      }
    } catch (e) { _showErrorDialog("ERRORE", "$e");
    } finally { setState(() => _isSyncing = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("IMPOSTAZIONI SISTEMA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: [
          if (!_isSyncing) IconButton(onPressed: _saveAll, icon: const Icon(Icons.check, color: AppColors.accent))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("1 - IDENTITÀ DIGITALE"),
            _buildCard(
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Icon(Icons.fingerprint, color: AppColors.accent, size: 40),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _idController,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        labelText: "ID UTENTE",
                        labelStyle: TextStyle(color: Colors.white38, fontSize: 10),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _importFromCloud(_idController.text.trim()),
                    icon: const Icon(Icons.cloud_download, color: AppColors.accent),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            _buildSectionTitle("2 - DATI UTENTE E VEICOLO"),
            _buildCard(
              child: Column(
                children: [
                  // CAMPO NOME DIVENTATO INPUT MODIFICABILE
                  _buildInput("NOME / AZIENDA REPORT", _nameController, Icons.person),
                  const Divider(color: Colors.white10, indent: 50),
                  _buildStaticRow(Icons.directions_car, "AUTO SELEZIONATA", widget.selectedCar.model.toUpperCase()),
                  const Divider(color: Colors.white10, indent: 50),
                  _buildStaticRow(Icons.battery_charging_full, "CAPACITÀ BATTERIA", "${widget.batteryValue} kWh"),
                ],
              ),
            ),

            const SizedBox(height: 25),

            _buildSectionTitle("3 - PARAMETRI ECONOMICI"),
            _buildCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInput("Gestore", _providerController, Icons.business),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Tariffa Monoraria", style: TextStyle(color: Colors.white70)),
                        Switch(
                          value: _isMonorario,
                          activeColor: AppColors.accent,
                          onChanged: (val) => setState(() => _isMonorario = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    if (_isMonorario)
                      _buildInput("Costo kWh (€)", _f1Controller, Icons.euro)
                    else
                      Row(
                        children: [
                          Expanded(child: _buildInput("F1", _f1Controller, Icons.bolt)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInput("F2", _f2Controller, Icons.bolt)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInput("F3", _f3Controller, Icons.bolt)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            if (_isSyncing) const Center(child: CircularProgressIndicator(color: AppColors.accent)),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                onPressed: _isSyncing ? null : _saveAll,
                child: const Text("SALVA E SINCRONIZZA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS (RIPRISTINATI) ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(title, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _buildStaticRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 20),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.accent.withOpacity(0.5), size: 18),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
      ),
    );
  }

  // Dialoghi
  void _showErrorDialog(String title, String message) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cardBg,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: Text(message, style: const TextStyle(color: Colors.white70)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
    ));
  }

  void _showInfoDialog(String title, String message) => _showErrorDialog(title, message);

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cardBg,
      title: const Text("CONFERMA", style: TextStyle(color: Colors.white)),
      content: const Text("Questo sovrascriverà i dati locali con quelli del Cloud. Continuare?", style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("ANNULLA")),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("CONTINUA", style: TextStyle(color: AppColors.accent))),
      ],
    ));
  }
}