import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcharge_v2/models/contract_model.dart';
import 'package:smartcharge_v2/models/charge_session.dart';
import 'package:smartcharge_v2/models/car_model.dart';
import 'package:smartcharge_v2/services/sync_service.dart';
import 'package:smartcharge_v2/providers/auth_provider.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';
import 'package:smartcharge_v2/screens/bill_scanner_page.dart';
import 'package:smartcharge_v2/screens/contract_summary_page.dart';
import 'package:provider/provider.dart';
import 'package:smartcharge_v2/pages/add_contract_page.dart';
import 'package:smartcharge_v2/services/cost_calculator.dart';

class SettingsPage extends StatefulWidget {
  final EnergyContract contract;
  final CarModel selectedCar;
  final String batteryValue;
  final AuthProvider authProvider;
  final HomeProvider homeProvider;

  const SettingsPage({
    super.key,
    required this.contract,
    required this.selectedCar,
    required this.batteryValue,
    required this.authProvider,
    required this.homeProvider,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _idController;
  late TextEditingController _nameController;
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
    _nameController = TextEditingController(text: widget.contract.userName);
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
    _nameController.dispose();
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
    widget.contract.userName = _nameController.text;
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
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _importFromCloud(String userId) async {
  if (userId.isEmpty) return;

  setState(() => _isSyncing = true);
  try {
    var data = await SyncService().downloadAllData(userId);
    if (data != null) {
      final prefs = await SharedPreferences.getInstance();
      
      // Salvataggio grezzo
      if (data['history'] != null) await prefs.setString('charge_history', jsonEncode(data['history']));
      if (data['contract'] != null) await prefs.setString('energy_contract', jsonEncode(data['contract']));

      // 🔥 IL TRUCCO: forza l'aggiornamento senza errori di compilazione
      await context.read<HomeProvider>().refreshAfterSettings();
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Sincronizzato!")));
    }
  } catch (e) {
    print("Errore: $e");
  } finally {
    if (mounted) setState(() => _isSyncing = false);
  }
}

  Future<bool?> _showLogoutConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text("Conferma logout", style: TextStyle(color: Colors.white)),
        content: const Text("Vuoi davvero uscire?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("ANNULLA")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("ESCI", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text("CONFERMA", style: TextStyle(color: Colors.white)),
        content: const Text("Sovrascrivere i dati locali con quelli del Cloud?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("ANNULLA")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("OK")),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: Text(title, style: const TextStyle(color: Colors.greenAccent)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
      ),
    );
  }

  void _showInfoDialog(String title, String message) => _showErrorDialog(title, message);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("IMPOSTAZIONI SISTEMA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.black.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blueAccent, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isSyncing) IconButton(
            onPressed: _saveAll, 
            icon: const Icon(Icons.check, color: Colors.blueAccent)
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("1 - SINCRONIZZAZIONE CLOUD"),
            _buildCard(
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Icon(Icons.cloud_queue, color: Colors.blueAccent, size: 30),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _idController,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        labelText: "ID SINCRONIZZAZIONE",
                        labelStyle: TextStyle(color: Colors.white38, fontSize: 10),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _importFromCloud(_idController.text.trim()),
                    icon: const Icon(Icons.download, color: Colors.blueAccent),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            _buildSectionTitle("2 - DATI UTENTE E VEICOLO"),
            _buildCard(
              child: Column(
                children: [
                  _buildInput("NOME UTENTE / AZIENDA", _nameController, Icons.person_outline),
                  const Divider(color: Colors.white10, indent: 50),
                  _buildStaticRow(Icons.directions_car, "AUTO SELEZIONATA", widget.selectedCar.model.toUpperCase()),
                  const Divider(color: Colors.white10, indent: 50),
                  _buildStaticRow(Icons.battery_charging_full, "CAPACITÀ BATTERIA", "${widget.batteryValue} kWh"),
                ],
              ),
            ),

            const SizedBox(height: 25),

            _buildSectionTitle("3 - GESTIONE CONTRATTI ENERGIA"),
            _buildCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // --- 📄 PULSANTE ANALIZZA BOLLETTA ---
                    InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BillScannerPage(provider: widget.homeProvider),
                          ),
                        );
                        if (result == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("✅ Tariffe aggiornate!"), backgroundColor: Colors.green),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.receipt_long, color: Colors.blueAccent, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text("📄 ANALIZZA BOLLETTA",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            Icon(Icons.arrow_forward, color: Colors.blueAccent, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- 📊 PULSANTE RESOCONTO CONTRATTO ---
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ContractSummaryPage()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.purple.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.pie_chart, color: Colors.purple, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text("📊 RESOCONTO CONTRATTO",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            Icon(Icons.arrow_forward, color: Colors.purple, size: 16),
                          ],
                        ),
                      ),
                    ),

                    const Divider(color: Colors.white10, height: 30),

                    // --- 📋 LISTA CONTRATTI SELEZIONABILI ---
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("SELEZIONA CONTRATTO ATTIVO",
                          style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 10),

                   Consumer<HomeProvider>(
  builder: (context, homeProv, child) {
    return Column(
      children: [
        ...homeProv.allContracts.map((contratto) {
          final isSelected = contratto.id == homeProv.activeContractId;
          
          // --- LOGICA DI COMPARAZIONE ---
          double risparmioTotale = 0;
          if (!isSelected && homeProv.chargeHistory.isNotEmpty) {
            for (var sessione in homeProv.chargeHistory) {
              double costoTeorico = CostCalculator.calculateComparison(
                session: sessione, 
                targetContract: contratto
              );
              risparmioTotale += (sessione.cost - costoTeorico);
            }
          }

          return RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            title: Text(contratto.contractName.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${contratto.provider} • F1: ${contratto.f1Price}€",
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
                
                // Mostra il risparmio solo se non è il contratto attivo
                if (!isSelected && homeProv.chargeHistory.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          risparmioTotale >= 0 ? Icons.trending_down : Icons.trending_up,
                          color: risparmioTotale >= 0 ? Colors.greenAccent : Colors.redAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          risparmioTotale >= 0 
                            ? "Risparmieresti ${risparmioTotale.toStringAsFixed(2)}€ totali"
                            : "Spenderesti ${risparmioTotale.abs().toStringAsFixed(2)}€ in più",
                          style: TextStyle(
                            color: risparmioTotale >= 0 ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            value: contratto.id,
            groupValue: homeProv.activeContractId,
            activeColor: Colors.blueAccent,
            onChanged: (String? value) {
              if (value != null) homeProv.selectActiveContract(value);
            },
            // 🔥 MODIFICA: Aggiunto Row con pulsanti Modifica ed Elimina
            secondary: SizedBox(
              width: 90, // Spazio per ospitare le due icone
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // TASTO MODIFICA (Sempre visibile)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddContractPage(contractToEdit: contratto),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  // TASTO ELIMINA (Solo se NON è selezionato o se vuoi permetterlo comunque)
                  isSelected 
                    ? const Icon(Icons.check_circle, color: Colors.blueAccent, size: 22)
                    : IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () => homeProv.deleteContract(contratto.id),
                      ),
                ],
              ),
            ),
          );
        }).toList(),

        const SizedBox(height: 15),

        // --- TASTO AGGIUNGI MANUALE ---
        InkWell(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const AddContractPage())),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.blueAccent, size: 18),
                SizedBox(width: 8),
                Text("AGGIUNGI NUOVO CONTRATTO",
                    style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  },
),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            _buildSectionTitle("4 - ACCOUNT"),
            _buildCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text("Esci dall'account", style: TextStyle(color: Colors.redAccent)),
                    onTap: () async {
                      final confirm = await _showLogoutConfirmDialog();
                      if (confirm == true) {
                        await widget.authProvider.signOut();
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            if (_isSyncing) const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
            
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: _isSyncing ? null : _saveAll,
                child: const Text("SALVA IMPOSTAZIONI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(title, style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.1)),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
      ),
    );
  }
}