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
  bool _hasNotifiedCompletion = false;
  
  // Callbacks
  Function(double)? onSocUpdate;
  Function(bool)? onStatusChange;
  Function()? onSimulationComplete;
  
  // ID per notifiche
  int _notificationId = 0;
  
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
  
  void initSimulation({
  required DateTime startDateTime,
  required double currentSoc,
  required double targetSoc,
  required double pwr,
  required double cap,
}) {
  debugPrint('🎯 initSimulation - currentSoc: $currentSoc, targetSoc: $targetSoc');
  debugPrint('🎯 initSimulation - startDateTime: $startDateTime');
  
  // 🔥 RESET TOTALE
  _hasNotifiedCompletion = false;
  scheduledStart = null;  // PRIMA NULL
  _endTime = null;        // POI NULL
  
  // ORA assegna i nuovi valori
  scheduledStart = startDateTime;
  _currentSoc = currentSoc;
  _targetSoc = targetSoc;
  _power = pwr;
  _capacity = cap;
  
  double energyNeeded = ((targetSoc - currentSoc) / 100) * cap;
  double hours = energyNeeded / pwr;
  _endTime = startDateTime.add(Duration(minutes: (hours * 60).round()));
  
  debugPrint('🎯 initSimulation - energyNeeded: $energyNeeded kWh');
  debugPrint('🎯 initSimulation - hours: $hours h');
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
    debugPrint('🔄 restoreSimulation - ripristino stato');
    
    _hasNotifiedCompletion = false;
    scheduledStart = startDateTime;
    _endTime = endDateTime;
    _currentSoc = currentSoc;
    _targetSoc = targetSoc;
    _power = pwr;
    _capacity = cap;
    
    final now = DateTime.now();

    // 🔥 LOGICA DI RECUPERO IMMEDIATO
    if (now.isAfter(startDateTime)) {
      _isSimulating = true;
      onStatusChange?.call(true);

      // Calcoliamo subito dove dovrebbe essere il SOC ora
      final totalSeconds = endDateTime.difference(startDateTime).inSeconds;
      final elapsedSeconds = now.difference(startDateTime).inSeconds;

      if (totalSeconds > 0) {
        double progress = (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);
        double jumpedSoc = _currentSoc + ((_targetSoc - _currentSoc) * progress);
        
        // Comunichiamo subito il SOC ricalcolato al Provider
        onSocUpdate?.call(jumpedSoc); 
        debugPrint('🚀 Saltato al SOC ricalcolato: ${jumpedSoc.toStringAsFixed(2)}%');
      }
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
  
  // 1. Controllo Partenza Programmata
  if (scheduledStart != null && !_isSimulating) {
    if (now.isAfter(scheduledStart!)) {
      debugPrint('⏰ Ora di iniziare la ricarica!');
      _startSimulation();
    }
  }
  
  // 2. Gestione Avanzamento Carica
  if (_isSimulating && _endTime != null && scheduledStart != null) {
    // Calcoliamo la durata totale prevista
    final totalSeconds = _endTime!.difference(scheduledStart!).inSeconds;
    if (totalSeconds <= 0) {
       _completeSimulation();
       return;
    }

    // Secondi passati dall'inizio REALE (scheduledStart)
    final elapsedSeconds = now.difference(scheduledStart!).inSeconds;

    if (now.isBefore(_endTime!)) {
      // Calcolo progresso (0.0 a 1.0)
      // Usiamo clamp per evitare valori negativi se 'now' è leggermente prima di 'scheduledStart'
      double progress = (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);
      
      double newSoc = _currentSoc + ((_targetSoc - _currentSoc) * progress);
      
      // Callback per aggiornare l'interfaccia
      onSocUpdate?.call(newSoc);
      
      // Log ridotto per non intasare la console
      if (elapsedSeconds % 10 == 0) { // Logga ogni 10 secondi
         debugPrint('⚡ Carica in corso: ${newSoc.toStringAsFixed(2)}%');
      }
    } else if (!_hasNotifiedCompletion) {
      _hasNotifiedCompletion = true;
      _completeSimulation();
    }
  }
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