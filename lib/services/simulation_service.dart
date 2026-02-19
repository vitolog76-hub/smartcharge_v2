import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimulationService {
  static final SimulationService _instance = SimulationService._internal();
  factory SimulationService() => _instance;
  SimulationService._internal();

  bool isSimulating = false;
  DateTime? scheduledStart;
  Timer? _timer;

  Function(double)? onSocUpdate;
  Function(bool)? onStatusChange;
  Function()? onSimulationComplete;

  void startChecking({
    required Function(double) onSocUpdate,
    required Function(bool) onStatusChange,
    required Function() onSimulationComplete,
  }) {
    this.onSocUpdate = onSocUpdate;
    this.onStatusChange = onStatusChange;
    this.onSimulationComplete = onSimulationComplete;
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => checkStatus());
  }

  Future<void> checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? startStr = prefs.getString('sim_start_time');
    
    if (startStr == null) {
      if (isSimulating) {
        isSimulating = false;
        onStatusChange?.call(false);
      }
      return;
    }

    DateTime start = DateTime.parse(startStr);
    scheduledStart = start;
    isSimulating = true;
    onStatusChange?.call(true);

    DateTime now = DateTime.now();
    
    // Se l'orario previsto di ricarica è giunto o passato
    if (now.isAfter(start)) {
      double socAtStart = prefs.getDouble('sim_soc_at_start') ?? 0;
      double pwr = prefs.getDouble('sim_pwr') ?? 3.7;
      double cap = prefs.getDouble('sim_cap') ?? 60.0;
      double target = prefs.getDouble('sim_target') ?? 80.0;

      // RECUPERO DEL MOMENTO ESATTO IN CUI È STATA AVVIATA LA SIMULAZIONE
      // Questo impedisce il salto (jump) dal 20% al 60% se l'orario 'start' era nel passato.
      int? activationTime = prefs.getInt('sim_activation_timestamp');
      if (activationTime == null) {
        activationTime = now.millisecondsSinceEpoch;
        await prefs.setInt('sim_activation_timestamp', activationTime);
      }

      // Il tempo di ricarica effettiva è il tempo passato da quando la ricarica è "partita" (now - start)
      // ma limitato dal momento in cui l'utente ha premuto AVVIA.
      DateTime effectiveStart = DateTime.fromMillisecondsSinceEpoch(activationTime).isAfter(start) 
          ? DateTime.fromMillisecondsSinceEpoch(activationTime) 
          : start;

      int secondsPassed = now.difference(effectiveStart).inSeconds;
      
      // Se secondsPassed è negativo (perché siamo nel futuro), lo mettiamo a 0
      if (secondsPassed < 0) secondsPassed = 0;

      double energyAdded = (pwr * secondsPassed) / 3600;
      double newSoc = socAtStart + (energyAdded / cap * 100);

      debugPrint("SIM: In corso. +${energyAdded.toStringAsFixed(2)}kWh, SoC: ${newSoc.toStringAsFixed(1)}%");

      if (newSoc >= target) {
        await stopSimulation();
        onSocUpdate?.call(target);
        onSimulationComplete?.call();
      } else {
        onSocUpdate?.call(newSoc);
      }
    } else {
      // IN ATTESA: Non inviamo nessun aggiornamento SoC per non resettare la UI dell'utente
      debugPrint("SIM: In attesa dell'orario stabilito...");
    }
  }

  Future<void> initSimulation({
    required DateTime startDateTime, 
    required double currentSoc, 
    required double targetSoc, 
    required double pwr, 
    required double cap
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Puliamo vecchi residui prima di scrivere i nuovi
    await prefs.remove('sim_activation_timestamp');

    await prefs.setString('sim_start_time', startDateTime.toIso8601String());
    await prefs.setDouble('sim_soc_at_start', currentSoc);
    await prefs.setDouble('sim_target', targetSoc);
    await prefs.setDouble('sim_pwr', pwr);
    await prefs.setDouble('sim_cap', cap);
    
    // Salviamo il momento esatto del click
    await prefs.setInt('sim_activation_timestamp', DateTime.now().millisecondsSinceEpoch);

    isSimulating = true;
    scheduledStart = startDateTime;
    onStatusChange?.call(true);
  }

  Future<void> stopSimulation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sim_start_time');
    await prefs.remove('sim_soc_at_start');
    await prefs.remove('sim_activation_timestamp');
    
    isSimulating = false;
    scheduledStart = null;
    onStatusChange?.call(false);
    debugPrint("SIM: Fermata e ripulita.");
  }
}