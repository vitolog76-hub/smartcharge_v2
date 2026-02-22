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
  
  // Callbacks
  Function(double)? onSocUpdate;
  Function(bool)? onStatusChange;
  Function()? onSimulationComplete;
  
  // ID per notifiche
  int _notificationId = 0;
  
  // Inizia il checking periodico
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
  
  // Inizializza la simulazione
  void initSimulation({
    required DateTime startDateTime,
    required double currentSoc,
    required double targetSoc,
    required double pwr,
    required double cap,
  }) {
    debugPrint('🎯 SimulationService: initSimulation chiamato');
    debugPrint('   startDateTime: $startDateTime');
    debugPrint('   currentSoc: $currentSoc%');
    debugPrint('   targetSoc: $targetSoc%');
    debugPrint('   pwr: $pwr kW');
    debugPrint('   cap: $cap kWh');
    
    scheduledStart = startDateTime;
    _currentSoc = currentSoc;
    _targetSoc = targetSoc;
    _power = pwr;
    _capacity = cap;
    
    // Calcola tempo di fine stimato
    double energyNeeded = ((targetSoc - currentSoc) / 100) * cap;
    double hours = energyNeeded / pwr;
    _endTime = startDateTime.add(Duration(minutes: (hours * 60).round()));
    
    debugPrint('📊 Calcoli:');
    debugPrint('   energia necessaria: $energyNeeded kWh');
    debugPrint('   ore: $hours h');
    debugPrint('   fine stimata: $_endTime');
    
    // Notifica inizio se è immediato
    if (startDateTime.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
      debugPrint('⚡ Simulazione immediata!');
      _startSimulation();
    }
  }
  
  // Avvia effettivamente la simulazione
  void _startSimulation() {
    debugPrint('🚀 SimulationService: _startSimulation chiamato');
    _isSimulating = true;
    onStatusChange?.call(true);
    debugPrint('   onStatusChange chiamato con true');
    
    // Notifica inizio ricarica
    NotificationService().showChargingStartedNotification(
      socIniziale: _currentSoc,
      socTarget: _targetSoc,
      startTime: DateTime.now(),
    );
    
    // Programma notifica di completamento
    if (_endTime != null && _endTime!.isAfter(DateTime.now())) {
      double energyNeeded = ((_targetSoc - _currentSoc) / 100) * _capacity;
      Duration duration = _endTime!.difference(DateTime.now());
      
      debugPrint('📅 Programmazione notifica completamento per: $_endTime');
      NotificationService().scheduleChargingComplete(
        id: _notificationId++,
        completionTime: _endTime!,
        socFinale: _targetSoc,
        energia: energyNeeded,
        durata: duration,
      );
    }
  }
  
  // Controlla lo stato della simulazione
  void _checkSimulation(Timer timer) {
    final now = DateTime.now();
    
    // Controlla se è ora di iniziare
    if (scheduledStart != null && !_isSimulating) {
      if (now.isAfter(scheduledStart!) || 
          now.isAtSameMomentAs(scheduledStart!)) {
        debugPrint('⏰ È ora di iniziare la simulazione!');
        _startSimulation();
      }
    }
    
    // Aggiorna SOC durante la simulazione
    if (_isSimulating && _endTime != null) {
      if (now.isBefore(_endTime!)) {
        // Calcola SOC progressivo
        double totalDuration = _endTime!.difference(scheduledStart!).inSeconds.toDouble();
        double elapsed = now.difference(scheduledStart!).inSeconds.toDouble();
        double progress = elapsed / totalDuration;
        
        double newSoc = _currentSoc + ((_targetSoc - _currentSoc) * progress);
        // debugPrint('📈 Progresso: ${(progress*100).toStringAsFixed(1)}%, SOC: ${newSoc.toStringAsFixed(1)}%');
        onSocUpdate?.call(newSoc.clamp(_currentSoc, _targetSoc));
      } else {
        debugPrint('🏁 Simulazione completata! now.isBefore(_endTime) = false');
        _completeSimulation();
      }
    }
  }
  
  // Completa la simulazione
  void _completeSimulation() {
    debugPrint('✅ SimulationService: _completeSimulation chiamato');
    _isSimulating = false;
    
    debugPrint('   Chiamata onStatusChange con false');
    onStatusChange?.call(false);
    
    debugPrint('   Chiamata onSocUpdate con target $_targetSoc');
    onSocUpdate?.call(_targetSoc);
    
    debugPrint('   🎯🎯🎯 CHIAMATA onSimulationComplete');
    onSimulationComplete?.call();
    debugPrint('   ✅ onSimulationComplete completata');
    
    // Notifica immediata di completamento (in caso la programmata non funzioni)
    double energyNeeded = ((_targetSoc - _currentSoc) / 100) * _capacity;
    Duration duration = _endTime!.difference(scheduledStart!);
    
    NotificationService().showChargingCompleteNotification(
      socFinale: _targetSoc,
      energia: energyNeeded,
      durata: duration,
    );
    
    debugPrint('📊 Dati finali:');
    debugPrint('   SOC finale: $_targetSoc%');
    debugPrint('   Energia: $energyNeeded kWh');
    debugPrint('   Durata: $duration');
    debugPrint('✅ Simulazione completata!');
  }
  
  // Ferma la simulazione
  void stopSimulation() {
    debugPrint('⏹️ SimulationService: stopSimulation chiamato');
    _isSimulating = false;
    scheduledStart = null;
    _endTime = null;
    onStatusChange?.call(false);
    
    // Cancella notifiche programmate
    NotificationService().cancelAllNotifications();
    
    debugPrint('⏹️ Simulazione fermata manualmente');
  }
  
  void dispose() {
    debugPrint('🧹 SimulationService: dispose chiamato');
    _timer?.cancel();
    NotificationService().cancelAllNotifications();
  }
}