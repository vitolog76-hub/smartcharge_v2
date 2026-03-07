import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartcharge_v2/services/notification_service.dart';

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
  
  // 🔥 STEP 1: Calcola la potenza in base al SOC con 3 step
  double _getCurrentPower(double currentSoc) {
    // Step 1: 20% - 80% -> potenza piena
    if (currentSoc < 80) {
      return _nominalPower;
    }
    // Step 2: 80% - 90% -> potenza ridotta al 60%
    else if (currentSoc >= 80 && currentSoc < 90) {
      return _nominalPower * 0.6;
    }
    // Step 3: 90% - 100% -> potenza ridotta al 20%
    else {
      return _nominalPower * 0.2;
    }
  }
  
  // 🔥 STEP 2: Calcola il tempo totale considerando i 3 step
  Duration _calculateTotalDuration() {
    double totalSeconds = 0;
    double currentSoc = _currentSoc;
    double remainingSoc = _targetSoc - currentSoc;
    
    if (remainingSoc <= 0) return Duration.zero;
    
    // Calcola quanta energia serve in ogni step
    double energyNeeded = 0;
    
    // Step 1: 20-80% (se applicabile)
    if (currentSoc < 80) {
      double step1End = _targetSoc < 80 ? _targetSoc : 80;
      double step1Delta = step1End - currentSoc;
      if (step1Delta > 0) {
        double step1Energy = (step1Delta / 100) * _capacity;
        double step1Hours = step1Energy / _nominalPower;
        totalSeconds += step1Hours * 3600;
        currentSoc = step1End;
      }
    }
    
    // Step 2: 80-90% (se applicabile)
    if (currentSoc >= 80 && currentSoc < 90 && _targetSoc > 80) {
      double step2End = _targetSoc < 90 ? _targetSoc : 90;
      double step2Delta = step2End - currentSoc;
      if (step2Delta > 0) {
        double step2Energy = (step2Delta / 100) * _capacity;
        double step2Hours = step2Energy / (_nominalPower * 0.6);
        totalSeconds += step2Hours * 3600;
        currentSoc = step2End;
      }
    }
    
    // Step 3: 90-100% (se applicabile)
    if (currentSoc >= 90 && _targetSoc > 90) {
      double step3Delta = _targetSoc - currentSoc;
      if (step3Delta > 0) {
        double step3Energy = (step3Delta / 100) * _capacity;
        double step3Hours = step3Energy / (_nominalPower * 0.2);
        totalSeconds += step3Hours * 3600;
      }
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
    
    // RESET TOTALE
    _hasNotifiedCompletion = false;
    scheduledStart = null;
    _endTime = null;
    
    // Assegna i nuovi valori
    scheduledStart = startDateTime;
    _currentSoc = currentSoc;
    _targetSoc = targetSoc;
    _nominalPower = pwr;
    _capacity = cap;
    
    // 🔥 Calcola il tempo totale considerando i 3 step
    Duration totalDuration = _calculateTotalDuration();
    _endTime = startDateTime.add(totalDuration);
    
    debugPrint('🎯 initSimulation - Potenza nominale: $_nominalPower kW');
    debugPrint('🎯 initSimulation - Durata totale: ${totalDuration.inMinutes} minuti');
    debugPrint('🎯 initSimulation - _endTime: $_endTime');
    debugPrint('🎯 initSimulation - now: ${DateTime.now()}');
    
    // Reset flag simulazione
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

      // 🔥 Calcola il progresso in modo più accurato considerando i 3 step
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
      if (now.isBefore(_endTime!)) {
        // 🔥 Calcola il SOC attuale considerando i 3 step
        double newSoc = _calculateCurrentSoc(now);
        onSocUpdate?.call(newSoc);
        
        if (now.second % 10 == 0) {
          debugPrint('⏳ Simulazione: SOC Attuale: ${newSoc.toStringAsFixed(1)}%');
        }
      } else if (!_hasNotifiedCompletion) {
        _hasNotifiedCompletion = true;
        _completeSimulation();
      }
    }
  }
  
  // 🔥 STEP 3: Calcola il SOC attuale basato sui 3 step di potenza
  double _calculateCurrentSoc(DateTime now) {
    if (now.isBefore(scheduledStart!)) return _currentSoc;
    
    double elapsedSeconds = now.difference(scheduledStart!).inSeconds.toDouble();
    if (elapsedSeconds <= 0) return _currentSoc;
    
    double soc = _currentSoc;
    double secondsRemaining = elapsedSeconds;
    
    // Step 1: 20-80% (potenza piena)
    if (soc < 80) {
      double step1End = _targetSoc < 80 ? _targetSoc : 80;
      double step1Delta = step1End - soc;
      if (step1Delta > 0) {
        double step1Energy = (step1Delta / 100) * _capacity;
        double step1Seconds = (step1Energy / _nominalPower) * 3600;
        
        if (secondsRemaining >= step1Seconds) {
          // Completato step 1
          soc = step1End;
          secondsRemaining -= step1Seconds;
        } else {
          // Ancora nello step 1
          double energyDone = (secondsRemaining / 3600) * _nominalPower;
          double socDone = (energyDone / _capacity) * 100;
          soc = _currentSoc + socDone;
          return soc.clamp(_currentSoc, _targetSoc);
        }
      }
    }
    
    // Step 2: 80-90% (potenza 60%)
    if (soc >= 80 && soc < 90 && _targetSoc > 80) {
      double step2End = _targetSoc < 90 ? _targetSoc : 90;
      double step2Delta = step2End - soc;
      if (step2Delta > 0) {
        double step2Energy = (step2Delta / 100) * _capacity;
        double step2Seconds = (step2Energy / (_nominalPower * 0.6)) * 3600;
        
        if (secondsRemaining >= step2Seconds) {
          // Completato step 2
          soc = step2End;
          secondsRemaining -= step2Seconds;
        } else {
          // Ancora nello step 2
          double power = _nominalPower * 0.6;
          double energyDone = (secondsRemaining / 3600) * power;
          double socDone = (energyDone / _capacity) * 100;
          soc = soc + socDone;
          return soc.clamp(_currentSoc, _targetSoc);
        }
      }
    }
    
    // Step 3: 90-100% (potenza 20%)
    if (soc >= 90 && _targetSoc > 90) {
      double step3Delta = _targetSoc - soc;
      if (step3Delta > 0) {
        double step3Energy = (step3Delta / 100) * _capacity;
        double step3Seconds = (step3Energy / (_nominalPower * 0.2)) * 3600;
        
        if (secondsRemaining >= step3Seconds) {
          // Completato step 3
          soc = _targetSoc;
        } else {
          // Ancora nello step 3
          double power = _nominalPower * 0.2;
          double energyDone = (secondsRemaining / 3600) * power;
          double socDone = (energyDone / _capacity) * 100;
          soc = soc + socDone;
          return soc.clamp(_currentSoc, _targetSoc);
        }
      }
    }
    
    return soc.clamp(_currentSoc, _targetSoc);
  }
  
  void _completeSimulation() {
    debugPrint('✅ _completeSimulation - chiamato');
    _isSimulating = false;
    onStatusChange?.call(false);
    onSocUpdate?.call(_targetSoc);
    
    onSimulationComplete?.call();
    
    double energyNeeded = ((_targetSoc - _currentSoc) / 100) * _capacity;
    Duration duration = _endTime!.difference(scheduledStart!);
    
    NotificationService().showChargingCompleteNotification(
      socFinale: _targetSoc,
      energia: energyNeeded,
      durata: duration,
    );
    
    debugPrint('✅ Simulazione completata!');
  }
  
  void stopSimulation() {
    debugPrint('⏹️ stopSimulation - chiamato');
    _isSimulating = false;
    scheduledStart = null;
    _endTime = null;
    onStatusChange?.call(false);
    NotificationService().cancelAllNotifications();
  }
  
  void dispose() {
    debugPrint('🧹 SimulationService: dispose chiamato');
    _timer?.cancel();
    NotificationService().cancelAllNotifications();
  }
}