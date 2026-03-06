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
    // 1. Inizializza timezone in modo sicuro
    tz.initializeTimeZones();
    
    // Configurazione per Android
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configurazione per iOS
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    // 2. Inizializza il plugin
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // 3. Richiedi permessi (Android 13+ e iOS)
    await _requestPermissions();
  }

  // Richiesta permessi granulare
  Future<void> _requestPermissions() async {
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
    else if (defaultTargetPlatform == TargetPlatform.android) {
      // Necessario per Android 13 (API 33) e superiori
      await Permission.notification.request();
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('🔔 Notifica aperta con payload: ${response.payload}');
  }

  // Mostra notifica immediata con ID robusto
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'charging_channel',
      'Canale Ricarica',
      channelDescription: 'Notifiche relative alla ricarica',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.blue,
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

    // ID basato sui microsecondi per evitare sovrascritture se arrivano notifiche ravvicinate
    final int id = DateTime.now().microsecondsSinceEpoch % 2147483647;
    
    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Mostra notifica programmata con protezione per orari passati
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // Se l'orario è già passato (es. rinvio dopo riavvio app), mostra subito
    if (scheduledTime.isBefore(DateTime.now())) {
      await showInstantNotification(title: title, body: body, payload: payload);
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'charging_channel',
      'Canale Ricarica',
      channelDescription: 'Notifiche relative alla ricarica',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.blue,
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
    
    try {
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
    } catch (e) {
      debugPrint('❌ Errore programmazione notifica: $e');
    }
  }

  Future<void> cancelNotification(int id) async => await _notificationsPlugin.cancel(id);

  Future<void> cancelAllNotifications() async => await _notificationsPlugin.cancelAll();

  // Helper per messaggi ricarica
  Future<void> showChargingCompleteNotification({
    required double socFinale,
    required double energia,
    required Duration durata,
  }) async {
    await showInstantNotification(
      title: '⚡ Ricarica Completata!',
      body: 'SOC: ${socFinale.toStringAsFixed(0)}% | Energia: ${energia.toStringAsFixed(1)} kWh | Durata: ${_formatDuration(durata)}',
      payload: 'charging_complete',
    );
  }

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

  Future<void> scheduleChargingComplete({
    required int id,
    required DateTime completionTime,
    required double socFinale,
    required double energia,
    required Duration durata,
  }) async {
    await scheduleNotification(
      id: id,
      title: '⚡ Ricarica Completata!',
      body: 'SOC: ${socFinale.toStringAsFixed(0)}% | Energia: ${energia.toStringAsFixed(1)} kWh | Durata: ${_formatDuration(durata)}',
      scheduledTime: completionTime,
      payload: 'charging_complete_$id',
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))} h';
  }
}