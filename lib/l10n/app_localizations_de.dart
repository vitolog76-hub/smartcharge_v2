// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'OriGO';

  @override
  String get home => 'Zuhause';

  @override
  String get totalKwh => 'GESAMT kWh';

  @override
  String get totalCost => 'GESAMT €';

  @override
  String get totalCharges => 'ANZAHL LADUNGEN';

  @override
  String get dailyTrend => 'Täglicher Trend (kWh)';

  @override
  String get monthlyTrend => 'Monatlicher Trend (kWh)';

  @override
  String get location => 'ORT';

  @override
  String get fascia => 'ZEITFENSTER';

  @override
  String get generatedOn => 'Generiert am';

  @override
  String get month => 'ZUSAMMENFASSUNG';

  @override
  String get year => 'JAHRESZUSAMMENFASSUNG';

  @override
  String get exportReport => 'Bericht exportieren';

  @override
  String get exportSubtitle => 'Wähle den Zeitraum für das PDF';

  @override
  String get currentMonth => 'Aktueller Monat';

  @override
  String get currentYear => 'Aktuelles Jahr';

  @override
  String get allHistory => 'Gesamter Verlauf';

  @override
  String get public => 'Öffentlich';

  @override
  String get costEuro => 'Kosten';

  @override
  String get hello => 'HALLO';

  @override
  String get contract => 'VERTRAG';

  @override
  String get readyAt => 'BEREIT UM';

  @override
  String get charging => 'LÄDT';

  @override
  String get waiting => 'WARTET';

  @override
  String calculatedOnPower(Object power) {
    return 'Berechnet auf $power kW';
  }

  @override
  String get batteryIntelligence => '3 - BATTERIE-INTELLIGENZ';

  @override
  String get nominalValue => 'NENNWERT';

  @override
  String get userVehicleData => '2 - BENUTZER- UND FAHRZEUGDATEN';

  @override
  String get languageSection => 'SPRACHE';

  @override
  String savingsMessage(Object amount) {
    return 'EINSPARUNG: +$amount€';
  }

  @override
  String extraCostMessage(Object amount) {
    return 'ZUSATZKOSTEN: $amount€';
  }

  @override
  String get history => 'LADEVERLAUF';

  @override
  String get energy => 'ENERGIE';

  @override
  String get cost => 'KOSTEN';

  @override
  String get kwh => 'kWh';

  @override
  String get euro => '€';

  @override
  String get noCharges => 'Keine Ladungen';

  @override
  String get start => 'START';

  @override
  String get stop => 'STOPP';

  @override
  String get power => 'LEISTUNG';

  @override
  String get duration => 'Dauer';

  @override
  String get finalPrice => 'Endpreis';

  @override
  String get initialSoc => 'START-SOC';

  @override
  String get finalSoc => 'END-SOC';

  @override
  String get currentSoc => 'AKTUELLER SOC';

  @override
  String get targetSoc => 'ZIEL';

  @override
  String get simulate => 'LADEN SIMULIEREN';

  @override
  String get simulateCharging => 'LADEN SIMULIEREN';

  @override
  String get addHomeCharge => 'HEIMLADEN HINZUFÜGEN';

  @override
  String get addPublicCharge => 'ÖFFENTLICHES LADEN HINZUFÜGEN';

  @override
  String get addManualCharge => 'Manuelles Laden hinzufügen';

  @override
  String get date => 'Datum';

  @override
  String get end => 'Ende';

  @override
  String get edit => 'BEARBEITEN';

  @override
  String get save => 'SPEICHERN';

  @override
  String get cancel => 'ABBRECHEN';

  @override
  String get delete => 'LÖSCHEN';

  @override
  String get confirm => 'BESTÄTIGEN';

  @override
  String get interrupt => 'UNTERBRECHEN';

  @override
  String get discard => 'VERWERFEN';

  @override
  String interruptMessage(Object soc) {
    return 'Ladung bei $soc%. Möchtest du die Sitzung im Verlauf speichern?';
  }

  @override
  String get close => 'SCHLIESSEN';

  @override
  String get batteryCoach => 'BATTERIEANALYSE';

  @override
  String get batteryCoachLfp => 'LFP-BATTERIEANALYSE';

  @override
  String get batteryCoachNmc => 'NMC-BATTERIEANALYSE';

  @override
  String get batteryCoachGeneric => 'ALLGEMEINER HINWEIS';

  @override
  String get batteryAdviceEmpty =>
      'Beginne mit dem Laden, um Tipps basierend auf deinem Fahrstil zu erhalten.';

  @override
  String get batteryAdviceLfp =>
      '⚠️ Du hast seit über einer Woche nicht auf 100% geladen. Lade heute Nacht, um die Zellen (BMS) zu kalibrieren.';

  @override
  String get batteryAdviceLfpGood =>
      '✅ Batterie gut kalibriert. Halte das Ziel für den Rest der Woche zwischen 20-80%.';

  @override
  String get batteryAdviceNmc =>
      '⚠️ Du hast im letzten Monat %d Mal über 80% geladen. Versuche es zu begrenzen, um die Degradation zu reduzieren.';

  @override
  String get batteryAdviceNmcGood =>
      '✅ Hervorragendes Management: Du schützt die Nickel-Chemie, indem du Ladespitzen begrenzt.';

  @override
  String get batteryAdviceGeneric =>
      'Halte die Ladung zwischen 20-80% für optimale Langlebigkeit.';

  @override
  String get taperingWarning => 'Über 80% verlangsamt sich das Laden';

  @override
  String get taperingWarningHigh => 'Über 90% ist das Laden sehr langsam';

  @override
  String get taperingWarning60 =>
      '🔋 Über 80% verlangsamt sich das Laden (60% Leistung)';

  @override
  String get taperingWarning20 =>
      '⚡ Über 90% ist das Laden sehr langsam (20% Leistung)';

  @override
  String get taperingSlowdown => 'Ladeverlangsamung';

  @override
  String get taperingSignificant => 'Erhebliche Verlangsamung';

  @override
  String get chargingComplete => '⚡ LADEN ABGESCHLOSSEN!';

  @override
  String get chargingInfo => 'Ladeinfo';

  @override
  String get readyBy => 'Bereit um';

  @override
  String get startsAt => 'Beginnt um';

  @override
  String get estimatedCost => 'Geschätzte Kosten';

  @override
  String get energyNeeded => 'Benötigte Energie';

  @override
  String get chargingTime => 'Ladezeit';

  @override
  String get confirmCharging => 'LADEN BESTÄTIGEN';

  @override
  String get selectLocation => 'Ort auswählen';

  @override
  String get chargeAdded => 'Ladung erfolgreich hinzugefügt';

  @override
  String get chargeDeleted => 'Ladung gelöscht';

  @override
  String get chargeEdited => 'Ladung bearbeitet';

  @override
  String get login => 'ANMELDEN';

  @override
  String get logout => 'Abmelden';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get noAccount => 'Kein Konto?';

  @override
  String get signUp => 'Registrieren';

  @override
  String get settings => 'Einstellungen';

  @override
  String get statistics => 'Statistiken';

  @override
  String get settingsSystem => 'SYSTEMEINSTELLUNGEN';

  @override
  String get cloudSync => 'CLOUD-SYNCHRONISATION';

  @override
  String get userId => 'SYNC-ID';

  @override
  String get userName => 'BENUTZERNAME / UNTERNEHMEN';

  @override
  String get selectedCar => 'AUSGEWÄHLTES AUTO';

  @override
  String get batteryCapacity => 'BATTERIEKAPAZITÄT';

  @override
  String get account => 'KONTO';

  @override
  String get saveAllChanges => 'CONFERMA TUTTE LE MODIFICHE';

  @override
  String get batteryChemistry => 'ZELLENCHEMIE';

  @override
  String get contracts => 'ENERGIEVERTRAGSVERWALTUNG';

  @override
  String get contractDetails => 'KOSTENDETAILS UND TRANSPARENZ';

  @override
  String get yourPlans => 'DEINE TARIFPLÄNE';

  @override
  String get addContract => 'NEUEN VERTRAG HINZUFÜGEN';

  @override
  String get batteryChemistryNmc => 'NMC / NCA';

  @override
  String get batteryChemistryLfp => 'LFP';

  @override
  String get batteryChemistryUnknown => 'UNBEKANNT';

  @override
  String get adviceLfpFull =>
      'LFP-HINWEIS: Täglich zwischen 20-80% halten. Einmal pro Woche auf 100% laden, um das BMS zu kalibrieren.';

  @override
  String get adviceNmcFull =>
      'NMC-HINWEIS: Für den täglichen Gebrauch 80% nicht überschreiten. Nur für lange Fahrten auf 100% laden.';

  @override
  String get adviceGenericFull =>
      'HINWEIS: Wenn du die Chemie nicht kennst, bleibe zwischen 20-80%. Das ist der universelle Sicherheitsbereich für alle Lithium-Batterien.';

  @override
  String get import => 'IMPORTIEREN';

  @override
  String get download => 'HERUNTERLADEN';

  @override
  String get upload => 'HOCHLADEN';

  @override
  String get syncInProgress => 'Synchronisiere...';

  @override
  String get confirmDelete => 'Löschen bestätigen?';

  @override
  String get confirmLogout => 'Abmelden bestätigen?';

  @override
  String get yes => 'JA';

  @override
  String get no => 'NEIN';

  @override
  String get chargingSlowdown => 'Ladeverlangsamung';

  @override
  String get chargingVerySlow => 'Erhebliche Verlangsamung';

  @override
  String get today => 'HEUTE';

  @override
  String get yesterday => 'GESTERN';

  @override
  String get thisMonth => 'DIESEN MONAT';

  @override
  String get total => 'GESAMT';

  @override
  String get average => 'DURCHSCHNITT';

  @override
  String get monthly => 'MONATLICH';

  @override
  String get yearly => 'JÄHRLICH';

  @override
  String get fasciaF1 => 'F1';

  @override
  String get fasciaF2 => 'F2';

  @override
  String get fasciaF3 => 'F3';

  @override
  String get fasciaDistribution => 'ZEITFENSTERVERTEILUNG';

  @override
  String get comingSoon => 'wird in der nächsten Version verfügbar sein';
}
