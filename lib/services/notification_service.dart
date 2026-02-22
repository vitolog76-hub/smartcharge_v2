import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  // Inizializzazione
  Future<void> init() async {
    // Inizializza timezone
    tz.initializeTimeZones();
    
    // Configurazione per Android
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configurazione per iOS
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings();
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    // Inizializza il plugin
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // Richiedi permessi
    await _requestPermissions();
  }

  // Richiedi permessi
  Future<void> _requestPermissions() async {
    // Per iOS
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } 
    // Per Android
    else if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        debugPrint('❌ Permesso notifiche negato');
      }
    }
  }

  // Gestione tap sulla notifica
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('🔔 Notifica aperta: ${response.payload}');
    // Qui puoi navigare a una schermata specifica
  }

  // Mostra notifica immediata
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = 
        AndroidNotificationDetails(
      'charging_channel',
      'Canale Ricarica',
      channelDescription: 'Notifiche relative alla ricarica',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.blue,
      ledColor: Colors.blue,
      ledOnMs: 1000,
      ledOffMs: 500,
      enableVibration: true,
      playSound: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      DateTime.now().millisecond, // ID univoco
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Mostra notifica programmata
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'charging_channel',
      'Canale Ricarica',
      channelDescription: 'Notifiche relative alla ricarica',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.blue,
      enableVibration: true,
      playSound: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
    
    debugPrint('✅ Notifica programmata per: $scheduledTime');
  }

  // Cancella notifiche
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Mostra notifica di ricarica completata
  Future<void> showChargingCompleteNotification({
    required double socFinale,
    required double energia,
    required Duration durata,
  }) async {
    String durataStr = _formatDuration(durata);
    
    await showInstantNotification(
      title: '⚡ Ricarica Completata!',
      body: 'SOC: ${socFinale.toStringAsFixed(0)}% | Energia: ${energia.toStringAsFixed(1)} kWh | Durata: $durataStr',
      payload: 'charging_complete',
    );
  }

  // Mostra notifica di ricarica iniziata
  Future<void> showChargingStartedNotification({
    required double socIniziale,
    required double socTarget,
    required DateTime startTime,
  }) async {
    final format = DateFormat.Hm();
    
    await showInstantNotification(
      title: '🚗 Ricarica Iniziata',
      body: 'Dal ${socIniziale.toStringAsFixed(0)}% al ${socTarget.toStringAsFixed(0)}% - Inizio: ${format.format(startTime)}',
      payload: 'charging_started',
    );
  }

  // Programma notifica di completamento
  Future<void> scheduleChargingComplete({
    required int id,
    required DateTime completionTime,
    required double socFinale,
    required double energia,
    required Duration durata,
  }) async {
    String durataStr = _formatDuration(durata);
    
    await scheduleNotification(
      id: id,
      title: '⚡ Ricarica Completata!',
      body: 'SOC: ${socFinale.toStringAsFixed(0)}% | Energia: ${energia.toStringAsFixed(1)} kWh | Durata: $durataStr',
      scheduledTime: completionTime,
      payload: 'charging_complete_$id',
    );
  }

  // Formatta durata
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return '$hours:$minutes h';
  }
}