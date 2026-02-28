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
  TimeOfDay readyTime = const TimeOfDay(hour: 7, minute: 0);
  
  late CarModel selectedCar;
  List<CarModel> allCars = [];
  bool carsLoaded = false;
  final capacityController = TextEditingController();
  
  EnergyContract myContract = EnergyContract();
  List<ChargeSession> chargeHistory = [];
  
  final SimulationService simService = SimulationService();
  bool isSimulating = false;
  bool _showCompletionDialog = false;

  // --- COSTANTI PER SHARED PREFERENCES ---
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
    await _loadContract();
    await _loadHistory();
    await _loadSimulationParameters(); // 🔥 Ora questo metodo esiste sotto e non darà più errore
    await _loadSimulationProgress();
    notifyListeners();
  }

  // --- GETTERS PER CALCOLI ---
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
    // Usa il CostCalculator che abbiamo aggiornato per non ricalcolare l'IVA
    return CostCalculator.calculate(energyNeeded, startTimeOfDay, DateTime.now(), myContract);
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

  void stopSimulation() {
    simService.stopSimulation();
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

  void _saveCompletedCharge() {
    final now = DateTime.now();
    final session = ChargeSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: now,
      startDateTime: simService.scheduledStart ?? now,
      endDateTime: now,
      startSoc: _socAtStartOfSim,
      endSoc: currentSoc,
      kwh: ChargeEngine.calculateEnergy(_socAtStartOfSim, currentSoc, currentBatteryCap),
      cost: estimatedCost,
      location: "Home",
      carBrand: selectedCar.brand,
      carModel: selectedCar.model,
      wallboxPower: wallboxPwr,
    );
    addChargeSession(session);
  }

  // --- PERSISTENZA ---
  Future<void> saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('charge_history', jsonEncode(chargeHistory.map((s) => s.toJson()).toList()));
  }

  Future<void> _syncHistoryIfPossible() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_sync_id');
    if (userId != null) {
      await SyncService().uploadData(userId, chargeHistory, myContract);
    }
  }

  // 🔥 SALVATAGGIO CONTRATTO CON NOTIFICA UI
  Future<void> saveContract() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonData = jsonEncode(myContract.toJson());
    await prefs.setString('energy_contract', jsonData);
    
    // Fondamentale per aggiornare il "Resoconto Contratto" subito
    notifyListeners(); 
    
    final userId = prefs.getString('user_sync_id');
    if (userId != null) {
      await SyncService().uploadData(userId, chargeHistory, myContract);
    }
  }

  Future<void> salvaTuttiParametri() async { 
    await _saveSimulationParameters(); 
  }

  // 🔥 METODO RECUPERATO (Risolve l'errore rosso)
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
      if (DateTime.now().isAfter(end)) { _clearSimulationProgress(); return; }
      _socAtStartOfSim = savedSoc;
      simService.restoreSimulation(startDateTime: start, endDateTime: end, currentSoc: _socAtStartOfSim, targetSoc: targetSoc, pwr: wallboxPwr, cap: currentBatteryCap);
      isSimulating = true;
    }
  }

  Future<void> _clearSimulationProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_SIM_ACTIVE);
    await prefs.remove(KEY_SIM_START);
    await prefs.remove(KEY_SIM_END);
    await prefs.remove(KEY_SIM_START_SOC);
  }

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
    final data = prefs.getString('energy_contract');
    if (data != null) myContract = EnergyContract.fromJson(jsonDecode(data));
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('charge_history');
    if (data != null) {
      final List<dynamic> list = jsonDecode(data);
      chargeHistory = list.map((e) => ChargeSession.fromJson(e)).toList();
    }
  }

  void selectCar(CarModel c) { selectedCar = c; capacityController.text = c.batteryCapacity.toString(); _saveSimulationParameters(); notifyListeners(); }
  void updateReadyTime(TimeOfDay t) { readyTime = t; _saveSimulationParameters(); notifyListeners(); }
  void updateWallboxPwr(double v) { wallboxPwr = v; _saveSimulationParameters(); notifyListeners(); }
  
  void updateCurrentSoc(double v) { 
    currentSoc = v.roundToDouble(); 
    _saveSimulationParameters(); 
    notifyListeners(); 
  }
  
  void updateTargetSoc(double v) { targetSoc = v; _saveSimulationParameters(); notifyListeners(); }
  bool get shouldShowCompletionDialog => _showCompletionDialog;
  void resetCompletionDialog() => _showCompletionDialog = false;
  Future<void> refreshAfterSettings() async { await _loadHistory(); await _loadContract(); notifyListeners(); }
}