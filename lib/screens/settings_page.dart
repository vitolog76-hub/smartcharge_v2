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

// IMPORT DEI NUOVI WIDGET
import 'package:origo/widgets/settings/expandable_section.dart';
import 'package:origo/widgets/settings/account_section.dart';
import 'package:origo/widgets/settings/user_vehicle_section.dart';
import 'package:origo/widgets/settings/contracts_section.dart';
import 'package:origo/widgets/settings/language_section.dart';

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

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin {
  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _providerController;
  late TextEditingController _f1Controller;
  late TextEditingController _f2Controller;
  late TextEditingController _f3Controller;
  late TextEditingController _batteryController;
  
  bool _isSyncing = false;
  late bool _isMonorario;
  String _selectedBatteryType = "NMC / NCA";

  // Stato delle 4 sezioni espandibili
  late Map<String, bool> _expandedSections;
  late Map<String, AnimationController> _animationControllers;
  late Map<String, Animation<double>> _animations;

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
    
    // 4 sezioni: tutte chiuse tranne account aperto di default
    _expandedSections = {
      'account': true,           // ACCOUNT (aperto di default)
      'userVehicle': false,      // DATI UTENTE E VEICOLO
      'contracts': false,        // GESTIONE CONTRATTI ENERGIA
      'language': false,         // LINGUA
    };
    
    _animationControllers = {};
    _animations = {};
    
    for (var key in _expandedSections.keys) {
      _animationControllers[key] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      );
      _animations[key] = CurvedAnimation(
        parent: _animationControllers[key]!,
        curve: Curves.easeInOut,
      );
      
      if (_expandedSections[key] == true) {
        _animationControllers[key]!.forward();
      }
    }
    
    _loadSettingsData();
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
    
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  void _toggleSection(String sectionKey) {
    setState(() {
      bool isExpanded = _expandedSections[sectionKey] ?? false;
      _expandedSections[sectionKey] = !isExpanded;
      
      if (!isExpanded) {
        _animationControllers[sectionKey]?.forward();
      } else {
        _animationControllers[sectionKey]?.reverse();
      }
    });
  }

  Future<void> _loadSettingsData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _idController.text = prefs.getString('user_sync_id') ?? "";
      _selectedBatteryType = prefs.getString('battery_chemistry') ?? "NMC / NCA";
      
      String? savedName = prefs.getString('global_user_name');
      if (savedName != null && savedName.isNotEmpty) {
        _nameController.text = savedName;
      }
    });
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

  void _saveAll() async {
    String batteryRaw = _batteryController.text.trim().replaceAll(',', '.');
    double? batteryValue = double.tryParse(batteryRaw);

    if (batteryValue == null || batteryValue <= 0) {
      _showErrorDialog(
        "VALORE NON VALIDO", 
        "Inserisci una capacità batteria maggiore di zero per permettere il calcolo dei costi."
      );
      return;
    }

    String userId = _idController.text.trim();
    String nuovoNomeProfilo = _nameController.text.trim(); 
    final homeProv = context.read<HomeProvider>();

    setState(() => _isSyncing = true);
    
    homeProv.capacityController.text = batteryValue.toString();
    homeProv.refreshBatteryChemistry(_selectedBatteryType); 

    await homeProv.syncUserProfile(nuovoNomeProfilo);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('battery_chemistry', _selectedBatteryType);
    
    if (userId.isNotEmpty) {
      await prefs.setString('user_sync_id', userId);
    }

    homeProv.updateActiveContractDetails(
      provider: _providerController.text,
      isMonorario: _isMonorario,
      f1: double.tryParse(_f1Controller.text) ?? homeProv.myContract.f1Price,
      f2: double.tryParse(_f2Controller.text),
      f3: double.tryParse(_f3Controller.text),
    );

    await homeProv.salvaTuttiParametri(); 

    setState(() => _isSyncing = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Impostazioni salvate!"),
          backgroundColor: Colors.green,
        )
      );
      Navigator.pop(context, true);
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
        content: const Text("Sei sicuro di voler uscire?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("ANNULLA")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("ESCI", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

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
              Color(0xFF0F172A),
              Color(0xFF020617),
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
                    // 1. ACCOUNT (ID + Logout)
                    AccountSection(
                      idController: _idController,
                      onImport: () => _importFromCloud(_idController.text.trim()),
                      onShowLogoutConfirm: _showLogoutConfirmDialog,
                      isExpanded: _expandedSections['account']!,
                      animation: _animations['account']!,
                      onToggle: () => _toggleSection('account'),
                    ),

                    const SizedBox(height: 8),

                    // 2. DATI UTENTE E VEICOLO
                    UserVehicleSection(
                      nameController: _nameController,
                      selectedCar: widget.selectedCar,
                      batteryController: _batteryController,
                      selectedBatteryType: _selectedBatteryType,
                      onBatteryTypeChanged: (val) => setState(() => _selectedBatteryType = val),
                      isExpanded: _expandedSections['userVehicle']!,
                      animation: _animations['userVehicle']!,
                      onToggle: () => _toggleSection('userVehicle'),
                    ),

                    const SizedBox(height: 8),

                    // 3. GESTIONE CONTRATTI ENERGIA
                    ContractsSection(
                      providerController: _providerController,
                      f1Controller: _f1Controller,
                      isMonorario: _isMonorario,
                      onContractSelected: (contract) {
                        _providerController.text = contract.provider;
                        _f1Controller.text = contract.f1Price.toString();
                      },
                      isExpanded: _expandedSections['contracts']!,
                      animation: _animations['contracts']!,
                      onToggle: () => _toggleSection('contracts'),
                    ),

                    const SizedBox(height: 8),

                    // 4. LINGUA
                    LanguageSection(
                      isExpanded: _expandedSections['language']!,
                      animation: _animations['language']!,
                      onToggle: () => _toggleSection('language'),
                    ),

                    const SizedBox(height: 30),

                    if (_isSyncing) const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: CircularProgressIndicator(color: Colors.cyanAccent),
                      ),
                    ),

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
                              l10n.saveAllChanges,  // <-- AGGIUNTA LA TRADUZIONE
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
}