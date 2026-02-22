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
  double _power = 0;
  double _capacity = 0;
  
  bool _isSimulating = false;
  bool _hasNotifiedCompletion = false; // FLAG PER EVITARE LOOP POPUP
  
  // Callbacks
  Function(double)? onSocUpdate;
  Function(bool)? onStatusChange;
  Function()? onSimulationComplete;
  
  // ID per notifiche
  int _notificationId = 0;
  
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
  }
  
  void initSimulation({
    required DateTime startDateTime,
    required double currentSoc,
    required double targetSoc,
    required double pwr,
    required double cap,
  }) {
    _hasNotifiedCompletion = false; // RESET DEL FLAG ALL'INIZIO
    scheduledStart = startDateTime;
    _currentSoc = currentSoc;
    _targetSoc = targetSoc;
    _power = pwr;
    _capacity = cap;
    
    double energyNeeded = ((targetSoc - currentSoc) / 100) * cap;
    double hours = energyNeeded / pwr;
    _endTime = startDateTime.add(Duration(minutes: (hours * 60).round()));
    
    if (startDateTime.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
      _startSimulation();
    }
  }
  
  void _startSimulation() {
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
    
    if (scheduledStart != null && !_isSimulating) {
      if (now.isAfter(scheduledStart!) || now.isAtSameMomentAs(scheduledStart!)) {
        _startSimulation();
      }
    }
    
    if (_isSimulating && _endTime != null) {
      if (now.isBefore(_endTime!)) {
        double totalDuration = _endTime!.difference(scheduledStart!).inSeconds.toDouble();
        double elapsed = now.difference(scheduledStart!).inSeconds.toDouble();
        double progress = elapsed / totalDuration;
        
        double newSoc = _currentSoc + ((_targetSoc - _currentSoc) * progress);
        onSocUpdate?.call(newSoc.clamp(_currentSoc, _targetSoc));
      } else if (!_hasNotifiedCompletion) { // CONTROLLO FLAG
        _hasNotifiedCompletion = true;    // BLOCCA ULTERIORI CHIAMATE
        _completeSimulation();
      }
    }
  }
  
  void _completeSimulation() {
    _isSimulating = false;
    onStatusChange?.call(false);
    onSocUpdate?.call(_targetSoc);
    
    // Questa chiamata ora avverrà una volta sola
    onSimulationComplete?.call();
    
    double energyNeeded = ((_targetSoc - _currentSoc) / 100) * _capacity;
    Duration duration = _endTime!.difference(scheduledStart!);
    
    NotificationService().showChargingCompleteNotification(
      socFinale: _targetSoc,
      energia: energyNeeded,
      durata: duration,
    );
  }
  
  void stopSimulation() {
    _isSimulating = false;
    scheduledStart = null;
    _endTime = null;
    onStatusChange?.call(false);
    NotificationService().cancelAllNotifications();
  }
  
  void dispose() {
    _timer?.cancel();
    NotificationService().cancelAllNotifications();
  }
}