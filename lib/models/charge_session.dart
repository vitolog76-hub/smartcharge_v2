import 'package:flutter/material.dart';

class ChargeSession {
  final DateTime date;
  final double kwh;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final double cost;
  final String location;

  ChargeSession({
    required this.date,
    required this.kwh,
    required this.startTime,
    required this.endTime,
    required this.cost,
    required this.location,
  });

  // Converte l'oggetto in una mappa per Shared Preferences
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'kwh': kwh,
    'startHour': startTime.hour,
    'startMinute': startTime.minute,
    'endHour': endTime.hour,
    'endMinute': endTime.minute,
    'cost': cost,
    'location': location,
  };

  // Ricrea l'oggetto dai dati salvati
  factory ChargeSession.fromJson(Map<String, dynamic> json) => ChargeSession(
    date: DateTime.parse(json['date']),
    kwh: json['kwh'],
    startTime: TimeOfDay(hour: json['startHour'], minute: json['startMinute']),
    endTime: TimeOfDay(hour: json['endHour'], minute: json['endMinute']),
    cost: json['cost'],
    location: json['location'],
  );
}