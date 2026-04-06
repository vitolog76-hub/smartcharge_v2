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
  
  // 🔥 STEP 1: Calcola la potenza in base al SOC (CORRETTO)
  double _getCurrentPower(double currentSoc) {
    // Step 1: < 80% -> potenza piena
    if (currentSoc < 80) {
      return _nominalPower;
    }
    // Step 2: 80% - 90% -> potenza al 75% (più realistico in AC)
    else if (currentSoc >= 80 && currentSoc < 90) {
      return _nominalPower * 0.75;
    }
    // Step 3: 90% - 100% -> potenza al 50% (minimo tecnico AC)
    else {
      return _nominalPower * 0.5;
    }
  }
  
  // 🔥 STEP 2: Calcola il tempo totale considerando i 3 step (CORRETTO)
  Duration _calculateTotalDuration() {
    double totalSeconds = 0;
    double currentSoc = _currentSoc;
    double remainingSoc = _targetSoc - currentSoc;
    
    if (remainingSoc <= 0) return Duration.zero;
    
    // Step 1: 0-80%
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
    
    // Step 2: 80-90% (Usiamo 0.75 invece di 0.6)
    if (currentSoc >= 80 && currentSoc < 90 && _targetSoc > 80) {
      double step2End = _targetSoc < 90 ? _targetSoc : 90;
      double step2Delta = step2End - currentSoc;
      if (step2Delta > 0) {
        double step2Energy = (step2Delta / 100) * _capacity;
        double step2Power = _nominalPower * 0.75;
        double step2Hours = step2Energy / step2Power;
        totalSeconds += step2Hours * 3600;
        currentSoc = step2End;
      }
    }
    
    // Step 3: 90-100% (Usiamo 0.5 invece di 0.2)
    if (currentSoc >= 90 && _targetSoc > 90) {
      double step3Delta = _targetSoc - currentSoc;
      if (step3Delta > 0) {
        double step3Energy = (step3Delta / 100) * _capacity;
        double step3Power = _nominalPower * 0.5;
        double step3Hours = step3Energy / step3Power;
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
      // Se abbiamo superato l'orario di fine, forziamo il completamento
      if (now.isAfter(_endTime!) && !_hasNotifiedCompletion) {
        _hasNotifiedCompletion = true;
        _completeSimulation();
      } else if (now.isBefore(_endTime!)) {
        // Altrimenti calcoliamo il progresso
        double newSoc = _calculateCurrentSoc(now);
        onSocUpdate?.call(newSoc);
        
        if (now.second % 10 == 0) {
          debugPrint('⏳ Simulazione: SOC Attuale: ${newSoc.toStringAsFixed(1)}%');
        }
      }
    }
  }
  
  double _calculateCurrentSoc(DateTime now) {
    if (scheduledStart == null || now.isBefore(scheduledStart!)) return _currentSoc;
    if (_endTime != null && now.isAfter(_endTime!)) return _targetSoc;
    
    double elapsedSeconds = now.difference(scheduledStart!).inSeconds.toDouble();
    if (elapsedSeconds <= 0) return _currentSoc;
    
    double soc = _currentSoc;
    double secondsRemaining = elapsedSeconds;
    
    // --- Step 1: 0-80% (Potenza Piena) ---
    // Rimane identico perché la simulazione qui è perfetta
    if (soc < 80) {
      double step1End = _targetSoc < 80 ? _targetSoc : 80;
      double step1Delta = step1End - soc;
      if (step1Delta > 0) {
        double step1Energy = (step1Delta / 100) * _capacity;
        double step1Seconds = (step1Energy / _nominalPower) * 3600;
        
        if (secondsRemaining >= step1Seconds) {
          soc = step1End;
          secondsRemaining -= step1Seconds;
        } else {
          double energyDone = (secondsRemaining / 3600) * _nominalPower;
          double socDone = (energyDone / _capacity) * 100;
          return (soc + socDone).clamp(_currentSoc, _targetSoc);
        }
      }
    }
    
    // --- Step 2: 80-90% (Potenza 80%) ---
    // Alzata da 0.6 a 0.8: in AC il rallentamento è minimo
    if (soc >= 80 && soc < 90 && _targetSoc > 80) {
      double step2End = _targetSoc < 90 ? _targetSoc : 90;
      double step2Delta = step2End - soc;
      if (step2Delta > 0) {
        double step2Power = _nominalPower * 0.8; 
        double step2Energy = (step2Delta / 100) * _capacity;
        double step2Seconds = (step2Energy / step2Power) * 3600;
        
        if (secondsRemaining >= step2Seconds) {
          soc = step2End;
          secondsRemaining -= step2Seconds;
        } else {
          double energyDone = (secondsRemaining / 3600) * step2Power;
          double socDone = (energyDone / _capacity) * 100;
          return (soc + socDone).clamp(_currentSoc, _targetSoc);
        }
      }
    }
    
    // --- Step 3: 90-100% (Potenza 60%) ---
    // Alzata da 0.2 a 0.6: evita lo sforamento di 3 ore
    if (soc >= 90 && _targetSoc > 90) {
      double step3Delta = _targetSoc - soc;
      if (step3Delta > 0) {
        double step3Power = _nominalPower * 0.6; 
        double step3Energy = (step3Delta / 100) * _capacity;
        double step3Seconds = (step3Energy / step3Power) * 3600;
        
        if (secondsRemaining >= step3Seconds) {
          soc = _targetSoc;
        } else {
          double energyDone = (secondsRemaining / 3600) * step3Power;
          double socDone = (energyDone / _capacity) * 100;
          soc = soc + socDone;
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