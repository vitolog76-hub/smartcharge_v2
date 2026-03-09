import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:origo/models/contract_model.dart';
import 'package:origo/models/charge_session.dart';
import 'package:origo/models/car_model.dart';
import 'package:origo/services/sync_service.dart';
import 'package:origo/providers/auth_provider.dart';
import 'package:origo/providers/home_provider.dart';
import 'package:origo/screens/contract_summary_page.dart';
import 'package:provider/provider.dart';
import 'package:origo/pages/add_contract_page.dart';
import 'package:origo/services/cost_calculator.dart';
import 'package:flutter/services.dart';
import 'package:origo/providers/locale_provider.dart';
import 'package:origo/l10n/app_localizations.dart';

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
  late TextEditingController _batteryController;
  DropdownMenuItem<String> _buildBatteryMenuItem(String value, String displayText) {
  return DropdownMenuItem(
    value: value,
    child: Text(displayText),
  );
}
  
  bool _isSyncing = false;
  late bool _isMonorario;

  // --- MODIFICA 1: AGGIUNGI QUESTA RIGA ---
  String _selectedBatteryType = "NMC / NCA"; 

  @override
  void initState() {
    super.initState();
    
    _providerController = TextEditingController(text: widget.contract.provider);
    _nameController = TextEditingController(text: widget.homeProvider.globalUserName);
    _batteryController = TextEditingController(text: widget.homeProvider.capacityController.text);
    _f1Controller = TextEditingController(text: widget.contract.f1Price.toString());
    _f2Controller = TextEditingController(text: widget.contract.f2Price.toString());
    _f3Controller = TextEditingController(text: widget.contract.f3Price.toString());
    _idController = TextEditingController();
    
    _isMonorario = widget.contract.isMonorario;
    
    // --- MODIFICA 2: CHIAMA IL CARICAMENTO DATI ---
    _loadSettingsData(); 
  }

  // Creiamo questa funzione per caricare tutto all'avvio
  Future<void> _loadSettingsData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _idController.text = prefs.getString('user_sync_id') ?? "";
      // Legge la batteria salvata, se non c'è usa il default
      _selectedBatteryType = prefs.getString('battery_chemistry') ?? "NMC / NCA";
      
      String? savedName = prefs.getString('global_user_name');
      if (savedName != null && savedName.isNotEmpty) {
        _nameController.text = savedName;
      }
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _batteryController.dispose();
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
  // --- 1. VALIDAZIONE DI SICUREZZA ---
  // Puliamo il testo da spazi e uniformiamo la virgola col punto
  String batteryRaw = _batteryController.text.trim().replaceAll(',', '.');
  double? batteryValue = double.tryParse(batteryRaw);

  // Controllo se il valore è nullo, zero o negativo
  if (batteryValue == null || batteryValue <= 0) {
    _showErrorDialog(
      "VALORE NON VALIDO", 
      "Inserisci una capacità batteria maggiore di zero per permettere il calcolo dei costi."
    );
    return; // Interrompe l'esecuzione e non salva nulla
  }

  // --- 2. PREPARAZIONE DATI ---
  String userId = _idController.text.trim();
  String nuovoNomeProfilo = _nameController.text.trim(); 
  final homeProv = context.read<HomeProvider>();

  setState(() => _isSyncing = true);
  
  // --- 3. AGGIORNAMENTO PROVIDER (Dati Tecnici) ---
  // Salviamo il valore pulito (formato numerico corretto)
  homeProv.capacityController.text = batteryValue.toString();
  
  // 3.1 Aggiornamento Chimica
  homeProv.refreshBatteryChemistry(_selectedBatteryType); 

  // --- 4. PERSISTENZA E CLOUD ---
  // 4.1 Profilo (Nome e ID)
  await homeProv.syncUserProfile(nuovoNomeProfilo);

  // 4.2 Preferenze Locali
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('battery_chemistry', _selectedBatteryType);
  
  if (userId.isNotEmpty) {
    await prefs.setString('user_sync_id', userId);
  }

  // 4.3 Dettagli Contratto
  homeProv.updateActiveContractDetails(
    provider: _providerController.text,
    isMonorario: _isMonorario,
    f1: double.tryParse(_f1Controller.text) ?? homeProv.myContract.f1Price,
    f2: double.tryParse(_f2Controller.text),
    f3: double.tryParse(_f3Controller.text),
  );

  // --- 5. SALVATAGGIO FINALE E CHIUSURA ---
  await homeProv.salvaTuttiParametri(); 

  setState(() => _isSyncing = false);
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Impostazioni e Batteria salvate!"),
        backgroundColor: Colors.green,
      )
    );
    Navigator.pop(context, true);
  }
}

  Future<void> _importFromCloud(String userId) async {
    if (userId.isEmpty) {
      _showErrorDialog("Errore", "Inserisci un ID valido.");
      return;
    }
    setState(() => _isSyncing = true);
    try {
      var data = await SyncService().downloadAllData(userId);
      if (data != null) {
        await context.read<HomeProvider>().refreshAfterSettings();
        final homeProv = context.read<HomeProvider>();
        final l10n = AppLocalizations.of(context)!;
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _nameController.text = homeProv.globalUserName;
          _selectedBatteryType = prefs.getString('battery_chemistry') ?? "NMC / NCA";
          _providerController.text = homeProv.myContract.provider;
          _f1Controller.text = homeProv.myContract.f1Price.toString();
        });
      }
    } catch (e) {
      _showErrorDialog("Errore", "Sincronizzazione fallita.");
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
      ),
    );
  }

  Future<bool?> _showLogoutConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("ANNULLA")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("ESCI", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) => _showErrorDialog(title, message);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              title: Text(
  l10n.settingsSystem,
  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)
),
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
                   _buildSectionTitle(l10n.cloudSync),  // "1 - SINCRONIZZAZIONE CLOUD"
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
                              decoration: InputDecoration(
  labelText: l10n.userId,  // "ID SINCRONIZZAZIONE"
  labelStyle: const TextStyle(color: Colors.white38, fontSize: 10),
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

                    _buildSectionTitle(l10n.userVehicleData),
_buildCard(
  child: Column(
    children: [
      _buildInput(l10n.userName, _nameController, Icons.person_outline),
      const Divider(color: Colors.white10, indent: 50),
      _buildStaticRow(
  Icons.directions_car, 
  l10n.selectedCar, 
  widget.selectedCar.model.toUpperCase()
),
      const Divider(color: Colors.white10, indent: 50),
      
      // --- CAPACITÀ BATTERIA EDITABILE ---
      // --- MODULO CAPACITÀ BATTERIA MODERNIZZATO ---
Container(
  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    // Effetto vetro scuro per far risaltare il modulo
    color: Colors.white.withOpacity(0.04), 
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withOpacity(0.08)),
  ),
  child: Row(
    children: [
      // Icona con bagliore neon
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.cyanAccent.withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: const Icon(Icons.bolt_rounded, color: Colors.cyanAccent, size: 22),
      ),
      const SizedBox(width: 16),
      
      // Testo informativo a doppia riga
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
  Text(
    l10n.nominalValue,  // "VALORE NOMINALE"
    style: TextStyle(
      color: Colors.cyanAccent, 
      fontSize: 8, 
      fontWeight: FontWeight.w900,
      letterSpacing: 1.5
    ),
  ),
  SizedBox(height: 2),
  Text(
    l10n.batteryCapacity,  // "CAPACITÀ (kWh)"
    style: TextStyle(
      color: Colors.white, 
      fontSize: 13, 
      fontWeight: FontWeight.bold
    ),
  ),
],
        ),
      ),

      // Box di inserimento stile "Display Digitale"
      Container(
        width: 95,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5), // Sfondo nero profondo
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: TextField(
          controller: _batteryController,
          inputFormatters: [
  FilteringTextInputFormatter.allow(RegExp(r'(^\d*[\.,]?\d*)')),
],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.cyanAccent, 
            fontWeight: FontWeight.w900, 
            fontSize: 18,
            fontFamily: 'Courier', // Se vuoi un look ancora più tecnico/digitale
          ),
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            hintText: "0.0",
            hintStyle: TextStyle(color: Colors.white10),
          ),
        ),
      ),
    ],
  ),
),
    ],
  ),
),
// --- NUOVA SEZIONE BATTERIA ---
_buildSectionTitle(l10n.batteryIntelligence), // "3 - INTELLIGENZA BATTERIA"
_buildCard(
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.batteryChemistry, style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedBatteryType,
            isExpanded: true, 
            dropdownColor: const Color(0xFF0F172A),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            items: [
              _buildBatteryMenuItem("NMC / NCA", l10n.batteryChemistryNmc),
              _buildBatteryMenuItem("LFP", l10n.batteryChemistryLfp),
              _buildBatteryMenuItem("UNKNOWN", l10n.batteryChemistryUnknown),
            ],
            onChanged: (val) {
              setState(() {
                _selectedBatteryType = val!;
              });
            },
          ),
        ),
        const Divider(color: Colors.white10, height: 20),
        Text(
          _selectedBatteryType == "LFP" 
            ? l10n.adviceLfpFull
            : _selectedBatteryType == "NMC / NCA"
                ? l10n.adviceNmcFull
                : l10n.adviceGenericFull,
          style: const TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
        ),
      ],
    ),
  ),
),
                    _buildSectionTitle(l10n.contracts), // "4 - GESTIONE CONTRATTI ENERGIA"
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
                                child: Row(
                                  children: [
                                    Icon(Icons.pie_chart, color: Colors.cyanAccent, size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(l10n.contractDetails, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                    Icon(Icons.arrow_forward, color: Colors.cyanAccent, size: 16),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(color: Colors.white10, height: 30),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(l10n.yourPlans, style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
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
                                                          Text(
  differenzaTotale >= 0 
      ? l10n.savingsMessage(differenzaTotale.toStringAsFixed(2))
      : l10n.extraCostMessage(differenzaTotale.abs().toStringAsFixed(2)),
  style: TextStyle(
    color: differenzaTotale >= 0 ? Colors.greenAccent : Colors.redAccent,
    fontSize: 10, 
    fontWeight: FontWeight.w900
  ),
),
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
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_circle_outline, color: Colors.cyanAccent, size: 18),
                                            SizedBox(width: 8),
                                            Text(
  l10n.addContract,
  style: const TextStyle(
    color: Colors.cyanAccent, 
    fontWeight: FontWeight.bold, 
    fontSize: 11
  ),
),
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

                    _buildSectionTitle(l10n.languageSection),
_buildCard(
  child: Consumer<LocaleProvider>(
    builder: (context, localeProvider, child) {
      return ListTile(
        leading: const Icon(Icons.language, color: Colors.cyanAccent),
        title: const Text("Lingua / Language"),
        subtitle: Row(
          children: [
            _getFlag(localeProvider.locale.languageCode),
            const SizedBox(width: 8),
            Text(_getLanguageName(localeProvider.locale)),
          ],
        ),
        trailing: DropdownButton<Locale>(
          value: localeProvider.locale,
          dropdownColor: const Color(0xFF0F172A),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
          onChanged: (Locale? newLocale) {
            if (newLocale != null) {
              localeProvider.setLocale(newLocale);
            }
          },
          items: [
            _buildDropdownItem('it', 'IT', 'Italiano', '🇮🇹'),
            _buildDropdownItem('en', 'US', 'English', '🇬🇧'),
            _buildDropdownItem('es', 'ES', 'Español', '🇪🇸'),
            _buildDropdownItem('de', 'DE', 'Deutsch', '🇩🇪'),
            _buildDropdownItem('fr', 'FR', 'Français', '🇫🇷'),
          ],
        ),
      );
    },
  ),
),

const SizedBox(height: 25),
                    
                    _buildSectionTitle("5 - ACCOUNT"),
                    _buildCard(
                      child: ListTile(
                        leading: const Icon(Icons.logout, color: Colors.redAccent),
                        title: Text(l10n.logout, style: const TextStyle(color: Colors.redAccent)),
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
                          : Text(
  l10n.saveAllChanges,
  style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
),
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
String _getLanguageName(Locale locale) {
  switch (locale.languageCode) {
    case 'it': return 'Italiano';
    case 'en': return 'English';
    case 'es': return 'Español';
    case 'de': return 'Deutsch';
    case 'fr': return 'Français';
    default: return 'Italiano';
  }
}
DropdownMenuItem<Locale> _buildDropdownItem(
  String languageCode, 
  String countryCode, 
  String name, 
  String flag
) {
  return DropdownMenuItem(
    value: Locale(languageCode, countryCode),
    child: Row(
      children: [
        Text(flag, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(name),
      ],
    ),
  );
}

Widget _getFlag(String languageCode) {
  switch (languageCode) {
    case 'it': return const Text('🇮🇹', style: TextStyle(fontSize: 20));
    case 'en': return const Text('🇬🇧', style: TextStyle(fontSize: 20));
    case 'es': return const Text('🇪🇸', style: TextStyle(fontSize: 20));
    case 'de': return const Text('🇩🇪', style: TextStyle(fontSize: 20));
    case 'fr': return const Text('🇫🇷', style: TextStyle(fontSize: 20));
    default: return const Text('🇮🇹', style: TextStyle(fontSize: 20));
  }
}


}