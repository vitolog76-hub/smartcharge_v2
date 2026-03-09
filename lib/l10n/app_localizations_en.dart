// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Charge';

  @override
  String get home => 'Home';

  @override
  String get totalKwh => 'TOTAL kWh';

  @override
  String get totalCost => 'TOTAL €';

  @override
  String get totalCharges => 'N. CHARGES';

  @override
  String get dailyTrend => 'Daily Trend (kWh)';

  @override
  String get monthlyTrend => 'Monthly Trend (kWh)';

  @override
  String get location => 'LOCATION';

  @override
  String get fascia => 'TIME SLOT';

  @override
  String get generatedOn => 'Generated on';

  @override
  String get month => 'SUMMARY';

  @override
  String get year => 'YEAR SUMMARY';

  @override
  String get exportReport => 'Export Report';

  @override
  String get exportSubtitle => 'Choose the period to include in the PDF';

  @override
  String get currentMonth => 'Current Month';

  @override
  String get currentYear => 'Current Year';

  @override
  String get allHistory => 'All History';

  @override
  String get public => 'Pubblica';

  @override
  String get costEuro => 'Costo';

  @override
  String get hello => 'HELLO';

  @override
  String get contract => 'CONTRACT';

  @override
  String get readyAt => 'READY AT';

  @override
  String get charging => 'CHARGING';

  @override
  String get waiting => 'WAITING';

  @override
  String calculatedOnPower(Object power) {
    return 'Calculated on $power kW';
  }

  @override
  String get batteryIntelligence => '3 - BATTERY INTELLIGENCE';

  @override
  String get nominalValue => 'NOMINAL VALUE';

  @override
  String get userVehicleData => '2 - USER AND VEHICLE DATA';

  @override
  String get languageSection => 'LANGUAGE';

  @override
  String savingsMessage(Object amount) {
    return 'SAVINGS: +$amount€';
  }

  @override
  String extraCostMessage(Object amount) {
    return 'EXTRA COST: $amount€';
  }

  @override
  String get history => 'History';

  @override
  String get energy => 'Energy';

  @override
  String get cost => 'COST';

  @override
  String get kwh => 'kWh';

  @override
  String get euro => '€';

  @override
  String get noCharges => 'No charges';

  @override
  String get start => 'START';

  @override
  String get stop => 'STOP';

  @override
  String get power => 'POWER';

  @override
  String get duration => 'DURATION';

  @override
  String get finalPrice => 'final price';

  @override
  String get initialSoc => 'INITIAL SOC';

  @override
  String get finalSoc => 'FINAL SOC';

  @override
  String get currentSoc => 'CURRENT SOC';

  @override
  String get targetSoc => 'TARGET';

  @override
  String get simulate => 'SIMULATE CHARGING';

  @override
  String get simulateCharging => 'SIMULATE CHARGING';

  @override
  String get addHomeCharge => 'ADD HOME CHARGE';

  @override
  String get addPublicCharge => 'ADD PUBLIC CHARGE';

  @override
  String get addManualCharge => 'Add Manual Charge';

  @override
  String get date => 'Date';

  @override
  String get end => 'End';

  @override
  String get edit => 'EDIT';

  @override
  String get save => 'SAVE';

  @override
  String get cancel => 'CANCEL';

  @override
  String get delete => 'DELETE';

  @override
  String get confirm => 'CONFIRM';

  @override
  String get interrupt => 'INTERRUPT';

  @override
  String get discard => 'DISCARD';

  @override
  String interruptMessage(Object soc) {
    return 'Charge at $soc%. Do you want to save the session to history?';
  }

  @override
  String get close => 'CLOSE';

  @override
  String get batteryCoach => 'BATTERY ANALYSIS';

  @override
  String get batteryCoachLfp => 'LFP BATTERY ANALYSIS';

  @override
  String get batteryCoachNmc => 'NMC BATTERY ANALYSIS';

  @override
  String get batteryCoachGeneric => 'GENERIC ADVICE';

  @override
  String get batteryAdviceEmpty =>
      'Start charging to get advice based on your driving style.';

  @override
  String get batteryAdviceLfp =>
      '⚠️ You haven\'t charged to 100% in over a week. Do it tonight to calibrate the BMS.';

  @override
  String get batteryAdviceLfpGood =>
      '✅ Battery well calibrated. Keep target between 20-80% for the rest of the week.';

  @override
  String get batteryAdviceNmc =>
      '⚠️ You\'ve charged above 80% %d times in the last month. Try to limit it to reduce degradation.';

  @override
  String get batteryAdviceNmcGood =>
      '✅ Great management: you\'re preserving nickel chemistry by limiting peak charges.';

  @override
  String get batteryAdviceGeneric =>
      'Keep charge between 20-80% for optimal longevity.';

  @override
  String get taperingWarning => 'Charging slows down above 80%';

  @override
  String get taperingWarningHigh => 'Charging is very slow above 90%';

  @override
  String get taperingWarning60 =>
      '🔋 Above 80% charging slows down (60% power)';

  @override
  String get taperingWarning20 =>
      '⚡ Above 90% charging is very slow (20% power)';

  @override
  String get taperingSlowdown => 'Charging slowdown';

  @override
  String get taperingSignificant => 'Significant slowdown';

  @override
  String get chargingComplete => '⚡ CHARGING COMPLETE!';

  @override
  String get chargingInfo => 'Charging Info';

  @override
  String get readyBy => 'Ready by';

  @override
  String get startsAt => 'Starts at';

  @override
  String get estimatedCost => 'Estimated cost';

  @override
  String get energyNeeded => 'Energy needed';

  @override
  String get chargingTime => 'Charging time';

  @override
  String get confirmCharging => 'CONFIRM CHARGING';

  @override
  String get selectLocation => 'Select location';

  @override
  String get chargeAdded => 'Charge added successfully';

  @override
  String get chargeDeleted => 'Charge deleted';

  @override
  String get chargeEdited => 'Charge edited';

  @override
  String get login => 'LOGIN';

  @override
  String get logout => 'Logout';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign up';

  @override
  String get settings => 'Settings';

  @override
  String get statistics => 'Statistics';

  @override
  String get settingsSystem => 'SYSTEM SETTINGS';

  @override
  String get cloudSync => 'CLOUD SYNCHRONIZATION';

  @override
  String get userId => 'SYNC ID';

  @override
  String get userName => 'USER NAME / COMPANY';

  @override
  String get selectedCar => 'SELECTED CAR';

  @override
  String get batteryCapacity => 'BATTERY CAPACITY';

  @override
  String get account => 'ACCOUNT';

  @override
  String get saveAllChanges => 'SAVE ALL CHANGES';

  @override
  String get batteryChemistry => 'CELL CHEMISTRY';

  @override
  String get contracts => 'ENERGY CONTRACT MANAGEMENT';

  @override
  String get contractDetails => 'COST DETAILS AND TRANSPARENCY';

  @override
  String get yourPlans => 'YOUR TARIFF PLANS';

  @override
  String get addContract => 'ADD NEW CONTRACT';

  @override
  String get batteryChemistryNmc => 'NMC / NCA';

  @override
  String get batteryChemistryLfp => 'LFP';

  @override
  String get batteryChemistryUnknown => 'UNKNOWN';

  @override
  String get adviceLfpFull =>
      'LFP ADVICE: Keep between 20-80% daily. Charge to 100% once a week to calibrate the BMS.';

  @override
  String get adviceNmcFull =>
      'NMC ADVICE: Avoid exceeding 80% for daily use. Charge to 100% only for long trips.';

  @override
  String get adviceGenericFull =>
      'ADVICE: If you don\'t know the chemistry, stay between 20-80%. It\'s the universal safety range for all lithium batteries.';

  @override
  String get import => 'IMPORT';

  @override
  String get download => 'DOWNLOAD';

  @override
  String get upload => 'UPLOAD';

  @override
  String get syncInProgress => 'Syncing...';

  @override
  String get confirmDelete => 'Confirm deletion?';

  @override
  String get confirmLogout => 'Confirm logout?';

  @override
  String get yes => 'YES';

  @override
  String get no => 'NO';

  @override
  String get chargingSlowdown => 'Charging slowdown';

  @override
  String get chargingVerySlow => 'Significant slowdown';

  @override
  String get today => 'TODAY';

  @override
  String get yesterday => 'YESTERDAY';

  @override
  String get thisMonth => 'THIS MONTH';

  @override
  String get total => 'TOTAL';

  @override
  String get average => 'AVERAGE';

  @override
  String get monthly => 'MONTHLY';

  @override
  String get yearly => 'YEARLY';

  @override
  String get fasciaF1 => 'F1';

  @override
  String get fasciaF2 => 'F2';

  @override
  String get fasciaF3 => 'F3';

  @override
  String get fasciaDistribution => 'TIME SLOT DISTRIBUTION';

  @override
  String get comingSoon => 'will be available in the next release';
}
