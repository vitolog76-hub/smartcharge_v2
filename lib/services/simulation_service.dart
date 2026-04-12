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
  double _nominalPower = 0;
  double _capacity = 0;
  
  bool _isSimulating = false;
  bool _hasNotifiedCompletion = false;
  
  // Callbacks
  Function(double)? onSocUpdate;
  Function(bool)? onStatusChange;
  Function()? onSimulationComplete;
  
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
  
  // 🔥 ALLINEATO A ChargeEngine: potenza costante, nessun rallentamento
  Duration _calculateTotalDuration() {
    if (_targetSoc <= _currentSoc) return Duration.zero;
    
    double energyNeeded = ((_targetSoc - _currentSoc) / 100) * _capacity;
    double hours = energyNeeded / _nominalPower;
    return Duration(minutes: (hours * 60).round());
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
    
    debugPrint('🎯 initSimulation - Potenza: $_nominalPower kW');
    debugPrint('🎯 initSimulation - Energia: ${((_targetSoc - _currentSoc) / 100 * _capacity).toStringAsFixed(1)} kWh');
    debugPrint('🎯 initSimulation - Durata: ${totalDuration.inMinutes} minuti');
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
      double newSoc = _calculateCurrentSoc(now);
      
      if (!now.isBefore(_endTime!)) {
        debugPrint('⏰ Raggiunto orario fine: ${DateFormat("HH:mm:ss").format(now)}');
        
        if (!_hasNotifiedCompletion) {
          _hasNotifiedCompletion = true;
          _completeSimulation();
        }
        return;
      }
      
      onSocUpdate?.call(newSoc);
      
      if (now.second % 10 == 0) {
        debugPrint('⏳ Simulazione: SOC Attuale: ${newSoc.toStringAsFixed(1)}%, Fine: ${DateFormat("HH:mm:ss").format(_endTime!)}');
      }
    }
  }
  
  // 🔥 ALLINEATO A ChargeEngine: calcolo lineare proporzionale
  double _calculateCurrentSoc(DateTime now) {
    if (scheduledStart == null) return _currentSoc;
    if (now.isBefore(scheduledStart!)) return _currentSoc;
    if (_endTime != null && !now.isBefore(_endTime!)) return _targetSoc;
    
    final totalDuration = _endTime!.difference(scheduledStart!);
    final elapsedDuration = now.difference(scheduledStart!);
    
    final progress = elapsedDuration.inSeconds / totalDuration.inSeconds;
    
    double soc = _currentSoc + (_targetSoc - _currentSoc) * progress;
    
    if (soc > _targetSoc) soc = _targetSoc;
    if (soc < _currentSoc) soc = _currentSoc;
    
    return double.parse(soc.toStringAsFixed(1));
  }
  
  void _completeSimulation() {
    debugPrint('✅ _completeSimulation - chiamato');
    
    _isSimulating = false;
    onStatusChange?.call(false);
    
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
    
    onSocUpdate = null;
    onStatusChange = null;
    onSimulationComplete = null;
  }
}