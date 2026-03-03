import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcharge_v2/models/contract_model.dart';
import 'package:smartcharge_v2/models/charge_session.dart';
import 'package:smartcharge_v2/models/car_model.dart';
import 'package:smartcharge_v2/services/sync_service.dart';
import 'package:smartcharge_v2/providers/auth_provider.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';
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
    _nameController = TextEditingController(text: widget.homeProvider.globalUserName);
    _f1Controller = TextEditingController(text: widget.contract.f1Price.toString());
    _f2Controller = TextEditingController(text: widget.contract.f2Price.toString());
    _f3Controller = TextEditingController(text: widget.contract.f3Price.toString());
    _idController = TextEditingController();
    
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
      String? savedName = prefs.getString('global_user_name');
      if (savedName != null && savedName.isNotEmpty) {
        _nameController.text = savedName;
      }
    });
  }

  void _saveAll() async {
    String userId = _idController.text.trim();
    String nuovoNomeProfilo = _nameController.text.trim(); 
    final homeProv = context.read<HomeProvider>();

    setState(() => _isSyncing = true);
    
    // 1. SALVATAGGIO PROFILO (Nome e ID)
    // Questo metodo salva su MacBook e sincronizza col Cloud se l'ID esiste
    await homeProv.syncUserProfile(nuovoNomeProfilo);

    // 2. SALVATAGGIO ID SINCRONIZZAZIONE (Se cambiato manualmente)
    if (userId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_sync_id', userId);
    }

    // 3. AGGIORNAMENTO DATI TECNICI CONTRATTO
    // Nota: Abbiamo rimosso 'userName' dai parametri perché ora è globale
    homeProv.updateActiveContractDetails(
      provider: _providerController.text,
      isMonorario: _isMonorario,
      f1: double.tryParse(_f1Controller.text) ?? homeProv.myContract.f1Price,
      f2: double.tryParse(_f2Controller.text),
      f3: double.tryParse(_f3Controller.text),
    );

    // 4. SALVATAGGIO FINALE E SYNC
    // Forza il rinfresco di tutto il pacchetto dati sul Cloud
    await homeProv.saveAllContracts(); 

    setState(() => _isSyncing = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Profilo e Impostazioni salvati con successo!"),
          backgroundColor: Colors.green,
        )
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _importFromCloud(String userId) async {
    if (userId.isEmpty) {
      _showErrorDialog("Errore", "Inserisci un ID valido per importare i dati.");
      return;
    }

    setState(() => _isSyncing = true);
    
    try {
      // 1. Scarica i dati da Firebase
      var data = await SyncService().downloadAllData(userId);
      
      if (data != null) {
        // 2. Applica i dati scaricati al Provider (storia, contratti, nome)
        await context.read<HomeProvider>().refreshAfterSettings();
        
        if (mounted) {
          final homeProv = context.read<HomeProvider>();
          final nuovoContrattoAttivo = homeProv.myContract;

          // 3. Aggiorna l'interfaccia con i dati appena scaricati
          setState(() {
            // Ora il nome viene dal profilo globale scaricato, non dal contratto!
            _nameController.text = homeProv.globalUserName; 
            
            _providerController.text = nuovoContrattoAttivo.provider;
            _f1Controller.text = nuovoContrattoAttivo.f1Price.toString();
            _f2Controller.text = nuovoContrattoAttivo.f2Price.toString();
            _f3Controller.text = nuovoContrattoAttivo.f3Price.toString();
            _isMonorario = nuovoContrattoAttivo.isMonorario;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Dati importati correttamente dal Cloud!"))
          );
        }
      } else {
        if (mounted) _showErrorDialog("Sync Fallito", "Nessun dato trovato per questo ID.");
      }
    } catch (e) {
      debugPrint("Errore Import: $e");
      if (mounted) _showErrorDialog("Errore Critico", "Impossibile scaricare i dati. Controlla la connessione.");
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  // --- DIALOGS ---
  Future<bool?> _showLogoutConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text("Conferma logout", style: TextStyle(color: Colors.white)),
        content: const Text("Vuoi davvero uscire? I dati locali rimarranno sul MacBook.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("ANNULLA")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("ESCI", style: TextStyle(color: Colors.redAccent))),
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

  void _showInfoDialog(String title, String message) => _showErrorDialog(title, message);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Slate 900
              Color(0xFF020617), // Slate 950
              Colors.black,
            ],
          ),
        ),
        child: Column(
          children: [
            AppBar(
              title: const Text("IMPOSTAZIONI SISTEMA", 
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.cyanAccent, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (!_isSyncing) IconButton(
                  onPressed: _saveAll, 
                  icon: const Icon(Icons.check, color: Colors.cyanAccent)
                )
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("1 - SINCRONIZZAZIONE CLOUD"),
                    _buildCard(
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Icon(Icons.cloud_queue, color: Colors.cyanAccent, size: 30),
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
                            icon: const Icon(Icons.download, color: Colors.cyanAccent),
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
                            InkWell(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContractSummaryPage())),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.pie_chart, color: Colors.cyanAccent, size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text("DETTAGLI E TRASPARENZA COSTI",
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                    Icon(Icons.arrow_forward, color: Colors.cyanAccent, size: 16),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(color: Colors.white10, height: 30),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text("I TUOI PIANI TARIFFARI",
                                  style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 10),

                            Consumer<HomeProvider>(
                              builder: (context, homeProv, child) {
                                return Column(
                                  children: [
                                    ...homeProv.allContracts.map((contratto) {
                                      final isSelected = contratto.id == homeProv.activeContractId;
                                      
                                      // Logica calcolo differenza (mantenuta uguale)
                                      double differenzaTotale = 0;
                                      if (!isSelected && homeProv.chargeHistory.isNotEmpty) {
                                        for (var sessione in homeProv.chargeHistory) {
                                          double costoAttuale = CostCalculator.calculateComparison(session: sessione, targetContract: homeProv.myContract);
                                          double costoAlternativo = CostCalculator.calculateComparison(session: sessione, targetContract: contratto);
                                          differenzaTotale += (costoAttuale - costoAlternativo);
                                        }
                                        int mesi = 1; 
                                        if(homeProv.chargeHistory.length > 1) {
                                          mesi = ((homeProv.chargeHistory.last.date.year - homeProv.chargeHistory.first.date.year) * 12) + (homeProv.chargeHistory.last.date.month - homeProv.chargeHistory.first.date.month);
                                          if (mesi <= 0) mesi = 1;
                                        }
                                        differenzaTotale += ((homeProv.myContract.fixedMonthlyFee ?? 0.0) - (contratto.fixedMonthlyFee ?? 0.0)) * mesi;
                                      }

                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected ? Colors.cyanAccent : Colors.white.withOpacity(0.05),
                                            width: isSelected ? 2 : 1,
                                          ),
                                          boxShadow: isSelected ? [BoxShadow(color: Colors.cyanAccent.withOpacity(0.15), blurRadius: 12)] : [],
                                        ),
                                        child: _buildCard(
                                          child: Theme(
                                            data: ThemeData(unselectedWidgetColor: Colors.white24),
                                            child: RadioListTile<String>(
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              value: contratto.id,
                                              groupValue: homeProv.activeContractId,
                                              activeColor: Colors.cyanAccent,
                                              onChanged: (val) {
                                                if (val != null) {
                                                  homeProv.selectActiveContract(val);
                                                  setState(() {
                                                    _providerController.text = contratto.provider;
                                                    _f1Controller.text = contratto.f1Price.toString();
                                                    _isMonorario = contratto.isMonorario;
                                                  });
                                                }
                                              },
                                              title: Text(contratto.contractName.toUpperCase(),
                                                style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                                              subtitle: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(height: 4),
                                                  Text("${contratto.provider} • F1: ${contratto.f1Price}€", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                                  if (!isSelected && homeProv.chargeHistory.isNotEmpty)
                                                    Container(
                                                      margin: const EdgeInsets.only(top: 8),
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: differenzaTotale >= 0 ? Colors.greenAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(differenzaTotale >= 0 ? Icons.trending_down : Icons.trending_up, color: differenzaTotale >= 0 ? Colors.greenAccent : Colors.redAccent, size: 14),
                                                          const SizedBox(width: 6),
                                                          Text(differenzaTotale >= 0 ? "RISPARMIO: +${differenzaTotale.toStringAsFixed(2)}€" : "COSTO EXTRA: ${differenzaTotale.abs().toStringAsFixed(2)}€",
                                                            style: TextStyle(color: differenzaTotale >= 0 ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900)),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              secondary: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit_rounded, color: Colors.white38, size: 20),
                                                    onPressed: () async {
                                                      await Navigator.push(context, MaterialPageRoute(builder: (_) => AddContractPage(contractToEdit: contratto)));
                                                      if (mounted) setState(() {});
                                                    },
                                                  ),
                                                  if (homeProv.allContracts.length > 1)
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
                                                      onPressed: () => homeProv.deleteContract(contratto.id),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    const SizedBox(height: 15),
                                    InkWell(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddContractPage())),
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
                                            Icon(Icons.add_circle_outline, color: Colors.cyanAccent, size: 18),
                                            SizedBox(width: 8),
                                            Text("AGGIUNGI NUOVO CONTRATTO",
                                                style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11)),
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
                      child: ListTile(
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
                    ),
                    const SizedBox(height: 30),
                    if (_isSyncing) const Center(child: Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: CircularProgressIndicator(color: Colors.cyanAccent),
                    )),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          elevation: 10,
                          shadowColor: Colors.cyanAccent.withOpacity(0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: _isSyncing ? null : _saveAll,
                        child: _isSyncing 
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text("CONFERMA TUTTE LE MODIFICHE", 
                              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 8, top: 15),
    child: Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 1,
              )
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildCard({required Widget child}) {
  return Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.08),
          Colors.white.withOpacity(0.03),
        ],
      ),
      border: Border.all(
        color: Colors.white.withOpacity(0.12),
        width: 1,
      ),
    ),
    child: child,
  );
}

  Widget _buildStaticRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blueAccent.withOpacity(0.7), size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildInput(String label, TextEditingController ctrl, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: Colors.blueAccent.withOpacity(0.6), size: 22),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintStyle: const TextStyle(color: Colors.white24),
      ),
    ),
  );
}
}