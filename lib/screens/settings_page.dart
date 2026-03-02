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
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContractSummaryPage())),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.pie_chart, color: Colors.blueAccent, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text("DETTAGLI E TRASPARENZA COSTI",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            Icon(Icons.arrow_forward, color: Colors.blueAccent, size: 16),
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
  
  double differenzaTotale = 0;

  if (!isSelected && homeProv.chargeHistory.isNotEmpty) {
    // 1. PARTE VARIABILE (Consumo kWh)
    for (var sessione in homeProv.chargeHistory) {
      double costoAttuale = CostCalculator.calculateComparison(
        session: sessione, 
        targetContract: homeProv.myContract
      );
      double costoAlternativo = CostCalculator.calculateComparison(
        session: sessione, 
        targetContract: contratto
      );
      differenzaTotale += (costoAttuale - costoAlternativo);
    }

    // 2. PARTE FISSA (Quota Mensile)
    // Calcoliamo quanti mesi copre lo storico (es: da Gennaio a Marzo = 3 mesi)
    DateTime dataInizio = homeProv.chargeHistory.first.date;
    DateTime dataFine = homeProv.chargeHistory.last.date;
    
    // Calcolo semplificato dei mesi trascorsi (minimo 1 mese)
    int mesi = ((dataFine.year - dataInizio.year) * 12) + (dataFine.month - dataInizio.month);
    if (mesi <= 0) mesi = 1; 

    double quotaFissaAttuale = homeProv.myContract.fixedMonthlyFee ?? 0.0;
    double quotaFissaAlternativa = contratto.fixedMonthlyFee ?? 0.0;

    // Aggiungiamo la differenza dei costi fissi al totale
    differenzaTotale += (quotaFissaAttuale - quotaFissaAlternativa) * mesi;
  }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.blueAccent.withOpacity(0.05) : Colors.white.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isSelected ? Colors.blueAccent.withOpacity(0.4) : Colors.white10),
                                ),
                                child: RadioListTile<String>(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  title: Text(contratto.contractName.toUpperCase(),
                                      style: TextStyle(color: isSelected ? Colors.blueAccent : Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("${contratto.provider} • F1: ${contratto.f1Price} €/kWh",
                                          style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                      if (!isSelected && homeProv.chargeHistory.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Row(
                                            children: [
                                              Icon(differenzaTotale >= 0 ? Icons.trending_down : Icons.trending_up,
                                                   color: differenzaTotale >= 0 ? Colors.greenAccent : Colors.redAccent, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                differenzaTotale >= 0 
                                                  ? "RISPARMIERESTI ${differenzaTotale.toStringAsFixed(2)}€"
                                                  : "SPENDERESTI ${differenzaTotale.abs().toStringAsFixed(2)}€ IN PIÙ",
                                                style: TextStyle(color: differenzaTotale >= 0 ? Colors.greenAccent : Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold),
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
                                    if (value != null) {
                                      // 1. Cambia il contratto attivo nel Provider
                                      homeProv.selectActiveContract(value);
                                      
                                      // 2. 🔥 AGGIORNA I BOX IN ALTO
                                      // Usiamo setState per forzare i controller a mostrare i dati del nuovo contratto
                                      setState(() {
                                        
                                        _providerController.text = contratto.provider;
                                        // Se hai anche i prezzi in questa pagina, aggiorna anche quelli:
                                        _f1Controller.text = contratto.f1Price.toString();
                                        _isMonorario = contratto.isMonorario;
                                      });
                                    }
                                  },
                                  secondary: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
  icon: const Icon(Icons.edit, color: Colors.white24, size: 18),
  onPressed: () async {
    // 1. Aspettiamo che l'utente finisca di modificare e prema "Salva"
    await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => AddContractPage(contractToEdit: contratto))
    );
    
    // 2. Una volta tornati qui, forziamo la ricostruzione della pagina.
    // Questo farà ripartire il ciclo 'for' con i nuovi prezzi appena salvati!
    if (mounted) {
      setState(() {});
    }
  },
),
                                      if (homeProv.allContracts.length > 1)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                          onPressed: () => homeProv.deleteContract(contratto.id),
                                        ),
                                    ],
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
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )),
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