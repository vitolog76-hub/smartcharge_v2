import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:origo/models/car_model.dart';
import 'package:origo/models/contract_model.dart';
import 'package:origo/models/charge_session.dart';
import 'package:origo/services/charge_engine.dart';
import 'package:origo/services/cost_calculator.dart';
import 'package:origo/services/simulation_service.dart';
import 'package:origo/services/sync_service.dart';
import 'package:intl/intl.dart';
import 'package:origo/services/notification_service.dart';
import 'package:origo/l10n/app_localizations.dart';

class HomeProvider extends ChangeNotifier {
  // --- STATO ---
  double currentSoc = -1;
  double targetSoc = 80.0;
  double _socAtStartOfSim = -1;
  double wallboxPwr = 3.7;
  double lastSavedEnergy = 0.0;
  double lastSavedCost = 0.0;
  TimeOfDay readyTime = const TimeOfDay(hour: 7, minute: 0);
  
  late CarModel selectedCar;
  List<CarModel> allCars = [];
  bool carsLoaded = false;
  final capacityController = TextEditingController();
  List<ChargeSession> chargeHistory = [];
  static const String KEY_SOC_INIZIALE_CONGELATO = 'soc_iniziale_congelato';
  static const String KEY_TIMESTAMP_INIZIO_CONGELATO = 'timestamp_inizio_congelato'; 
  
  final SimulationService simService = SimulationService();
  bool isSimulating = false;
  bool _showCompletionDialog = false;
  bool _isSavingCompletion = false;
  bool _showErrorDialog = false;
  bool get showTaperingWarning => targetSoc > 80;
  List<EnergyContract> allContracts = [];

  String activeContractId = "";

  // 🔥 STATO DI SALVATAGGIO
  bool _isSaving = false;
  int _saveProgress = 0;
  String _saveStep = "";
  String? _saveError;
  bool _saveSuccess = false;

  // 🔥 STATO DI INIZIALIZZAZIONE
  bool _isInitializing = true;
  double _initProgress = 0.0;
  String _initMessage = "Avvio applicazione...";
  String? _initSubMessage;

  // Getter
  bool get isSaving => _isSaving;
  int get saveProgress => _saveProgress;
  String get saveStep => _saveStep;
  String? get saveError => _saveError;
  bool get saveSuccess => _saveSuccess;
  bool get isInitializing => _isInitializing;
  double get initProgress => _initProgress;
  String get initMessage => _initMessage;
  String? get initSubMessage => _initSubMessage;
  bool get isSavingCompletion => _isSavingCompletion;
  bool get shouldShowErrorDialog => _showErrorDialog;

  // 🔥 NOME UTENTE GLOBALE (PROFILO) - INDIPENDENTE DAI CONTRATTI
  String _globalUserName = "Utente";
  String get globalUserName => _globalUserName;
  String _batteryChemistry = "NMC / NCA";
  String get batteryChemistry => _batteryChemistry;

  // Metodo per resettare lo stato di salvataggio
  void resetSaveState() {
    _isSaving = false;
    _saveProgress = 0;
    _saveStep = "";
    _saveError = null;
    _saveSuccess = false;
    notifyListeners();
  }

  // 🔥 METODO PER RESET ERRORI
  void resetErrorDialog() => _showErrorDialog = false;

  String getSmartBatteryAdvice([AppLocalizations? l10n]) {
    final t = l10n;
    
    if (chargeHistory.isEmpty) {
      return t?.batteryAdviceEmpty ?? "Inizia a caricare per ricevere consigli basati sul tuo stile di guida.";
    }

    final ora = DateTime.now();
    
    if (_batteryChemistry == "LFP") {
      bool haCaricatoAl100Recentemente = chargeHistory.any((s) => 
        s.endSoc >= 99 && ora.difference(s.date).inDays <= 7
      );

      if (!haCaricatoAl100Recentemente) {
        return t?.batteryAdviceLfp ?? "⚠️ Non carichi al 100% da più di una settimana. Fallo stasera per allineare le celle (BMS).";
      }
      return t?.batteryAdviceLfpGood ?? "✅ Batteria ben calibrata. Mantieni il target tra 20-80% per il resto della settimana.";
    }

    if (_batteryChemistry == "NMC / NCA") {
      int caricheEccessive = chargeHistory.where((s) => 
        s.endSoc > 85 && ora.difference(s.date).inDays <= 30
      ).length;

      if (caricheEccessive > 4) {
        String message = t?.batteryAdviceNmc ?? "⚠️ Hai caricato oltre l'80% ben %d volte nell'ultimo mese. Cerca di limitarlo per ridurre il degrado.";
        return message.replaceAll('%d', caricheEccessive.toString());
      }
      return t?.batteryAdviceNmcGood ?? "✅ Ottima gestione: stai preservando la chimica al nichel limitando i picchi di carica.";
    }

    return t?.batteryAdviceGeneric ?? "Mantieni la carica tra 20-80% per una longevità ottimale.";
  }

  // --- GESTIONE PROFILO ---
  Future<void> syncUserProfile(String nuovoNome) async {
    _globalUserName = nuovoNome;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('global_user_name', nuovoNome);
    
    final String? userId = prefs.getString('user_sync_id');
    if (userId != null && userId.isNotEmpty) {
      await SyncService().uploadData(
        userId, 
        chargeHistory, 
        allContracts, 
        activeContractId, 
        _globalUserName
      );
    }
    notifyListeners(); 
  }
  
  // Getter per ottenere il contratto attivo corrente
  EnergyContract get myContract {
    if (allContracts.isEmpty) return EnergyContract(id: 'default', contractName: 'Contratto Base');
    return allContracts.firstWhere(
      (c) => c.id == activeContractId,
      orElse: () => allContracts.isNotEmpty ? allContracts.first : EnergyContract(id: 'default', contractName: 'Contratto Base'),
    );
  }

  // --- COSTANTI ---
  static const String KEY_CONTRACTS_LIST = 'energy_contracts_list';
  static const String KEY_ACTIVE_CONTRACT_ID = 'active_contract_id';
  static const String KEY_SOC_INIZIALE = 'saved_current_soc';
  static const String KEY_SOC_TARGET = 'saved_target_soc';
  static const String KEY_WALLBOX_PWR = 'saved_wallbox_pwr';
  static const String KEY_READY_TIME_HOUR = 'ready_time_hour';
  static const String KEY_READY_TIME_MINUTE = 'ready_time_minute';
  static const String KEY_SIM_ACTIVE = 'simulation_active';
  static const String KEY_SIM_START = 'simulation_start';
  static const String KEY_SIM_END = 'simulation_end';
  static const String KEY_SIM_START_SOC = 'simulation_start_soc';

  // --- COSTRUTTORE ---
  HomeProvider() {
    currentSoc = -1.0; 
    _socAtStartOfSim = -1.0;
    carsLoaded = false;

    simService.startChecking(
      onSocUpdate: (newSoc) {
        if (currentSoc == -1.0) return;
        currentSoc = double.parse(newSoc.toStringAsFixed(1));
        _saveSimulationProgress();
        notifyListeners();
      },
      onStatusChange: (status) {
        if (currentSoc == -1.0) return;
        isSimulating = status;
        if (!status) _clearSimulationProgress();
        notifyListeners();
      },
      onSimulationComplete: () {
        if (currentSoc == -1.0) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleSimulationCompletion();
        });
      },
    );
  }

  // 🔥 Gestione completion simulazione
  Future<void> _handleSimulationCompletion() async {
  _isSavingCompletion = true;
  notifyListeners();
  
  // 🔥 Calcola subito i valori per il popup
  final double socIniziale = _socAtStartOfSim;
  final double socFinale = currentSoc;
  final double capacita = currentBatteryCap;
  
  if (socIniziale < currentSoc) {
    final kwhEffettivi = ChargeEngine.calculateEnergy(socIniziale, socFinale, capacita);
    final costoCalcolato = CostCalculator.calculate(
      totalKwh: kwhEffettivi,
      wallboxPower: wallboxPwr,
      startTime: TimeOfDay.fromDateTime(simService.scheduledStart ?? DateTime.now()),
      date: DateTime.now(),
      contract: myContract,
    );
    
    lastSavedEnergy = kwhEffettivi;
    lastSavedCost = costoCalcolato;
  }
  
  _showCompletionDialog = true;
  
  _isSavingCompletion = false;
  _clearSimulationProgress();
  notifyListeners();
}
  Future<void> init() async {
    try {
      debugPrint("🚀 INIT: Inizio caricamento HomeProvider");
      
      _isInitializing = true;
      _initProgress = 0.0;
      _initMessage = "Avvio applicazione...";
      notifyListeners();
      
      _initProgress = 0.2;
      _initMessage = "Caricamento parametri...";
      notifyListeners();
      await _loadSimulationParameters(); 
      
      if (currentSoc == -1.0) {
        currentSoc = 20.0;
        _socAtStartOfSim = 20.0;
      }

      _initProgress = 0.4;
      _initMessage = "Caricamento modelli auto...";
      notifyListeners();
      await _loadCarsFromJson();  
      
      _initProgress = 0.6;
      _initMessage = "Preparazione interfaccia...";
      carsLoaded = true;
      notifyListeners();
      
      _initProgress = 0.8;
      _initMessage = "Caricamento dati aggiuntivi...";
      _initSubMessage = "Questo potrebbe richiedere qualche secondo";
      notifyListeners();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSecondaryData();
      });
      
      _initProgress = 0.9;
      _initMessage = "Quasi pronto...";
      notifyListeners();
      
      Future.delayed(const Duration(seconds: 10), () {
        if (_isInitializing) {
          debugPrint("⏱️ Timeout caricamento secondario, forzo visualizzazione");
          _isInitializing = false;
          notifyListeners();
        }
      });
      
      debugPrint("🚀 INIT: Completato con successo");
    } catch (e, stackTrace) {
      debugPrint("❌❌❌ ERRORE GRAVE IN INIT: $e");
      debugPrint("❌❌❌ STACKTRACE: $stackTrace");
      
      if (currentSoc == -1.0) currentSoc = 20.0;
      if (allCars.isEmpty) {
        selectedCar = CarModel(brand: "Default", model: "EV", batteryCapacity: 50.0);
      }
      _isInitializing = false;
      carsLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _loadSecondaryData() async {
    try {
      debugPrint("🔄 Caricamento dati secondari in background...");
      
      await loadBatteryConfig();
      await _loadContract(); 
      await _loadHistory(); 
      await _loadSimulationProgress();
      _startBackgroundSync();
      
      debugPrint("✅ Dati secondari caricati");
    } catch (e) {
      debugPrint("❌ Errore caricamento dati secondari: $e");
    }
  }

  void _recuperaRicaricaTerminataOffline(DateTime inizioReale, DateTime end) {
    debugPrint("🔄 Eseguo recupero offline in post-init...");
    
    try {
      if (selectedCar.batteryCapacity <= 0) {
        debugPrint("⚠️ Dati auto non ancora caricati, impossibile recuperare - riprovo tra 1 secondo");
        Future.delayed(const Duration(seconds: 1), () {
          _recuperaRicaricaTerminataOffline(inizioReale, end);
        });
        return;
      }
      
      debugPrint("🔄 Calcolo kWh con: socIniziale=$_socAtStartOfSim, target=$targetSoc, capacita=$currentBatteryCap");
      
      final double kwhEffettivi = ChargeEngine.calculateEnergy(
        _socAtStartOfSim, 
        targetSoc, 
        currentBatteryCap
      );
      
      debugPrint("🔄 kWh calcolati: $kwhEffettivi");
      
      final double costoCalcolato = CostCalculator.calculate(
        totalKwh: kwhEffettivi,
        wallboxPower: wallboxPwr,
        startTime: TimeOfDay.fromDateTime(inizioReale),
        date: DateTime.now(),
        contract: myContract,
      );

      debugPrint("🔄 Costo calcolato: $costoCalcolato");

      final session = ChargeSession(
        id: "CHG_${DateTime.now().millisecondsSinceEpoch}", 
        date: DateTime.now(),
        startDateTime: inizioReale,
        endDateTime: DateTime.now(),
        startSoc: _socAtStartOfSim,
        endSoc: targetSoc,
        kwh: kwhEffettivi,
        cost: costoCalcolato,
        location: "Home",
        carBrand: selectedCar.brand,
        carModel: selectedCar.model,
        contractId: activeContractId,
        wallboxPower: wallboxPwr,
        fascia: CostCalculator.getFasciaLabel(
          totalKwh: kwhEffettivi,
          wallboxPower: wallboxPwr,
          startTime: TimeOfDay.fromDateTime(inizioReale),
          date: DateTime.now(),
          isMonorario: myContract.isMonorario,
        ),
        f1PriceAtTime: myContract.f1Price,
        f2PriceAtTime: myContract.f2Price,
        f3PriceAtTime: myContract.f3Price,
      );
      
      chargeHistory.add(session);
      saveHistory();
      
      currentSoc = targetSoc;
      lastSavedEnergy = kwhEffettivi;
      lastSavedCost = costoCalcolato;
      _showCompletionDialog = true;
      
      NotificationService().showChargingCompleteNotification(
        socFinale: targetSoc,
        energia: kwhEffettivi,
        durata: end.difference(inizioReale),
      );
      
      notifyListeners();
      
      debugPrint("✅ Recupero offline completato con successo");
    } catch (e, stackTrace) {
      debugPrint("❌❌❌ Errore nel recupero offline: $e");
      debugPrint("❌❌❌ STACKTRACE: $stackTrace");
    }
  }

  void _startBackgroundSync() {
    debugPrint("☁️ Sync Cloud in corso...");
    Future.delayed(const Duration(seconds: 2), () async {
      await _syncFromCloudBackground();
    });
  }

  Future<void> _syncFromCloudBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_sync_id');
    
    if (userId != null && userId.isNotEmpty) {
      try {
        final cloudData = await SyncService().downloadAllData(userId);
        if (cloudData != null) {
          _updateFromDownload(cloudData);
          notifyListeners();
        }
      } catch (e) {
        debugPrint("☁️ Errore download in background: $e");
      }
    }
  }

  void updateActiveContractDetails({
    required String provider,
    required bool isMonorario,
    required double f1,
    double? f2,
    double? f3,
  }) {
    final index = allContracts.indexWhere((c) => c.id == activeContractId);
    
    if (index != -1) {
      allContracts[index].provider = provider;
      allContracts[index].isMonorario = isMonorario;
      allContracts[index].f1Price = f1;
      allContracts[index].f2Price = isMonorario ? f1 : (f2 ?? f1);
      allContracts[index].f3Price = isMonorario ? f1 : (f3 ?? f1);
      saveAllContracts(); 
    }
  }

  // --- CALCOLI ---
  double get currentBatteryCap => double.tryParse(capacityController.text) ?? (carsLoaded ? selectedCar.batteryCapacity : 50.0);
  double get energyNeeded => ChargeEngine.calculateEnergy(currentSoc, targetSoc, currentBatteryCap);
  Duration get duration => ChargeEngine.calculateDuration(energyNeeded, wallboxPwr);

  DateTime get targetReadyDateTime {
    final now = DateTime.now();
    DateTime target = DateTime(now.year, now.month, now.day, readyTime.hour, readyTime.minute);
    if (target.isBefore(now)) target = target.add(const Duration(days: 1));
    return target;
  }

  DateTime get calculatedStartDateTime => targetReadyDateTime.subtract(duration);
  String get startTimeDisplay => DateFormat('HH:mm').format(calculatedStartDateTime);
  bool get isChargingReal => isSimulating && DateTime.now().isAfter(simService.scheduledStart ?? DateTime.now());

  double get estimatedCost {
    final startTimeOfDay = TimeOfDay.fromDateTime(calculatedStartDateTime);
    return CostCalculator.calculate(
      totalKwh: energyNeeded,
      wallboxPower: wallboxPwr,
      startTime: startTimeOfDay,
      date: DateTime.now(),
      contract: myContract,
    );
  }

  // --- AZIONI SIMULAZIONE ---
  void startSimulation() {
    _socAtStartOfSim = currentSoc; 

    _clearSimulationProgress().then((_) async {
      DateTime startTime = calculatedStartDateTime;
      final now = DateTime.now();
      if (startTime.isBefore(now)) startTime = now;

      simService.initSimulation(
        startDateTime: startTime,
        currentSoc: _socAtStartOfSim,
        targetSoc: targetSoc,
        pwr: wallboxPwr,
        cap: currentBatteryCap,
      );

      NotificationService().showChargingStartedNotification(
        socIniziale: _socAtStartOfSim,
        socTarget: targetSoc,
        startTime: startTime,
      );

      NotificationService().scheduleChargingComplete(
        id: 999,
        completionTime: simService.endTime ?? now.add(duration),
        socFinale: targetSoc,
        energia: energyNeeded,
        durata: duration,
      );

      isSimulating = true;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(KEY_SOC_INIZIALE_CONGELATO, _socAtStartOfSim);
      await prefs.setInt(KEY_TIMESTAMP_INIZIO_CONGELATO, startTime.millisecondsSinceEpoch);
      
      _saveSimulationProgress();
      notifyListeners();
    });
  }

  Future<void> loadBatteryConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _batteryChemistry = prefs.getString('battery_chemistry') ?? "NMC / NCA";
    notifyListeners();
  }

  void stopSimulation() {
    simService.stopSimulation();
    NotificationService().cancelAllNotifications(); 
    isSimulating = false;
    _clearSimulationProgress();
    _saveSimulationParameters();
    notifyListeners();
  }

  void addChargeSession(ChargeSession session) {
    chargeHistory.add(session);
    saveHistory();
    _syncHistoryIfPossible();
    notifyListeners();
  }

  void saveCurrentCharge() {
    if (_socAtStartOfSim < currentSoc) {
      _saveCompletedCharge();
    }
  }

  Future<bool> _saveCompletedCharge() async {
    _isSaving = true;
    _saveProgress = 0;
    _saveSuccess = false;
    _saveError = null;
    notifyListeners();

    try {
      _saveStep = "Preparazione dati...";
      _saveProgress = 10;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));

      final now = DateTime.now();
      final double socIniziale = _socAtStartOfSim;
      final double socFinale = currentSoc;
      final double capacita = currentBatteryCap;
      
      if (socIniziale < 0 || socFinale < 0 || capacita <= 0) {
        _saveError = "Dati non validi";
        return false;
      }
      
      final kwhEffettivi = ChargeEngine.calculateEnergy(socIniziale, socFinale, capacita);
      
      if (kwhEffettivi <= 0.05) {
        _saveError = "Energia troppo bassa";
        _saveProgress = 0;
        return false;
      }

      if (chargeHistory.isNotEmpty) {
        final last = chargeHistory.last;
        bool stessaOra = now.difference(last.date).inSeconds.abs() < 30;
        bool stessoSoc = (last.endSoc - socFinale).abs() < 0.1;
        if (stessaOra && stessoSoc) {
          _isSaving = false;
          notifyListeners();
          return false;
        }
      }

      _saveStep = "Calcolo costi energetici...";
      _saveProgress = 25;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));

      final contrattoAttivo = myContract;
      final costoCalcolato = CostCalculator.calculate(
        totalKwh: kwhEffettivi,
        wallboxPower: wallboxPwr,
        startTime: TimeOfDay.fromDateTime(simService.scheduledStart ?? now),
        date: now,
        contract: contrattoAttivo,
      );

      final session = ChargeSession(
        id: "CHG_${now.millisecondsSinceEpoch}_${now.microsecond}", 
        date: now,
        startDateTime: simService.scheduledStart ?? now,
        endDateTime: now,
        startSoc: socIniziale,
        endSoc: socFinale,
        kwh: kwhEffettivi,
        cost: costoCalcolato,
        location: "Home",
        carBrand: selectedCar.brand,
        carModel: selectedCar.model,
        contractId: activeContractId,
        wallboxPower: wallboxPwr,
        fascia: CostCalculator.getFasciaLabel(
          totalKwh: kwhEffettivi,
          wallboxPower: wallboxPwr,
          startTime: TimeOfDay.fromDateTime(simService.scheduledStart ?? now),
          date: now,
          isMonorario: contrattoAttivo.isMonorario,
        ),
        f1PriceAtTime: contrattoAttivo.f1Price,
        f2PriceAtTime: contrattoAttivo.f2Price,
        f3PriceAtTime: contrattoAttivo.f3Price,
      );
      
      chargeHistory.add(session);

      _saveStep = "Salvataggio su dispositivo...";
      _saveProgress = 50;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));
      
      await saveHistory();

      _saveStep = "Sincronizzazione con Cloud...";
      _saveProgress = 75;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_sync_id');
      
      if (userId != null && userId.isNotEmpty) {
        await SyncService().uploadData(
          userId, 
          chargeHistory, 
          allContracts, 
          activeContractId, 
          _globalUserName
        );
      }

      _saveStep = "Verifica finale...";
      _saveProgress = 90;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 500));

      lastSavedEnergy = kwhEffettivi;
      lastSavedCost = costoCalcolato;
      _socAtStartOfSim = currentSoc;
      
      _saveStep = "Completato!";
      _saveProgress = 100;
      _saveSuccess = true;
      notifyListeners();
      
      await Future.delayed(const Duration(seconds: 1));
      
      debugPrint("✅ Ricarica salvata: ${kwhEffettivi.toStringAsFixed(2)} kWh, ${costoCalcolato.toStringAsFixed(2)} €");
      return true;
      
    } catch (e, stackTrace) {
      _saveError = "Errore: $e";
      _saveProgress = 0;
      debugPrint("❌ ERRORE GRAVE salvataggio: $e");
      debugPrint("❌ STACKTRACE: $stackTrace");
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // --- PERSISTENZA E SYNC ---
  Future<bool> saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonData = jsonEncode(chargeHistory.map((s) => s.toJson()).toList());
      
      if (jsonData.isEmpty || jsonData == '[]') {
        debugPrint("⚠️ Tentativo di salvare history vuota, ignorato");
        return false;
      }
      
      bool success = await prefs.setString('charge_history', jsonData);
      
      if (success) {
        final savedData = prefs.getString('charge_history');
        if (savedData == jsonData) {
          await prefs.setInt('last_local_update', DateTime.now().millisecondsSinceEpoch);
          debugPrint("💾 History salvata e VERIFICATA: ${chargeHistory.length} sessioni");
          return true;
        } else {
          debugPrint("⚠️ Verifica fallita: dato salvato non corrisponde");
          return false;
        }
      } else {
        debugPrint("⚠️ SharedPreferences ha restituito 'false'");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Errore durante il salvataggio: $e");
      return false;
    }
  }

  Future<void> _syncHistoryIfPossible() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_sync_id');
    if (userId != null && userId.isNotEmpty) {
      await SyncService().uploadData(
        userId, 
        chargeHistory, 
        allContracts, 
        activeContractId, 
        _globalUserName
      );
    }
  }

  Future<void> saveAllContracts() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('global_user_name', _globalUserName);
    
    final String jsonData = jsonEncode(allContracts.map((c) => c.toJson()).toList());
    await prefs.setString(KEY_CONTRACTS_LIST, jsonData);
    await prefs.setString(KEY_ACTIVE_CONTRACT_ID, activeContractId);

    final userId = prefs.getString('user_sync_id');
    if (userId != null && userId.isNotEmpty) { 
      await SyncService().uploadData(
        userId, 
        chargeHistory, 
        allContracts, 
        activeContractId, 
        _globalUserName
      );
    }
    notifyListeners();
  }

  void selectActiveContract(String id) {
    activeContractId = id;
    saveAllContracts();
  }

  void addOrUpdateContract(EnergyContract contract) {
    final index = allContracts.indexWhere((c) => c.id == contract.id);
    if (index != -1) {
      allContracts[index] = contract;
    } else {
      allContracts.add(contract);
    }
    saveAllContracts();
  }

  void deleteContract(String id) {
    if (allContracts.length > 1) { 
      allContracts.removeWhere((c) => c.id == id);
      if (activeContractId == id) {
        activeContractId = allContracts.first.id;
      }
      saveAllContracts();
      notifyListeners();
    }
  }

  void refreshBatteryChemistry(String newChemistry) {
    _batteryChemistry = newChemistry;
    notifyListeners();
  }

  // --- PARAMETRI SIMULAZIONE ---
  Future<void> salvaTuttiParametri() async { await _saveSimulationParameters(); }

  Future<void> _loadSimulationParameters() async {
    final prefs = await SharedPreferences.getInstance();
    
    currentSoc = prefs.getDouble(KEY_SOC_INIZIALE) ?? 20.0;
    _socAtStartOfSim = currentSoc; 
    
    targetSoc = prefs.getDouble(KEY_SOC_TARGET) ?? 80.0;
    wallboxPwr = prefs.getDouble(KEY_WALLBOX_PWR) ?? 3.7;
    
    final h = prefs.getInt(KEY_READY_TIME_HOUR);
    final m = prefs.getInt(KEY_READY_TIME_MINUTE);
    if (h != null && m != null) {
      readyTime = TimeOfDay(hour: h, minute: m);
    }
    
    debugPrint("📥 Parametri caricati: SoC attuale $currentSoc%, StartSim: $_socAtStartOfSim%");
  }
  
  Future<void> _saveSimulationParameters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(KEY_SOC_INIZIALE, currentSoc);
    await prefs.setDouble(KEY_SOC_TARGET, targetSoc);
    await prefs.setDouble(KEY_WALLBOX_PWR, wallboxPwr);
    await prefs.setInt(KEY_READY_TIME_HOUR, readyTime.hour);
    await prefs.setInt(KEY_READY_TIME_MINUTE, readyTime.minute);
  }

  Future<void> _saveSimulationProgress() async {
    if (!isSimulating) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(KEY_SIM_ACTIVE, true);
    await prefs.setString(KEY_SIM_START, simService.scheduledStart?.toIso8601String() ?? '');
    await prefs.setString(KEY_SIM_END, simService.endTime?.toIso8601String() ?? '');
    await prefs.setDouble(KEY_SIM_START_SOC, _socAtStartOfSim);
  }

  Future<void> _loadSimulationProgress() async {
    try {
      debugPrint("📂 _loadSimulationProgress: INIZIO");
      
      await Future.any([
        _loadSimulationProgressInternal(),
        Future.delayed(const Duration(seconds: 3), () {
          debugPrint("⏱️ TIMEOUT _loadSimulationProgress, forzo uscita");
          return null;
        })
      ]);
    } catch (e) {
      debugPrint("❌ ERRORE TIMEOUT: $e");
      await _clearSimulationProgress();
      isSimulating = false;
      notifyListeners();
    }
  }

  Future<void> _loadSimulationProgressInternal() async {
    if (!carsLoaded || selectedCar.batteryCapacity <= 0) {
      debugPrint("⚠️ Dati auto non pronti, rimando _loadSimulationProgress");
      await Future.delayed(const Duration(milliseconds: 300));
      _loadSimulationProgressInternal();
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    
    if (!(prefs.getBool(KEY_SIM_ACTIVE) ?? false)) {
      debugPrint("ℹ️ Nessun progresso da ripristinare.");
      return;
    }

    debugPrint("📂 Trovata simulazione attiva in SharedPreferences");
    
    final String? startStr = prefs.getString(KEY_SIM_START);
    final String? endStr = prefs.getString(KEY_SIM_END);
    final double? savedStartSoc = prefs.getDouble(KEY_SIM_START_SOC);
    
    debugPrint("📂 startStr: $startStr, endStr: $endStr, savedStartSoc: $savedStartSoc");
    
    if (startStr == null || endStr == null || savedStartSoc == null) {
      debugPrint("⚠️ Dati simulazione incompleti, pulisco...");
      await _clearSimulationProgress();
      return;
    }

    final start = DateTime.parse(startStr);
    final end = DateTime.parse(endStr);
    final now = DateTime.now();
    
    final double? socInizialeCongelato = prefs.getDouble(KEY_SOC_INIZIALE_CONGELATO);
    final int? timestampInizioCongelato = prefs.getInt(KEY_TIMESTAMP_INIZIO_CONGELATO);
    
    debugPrint("📂 socInizialeCongelato: $socInizialeCongelato, timestampInizioCongelato: $timestampInizioCongelato");
    
    _socAtStartOfSim = socInizialeCongelato ?? savedStartSoc;
    final DateTime inizioReale = timestampInizioCongelato != null 
        ? DateTime.fromMillisecondsSinceEpoch(timestampInizioCongelato)
        : start;
    
    debugPrint("📂 _socAtStartOfSim: $_socAtStartOfSim, inizioReale: $inizioReale");

    if (now.isAfter(end)) {
      debugPrint("🏁 Carica terminata offline. Pianifico salvataggio post-init...");
      
      if (selectedCar.batteryCapacity <= 0) {
        debugPrint("⚠️ Dati auto non ancora caricati, rimando recupero...");
        Future.delayed(const Duration(milliseconds: 500), () {
          _recuperaRicaricaTerminataOffline(inizioReale, end);
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _recuperaRicaricaTerminataOffline(inizioReale, end);
        });
      }
      
      isSimulating = false;
      await _clearSimulationProgress();
      notifyListeners();
    } else {
      debugPrint("⚡ Ripristino simulazione attiva...");
      
      if (selectedCar.batteryCapacity > 0) {
        simService.restoreSimulation(
          startDateTime: inizioReale,
          endDateTime: end, 
          currentSoc: _socAtStartOfSim,
          targetSoc: targetSoc, 
          pwr: wallboxPwr, 
          cap: currentBatteryCap
        );
        isSimulating = true;
      } else {
        debugPrint("⚠️ Dati auto non ancora caricati, rimando ripristino...");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (selectedCar.batteryCapacity > 0) {
            simService.restoreSimulation(
              startDateTime: inizioReale,
              endDateTime: end, 
              currentSoc: _socAtStartOfSim,
              targetSoc: targetSoc, 
              pwr: wallboxPwr, 
              cap: currentBatteryCap
            );
            isSimulating = true;
            notifyListeners();
          }
        });
      }
      notifyListeners();
    }
    
    debugPrint("📂 _loadSimulationProgress: FINE");
  }

  Future<void> _clearSimulationProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_SIM_ACTIVE);
    await prefs.remove(KEY_SIM_START);
    await prefs.remove(KEY_SIM_END);
    await prefs.remove(KEY_SIM_START_SOC);
    await prefs.remove(KEY_SOC_INIZIALE_CONGELATO);
    await prefs.remove(KEY_TIMESTAMP_INIZIO_CONGELATO);
  }

  // --- CARICAMENTO DATI ---
  Future<void> _loadCarsFromJson() async {
    final String response = await rootBundle.loadString('assets/cars.json');
    final List<dynamic> data = json.decode(response);
    allCars = data.map((item) => CarModel.fromJson(item)).toList();
    final prefs = await SharedPreferences.getInstance();
    final b = prefs.getString('selected_car_brand');
    final m = prefs.getString('selected_car_model');
    selectedCar = allCars.firstWhere((c) => c.brand == b && c.model == m, orElse: () => allCars.first);
    capacityController.text = selectedCar.batteryCapacity.toString();
    carsLoaded = true;
  }

  Future<void> _loadContract() async {
    final prefs = await SharedPreferences.getInstance();
    
    _globalUserName = prefs.getString('global_user_name') ?? "Utente";

    final String? listData = prefs.getString(KEY_CONTRACTS_LIST);
    if (listData != null) {
      final List<dynamic> decoded = jsonDecode(listData);
      allContracts = decoded.map((item) => EnergyContract.fromJson(item)).toList();
    }
    
    activeContractId = prefs.getString(KEY_ACTIVE_CONTRACT_ID) ?? "";

    if (allContracts.isEmpty) {
      final defaultContract = EnergyContract(id: 'def_1', contractName: 'Principale');
      allContracts.add(defaultContract);
      activeContractId = defaultContract.id;
    }
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('charge_history');
      
      if (data == null || data.isEmpty) {
        debugPrint("📂 Cronologia vuota o inesistente.");
        chargeHistory = [];
        return;
      }

      final List<dynamic> list = jsonDecode(data);
      chargeHistory = list.map((e) => ChargeSession.fromJson(e)).toList();
      debugPrint("✅ Cronologia caricata: ${chargeHistory.length} sessioni.");
      
    } catch (e) {
      debugPrint("❌ ERRORE FATALE CARICAMENTO HISTORY (File corrotto?): $e");
      chargeHistory = [];
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('charge_history');
    }
  }
  
  // --- SYNC DOWNLOAD ---
  void _updateFromDownload(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    int localTS = prefs.getInt('last_local_update') ?? 0;
    
    int cloudTS = 0;
    var cloudRaw = data['lastUpdate'];
    if (cloudRaw is int) cloudTS = cloudRaw;
    else if (cloudRaw != null && cloudRaw.runtimeType.toString().contains('Timestamp')) {
      cloudTS = cloudRaw.millisecondsSinceEpoch;
    }

    if (localTS > cloudTS) {
      debugPrint("⏳ MacBook più recente ($localTS) del Cloud ($cloudTS). Salto download history.");
      if (data['globalUserName'] != null) _globalUserName = data['globalUserName'];
      notifyListeners();
      return; 
    }

    bool hasChanged = false;

    if (data['globalUserName'] != null) {
      _globalUserName = data['globalUserName'];
      hasChanged = true;
    }

    if (data['history'] != null) {
      List<dynamic> cloudList = data['history'];
      chargeHistory = cloudList.map((e) => ChargeSession.fromJson(e)).toList();
      chargeHistory.sort((a, b) => b.date.compareTo(a.date));
      hasChanged = true;
    }

    if (hasChanged) {
      await prefs.setString('charge_history', jsonEncode(chargeHistory.map((s) => s.toJson()).toList()));
      notifyListeners();
    }
  }

  void selectCar(CarModel c) { 
    selectedCar = c; 
    capacityController.text = c.batteryCapacity.toString(); 
    _saveSimulationParameters(); 
    notifyListeners(); 
  }
  
  void updateReadyTime(TimeOfDay t) { 
    readyTime = t; 
    _saveSimulationParameters(); 
    notifyListeners(); 
  }
  
  void updateWallboxPwr(double v) { 
    wallboxPwr = v; 
    _saveSimulationParameters(); 
    notifyListeners(); 
  }
  
  void updateCurrentSoc(double v) { 
    currentSoc = double.parse(v.toStringAsFixed(1)); 
    _socAtStartOfSim = currentSoc;
    _saveSimulationParameters(); 
    notifyListeners(); 
  }

  void updateTargetSoc(double v) { 
    targetSoc = v; 
    _saveSimulationParameters(); 
    notifyListeners(); 
  }
  
  bool get shouldShowCompletionDialog => _showCompletionDialog;
  void resetCompletionDialog() => _showCompletionDialog = false;
  
  Future<void> refreshAfterSettings() async { 
    await _loadHistory(); 
    await _loadContract(); 
    notifyListeners(); 
    await loadBatteryConfig();
  }

  void deleteChargeSession(String id) async {
    chargeHistory.removeWhere((s) => s.id == id);
    await saveHistory();
    notifyListeners();
  }
}