import 'package:flutter/material.dart';

class ChargeSession {
  final String id;                    // Identificativo univoco
  final DateTime date;
  final DateTime startDateTime;       // Data e ora inizio completa
  final DateTime endDateTime;         // Data e ora fine completa
  final double startSoc;              // SOC iniziale %
  final double endSoc;                // SOC finale %
  final double kwh;                   // Energia usata
  final double cost;
  final String location;              // "Home" o "Pubblica"
  final String carBrand;              // Marca auto
  final String carModel;              // Modello auto
  final double wallboxPower;          // Potenza wallbox in kW

  ChargeSession({
    required this.id,
    required this.date,
    required this.startDateTime,
    required this.endDateTime,
    required this.startSoc,
    required this.endSoc,
    required this.kwh,
    required this.cost,
    required this.location,
    required this.carBrand,
    required this.carModel,
    required this.wallboxPower,
  });

  // Getter per compatibilità con codice esistente
  TimeOfDay get startTime => TimeOfDay.fromDateTime(startDateTime);
  TimeOfDay get endTime => TimeOfDay.fromDateTime(endDateTime);

  // Converte l'oggetto in una mappa per Shared Preferences
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'startDateTime': startDateTime.toIso8601String(),
    'endDateTime': endDateTime.toIso8601String(),
    'startSoc': startSoc,
    'endSoc': endSoc,
    'kwh': kwh,
    'cost': cost,
    'location': location,
    'carBrand': carBrand,
    'carModel': carModel,
    'wallboxPower': wallboxPower,
  };

  // Ricrea l'oggetto dai dati salvati
  factory ChargeSession.fromJson(Map<String, dynamic> json) => ChargeSession(
    id: json['id'],
    date: DateTime.parse(json['date']),
    startDateTime: DateTime.parse(json['startDateTime']),
    endDateTime: DateTime.parse(json['endDateTime']),
    startSoc: json['startSoc'].toDouble(),
    endSoc: json['endSoc'].toDouble(),
    kwh: json['kwh'].toDouble(),
    cost: json['cost'].toDouble(),
    location: json['location'],
    carBrand: json['carBrand'],
    carModel: json['carModel'],
    wallboxPower: json['wallboxPower'].toDouble(),
  );

  // Metodo per formattare la durata
  String get formattedDuration {
    final duration = endDateTime.difference(startDateTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} h';
  }

  // Metodo per formattare l'orario
  String get formattedStartTime => '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  String get formattedEndTime => '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
}