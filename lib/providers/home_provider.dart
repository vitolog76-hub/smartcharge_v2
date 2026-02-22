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
        debugPrint('🎯 Callback onSimulationComplete chiamato!');
        
        // 🔥 SALVA LA RICARICA NELLO STORICO
        _saveCompletedCharge();
        
        // 🔥 MOSTRA IL DIALOG
        _showCompletionDialog = true;
        
        debugPrint('🎯 _showCompletionDialog impostato a true');
        notifyListeners();
      },
    );
  }

  Future<void> init() async {
    debugPrint("🚀 HomeProvider: Inizializzazione...");
    
    // 1. Prima carica le auto (serve per selectedCar)
    await _loadCarsFromJson();
    
    // 2. Poi carica i parametri (usa selectedCar)
    await _loadSimulationParameters();
    
    // 3. Poi carica il contratto
    await _loadContract();
    
    // 4. INFINE carica lo storico (ORA selectedCar è disponibile!)
    await _loadHistory();
    
    notifyListeners();
    debugPrint("✅ HomeProvider: Inizializzazione completata");
  }

  // --- NUOVO METODO: Salva la ricarica completata ---
  void _saveCompletedCharge() {
    try {
      debugPrint('💾 Salvataggio ricarica completata...');
      debugPrint('   SOC iniziale: $_socAtStartOfSim%');
      debugPrint('   SOC finale: $targetSoc%');
      debugPrint('   Energia: $energyNeeded kWh');
      debugPrint('   Costo: $estimatedCost €');
      
      final now = DateTime.now();
      final session = ChargeSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: now,
        startDateTime: simService.scheduledStart ?? now,
        endDateTime: now,
        startSoc: _socAtStartOfSim,
        endSoc: targetSoc,
        kwh: energyNeeded,
        cost: estimatedCost,
        location: "Home",
        carBrand: selectedCar.brand,
        carModel: selectedCar.model,
        wallboxPower: wallboxPwr,
      );
      
      addChargeSession(session);
      debugPrint('✅ Ricarica salvata nello storico con ID: ${session.id}');
    } catch (e) {
      debugPrint('❌ Errore nel salvataggio della ricarica: $e');
    }
  }

  // --- METODO PER SALVARE LA RICARICA CORRENTE (chiamato da HomePage) ---
  void saveCurrentCharge() {
    if (_socAtStartOfSim < targetSoc) {
      _saveCompletedCharge();
    }
  }

  // --- NUOVO METODO: Carica i parametri di simulazione ---
  Future<void> _loadSimulationParameters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      currentSoc = prefs.getDouble(KEY_SOC_INIZIALE) ?? 20.0;
      targetSoc = prefs.getDouble(KEY_SOC_TARGET) ?? 80.0;
      wallboxPwr = prefs.getDouble(KEY_WALLBOX_PWR) ?? 3.7;
      
      final savedHour = prefs.getInt(KEY_READY_TIME_HOUR);
      final savedMinute = prefs.getInt(KEY_READY_TIME_MINUTE);
      
      if (savedHour != null && savedMinute != null) {
        readyTime = TimeOfDay(hour: savedHour, minute: savedMinute);
      } else {
        readyTime = const TimeOfDay(hour: 7, minute: 0);
      }
      
      debugPrint("✅ Parametri caricati: SOC=$currentSoc, Target=$targetSoc, Potenza=$wallboxPwr, Ora=$readyTime");
    } catch (e) {
      debugPrint("❌ Errore caricamento parametri: $e");
    }
  }

  // --- NUOVO METODO: Salva i parametri di simulazione ---
  Future<void> _saveSimulationParameters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setDouble(KEY_SOC_INIZIALE, currentSoc);
      await prefs.setDouble(KEY_SOC_TARGET, targetSoc);
      await prefs.setDouble(KEY_WALLBOX_PWR, wallboxPwr);
      await prefs.setInt(KEY_READY_TIME_HOUR, readyTime.hour);
      await prefs.setInt(KEY_READY_TIME_MINUTE, readyTime.minute);
      
      debugPrint("✅ Parametri salvati");
    } catch (e) {
      debugPrint("❌ Errore salvataggio parametri: $e");
    }
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
    } catch (e) {
      debugPrint("❌ Errore caricamento auto: $e");
    }
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyData = prefs.getString('charge_history');
      
      if (historyData != null && historyData.isNotEmpty) {
        debugPrint('📂 Trovato storico: ${historyData.length} caratteri');
        final List<dynamic> decodedData = jsonDecode(historyData);
        debugPrint('📊 Elementi trovati: ${decodedData.length}');
        
        // 🔥 MIGRAZIONE: Gestisci vecchi dati
        final List<ChargeSession> migratedHistory = [];
        int migratedCount = 0;
        int keptCount = 0;
        
        for (var item in decodedData) {
          try {
            // Prova a parsare come nuovo formato
            final session = ChargeSession.fromJson(item);
            migratedHistory.add(session);
            keptCount++;
          } catch (e) {
            debugPrint('🔄 Migrazione necessaria per un elemento: $e');
            migratedCount++;
            
            // Se fallisce, è un vecchio formato - converti
            try {
              // Estrai dati dal vecchio formato
              final oldDate = DateTime.parse(item['date']);
              final oldKwh = item['kwh'] is int 
                  ? (item['kwh'] as int).toDouble() 
                  : item['kwh'].toDouble();
              final oldCost = item['cost'] is int 
                  ? (item['cost'] as int).toDouble() 
                  : item['cost'].toDouble();
              final oldLocation = item['location'] ?? "Home";
              
              // Recupera startHour/startMinute se esistono
              int startHour = 8;
              int startMinute = 0;
              int endHour = TimeOfDay.now().hour;
              int endMinute = TimeOfDay.now().minute;
              
              if (item.containsKey('startHour')) {
                startHour = item['startHour'] is int 
                    ? item['startHour'] 
                    : int.tryParse(item['startHour'].toString()) ?? 8;
              }
              
              if (item.containsKey('startMinute')) {
                startMinute = item['startMinute'] is int 
                    ? item['startMinute'] 
                    : int.tryParse(item['startMinute'].toString()) ?? 0;
              }
              
              if (item.containsKey('endHour')) {
                endHour = item['endHour'] is int 
                    ? item['endHour'] 
                    : int.tryParse(item['endHour'].toString()) ?? TimeOfDay.now().hour;
              }
              
              if (item.containsKey('endMinute')) {
                endMinute = item['endMinute'] is int 
                    ? item['endMinute'] 
                    : int.tryParse(item['endMinute'].toString()) ?? TimeOfDay.now().minute;
              }
              
              final startDateTime = DateTime(
                oldDate.year,
                oldDate.month,
                oldDate.day,
                startHour,
                startMinute,
              );
              
              final endDateTime = DateTime(
                oldDate.year,
                oldDate.month,
                oldDate.day,
                endHour,
                endMinute,
              );
              
              // Stima SOC basato su kWh se possibile
              double startSoc = 20.0;
              double endSoc = 80.0;
              
              if (selectedCar.batteryCapacity > 0 && oldKwh > 0) {
                final percentIncrease = (oldKwh / selectedCar.batteryCapacity) * 100;
                endSoc = startSoc + percentIncrease;
                if (endSoc > 100) endSoc = 100;
                if (endSoc < 0) endSoc = 80;
              }
              
              // Crea nuova sessione
              final migratedSession = ChargeSession(
                id: 'migrated_${DateTime.now().millisecondsSinceEpoch}_${migratedHistory.length}',
                date: oldDate,
                startDateTime: startDateTime,
                endDateTime: endDateTime,
                startSoc: startSoc,
                endSoc: endSoc,
                kwh: oldKwh,
                cost: oldCost,
                location: oldLocation,
                carBrand: selectedCar.brand,
                carModel: selectedCar.model,
                wallboxPower: 3.7,
              );
              
              migratedHistory.add(migratedSession);
              debugPrint('✅ Migrata sessione del ${DateFormat('dd/MM/yyyy').format(oldDate)}');
            } catch (migrationError) {
              debugPrint('❌ Errore migrazione: $migrationError');
            }
          }
        }
        
        chargeHistory = migratedHistory;
        debugPrint('✅ Storico caricato: $keptCount mantenuti, $migratedCount migrati, totale ${chargeHistory.length} sessioni');
        
        // Salva il formato migrato se ci sono state conversioni
        if (migratedCount > 0) {
          debugPrint('💾 Salvataggio storico migrato...');
          await saveHistory();
        }
      } else {
        chargeHistory = [];
        debugPrint('📭 Nessuno storico trovato');
      }
    } catch (e) {
      debugPrint("❌ Errore caricamento storico: $e");
      chargeHistory = [];
    }
  }

  Future<void> forceMigrateHistory() async {
    debugPrint('🔄 Forzatura migrazione storico...');
    await _loadHistory();
    debugPrint('✅ Migrazione completata: ${chargeHistory.length} sessioni');
  }

  Future<void> _loadContract() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? contractData = prefs.getString('energy_contract');
      if (contractData != null && contractData.isNotEmpty) {
        myContract = EnergyContract.fromJson(jsonDecode(contractData));
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
      debugPrint('✅ Storico salvato: ${chargeHistory.length} sessioni');
      
      final userId = prefs.getString('user_sync_id');
      if (userId != null && userId.isNotEmpty) {
        await SyncService().uploadData(userId, chargeHistory, myContract);
      }
    } catch (e) {
      debugPrint("❌ Errore salvataggio: $e");
    }
  }

  void selectCar(CarModel car) {
    selectedCar = car;
    capacityController.text = car.batteryCapacity.toString();
    saveSelectedCar(car);
    _saveSimulationParameters();
    notifyListeners();
  }

  Future<void> saveSelectedCar(CarModel car) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_car_brand', car.brand);
    await prefs.setString('selected_car_model', car.model);
  }

  void updateReadyTime(TimeOfDay time) { 
    readyTime = time; 
    _saveSimulationParameters();
    notifyListeners(); 
  }
  
  void updateWallboxPwr(double value) { 
    wallboxPwr = value; 
    _saveSimulationParameters();
    notifyListeners(); 
  }
  
  void updateCurrentSoc(double value) { 
    currentSoc = value; 
    _saveSimulationParameters();
    notifyListeners(); 
  }
  
  void updateTargetSoc(double value) { 
    targetSoc = value; 
    _saveSimulationParameters();
    notifyListeners(); 
  }

  void addChargeSession(ChargeSession session) {
    debugPrint('➕ Aggiunta sessione allo storico: ${session.id}');
    chargeHistory.add(session);
    saveHistory();
    notifyListeners();
  }

  void startSimulation() {
  debugPrint('🚀 Avvio simulazione - SOC iniziale: $currentSoc%, Target: $targetSoc%');
  _socAtStartOfSim = currentSoc;
  simService.initSimulation(
    startDateTime: calculatedStartDateTime,
    currentSoc: currentSoc,
    targetSoc: targetSoc,
    pwr: wallboxPwr,
    cap: currentBatteryCap,
  );
  // 🔥 MANCA QUESTA RIGA!
  isSimulating = true;  // <-- DEVI AGGIUNGERE QUESTA
  notifyListeners();
}

  void stopSimulation() {
    debugPrint('⏹️ Simulazione fermata manualmente');
    simService.stopSimulation();
  }

  Future<void> refreshAfterSettings() async {
    await _loadHistory();
    await _loadContract();
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    currentSoc = 20.0;
    targetSoc = 80.0;
    wallboxPwr = 3.7;
    readyTime = const TimeOfDay(hour: 7, minute: 0);
    
    await _saveSimulationParameters();
    notifyListeners();
  }

  Future<void> salvaTuttiParametri() async {
    await _saveSimulationParameters();
  }
}