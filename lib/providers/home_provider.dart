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

  // --- COSTRUTTORE ---
  HomeProvider() {
    simService.startChecking(
      onSocUpdate: (newSoc) {
        currentSoc = newSoc;
        notifyListeners();
      },
      onStatusChange: (status) {
        isSimulating = status;
        notifyListeners();
      },
      onSimulationComplete: () {
        _showCompletionDialog = true;
        notifyListeners();
      },
    );
  }

 Future<void> init() async {
  debugPrint("🚀 HomeProvider: Inizializzazione...");
  await _loadCarsFromJson();
  await _loadHistory();
  await _loadContract();
  notifyListeners();
}

  // --- METODO PER REFRESH DOPO LOGIN ---
  Future<void> refreshAfterLogin() async {
    debugPrint("🔄 HomeProvider: Refresh dopo login...");
    await _loadCarsFromJson();
    await _loadHistory();
    await _loadContract();
    notifyListeners();
  }

  // --- GETTERS CALCOLATI ---
  double get currentBatteryCap => 
      double.tryParse(capacityController.text) ?? (carsLoaded ? selectedCar.batteryCapacity : 50.0);
  
  double get energyNeeded => 
      ChargeEngine.calculateEnergy(currentSoc, targetSoc, currentBatteryCap);
  
  Duration get duration => 
      ChargeEngine.calculateDuration(energyNeeded, wallboxPwr);
  
  DateTime get targetReadyDateTime {
    final now = DateTime.now();
    DateTime target = DateTime(now.year, now.month, now.day, readyTime.hour, readyTime.minute);
    if (target.isBefore(now)) target = target.add(const Duration(days: 1));
    return target;
  }
  
  DateTime get calculatedStartDateTime => targetReadyDateTime.subtract(duration);
  
  String get startTimeDisplay => DateFormat('HH:mm').format(calculatedStartDateTime);
  
  double get estimatedCost {
    final startTimeOfDay = TimeOfDay.fromDateTime(calculatedStartDateTime);
    return CostCalculator.calculate(energyNeeded, startTimeOfDay, DateTime.now(), myContract);
  }
  
  bool get isChargingReal => 
      isSimulating && DateTime.now().isAfter(simService.scheduledStart ?? DateTime.now());

  bool get shouldShowCompletionDialog => _showCompletionDialog;
  void resetCompletionDialog() => _showCompletionDialog = false;

  // --- METODI PRIVATI DI CARICAMENTO ---
  Future<void> _loadCarsFromJson() async {
    try {
      final String response = await rootBundle.loadString('assets/cars.json');
      final List<dynamic> data = json.decode(response);
      allCars = data.map((item) => CarModel.fromJson(item)).toList();
      
      final prefs = await SharedPreferences.getInstance();
      final savedBrand = prefs.getString('selected_car_brand');
      final savedModel = prefs.getString('selected_car_model');
      
      if (savedBrand != null && savedModel != null) {
        try {
          selectedCar = allCars.firstWhere((c) => c.brand == savedBrand && c.model == savedModel);
        } catch (e) {
          selectedCar = allCars.first;
        }
      } else {
        selectedCar = allCars.first;
      }
      
      capacityController.text = selectedCar.batteryCapacity.toString();
      carsLoaded = true;
      debugPrint("✅ Auto caricate: ${allCars.length} modelli");
    } catch (e) {
      debugPrint("❌ Errore caricamento auto: $e");
    }
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyData = prefs.getString('charge_history');
      if (historyData != null && historyData.isNotEmpty) {
        final List<dynamic> decodedData = jsonDecode(historyData);
        chargeHistory = decodedData.map((item) => ChargeSession.fromJson(item)).toList();
        debugPrint("✅ Storico caricato: ${chargeHistory.length} sessioni");
      } else {
        chargeHistory = [];
        debugPrint("📂 Nessuno storico trovato");
      }
    } catch (e) {
      debugPrint("❌ Errore caricamento storico: $e");
      chargeHistory = [];
    }
  }

  Future<void> _loadContract() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? contractData = prefs.getString('energy_contract');
      if (contractData != null && contractData.isNotEmpty) {
        myContract = EnergyContract.fromJson(jsonDecode(contractData));
        debugPrint("✅ Contratto caricato: ${myContract.provider}");
      }
    } catch (e) {
      debugPrint("❌ Errore caricamento contratto: $e");
    }
  }

  // --- AZIONI ---
  Future<void> saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(chargeHistory.map((s) => s.toJson()).toList());
      await prefs.setString('charge_history', jsonData);
      debugPrint("💾 Storico salvato: ${chargeHistory.length} sessioni");
      
      final userId = prefs.getString('user_sync_id');
      if (userId != null && userId.isNotEmpty) {
        await SyncService().uploadData(userId, chargeHistory, myContract);
      }
    } catch (e) {
      debugPrint("❌ Errore salvataggio: $e");
    }
  }

  Future<void> saveSelectedCar(CarModel car) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_car_brand', car.brand);
    await prefs.setString('selected_car_model', car.model);
  }

  void selectCar(CarModel car) {
    selectedCar = car;
    capacityController.text = car.batteryCapacity.toString();
    saveSelectedCar(car);
    notifyListeners();
  }

  void updateReadyTime(TimeOfDay time) { 
    readyTime = time; 
    notifyListeners(); 
  }
  
  void updateWallboxPwr(double value) { 
    wallboxPwr = value; 
    notifyListeners(); 
  }
  
  void updateCurrentSoc(double value) { 
    currentSoc = value; 
    notifyListeners(); 
  }
  
  void updateTargetSoc(double value) { 
    targetSoc = value; 
    notifyListeners(); 
  }

  void addChargeSession(ChargeSession session) {
    chargeHistory.add(session);
    saveHistory();
    notifyListeners();
  }

  void startSimulation() {
    _socAtStartOfSim = currentSoc;
    simService.initSimulation(
      startDateTime: calculatedStartDateTime,
      currentSoc: currentSoc,
      targetSoc: targetSoc,
      pwr: wallboxPwr,
      cap: currentBatteryCap,
    );
  }

  void stopSimulation() => simService.stopSimulation();

  Future<void> refreshAfterSettings() async {
    debugPrint("⚙️ Refresh dopo settings...");
    await _loadHistory();
    await _loadContract();
    notifyListeners();
  }
}