import 'package:flutter/material.dart';
import 'package:smartcharge_v2/models/contract_model.dart';
import 'package:smartcharge_v2/models/charge_session.dart';

class CostCalculator {
  // --- COSTANTI STANDARD ARERA (Aggiornate 2025/2026) ---
  
  // Perdite di rete (obbligatorie per il mercato libero)
  static const double perditeRete = 1.102; // +10,2%
  
  // Componenti variabili uguali per tutti i gestori (Accise + Trasporto + Oneri)
  static const double acciseOneriVariabili = 0.038; // €/kWh
  
  // Quota Potenza ARERA: ~21,48€/kW all'anno
  static const double quotaPotenzaAnnuaKw = 21.48; 
  
  static const double minutiInMese = 30 * 24 * 60;

  /// 1. CALCOLO COSTO TOTALE DELLA SESSIONE
  /// Somma i costi variabili (energia + spread) e i costi fissi pro-rata (PCV e Potenza)
  static double calculate({
    required double totalKwh,
    required double wallboxPower,
    required TimeOfDay startTime,
    required DateTime date,
    required EnergyContract contract,
  }) {
    if (totalKwh <= 0 || wallboxPower <= 0) return 0.0;
    
    int totalMinutes = ((totalKwh / wallboxPower) * 60).round();
    if (totalMinutes == 0) totalMinutes = 1;

    // --- A. COMPONENTE ENERGIA (Variabile: Materia + Spread + Perdite) ---
    double energyPriceBase = 0.0;
    double spread = contract.spread; // Recuperiamo lo spread dal modello

    if (contract.isMonorario) {
      // (Prezzo F0 + Spread) * Perdite di Rete
      energyPriceBase = totalKwh * ((contract.f1Price + spread) * perditeRete);
    } else {
      double energyPerMinute = totalKwh / totalMinutes;
      DateTime current = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
      for (int i = 0; i < totalMinutes; i++) {
        double currentMateria = _getMinutePrice(current, contract);
        // (Materia della fascia + Spread) * Perdite
        energyPriceBase += energyPerMinute * ((currentMateria + spread) * perditeRete);
        current = current.add(const Duration(minutes: 1));
      }
    }
    
    // Accise e Oneri variabili (Standard ARERA) applicati ai kWh
    double variableTaxes = totalKwh * acciseOneriVariabili;

    // --- B. COMPONENTE COSTI FISSI (Pro-Rata sui minuti di ricarica) ---
    // 1. Quota Fissa Venditore (PCV)
    double fixedMonthly = contract.fixedMonthlyFee ?? 0.0;
    double chargeFixedCost = (fixedMonthly / minutiInMese) * totalMinutes;

    // 2. Quota Potenza ARERA (basata sui kW del contatore)
    double powerLimit = contract.powerFee ?? 6.0; 
    double powerFeeMonthly = (quotaPotenzaAnnuaKw / 12) * powerLimit; 
    double chargePowerCost = (powerFeeMonthly / minutiInMese) * totalMinutes;

    // --- C. TOTALE + IVA ---
    double subtotal = energyPriceBase + variableTaxes + chargeFixedCost + chargePowerCost;
    double vatMultiplier = 1 + ((contract.vat ?? 10.0) / 100);

    return subtotal * vatMultiplier;
  }

  /// 2. CALCOLO TARIFFA EFFETTIVA AL kWh (Solo Variabile)
  /// Include: Materia + Spread + Perdite + Accise + IVA.
  /// ESCLUDE i costi fissi mensili.
  static double getVariableKwhPrice(double materiaPrima, double spread, {double vat = 10.0}) {
    double baseWithSpreadAndLosses = (materiaPrima + spread) * perditeRete;
    double totalVariable = baseWithSpreadAndLosses + acciseOneriVariabili;
    double vatMultiplier = 1 + (vat / 100);
    return totalVariable * vatMultiplier;
  }

  /// 3. CALCOLO COSTI FISSI MENSILI TOTALI
  /// Somma la quota fissa del venditore e la quota potenza ARERA.
  static double getMonthlyFixedCosts(EnergyContract contract) {
    double fixedMonthly = contract.fixedMonthlyFee ?? 0.0;
    double powerLimit = contract.powerFee ?? 6.0;
    double powerFeeMonthly = (quotaPotenzaAnnuaKw / 12) * powerLimit;
    
    double subtotal = fixedMonthly + powerFeeMonthly;
    double vatMultiplier = 1 + ((contract.vat ?? 10.0) / 100);
    return subtotal * vatMultiplier;
  }

  // --- METODI DI SUPPORTO ---

  static double calculateComparison({
    required ChargeSession session,
    required EnergyContract targetContract,
  }) {
    final startTime = TimeOfDay.fromDateTime(session.startDateTime);
    return calculate(
      totalKwh: session.kwh,
      wallboxPower: session.wallboxPower,
      startTime: startTime,
      date: session.startDateTime,
      contract: targetContract,
    );
  }

  static String getFasciaLabel({
    required double totalKwh,
    required double wallboxPower,
    required TimeOfDay startTime,
    required DateTime date,
    required bool isMonorario,
  }) {
    if (isMonorario) return "Monoraria";
    if (totalKwh <= 0 || wallboxPower <= 0) return "N/D";

    int totalMinutes = ((totalKwh / wallboxPower) * 60).round();
    if (totalMinutes == 0) totalMinutes = 1;

    Set<String> fasceToccate = {};
    DateTime current = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);

    for (int i = 0; i < totalMinutes; i++) {
      fasceToccate.add(_getFasciaName(current));
      current = current.add(const Duration(minutes: 1));
    }

    if (fasceToccate.length > 1) {
      List<String> sortedFasce = fasceToccate.toList()..sort();
      return "Mista ${sortedFasce.join('/')}";
    } else {
      return fasceToccate.isNotEmpty ? fasceToccate.first : "N/D";
    }
  }

  static double _getMinutePrice(DateTime dt, EnergyContract contract) {
    String fascia = _getFasciaName(dt);
    if (fascia == "F1") return contract.f1Price;
    if (fascia == "F2") return contract.f2Price;
    return contract.f3Price;
  }

  static String _getFasciaName(DateTime dt) {
    int hour = dt.hour;
    int weekday = dt.weekday;
    if (weekday == DateTime.sunday || _isHoliday(dt)) return "F3";
    if (weekday == DateTime.saturday) return (hour >= 7 && hour < 23) ? "F2" : "F3";
    if (hour >= 8 && hour < 19) return "F1";
    if ((hour >= 7 && hour < 8) || (hour >= 19 && hour < 23)) return "F2";
    return "F3";
  }

  static bool _isHoliday(DateTime date) {
    final int d = date.day;
    final int m = date.month;
    if ((m == 1 && d == 1) || (m == 1 && d == 6) || (m == 4 && d == 25) || 
        (m == 5 && d == 1) || (m == 6 && d == 2) || (m == 8 && d == 15) || 
        (m == 11 && d == 1) || (m == 12 && d == 8) || (m == 12 && d == 25) || 
        (m == 12 && d == 26)) return true; 
    return false;
  }
}