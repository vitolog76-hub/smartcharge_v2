import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcharge_v2/models/car_model.dart';
import 'package:smartcharge_v2/models/contract_model.dart';
import 'package:smartcharge_v2/models/charge_session.dart';
import 'package:smartcharge_v2/services/charge_engine.dart';
import 'package:smartcharge_v2/services/cost_calculator.dart';
import 'package:smartcharge_v2/services/simulation_service.dart';
import 'package:smartcharge_v2/services/sync_service.dart';
import 'package:intl/intl.dart';

class HomeProvider extends ChangeNotifier {
  // --- STATO ---
  double currentSoc = 20.0;
  double targetSoc = 80.0;
  double _socAtStartOfSim = 20.0;
  double wallboxPwr = 3.7;
  double lastSavedEnergy = 0.0;
  double lastSavedCost = 0.0;
  TimeOfDay readyTime = const TimeOfDay(hour: 7, minute: 0);
  
  late CarModel selectedCar;
  List<CarModel> allCars = [];
  bool carsLoaded = false;
  final capacityController = TextEditingController();
  List<ChargeSession> chargeHistory = [];
  
  final SimulationService simService = SimulationService();
  bool isSimulating = false;
  bool _showCompletionDialog = false;
  List<EnergyContract> allContracts = [];

  String activeContractId = "";

  // 🔥 NOME UTENTE GLOBALE (PROFILO) - INDIPENDENTE DAI CONTRATTI
  String _globalUserName = "Utente";
  String get globalUserName => _globalUserName;
  String _batteryChemistry = "NMC / NCA";
  String get batteryChemistry => _batteryChemistry;

  String getSmartBatteryAdvice() {
  if (chargeHistory.isEmpty) return "Inizia a caricare per ricevere consigli basati sul tuo stile di guida.";

  final ora = DateTime.now();
  
  // --- LOGICA PER LFP (Calibrazione) ---
  if (_batteryChemistry == "LFP") {
    bool haCaricatoAl100Recentemente = chargeHistory.any((s) => 
      s.endSoc >= 99 && ora.difference(s.date).inDays <= 7
    );

    if (!haCaricatoAl100Recentemente) {
      return "⚠️ Non carichi al 100% da più di una settimana. Fallo stasera per allineare le celle (BMS).";
    }
    return "✅ Batteria ben calibrata. Mantieni il target tra 20-80% per il resto della settimana.";
  }

  // --- LOGICA PER NMC (Stress chimico) ---
  if (_batteryChemistry == "NMC / NCA") {
    int caricheEccessive = chargeHistory.where((s) => 
      s.endSoc > 85 && ora.difference(s.date).inDays <= 30
    ).length;

    if (caricheEccessive > 4) {
      return "⚠️ Hai caricato oltre l'80% ben $caricheEccessive volte nell'ultimo mese. Cerca di limitarlo per ridurre il degrado.";
    }
    return "✅ Ottima gestione: stai preservando la chimica al nichel limitando i picchi di carica.";
  }

  return "Mantieni la carica tra 20-80% per una longevità ottimale.";
}

  // --- GESTIONE PROFILO (ID + NOME) ---
  // Da chiamare nella SettingsPage per salvare il nome
  Future<void> syncUserProfile(String nuovoNome) async {
    _globalUserName = nuovoNome;
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Salva il nome nel profilo locale sul MacBook associato all'ID/Profilo
    await prefs.setString('global_user_name', nuovoNome);
    
    // 2. Se esiste un ID utente, associa il nome a quell'ID nel Cloud
    final String? userId = prefs.getString('user_sync_id');
    if (userId != null && userId.isNotEmpty) {
      // Carica il nome come attributo del profilo utente (non del contratto)
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
    simService.startChecking(
      onSocUpdate: (newSoc) {
        currentSoc = double.parse(newSoc.toStringAsFixed(1));
        _saveSimulationProgress();
        notifyListeners();
      },
      onStatusChange: (status) {
        isSimulating = status;
        if (!status) _clearSimulationProgress();
        notifyListeners();
      },
      onSimulationComplete: () {
        _saveCompletedCharge();
        _showCompletionDialog = true;
        _clearSimulationProgress();
        notifyListeners();
      },
    );
  }

  // --- INIZIALIZZAZIONE ---
  Future<void> init() async {
    await _loadCarsFromJson();
    await _loadContract(); // Questo ora carica anche il Nome Profilo
    await _loadHistory(); 
    await _loadSimulationParameters(); 
    await _loadSimulationProgress();
    await loadBatteryConfig();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_sync_id');
    
    if (userId != null && userId.isNotEmpty) {
      final cloudData = await SyncService().downloadAllData(userId);
      if (cloudData != null) {
        _updateFromDownload(cloudData);
      }
    }

    notifyListeners();
  }

  
  void updateActiveContractDetails({
    required String provider,
    required bool isMonorario,
    required double f1,
    double? f2,
    double? f3,
  }) {
    // Cerchiamo il contratto attivo nella lista
    final index = allContracts.indexWhere((c) => c.id == activeContractId);
    
    if (index != -1) {
      allContracts[index].provider = provider;
      allContracts[index].isMonorario = isMonorario;
      allContracts[index].f1Price = f1;
      allContracts[index].f2Price = isMonorario ? f1 : (f2 ?? f1);
      allContracts[index].f3Price = isMonorario ? f1 : (f3 ?? f1);

      // Salva la lista aggiornata (prezzi, spread, etc.)
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
    _clearSimulationProgress().then((_) {
      _socAtStartOfSim = currentSoc.roundToDouble();
      currentSoc = _socAtStartOfSim;
      
      DateTime startTime = calculatedStartDateTime;
      final now = DateTime.now();

      if (startTime.isBefore(now)) {
        startTime = now;
      }

      simService.initSimulation(
        startDateTime: startTime,
        currentSoc: _socAtStartOfSim,
        targetSoc: targetSoc,
        pwr: wallboxPwr,
        cap: currentBatteryCap,
      );

      isSimulating = true;
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
  isSimulating = false;
  // _saveCompletedCharge(); <--- SE C'È QUESTA RIGA, CANCELLALA!
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

  void _saveCompletedCharge() {
  // 1. CATTURA IMMEDIATA DEI DATI (Prima che vengano azzerati)
  final now = DateTime.now();
  final double socIniziale = _socAtStartOfSim;
  final double socFinale = currentSoc;
  final double capacita = currentBatteryCap;
  
  // Calcolo energia effettiva
  final kwhEfettivi = ChargeEngine.calculateEnergy(socIniziale, socFinale, capacita);
  
  // PROTEZIONE DOPPIO SALVATAGGIO: 
  // Se l'energia è quasi nulla o il SOC non è cambiato, ignoriamo.
  if (kwhEfettivi <= 0.01) {
    print("DEBUG: Ricarica nulla o già salvata. Ignoro.");
    return;
  }

  // 2. RECUPERO CONTRATTO ATTIVO
  final contrattoAttivo = myContract;

  // 3. CALCOLO COSTO REALE
  final costoCalcolato = CostCalculator.calculate(
    totalKwh: kwhEfettivi,
    wallboxPower: wallboxPwr,
    startTime: TimeOfDay.fromDateTime(simService.scheduledStart ?? now),
    date: now,
    contract: contrattoAttivo,
  );

  // 4. CREAZIONE SESSIONE PER CRONOLOGIA
  final session = ChargeSession(
    id: "CHG_${DateTime.now().millisecondsSinceEpoch}", 
    date: now,
    startDateTime: simService.scheduledStart ?? now,
    endDateTime: now,
    startSoc: socIniziale,
    endSoc: socFinale,
    kwh: kwhEfettivi,
    cost: costoCalcolato,
    location: "Home",
    carBrand: selectedCar.brand,
    carModel: selectedCar.model,
    contractId: activeContractId,
    wallboxPower: wallboxPwr,
    fascia: CostCalculator.getFasciaLabel(
      totalKwh: kwhEfettivi,
      wallboxPower: wallboxPwr,
      startTime: TimeOfDay.fromDateTime(simService.scheduledStart ?? now),
      date: now,
      isMonorario: contrattoAttivo.isMonorario,
    ),
    f1PriceAtTime: contrattoAttivo.f1Price,
    f2PriceAtTime: contrattoAttivo.f2Price,
    f3PriceAtTime: contrattoAttivo.f3Price,
  );
  
  // 5. SALVATAGGIO IN CRONOLOGIA
  chargeHistory.add(session);
  saveHistory();
  _syncHistoryIfPossible();

  // 🔥 6. AGGIORNAMENTO VARIABILI PER IL DIALOG (UI)
  // Queste variabili "congelano" il risultato per mostrarlo nel popup finale
  lastSavedEnergy = kwhEfettivi;
  lastSavedCost = costoCalcolato;

  // 7. RESET STATO INTERNO
  // Impedisce salvataggi multipli se il metodo viene richiamato per errore
  _socAtStartOfSim = currentSoc; 
  
  print("DEBUG SALVATAGGIO: $kwhEfettivi kWh salvati al costo di $costoCalcolato €");
  
  notifyListeners();
}
  // --- PERSISTENZA E SYNC ---
  Future<void> saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('charge_history', jsonEncode(chargeHistory.map((s) => s.toJson()).toList()));
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
    
    // Salva il nome utente globale (Profilo) indipendentemente dai contratti
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
  _batteryChemistry = newChemistry; // Aggiorna la variabile privata
  notifyListeners(); // 🔥 Fondamentale: scatena il rebuild del "Battery Coach" nella Home
}

  // --- PARAMETRI SIMULAZIONE ---
  Future<void> salvaTuttiParametri() async { await _saveSimulationParameters(); }

  Future<void> _loadSimulationParameters() async {
    final prefs = await SharedPreferences.getInstance();
    double savedSoc = prefs.getDouble(KEY_SOC_INIZIALE) ?? 20.0;
    currentSoc = savedSoc.roundToDouble();
    targetSoc = prefs.getDouble(KEY_SOC_TARGET) ?? 80.0;
    wallboxPwr = prefs.getDouble(KEY_WALLBOX_PWR) ?? 3.7;
    final h = prefs.getInt(KEY_READY_TIME_HOUR);
    final m = prefs.getInt(KEY_READY_TIME_MINUTE);
    if (h != null && m != null) readyTime = TimeOfDay(hour: h, minute: m);
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
  final prefs = await SharedPreferences.getInstance();
  if (!(prefs.getBool(KEY_SIM_ACTIVE) ?? false)) return;

  final startStr = prefs.getString(KEY_SIM_START);
  final endStr = prefs.getString(KEY_SIM_END);
  final savedSoc = prefs.getDouble(KEY_SIM_START_SOC);

  if (startStr != null && endStr != null && savedSoc != null) {
    final start = DateTime.parse(startStr);
    final end = DateTime.parse(endStr);
    _socAtStartOfSim = savedSoc;

    // --- FIX: SE LA RICARICA È FINITA MENTRE L'APP ERA CHIUSA ---
    if (DateTime.now().isAfter(end)) {
      // 1. Portiamo il SOC al target (perché il tempo è scaduto)
      currentSoc = targetSoc; 
      
      // 2. Calcoliamo i dati finali per "congelarli" nel Dialog
      final kwh = ChargeEngine.calculateEnergy(_socAtStartOfSim, targetSoc, currentBatteryCap);
      lastSavedEnergy = kwh;
      lastSavedCost = CostCalculator.calculate(
        totalKwh: kwh,
        wallboxPower: wallboxPwr,
        startTime: TimeOfDay.fromDateTime(start),
        date: end, // Usiamo l'ora di fine prevista
        contract: myContract,
      );

      // 3. Prepariamo lo stato per la HomePage
      isSimulating = false;
      _showCompletionDialog = true; // 🔥 Questo farà scattare il pop-up all'avvio!
      
      // 4. Puliamo i dati temporanei dal disco
      await _clearSimulationProgress();
      
      notifyListeners();
      return; 
    }
    // --- FINE FIX ---

    // Se invece è ancora in corso, ripristiniamo normalmente
    simService.restoreSimulation(
      startDateTime: start, 
      endDateTime: end, 
      currentSoc: _socAtStartOfSim, 
      targetSoc: targetSoc, 
      pwr: wallboxPwr, 
      cap: currentBatteryCap
    );
    isSimulating = true;
    notifyListeners();
  }
}

  Future<void> _clearSimulationProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_SIM_ACTIVE);
    await prefs.remove(KEY_SIM_START);
    await prefs.remove(KEY_SIM_END);
    await prefs.remove(KEY_SIM_START_SOC);
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
    
    // 🔥 CARICAMENTO NOME UTENTE GLOBALE (Indipendente dai contratti)
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
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('charge_history');
    if (data != null) {
      final List<dynamic> list = jsonDecode(data);
      chargeHistory = list.map((e) => ChargeSession.fromJson(e)).toList();
    }
  }
  
  // --- SYNC DOWNLOAD ---
  void _updateFromDownload(Map<String, dynamic> data) {
    bool hasChanged = false;

    // 🔥 Recupero Nome Utente Globale dal Cloud
    if (data['globalUserName'] != null) {
      _globalUserName = data['globalUserName'];
      hasChanged = true;
    }

    if (data['allContracts'] != null) {
      List<dynamic> cloudList = data['allContracts'];
      allContracts = cloudList.map((item) => EnergyContract.fromJson(item)).toList();
      activeContractId = data['activeContractId'] ?? allContracts.first.id;
      hasChanged = true;
    } 

    if (data['history'] != null) {
      List<dynamic> cloudList = data['history'];
      List<ChargeSession> cloudSessions = cloudList.map((e) => ChargeSession.fromJson(e)).toList();
      for (var session in cloudSessions) {
        if (!chargeHistory.any((s) => s.id == session.id)) {
          chargeHistory.add(session);
          hasChanged = true;
        }
      }
      chargeHistory.sort((a, b) => b.date.compareTo(a.date));
    }

    if (hasChanged) {
      saveHistory();
      saveAllContracts();
    }
  }

  void selectCar(CarModel c) { selectedCar = c; capacityController.text = c.batteryCapacity.toString(); _saveSimulationParameters(); notifyListeners(); }
  void updateReadyTime(TimeOfDay t) { readyTime = t; _saveSimulationParameters(); notifyListeners(); }
  void updateWallboxPwr(double v) { wallboxPwr = v; _saveSimulationParameters(); notifyListeners(); }
  void updateCurrentSoc(double v) { currentSoc = v.roundToDouble(); _saveSimulationParameters(); notifyListeners(); }
  void updateTargetSoc(double v) { targetSoc = v; _saveSimulationParameters(); notifyListeners(); }
  bool get shouldShowCompletionDialog => _showCompletionDialog;
  void resetCompletionDialog() => _showCompletionDialog = false;
  Future<void> refreshAfterSettings() async { 
    await _loadHistory(); 
    await _loadContract(); notifyListeners(); 
    await loadBatteryConfig();
    }
}