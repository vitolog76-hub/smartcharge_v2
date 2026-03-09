import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In it, this message translates to:
  /// **'Smart Charge'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In it, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @totalKwh.
  ///
  /// In it, this message translates to:
  /// **'TOTALE kWh'**
  String get totalKwh;

  /// No description provided for @totalCost.
  ///
  /// In it, this message translates to:
  /// **'TOTALE €'**
  String get totalCost;

  /// No description provided for @totalCharges.
  ///
  /// In it, this message translates to:
  /// **'N. RICARICHE'**
  String get totalCharges;

  /// No description provided for @dailyTrend.
  ///
  /// In it, this message translates to:
  /// **'Andamento Giornaliero (kWh)'**
  String get dailyTrend;

  /// No description provided for @monthlyTrend.
  ///
  /// In it, this message translates to:
  /// **'Andamento Mensile (kWh)'**
  String get monthlyTrend;

  /// No description provided for @location.
  ///
  /// In it, this message translates to:
  /// **'LUOGO'**
  String get location;

  /// No description provided for @fascia.
  ///
  /// In it, this message translates to:
  /// **'FASCIA'**
  String get fascia;

  /// No description provided for @generatedOn.
  ///
  /// In it, this message translates to:
  /// **'Generato il'**
  String get generatedOn;

  /// No description provided for @month.
  ///
  /// In it, this message translates to:
  /// **'RIEPILOGO'**
  String get month;

  /// No description provided for @year.
  ///
  /// In it, this message translates to:
  /// **'RIEPILOGO ANNO'**
  String get year;

  /// No description provided for @exportReport.
  ///
  /// In it, this message translates to:
  /// **'Esporta Report'**
  String get exportReport;

  /// No description provided for @exportSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Scegli il periodo da includere nel PDF'**
  String get exportSubtitle;

  /// No description provided for @currentMonth.
  ///
  /// In it, this message translates to:
  /// **'Mese Corrente'**
  String get currentMonth;

  /// No description provided for @currentYear.
  ///
  /// In it, this message translates to:
  /// **'Anno Corrente'**
  String get currentYear;

  /// No description provided for @allHistory.
  ///
  /// In it, this message translates to:
  /// **'Tutto lo Storico'**
  String get allHistory;

  /// No description provided for @public.
  ///
  /// In it, this message translates to:
  /// **'Pubblica'**
  String get public;

  /// No description provided for @costEuro.
  ///
  /// In it, this message translates to:
  /// **'Costo'**
  String get costEuro;

  /// No description provided for @hello.
  ///
  /// In it, this message translates to:
  /// **'CIAO'**
  String get hello;

  /// No description provided for @contract.
  ///
  /// In it, this message translates to:
  /// **'CONTRATTO'**
  String get contract;

  /// No description provided for @readyAt.
  ///
  /// In it, this message translates to:
  /// **'PRONTA ALLE'**
  String get readyAt;

  /// No description provided for @charging.
  ///
  /// In it, this message translates to:
  /// **'IN CARICA'**
  String get charging;

  /// No description provided for @waiting.
  ///
  /// In it, this message translates to:
  /// **'IN ATTESA'**
  String get waiting;

  /// No description provided for @calculatedOnPower.
  ///
  /// In it, this message translates to:
  /// **'Calcolato su {power} kW'**
  String calculatedOnPower(Object power);

  /// No description provided for @batteryIntelligence.
  ///
  /// In it, this message translates to:
  /// **'3 - INTELLIGENZA BATTERIA'**
  String get batteryIntelligence;

  /// No description provided for @nominalValue.
  ///
  /// In it, this message translates to:
  /// **'VALORE NOMINALE'**
  String get nominalValue;

  /// No description provided for @userVehicleData.
  ///
  /// In it, this message translates to:
  /// **'2 - DATI UTENTE E VEICOLO'**
  String get userVehicleData;

  /// No description provided for @languageSection.
  ///
  /// In it, this message translates to:
  /// **'LINGUA'**
  String get languageSection;

  /// No description provided for @savingsMessage.
  ///
  /// In it, this message translates to:
  /// **'RISPARMIO: +{amount}€'**
  String savingsMessage(Object amount);

  /// No description provided for @extraCostMessage.
  ///
  /// In it, this message translates to:
  /// **'COSTO EXTRA: {amount}€'**
  String extraCostMessage(Object amount);

  /// No description provided for @history.
  ///
  /// In it, this message translates to:
  /// **'Cronologia'**
  String get history;

  /// No description provided for @energy.
  ///
  /// In it, this message translates to:
  /// **'Energia'**
  String get energy;

  /// No description provided for @cost.
  ///
  /// In it, this message translates to:
  /// **'COSTO'**
  String get cost;

  /// No description provided for @kwh.
  ///
  /// In it, this message translates to:
  /// **'kWh'**
  String get kwh;

  /// No description provided for @euro.
  ///
  /// In it, this message translates to:
  /// **'€'**
  String get euro;

  /// No description provided for @noCharges.
  ///
  /// In it, this message translates to:
  /// **'Nessuna ricarica'**
  String get noCharges;

  /// No description provided for @start.
  ///
  /// In it, this message translates to:
  /// **'INIZIO'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In it, this message translates to:
  /// **'STOP'**
  String get stop;

  /// No description provided for @power.
  ///
  /// In it, this message translates to:
  /// **'POTENZA'**
  String get power;

  /// No description provided for @duration.
  ///
  /// In it, this message translates to:
  /// **'Durata'**
  String get duration;

  /// No description provided for @finalPrice.
  ///
  /// In it, this message translates to:
  /// **'finito'**
  String get finalPrice;

  /// No description provided for @initialSoc.
  ///
  /// In it, this message translates to:
  /// **'SOC INIZIALE'**
  String get initialSoc;

  /// No description provided for @finalSoc.
  ///
  /// In it, this message translates to:
  /// **'SOC FINALE'**
  String get finalSoc;

  /// No description provided for @currentSoc.
  ///
  /// In it, this message translates to:
  /// **'SOC ATTUALE'**
  String get currentSoc;

  /// No description provided for @targetSoc.
  ///
  /// In it, this message translates to:
  /// **'TARGET'**
  String get targetSoc;

  /// No description provided for @simulate.
  ///
  /// In it, this message translates to:
  /// **'SIMULA RICARICA'**
  String get simulate;

  /// No description provided for @simulateCharging.
  ///
  /// In it, this message translates to:
  /// **'SIMULA RICARICA'**
  String get simulateCharging;

  /// No description provided for @addHomeCharge.
  ///
  /// In it, this message translates to:
  /// **'INSERISCI RICARICA HOME'**
  String get addHomeCharge;

  /// No description provided for @addPublicCharge.
  ///
  /// In it, this message translates to:
  /// **'INSERISCI RICARICA PUBBLICA'**
  String get addPublicCharge;

  /// No description provided for @addManualCharge.
  ///
  /// In it, this message translates to:
  /// **'Registra Ricarica Manuale'**
  String get addManualCharge;

  /// No description provided for @date.
  ///
  /// In it, this message translates to:
  /// **'Data'**
  String get date;

  /// No description provided for @end.
  ///
  /// In it, this message translates to:
  /// **'Fine'**
  String get end;

  /// No description provided for @edit.
  ///
  /// In it, this message translates to:
  /// **'MODIFICA'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In it, this message translates to:
  /// **'SALVA'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In it, this message translates to:
  /// **'ANNULLA'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In it, this message translates to:
  /// **'ELIMINA'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In it, this message translates to:
  /// **'CONFERMA'**
  String get confirm;

  /// No description provided for @interrupt.
  ///
  /// In it, this message translates to:
  /// **'INTERROMPI'**
  String get interrupt;

  /// No description provided for @discard.
  ///
  /// In it, this message translates to:
  /// **'SCARTA'**
  String get discard;

  /// No description provided for @interruptMessage.
  ///
  /// In it, this message translates to:
  /// **'Ricarica al {soc}%. Vuoi salvare la sessione nello storico?'**
  String interruptMessage(Object soc);

  /// No description provided for @close.
  ///
  /// In it, this message translates to:
  /// **'CHIUDI'**
  String get close;

  /// No description provided for @batteryCoach.
  ///
  /// In it, this message translates to:
  /// **'ANALISI BATTERIA'**
  String get batteryCoach;

  /// No description provided for @batteryCoachLfp.
  ///
  /// In it, this message translates to:
  /// **'ANALISI BATTERIA LFP'**
  String get batteryCoachLfp;

  /// No description provided for @batteryCoachNmc.
  ///
  /// In it, this message translates to:
  /// **'ANALISI BATTERIA NMC'**
  String get batteryCoachNmc;

  /// No description provided for @batteryCoachGeneric.
  ///
  /// In it, this message translates to:
  /// **'CONSIGLIO GENERICO'**
  String get batteryCoachGeneric;

  /// No description provided for @batteryAdviceEmpty.
  ///
  /// In it, this message translates to:
  /// **'Inizia a caricare per ricevere consigli basati sul tuo stile di guida.'**
  String get batteryAdviceEmpty;

  /// No description provided for @batteryAdviceLfp.
  ///
  /// In it, this message translates to:
  /// **'⚠️ Non carichi al 100% da più di una settimana. Fallo stasera per allineare le celle (BMS).'**
  String get batteryAdviceLfp;

  /// No description provided for @batteryAdviceLfpGood.
  ///
  /// In it, this message translates to:
  /// **'✅ Batteria ben calibrata. Mantieni il target tra 20-80% per il resto della settimana.'**
  String get batteryAdviceLfpGood;

  /// No description provided for @batteryAdviceNmc.
  ///
  /// In it, this message translates to:
  /// **'⚠️ Hai caricato oltre l\'80% %d volte nell\'ultimo mese. Cerca di limitarlo per ridurre il degrado.'**
  String get batteryAdviceNmc;

  /// No description provided for @batteryAdviceNmcGood.
  ///
  /// In it, this message translates to:
  /// **'✅ Ottima gestione: stai preservando la chimica al nichel limitando i picchi di carica.'**
  String get batteryAdviceNmcGood;

  /// No description provided for @batteryAdviceGeneric.
  ///
  /// In it, this message translates to:
  /// **'Mantieni la carica tra 20-80% per una longevità ottimale.'**
  String get batteryAdviceGeneric;

  /// No description provided for @taperingWarning.
  ///
  /// In it, this message translates to:
  /// **'Oltre l\'80% la ricarica rallenta'**
  String get taperingWarning;

  /// No description provided for @taperingWarningHigh.
  ///
  /// In it, this message translates to:
  /// **'Oltre il 90% la ricarica è molto lenta'**
  String get taperingWarningHigh;

  /// No description provided for @taperingWarning60.
  ///
  /// In it, this message translates to:
  /// **'🔋 Oltre l\'80% la ricarica rallenta (60% della potenza)'**
  String get taperingWarning60;

  /// No description provided for @taperingWarning20.
  ///
  /// In it, this message translates to:
  /// **'⚡ Oltre il 90% la ricarica è molto lenta (20% della potenza)'**
  String get taperingWarning20;

  /// No description provided for @taperingSlowdown.
  ///
  /// In it, this message translates to:
  /// **'Rallentamento della ricarica'**
  String get taperingSlowdown;

  /// No description provided for @taperingSignificant.
  ///
  /// In it, this message translates to:
  /// **'Rallentamento significativo'**
  String get taperingSignificant;

  /// No description provided for @chargingComplete.
  ///
  /// In it, this message translates to:
  /// **'⚡ RICARICA COMPLETATA!'**
  String get chargingComplete;

  /// No description provided for @chargingInfo.
  ///
  /// In it, this message translates to:
  /// **'Info Ricarica'**
  String get chargingInfo;

  /// No description provided for @readyBy.
  ///
  /// In it, this message translates to:
  /// **'Pronto per le'**
  String get readyBy;

  /// No description provided for @startsAt.
  ///
  /// In it, this message translates to:
  /// **'Inizia alle'**
  String get startsAt;

  /// No description provided for @estimatedCost.
  ///
  /// In it, this message translates to:
  /// **'Costo stimato'**
  String get estimatedCost;

  /// No description provided for @energyNeeded.
  ///
  /// In it, this message translates to:
  /// **'Energia necessaria'**
  String get energyNeeded;

  /// No description provided for @chargingTime.
  ///
  /// In it, this message translates to:
  /// **'Tempo di ricarica'**
  String get chargingTime;

  /// No description provided for @confirmCharging.
  ///
  /// In it, this message translates to:
  /// **'CONFERMA RICARICA'**
  String get confirmCharging;

  /// No description provided for @selectLocation.
  ///
  /// In it, this message translates to:
  /// **'Seleziona luogo'**
  String get selectLocation;

  /// No description provided for @chargeAdded.
  ///
  /// In it, this message translates to:
  /// **'Ricarica aggiunta con successo'**
  String get chargeAdded;

  /// No description provided for @chargeDeleted.
  ///
  /// In it, this message translates to:
  /// **'Ricarica eliminata'**
  String get chargeDeleted;

  /// No description provided for @chargeEdited.
  ///
  /// In it, this message translates to:
  /// **'Ricarica modificata'**
  String get chargeEdited;

  /// No description provided for @login.
  ///
  /// In it, this message translates to:
  /// **'ACCEDI'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In it, this message translates to:
  /// **'Esci dall\'account'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In it, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In it, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In it, this message translates to:
  /// **'Password dimenticata?'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In it, this message translates to:
  /// **'Non hai un account?'**
  String get noAccount;

  /// No description provided for @signUp.
  ///
  /// In it, this message translates to:
  /// **'Registrati'**
  String get signUp;

  /// No description provided for @settings.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get settings;

  /// No description provided for @statistics.
  ///
  /// In it, this message translates to:
  /// **'Statistiche'**
  String get statistics;

  /// No description provided for @settingsSystem.
  ///
  /// In it, this message translates to:
  /// **'IMPOSTAZIONI SISTEMA'**
  String get settingsSystem;

  /// No description provided for @cloudSync.
  ///
  /// In it, this message translates to:
  /// **'SINCRONIZZAZIONE CLOUD'**
  String get cloudSync;

  /// No description provided for @userId.
  ///
  /// In it, this message translates to:
  /// **'ID SINCRONIZZAZIONE'**
  String get userId;

  /// No description provided for @userName.
  ///
  /// In it, this message translates to:
  /// **'NOME UTENTE / AZIENDA'**
  String get userName;

  /// No description provided for @selectedCar.
  ///
  /// In it, this message translates to:
  /// **'AUTO SELEZIONATA'**
  String get selectedCar;

  /// No description provided for @batteryCapacity.
  ///
  /// In it, this message translates to:
  /// **'CAPACITÀ BATTERIA'**
  String get batteryCapacity;

  /// No description provided for @account.
  ///
  /// In it, this message translates to:
  /// **'ACCOUNT'**
  String get account;

  /// No description provided for @saveAllChanges.
  ///
  /// In it, this message translates to:
  /// **'CONFERMA TUTTE LE MODIFICHE'**
  String get saveAllChanges;

  /// No description provided for @batteryChemistry.
  ///
  /// In it, this message translates to:
  /// **'CHIMICA DELLE CELLE'**
  String get batteryChemistry;

  /// No description provided for @contracts.
  ///
  /// In it, this message translates to:
  /// **'GESTIONE CONTRATTI ENERGIA'**
  String get contracts;

  /// No description provided for @contractDetails.
  ///
  /// In it, this message translates to:
  /// **'DETTAGLI E TRASPARENZA COSTI'**
  String get contractDetails;

  /// No description provided for @yourPlans.
  ///
  /// In it, this message translates to:
  /// **'I TUOI PIANI TARIFFARI'**
  String get yourPlans;

  /// No description provided for @addContract.
  ///
  /// In it, this message translates to:
  /// **'AGGIUNGI NUOVO CONTRATTO'**
  String get addContract;

  /// No description provided for @batteryChemistryNmc.
  ///
  /// In it, this message translates to:
  /// **'NMC / NCA'**
  String get batteryChemistryNmc;

  /// No description provided for @batteryChemistryLfp.
  ///
  /// In it, this message translates to:
  /// **'LFP'**
  String get batteryChemistryLfp;

  /// No description provided for @batteryChemistryUnknown.
  ///
  /// In it, this message translates to:
  /// **'SCONOSCIUTA'**
  String get batteryChemistryUnknown;

  /// No description provided for @adviceLfpFull.
  ///
  /// In it, this message translates to:
  /// **'CONSIGLIO LFP: Mantieni tra 20-80% quotidianamente. Carica al 100% una volta a settimana per calibrare il BMS.'**
  String get adviceLfpFull;

  /// No description provided for @adviceNmcFull.
  ///
  /// In it, this message translates to:
  /// **'CONSIGLIO NMC: Evita di superare l\'80% per l\'uso quotidiano. Carica al 100% solo per lunghi viaggi.'**
  String get adviceNmcFull;

  /// No description provided for @adviceGenericFull.
  ///
  /// In it, this message translates to:
  /// **'CONSIGLIO: Se non conosci la chimica, resta tra il 20% e l\'80%. È la fascia di sicurezza universale per ogni batteria al litio.'**
  String get adviceGenericFull;

  /// No description provided for @import.
  ///
  /// In it, this message translates to:
  /// **'IMPORTA'**
  String get import;

  /// No description provided for @download.
  ///
  /// In it, this message translates to:
  /// **'SCARICA'**
  String get download;

  /// No description provided for @upload.
  ///
  /// In it, this message translates to:
  /// **'CARICA'**
  String get upload;

  /// No description provided for @syncInProgress.
  ///
  /// In it, this message translates to:
  /// **'Sincronizzazione in corso...'**
  String get syncInProgress;

  /// No description provided for @confirmDelete.
  ///
  /// In it, this message translates to:
  /// **'Confermi eliminazione?'**
  String get confirmDelete;

  /// No description provided for @confirmLogout.
  ///
  /// In it, this message translates to:
  /// **'Confermi logout?'**
  String get confirmLogout;

  /// No description provided for @yes.
  ///
  /// In it, this message translates to:
  /// **'SÌ'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In it, this message translates to:
  /// **'NO'**
  String get no;

  /// No description provided for @chargingSlowdown.
  ///
  /// In it, this message translates to:
  /// **'Rallentamento della ricarica'**
  String get chargingSlowdown;

  /// No description provided for @chargingVerySlow.
  ///
  /// In it, this message translates to:
  /// **'Rallentamento significativo'**
  String get chargingVerySlow;

  /// No description provided for @today.
  ///
  /// In it, this message translates to:
  /// **'OGGI'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In it, this message translates to:
  /// **'IERI'**
  String get yesterday;

  /// No description provided for @thisMonth.
  ///
  /// In it, this message translates to:
  /// **'QUESTO MESE'**
  String get thisMonth;

  /// No description provided for @total.
  ///
  /// In it, this message translates to:
  /// **'TOTALE'**
  String get total;

  /// No description provided for @average.
  ///
  /// In it, this message translates to:
  /// **'MEDIA'**
  String get average;

  /// No description provided for @monthly.
  ///
  /// In it, this message translates to:
  /// **'MENSILE'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In it, this message translates to:
  /// **'ANNUALE'**
  String get yearly;

  /// No description provided for @fasciaF1.
  ///
  /// In it, this message translates to:
  /// **'F1'**
  String get fasciaF1;

  /// No description provided for @fasciaF2.
  ///
  /// In it, this message translates to:
  /// **'F2'**
  String get fasciaF2;

  /// No description provided for @fasciaF3.
  ///
  /// In it, this message translates to:
  /// **'F3'**
  String get fasciaF3;

  /// No description provided for @fasciaDistribution.
  ///
  /// In it, this message translates to:
  /// **'DISTRIBUZIONE FASCE ORARIE'**
  String get fasciaDistribution;

  /// No description provided for @comingSoon.
  ///
  /// In it, this message translates to:
  /// **'sarà disponibile nella prossima release'**
  String get comingSoon;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
