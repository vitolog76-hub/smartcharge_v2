import 'package:flutter/material.dart';
import 'package:origo/models/contract_model.dart';
import 'package:origo/models/charge_session.dart';

class CostCalculator {
  // ==========================================================
  // --- 1. DATI ARERA CENTRALI (Q1 2026) ---
  // ==========================================================
  static const double perditeRete = 1.102;        // +10,2%
  static const double oneriSistema = 0.031;       // ASOS + ARIM
  static const double trasportoEnergia = 0.008;   // Quota variabile
  static const double accise = 0.0227;            // Imposta erariale
  static const double quotaPotenzaAnnuaKw = 21.48; 
  static const double minutiInMese = 30 * 24 * 60;

  // ==========================================================
  // --- 2. METODI DI CALCOLO PRINCIPALI ---
  // ==========================================================

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

    double energyPriceBase = 0.0;
    double spread = contract.spread;

    if (contract.isMonorario) {
      energyPriceBase = totalKwh * ((contract.f1Price + spread) * perditeRete);
    } else {
      double energyPerMinute = totalKwh / totalMinutes;
      DateTime current = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
      for (int i = 0; i < totalMinutes; i++) {
        double currentMateria = _getMinutePrice(current, contract);
        energyPriceBase += energyPerMinute * ((currentMateria + spread) * perditeRete);
        current = current.add(const Duration(minutes: 1));
      }
    }
    
    double variableTaxes = totalKwh * (oneriSistema + trasportoEnergia + accise);

    double fixedMonthly = contract.fixedMonthlyFee ?? 0.0;
    double chargeFixedCost = (fixedMonthly / minutiInMese) * totalMinutes;

    double powerLimit = contract.powerFee ?? 6.0; 
    double powerFeeMonthly = (quotaPotenzaAnnuaKw / 12) * powerLimit; 
    double chargePowerCost = (powerFeeMonthly / minutiInMese) * totalMinutes;

    double subtotal = energyPriceBase + variableTaxes + chargeFixedCost + chargePowerCost;
    double vatMultiplier = 1 + ((contract.vat ?? 10.0) / 100);

    return subtotal * vatMultiplier;
  }

  static double getVariableKwhPrice(double materiaPrima, double spread, {double vat = 10.0}) {
    double base = (materiaPrima + spread) * perditeRete;
    double totalNet = base + oneriSistema + trasportoEnergia + accise;
    return totalNet * (1 + (vat / 100));
  }

  static double getMonthlyFixedCosts(EnergyContract contract) {
    double fixedMonthly = contract.fixedMonthlyFee ?? 0.0;
    double powerLimit = contract.powerFee ?? 6.0;
    double powerFeeMonthly = (quotaPotenzaAnnuaKw / 12) * powerLimit;
    
    double subtotal = fixedMonthly + powerFeeMonthly;
    return subtotal * (1 + ((contract.vat ?? 10.0) / 100));
  }

  // ==========================================================
  // --- 3. METODI PER IL RIEPILOGO DETTAGLIATO (UI) ---
  // ==========================================================

  static Map<String, double> getPriceBreakdown(EnergyContract contract) {
    // Usiamo F1 come riferimento per il breakdown nel resoconto
    double materia = contract.f1Price;
    double spread = contract.spread;
    double vatPercent = (contract.vat ?? 10.0) / 100;

    // 1. Materia Prima + Spread con perdite
    double materiaNetta = (materia + spread) * perditeRete;
    
    // 2. Somma di tutte le componenti nette (Imponibile)
    double totaleImponibile = materiaNetta + oneriSistema + trasportoEnergia + accise;
    
    // 3. IVA calcolata sul totale imponibile
    double quotaIva = totaleImponibile * vatPercent;

    return {
      "Materia + Perdite + Spread": materiaNetta,
      "Oneri di Sistema": oneriSistema,
      "Trasporto Variabile": trasportoEnergia,
      "Accise (Imposta Erariale)": accise,
      "IVA (10%)": quotaIva,
      "COSTO FINITO AL kWh": totaleImponibile + quotaIva,
    };
  }

  static Map<String, double> getFixedBreakdown(EnergyContract contract) {
    double vatM = 1 + ((contract.vat ?? 10.0) / 100);
    double powerLimit = contract.powerFee ?? 6.0;
    double powerMonthlyNet = (quotaPotenzaAnnuaKw / 12) * powerLimit;

    return {
      "Commercializzazione": (contract.fixedMonthlyFee ?? 0.0) * vatM,
      "Quota Potenza (${powerLimit.toStringAsFixed(0)}kW)": powerMonthlyNet * vatM,
      "TOTALE FISSI MENSILI": getMonthlyFixedCosts(contract),
    };
  }

  // ==========================================================
  // --- 4. METODI DI SUPPORTO ---
  // ==========================================================

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

    return fasceToccate.length > 1 ? "Mista ${fasceToccate.join('/')}" : fasceToccate.first;
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
    if ((m == 1 && (d == 1 || d == 6)) || (m == 4 && d == 25) || (m == 5 && d == 1) || 
        (m == 6 && d == 2) || (m == 8 && d == 15) || (m == 11 && d == 1) || 
        (m == 12 && (d == 8 || d == 25 || d == 26))) return true; 
    return false;
  }
}