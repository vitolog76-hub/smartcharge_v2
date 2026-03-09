// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Smart Charge';

  @override
  String get home => 'Domicile';

  @override
  String get totalKwh => 'TOTAL kWh';

  @override
  String get totalCost => 'TOTAL €';

  @override
  String get totalCharges => 'N. CHARGES';

  @override
  String get dailyTrend => 'Tendance Journalière (kWh)';

  @override
  String get monthlyTrend => 'Tendance Mensuelle (kWh)';

  @override
  String get location => 'LIEU';

  @override
  String get fascia => 'TRANCHE';

  @override
  String get generatedOn => 'Généré le';

  @override
  String get month => 'RÉSUMÉ';

  @override
  String get year => 'RÉSUMÉ ANNUEL';

  @override
  String get exportReport => 'Exporter le Rapport';

  @override
  String get exportSubtitle => 'Choisissez la période à inclure dans le PDF';

  @override
  String get currentMonth => 'Mois en Cours';

  @override
  String get currentYear => 'Année en Cours';

  @override
  String get allHistory => 'Tout l\'Historique';

  @override
  String get public => 'Public';

  @override
  String get costEuro => 'Coût';

  @override
  String get hello => 'BONJOUR';

  @override
  String get contract => 'CONTRAT';

  @override
  String get readyAt => 'PRÊT À';

  @override
  String get charging => 'EN CHARGE';

  @override
  String get waiting => 'EN ATTENTE';

  @override
  String calculatedOnPower(Object power) {
    return 'Calculé sur $power kW';
  }

  @override
  String get batteryIntelligence => '3 - INTELLIGENCE BATTERIE';

  @override
  String get nominalValue => 'VALEUR NOMINALE';

  @override
  String get userVehicleData => '2 - DONNÉES UTILISATEUR ET VÉHICULE';

  @override
  String get languageSection => 'LANGUE';

  @override
  String savingsMessage(Object amount) {
    return 'ÉCONOMIE : +$amount€';
  }

  @override
  String extraCostMessage(Object amount) {
    return 'COÛT SUPPLÉMENTAIRE : $amount€';
  }

  @override
  String get history => 'HISTORIQUE DES CHARGES';

  @override
  String get energy => 'ÉNERGIE';

  @override
  String get cost => 'DÉPENSE';

  @override
  String get kwh => 'kWh';

  @override
  String get euro => '€';

  @override
  String get noCharges => 'Aucune charge';

  @override
  String get start => 'DÉBUT';

  @override
  String get stop => 'ARRÊT';

  @override
  String get power => 'PUISSANCE';

  @override
  String get duration => 'Durée';

  @override
  String get finalPrice => 'final';

  @override
  String get initialSoc => 'SOC INITIAL';

  @override
  String get finalSoc => 'SOC FINAL';

  @override
  String get currentSoc => 'SOC ACTUEL';

  @override
  String get targetSoc => 'CIBLE';

  @override
  String get simulate => 'SIMULER CHARGE';

  @override
  String get simulateCharging => 'SIMULER CHARGE';

  @override
  String get addHomeCharge => 'AJOUTER CHARGE DOMICILE';

  @override
  String get addPublicCharge => 'AJOUTER CHARGE PUBLIQUE';

  @override
  String get addManualCharge => 'Ajouter Charge Manuelle';

  @override
  String get date => 'Date';

  @override
  String get end => 'Fin';

  @override
  String get edit => 'MODIFIER';

  @override
  String get save => 'ENREGISTRER';

  @override
  String get cancel => 'ANNULER';

  @override
  String get delete => 'SUPPRIMER';

  @override
  String get confirm => 'CONFIRMER';

  @override
  String get interrupt => 'INTERROMPRE';

  @override
  String get discard => 'IGNORER';

  @override
  String interruptMessage(Object soc) {
    return 'Charge à $soc%. Voulez-vous enregistrer la session dans l\'historique ?';
  }

  @override
  String get close => 'FERMER';

  @override
  String get batteryCoach => 'ANALYSE BATTERIE';

  @override
  String get batteryCoachLfp => 'ANALYSE BATTERIE LFP';

  @override
  String get batteryCoachNmc => 'ANALYSE BATTERIE NMC';

  @override
  String get batteryCoachGeneric => 'CONSEIL GÉNÉRIQUE';

  @override
  String get batteryAdviceEmpty =>
      'Commencez à charger pour recevoir des conseils basés sur votre style de conduite.';

  @override
  String get batteryAdviceLfp =>
      '⚠️ Vous n\'avez pas chargé à 100% depuis plus d\'une semaine. Faites-le ce soir pour aligner les cellules (BMS).';

  @override
  String get batteryAdviceLfpGood =>
      '✅ Batterie bien calibrée. Maintenez l\'objectif entre 20-80% pour le reste de la semaine.';

  @override
  String get batteryAdviceNmc =>
      '⚠️ Vous avez chargé au-dessus de 80% %d fois le mois dernier. Essayez de limiter pour réduire la dégradation.';

  @override
  String get batteryAdviceNmcGood =>
      '✅ Excellente gestion : vous préservez la chimie au nickel en limitant les pics de charge.';

  @override
  String get batteryAdviceGeneric =>
      'Maintenez la charge entre 20-80% pour une longévité optimale.';

  @override
  String get taperingWarning => 'Au-dessus de 80%, la charge ralentit';

  @override
  String get taperingWarningHigh =>
      'Au-dessus de 90%, la charge est très lente';

  @override
  String get taperingWarning60 =>
      '🔋 Au-dessus de 80%, la charge ralentit (60% de puissance)';

  @override
  String get taperingWarning20 =>
      '⚡ Au-dessus de 90%, la charge est très lente (20% de puissance)';

  @override
  String get taperingSlowdown => 'Ralentissement de la charge';

  @override
  String get taperingSignificant => 'Ralentissement significatif';

  @override
  String get chargingComplete => '⚡ CHARGE TERMINÉE !';

  @override
  String get chargingInfo => 'Infos Charge';

  @override
  String get readyBy => 'Prêt pour';

  @override
  String get startsAt => 'Commence à';

  @override
  String get estimatedCost => 'Coût estimé';

  @override
  String get energyNeeded => 'Énergie nécessaire';

  @override
  String get chargingTime => 'Temps de charge';

  @override
  String get confirmCharging => 'CONFIRMER CHARGE';

  @override
  String get selectLocation => 'Sélectionner lieu';

  @override
  String get chargeAdded => 'Charge ajoutée avec succès';

  @override
  String get chargeDeleted => 'Charge supprimée';

  @override
  String get chargeEdited => 'Charge modifiée';

  @override
  String get login => 'CONNEXION';

  @override
  String get logout => 'Déconnexion';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get noAccount => 'Pas de compte ?';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get settings => 'Paramètres';

  @override
  String get statistics => 'Statistiques';

  @override
  String get settingsSystem => 'PARAMÈTRES SYSTÈME';

  @override
  String get cloudSync => 'SYNCHRONISATION CLOUD';

  @override
  String get userId => 'ID DE SYNCHRONISATION';

  @override
  String get userName => 'NOM UTILISATEUR / ENTREPRISE';

  @override
  String get selectedCar => 'VOITURE SÉLECTIONNÉE';

  @override
  String get batteryCapacity => 'CAPACITÉ BATTERIE';

  @override
  String get account => 'COMPTE';

  @override
  String get saveAllChanges => 'CONFERMA TUTTE LE MODIFICHE';

  @override
  String get batteryChemistry => 'CHIMIE DES CELLULES';

  @override
  String get contracts => 'GESTION CONTRATS ÉNERGIE';

  @override
  String get contractDetails => 'DÉTAILS ET TRANSPARENCE DES COÛTS';

  @override
  String get yourPlans => 'VOS PLANS TARIFAIRES';

  @override
  String get addContract => 'AJOUTER NOUVEAU CONTRAT';

  @override
  String get batteryChemistryNmc => 'NMC / NCA';

  @override
  String get batteryChemistryLfp => 'LFP';

  @override
  String get batteryChemistryUnknown => 'INCONNUE';

  @override
  String get adviceLfpFull =>
      'CONSEIL LFP : Maintenez entre 20-80% quotidiennement. Chargez à 100% une fois par semaine pour calibrer le BMS.';

  @override
  String get adviceNmcFull =>
      'CONSEIL NMC : Évitez de dépasser 80% pour l\'usage quotidien. Chargez à 100% uniquement pour les longs trajets.';

  @override
  String get adviceGenericFull =>
      'CONSEIL : Si vous ne connaissez pas la chimie, restez entre 20-80%. C\'est la plage de sécurité universelle pour toutes les batteries lithium.';

  @override
  String get import => 'IMPORTER';

  @override
  String get download => 'TÉLÉCHARGER';

  @override
  String get upload => 'ENVOYER';

  @override
  String get syncInProgress => 'Synchronisation...';

  @override
  String get confirmDelete => 'Confirmer la suppression ?';

  @override
  String get confirmLogout => 'Confirmer la déconnexion ?';

  @override
  String get yes => 'OUI';

  @override
  String get no => 'NON';

  @override
  String get chargingSlowdown => 'Ralentissement de la charge';

  @override
  String get chargingVerySlow => 'Ralentissement significatif';

  @override
  String get today => 'AUJOURD\'HUI';

  @override
  String get yesterday => 'HIER';

  @override
  String get thisMonth => 'CE MOIS';

  @override
  String get total => 'TOTAL';

  @override
  String get average => 'MOYENNE';

  @override
  String get monthly => 'MENSUEL';

  @override
  String get yearly => 'ANNUEL';

  @override
  String get fasciaF1 => 'F1';

  @override
  String get fasciaF2 => 'F2';

  @override
  String get fasciaF3 => 'F3';

  @override
  String get fasciaDistribution => 'DISTRIBUTION DES TRANCHES HORAIRES';

  @override
  String get comingSoon => 'sera disponible dans la prochaine version';
}
