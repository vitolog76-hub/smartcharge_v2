import 'package:flutter/material.dart';
import 'package:smartcharge_v2/models/contract_model.dart';

class CostCalculator {
  // Metodo statico che riceve i kWh, l'ora di inizio, la data e il contratto
  static double calculate(double kwh, TimeOfDay start, DateTime date, EnergyContract contract) {
    if (kwh <= 0) return 0.0;
    
    // Se è monorario, usa il prezzo F1 (già ivato dall'IA)
    if (contract.isMonorario) return kwh * contract.f1Price;

    double prezzoDaUsare;
    int hour = start.hour;
    int weekday = date.weekday;

    // Logica fasce ARERA (solo per scegliere QUALE prezzo IA usare)
    if (weekday == DateTime.sunday) {
      prezzoDaUsare = contract.f3Price;
    } else if (weekday == DateTime.saturday) {
      prezzoDaUsare = (hour < 8 || hour >= 23) ? contract.f3Price : contract.f2Price;
    } else {
      if (hour >= 8 && hour < 19) {
        prezzoDaUsare = contract.f1Price;
      } else if ((hour >= 7 && hour < 8) || (hour >= 19 && hour < 23)) {
        prezzoDaUsare = contract.f2Price;
      } else {
        prezzoDaUsare = contract.f3Price;
      }
    }

    return kwh * prezzoDaUsare;
  }
}