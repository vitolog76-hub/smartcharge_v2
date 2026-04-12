import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:origo/services/notification_service.dart';

class SimulationService {
  Timer? _timer;
  DateTime? _startTime;
  DateTime? _endTime;
  DateTime? scheduledStart;
  
  double _currentSoc = 0;
  double _targetSoc = 0;
  double _nominalPower = 0; // Potenza nominale (es. 3.7 kW)
  double _capacity = 0;
  
  bool _isSimulating = false;
  bool _hasNotifiedCompletion = false;
  
  // Callbacks
  Function(double)? onSocUpdate;
  Function(bool)? onStatusChange;
  Function()? onSimulationComplete;
  
  // Getter per esporre _endTime
  DateTime? get endTime => _endTime;
  
  void startChecking({
    required Function(double) onSocUpdate,
    required Function(bool) onStatusChange,
    required Function() onSimulationComplete,
  }) {
    debugPrint('🔄 SimulationService: startChecking chiamato');
    this.onSocUpdate = onSocUpdate;
    this.onStatusChange = onStatusChange;
    this.onSimulationComplete = onSimulationComplete;
    
    _timer = Timer.periodic(const Duration(seconds: 1), _checkSimulation);
    debugPrint('✅ SimulationService: timer avviato');
  }
  
  // 🔥 UNICA FONTE DI VERITÀ PER IL RALLENTAMENTO
  double _getStepPowerFactor(double soc) {
    if (soc < 80) return 1.0;
    if (soc < 90) return 0.75;
    return 0.50;
  }

  double _getCurrentPower(double currentSoc) {
    return _nominalPower * _getStepPowerFactor(currentSoc);
  }
  
  Duration _calculateTotalDuration() {
    double totalSeconds = 0;
    double tempSoc = _currentSoc;
    
    if (_targetSoc - tempSoc <= 0) return Duration.zero;
    
    while (tempSoc < _targetSoc) {
      double nextThreshold = tempSoc < 80 ? 80 : (tempSoc < 90 ? 90 : 100);
      double targetForStep = _targetSoc < nextThreshold ? _targetSoc : nextThreshold;
      
      double deltaSoc = targetForStep - tempSoc;
      double energy = (deltaSoc / 100) * _capacity;
      double power = _nominalPower * _getStepPowerFactor(tempSoc);
      
      totalSeconds += (energy / power) * 3600;
      tempSoc = targetForStep;
    }
    
    return Duration(seconds: totalSeconds.round());
  }
  
  void initSimulation({
    required DateTime startDateTime,
    required double currentSoc,
    required double targetSoc,
    required double pwr,
    required double cap,
  }) {
    debugPrint('🎯 initSimulation - currentSoc: $currentSoc, targetSoc: $targetSoc');
    debugPrint('🎯 initSimulation - startDateTime: $startDateTime');
    
    _hasNotifiedCompletion = false;
    scheduledStart = null;
    _endTime = null;
    
    scheduledStart = startDateTime;
    _currentSoc = currentSoc;
    _targetSoc = targetSoc;
    _nominalPower = pwr;
    _capacity = cap;
    
    Duration totalDuration = _calculateTotalDuration();
    _endTime = startDateTime.add(totalDuration);
    
    debugPrint('🎯 initSimulation - Potenza nominale: $_nominalPower kW');
    debugPrint('🎯 initSimulation - Durata totale: ${totalDuration.inMinutes} minuti');
    debugPrint('🎯 initSimulation - _endTime: $_endTime');
    
    _isSimulating = false;
    
    if (startDateTime.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
      debugPrint('🎯 initSimulation - partenza immediata!');
      _startSimulation();
    }
  }
  
  void restoreSimulation({
    required DateTime startDateTime,
    required DateTime endDateTime,
    required double currentSoc,
    required double targetSoc,
    required double pwr,
    required double cap,
  }) {
    debugPrint('🔄 restoreSimulation - Punto di partenza: $currentSoc%');
    
    _hasNotifiedCompletion = false;
    scheduledStart = startDateTime;
    _endTime = endDateTime;
    _currentSoc = currentSoc;
    _targetSoc = targetSoc;
    _nominalPower = pwr;
    _capacity = cap;
    
    final now = DateTime.now();

    if (now.isAfter(startDateTime)) {
      _isSimulating = true;
      onStatusChange?.call(true);

      double newSoc = _calculateCurrentSoc(now);
      
      Future.microtask(() {
        onSocUpdate?.call(double.parse(newSoc.toStringAsFixed(1)));
      });
      
      debugPrint('🚀 Restore OK: SOC calcolato ${newSoc.toStringAsFixed(1)}%');
    }
  }
  
  void _startSimulation() {
    debugPrint('▶️ _startSimulation - chiamato');
    _isSimulating = true;
    onStatusChange?.call(true);
    
    NotificationService().showChargingStartedNotification(
      socIniziale: _currentSoc,
      socTarget: _targetSoc,
      startTime: DateTime.now(),
    );
  }
  
  void _checkSimulation(Timer timer) {
    final now = DateTime.now();
    
    if (_isSimulating && _endTime != null && scheduledStart != null) {
      // 🔥 Calcola SOC attuale
      double newSoc = _calculateCurrentSoc(now);
      
      // 🔥 Se abbiamo raggiunto o superato l'orario di fine
      if (!now.isBefore(_endTime!)) {
        debugPrint('⏰ Raggiunto orario fine: ${DateFormat("HH:mm:ss").format(now)}');
        
        if (!_hasNotifiedCompletion) {
          _hasNotifiedCompletion = true;
          _completeSimulation();
        }
        return;
      }
      
      // 🔥 Se siamo entro 2 secondi dalla fine e SOC è quasi al target
      final twoSecondsBeforeEnd = _endTime!.subtract(const Duration(seconds: 2));
      if (now.isAfter(twoSecondsBeforeEnd) && (newSoc >= _targetSoc - 0.5)) {
        if (!_hasNotifiedCompletion) {
          debugPrint('🎯 Quasi alla fine, forzo completamento');
          _hasNotifiedCompletion = true;
          _completeSimulation();
        }
        return;
      }
      
      // Aggiornamento normale
      onSocUpdate?.call(newSoc);
      
      if (now.second % 10 == 0) {
        debugPrint('⏳ Simulazione: SOC Attuale: ${newSoc.toStringAsFixed(1)}%, Fine: ${DateFormat("HH:mm:ss").format(_endTime!)}');
      }
    }
  }
  
  // 🔥 METODO RIVEDUTO E CORRETTO
  double _calculateCurrentSoc(DateTime now) {
    // Se non c'è orario di inizio
    if (scheduledStart == null) return _currentSoc;
    
    // Se non è ancora iniziata
    if (now.isBefore(scheduledStart!)) return _currentSoc;
    
    // Se abbiamo raggiunto o superato l'orario di fine
    if (_endTime != null && !now.isBefore(_endTime!)) {
      return _targetSoc;
    }
    
    // Calcola il tempo trascorso in secondi
    double elapsedSeconds = now.difference(scheduledStart!).inSeconds.toDouble();
    
    // Calcola la durata totale prevista
    Duration totalDuration = _calculateTotalDuration();
    double totalSeconds = totalDuration.inSeconds.toDouble();
    
    if (totalSeconds <= 0) return _currentSoc;
    
    // Calcola la percentuale di tempo trascorsa
    double progress = elapsedSeconds / totalSeconds;
    
    // Limita progresso tra 0 e 1
    progress = progress.clamp(0.0, 1.0);
    
    // 🔥 Usa la stessa logica ma inversa: dal tempo al SOC
    double soc = _currentSoc;
    double accumulatedProgress = 0;
    
    while (soc < _targetSoc && accumulatedProgress < progress) {
      // Determina il prossimo step
      double nextThreshold = soc < 80 ? 80 : (soc < 90 ? 90 : 100);
      double targetForStep = _targetSoc < nextThreshold ? _targetSoc : nextThreshold;
      
      double deltaSoc = targetForStep - soc;
      double energyNeeded = (deltaSoc / 100) * _capacity;
      double power = _nominalPower * _getStepPowerFactor(soc);
      double stepSeconds = (energyNeeded / power) * 3600;
      double stepProgress = stepSeconds / totalSeconds;
      
      if (accumulatedProgress + stepProgress <= progress) {
        // Completato tutto lo step
        soc = targetForStep;
        accumulatedProgress += stepProgress;
      } else {
        // Step parziale
        double remainingProgress = progress - accumulatedProgress;
        double fractionOfStep = remainingProgress / stepProgress;
        soc += deltaSoc * fractionOfStep;
        break;
      }
    }
    
    // 🔥 Assicurati che non superi il target per errori floating point
    if (soc > _targetSoc) soc = _targetSoc;
    if (soc < _currentSoc) soc = _currentSoc;
    
    // 🔥 Arrotonda a 1 decimale per evitare oscillazioni
    return double.parse(soc.toStringAsFixed(1));
  }
  
  void _completeSimulation() {
    debugPrint('✅ _completeSimulation - chiamato');
    
    // 🔥 Forza SOC al target esatto
    _isSimulating = false;
    onStatusChange?.call(false);
    
    // Forza l'aggiornamento UI con SOC target esatto
    Future.microtask(() {
      onSocUpdate?.call(_targetSoc);
      debugPrint('✅ Forzato aggiornamento SOC finale: $_targetSoc%');
    });
    
    onSimulationComplete?.call();
    
    double energyNeeded = ((_targetSoc - _currentSoc) / 100) * _capacity;
    Duration duration = _endTime!.difference(scheduledStart!);
    
    NotificationService().showChargingCompleteNotification(
      socFinale: _targetSoc,
      energia: energyNeeded,
      durata: duration,
    );
    
    debugPrint('✅ Simulazione completata! SOC finale: $_targetSoc%');
  }
  
  void stopSimulation() {
    debugPrint('⏹️ stopSimulation - chiamato');
    _isSimulating = false;
    scheduledStart = null;
    _endTime = null;
    _hasNotifiedCompletion = false;
    onStatusChange?.call(false);
    NotificationService().cancelAllNotifications();
  }
  
  void dispose() {
    debugPrint('🧹 SimulationService: dispose chiamato');
    _timer?.cancel();
    _timer = null;
    NotificationService().cancelAllNotifications();
    
    // Pulisci i callback per evitare memory leak
    onSocUpdate = null;
    onStatusChange = null;
    onSimulationComplete = null;
  }
}