import 'package:flutter/material.dart';

class ChargeSession {
  final String id;
  final DateTime date;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final double startSoc;
  final double endSoc;
  final double kwh;
  final double cost;
  final String location;
  final String carBrand;
  final String carModel;
  final double wallboxPower;
  final String fascia;
  final String? contractId;
  
  // 🔥 AGGIUNTI: Prezzi al momento della ricarica
  final double f1PriceAtTime;
  final double f2PriceAtTime;
  final double f3PriceAtTime;

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
    required this.fascia,
    this.contractId,
    // 🔥 Aggiunti al costruttore (obbligatori per le nuove, default 0 per vecchie)
    this.f1PriceAtTime = 0.0,
    this.f2PriceAtTime = 0.0,
    this.f3PriceAtTime = 0.0,
  });

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
    'fascia': fascia,
    'contractId': contractId,
    // 🔥 Salvataggio prezzi
    'f1PriceAtTime': f1PriceAtTime,
    'f2PriceAtTime': f2PriceAtTime,
    'f3PriceAtTime': f3PriceAtTime,
  };

  factory ChargeSession.fromJson(Map<String, dynamic> json) => ChargeSession(
  id: json['id'] ?? '',
  date: DateTime.parse(json['date']),
  startDateTime: json['startDateTime'] != null ? DateTime.parse(json['startDateTime']) : DateTime.parse(json['date']),
  endDateTime: json['endDateTime'] != null ? DateTime.parse(json['endDateTime']) : DateTime.parse(json['date']),
  startSoc: (json['startSoc'] ?? 0.0).toDouble(),
  endSoc: (json['endSoc'] ?? 0.0).toDouble(),
  kwh: (json['kwh'] ?? 0.0).toDouble(),
  cost: (json['cost'] ?? 0.0).toDouble(),
  location: json['location'] ?? "Home",
  carBrand: json['carBrand'] ?? "",
  carModel: json['carModel'] ?? "",
  wallboxPower: (json['wallboxPower'] ?? 3.7).toDouble(),
  fascia: json['fascia'] ?? "F1",

  // 🔥 I CAMPI CRITICI: Aggiungi questi default per le vecchie sessioni
  contractId: json['contractId'] ?? "migrated_default", 
  f1PriceAtTime: (json['f1PriceAtTime'] ?? 0.0).toDouble(),
  f2PriceAtTime: (json['f2PriceAtTime'] ?? 0.0).toDouble(),
  f3PriceAtTime: (json['f3PriceAtTime'] ?? 0.0).toDouble(),
);

  TimeOfDay get startTime => TimeOfDay.fromDateTime(startDateTime);
  TimeOfDay get endTime => TimeOfDay.fromDateTime(endDateTime);
  
  String get formattedDuration {
    final duration = endDateTime.difference(startDateTime);
    return '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')} h';
  }
}