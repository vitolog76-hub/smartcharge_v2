import 'package:intl/intl.dart';

class ChargeEngine {
  static double calculateEnergy(double current, double target, double capacity) {
    if (target <= current) return 0;
    return ((target - current) / 100) * capacity;
  }

  static Duration calculateDuration(double energy, double power) {
    if (power <= 0) return Duration.zero;
    double hours = energy / power;
    return Duration(minutes: (hours * 60).round());
  }

  // NUOVA FUNZIONE: Calcola l'orario di inizio
  static String calculateStartTime(DateTime targetTime, Duration duration) {
    DateTime startTime = targetTime.subtract(duration);
    return DateFormat('HH:mm').format(startTime);
  }
}