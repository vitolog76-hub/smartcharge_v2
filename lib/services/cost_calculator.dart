import 'package:flutter/material.dart';
import 'package:smartcharge_v2/models/contract_model.dart';

class CostCalculator {
  static double calculate(double kwh, TimeOfDay start, DateTime date, EnergyContract contract) {
    // 1. Se è monorario, usa sempre il prezzo F1
    if (contract.isMonorario) return kwh * contract.f1Price;

    // 2. F3: Domenica, festivi e ore notturne (00-07 / 23-24)
    if (date.weekday == DateTime.sunday || start.hour < 7 || start.hour >= 23) {
      return kwh * contract.f3Price;
    }
    
    // 3. F1: Lun-Ven (08-19)
    if (date.weekday <= 5 && start.hour >= 8 && start.hour < 19) {
      return kwh * contract.f1Price;
    }

    // 4. Altrimenti F2 (Sabato o fasce intermedie Lun-Ven)
    return kwh * contract.f2Price;
  }
}