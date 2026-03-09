// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Smart Charge';

  @override
  String get home => 'Home';

  @override
  String get totalKwh => 'TOTALE kWh';

  @override
  String get totalCost => 'TOTALE €';

  @override
  String get totalCharges => 'N. RICARICHE';

  @override
  String get dailyTrend => 'Andamento Giornaliero (kWh)';

  @override
  String get monthlyTrend => 'Andamento Mensile (kWh)';

  @override
  String get location => 'LUOGO';

  @override
  String get fascia => 'FASCIA';

  @override
  String get generatedOn => 'Generato il';

  @override
  String get month => 'RIEPILOGO';

  @override
  String get year => 'RIEPILOGO ANNO';

  @override
  String get exportReport => 'Esporta Report';

  @override
  String get exportSubtitle => 'Scegli il periodo da includere nel PDF';

  @override
  String get currentMonth => 'Mese Corrente';

  @override
  String get currentYear => 'Anno Corrente';

  @override
  String get allHistory => 'Tutto lo Storico';

  @override
  String get public => 'Pubblica';

  @override
  String get costEuro => 'Costo';

  @override
  String get hello => 'CIAO';

  @override
  String get contract => 'CONTRATTO';

  @override
  String get readyAt => 'PRONTA ALLE';

  @override
  String get charging => 'IN CARICA';

  @override
  String get waiting => 'IN ATTESA';

  @override
  String calculatedOnPower(Object power) {
    return 'Calcolato su $power kW';
  }

  @override
  String get batteryIntelligence => '3 - INTELLIGENZA BATTERIA';

  @override
  String get nominalValue => 'VALORE NOMINALE';

  @override
  String get userVehicleData => '2 - DATI UTENTE E VEICOLO';

  @override
  String get languageSection => 'LINGUA';

  @override
  String savingsMessage(Object amount) {
    return 'RISPARMIO: +$amount€';
  }

  @override
  String extraCostMessage(Object amount) {
    return 'COSTO EXTRA: $amount€';
  }

  @override
  String get history => 'Cronologia';

  @override
  String get energy => 'Energia';

  @override
  String get cost => 'COSTO';

  @override
  String get kwh => 'kWh';

  @override
  String get euro => '€';

  @override
  String get noCharges => 'Nessuna ricarica';

  @override
  String get start => 'INIZIO';

  @override
  String get stop => 'STOP';

  @override
  String get power => 'POTENZA';

  @override
  String get duration => 'Durata';

  @override
  String get finalPrice => 'finito';

  @override
  String get initialSoc => 'SOC INIZIALE';

  @override
  String get finalSoc => 'SOC FINALE';

  @override
  String get currentSoc => 'SOC ATTUALE';

  @override
  String get targetSoc => 'TARGET';

  @override
  String get simulate => 'SIMULA RICARICA';

  @override
  String get simulateCharging => 'SIMULA RICARICA';

  @override
  String get addHomeCharge => 'INSERISCI RICARICA HOME';

  @override
  String get addPublicCharge => 'INSERISCI RICARICA PUBBLICA';

  @override
  String get addManualCharge => 'Registra Ricarica Manuale';

  @override
  String get date => 'Data';

  @override
  String get end => 'Fine';

  @override
  String get edit => 'MODIFICA';

  @override
  String get save => 'SALVA';

  @override
  String get cancel => 'ANNULLA';

  @override
  String get delete => 'ELIMINA';

  @override
  String get confirm => 'CONFERMA';

  @override
  String get interrupt => 'INTERROMPI';

  @override
  String get discard => 'SCARTA';

  @override
  String interruptMessage(Object soc) {
    return 'Ricarica al $soc%. Vuoi salvare la sessione nello storico?';
  }

  @override
  String get close => 'CHIUDI';

  @override
  String get batteryCoach => 'ANALISI BATTERIA';

  @override
  String get batteryCoachLfp => 'ANALISI BATTERIA LFP';

  @override
  String get batteryCoachNmc => 'ANALISI BATTERIA NMC';

  @override
  String get batteryCoachGeneric => 'CONSIGLIO GENERICO';

  @override
  String get batteryAdviceEmpty =>
      'Inizia a caricare per ricevere consigli basati sul tuo stile di guida.';

  @override
  String get batteryAdviceLfp =>
      '⚠️ Non carichi al 100% da più di una settimana. Fallo stasera per allineare le celle (BMS).';

  @override
  String get batteryAdviceLfpGood =>
      '✅ Batteria ben calibrata. Mantieni il target tra 20-80% per il resto della settimana.';

  @override
  String get batteryAdviceNmc =>
      '⚠️ Hai caricato oltre l\'80% %d volte nell\'ultimo mese. Cerca di limitarlo per ridurre il degrado.';

  @override
  String get batteryAdviceNmcGood =>
      '✅ Ottima gestione: stai preservando la chimica al nichel limitando i picchi di carica.';

  @override
  String get batteryAdviceGeneric =>
      'Mantieni la carica tra 20-80% per una longevità ottimale.';

  @override
  String get taperingWarning => 'Oltre l\'80% la ricarica rallenta';

  @override
  String get taperingWarningHigh => 'Oltre il 90% la ricarica è molto lenta';

  @override
  String get taperingWarning60 =>
      '🔋 Oltre l\'80% la ricarica rallenta (60% della potenza)';

  @override
  String get taperingWarning20 =>
      '⚡ Oltre il 90% la ricarica è molto lenta (20% della potenza)';

  @override
  String get taperingSlowdown => 'Rallentamento della ricarica';

  @override
  String get taperingSignificant => 'Rallentamento significativo';

  @override
  String get chargingComplete => '⚡ RICARICA COMPLETATA!';

  @override
  String get chargingInfo => 'Info Ricarica';

  @override
  String get readyBy => 'Pronto per le';

  @override
  String get startsAt => 'Inizia alle';

  @override
  String get estimatedCost => 'Costo stimato';

  @override
  String get energyNeeded => 'Energia necessaria';

  @override
  String get chargingTime => 'Tempo di ricarica';

  @override
  String get confirmCharging => 'CONFERMA RICARICA';

  @override
  String get selectLocation => 'Seleziona luogo';

  @override
  String get chargeAdded => 'Ricarica aggiunta con successo';

  @override
  String get chargeDeleted => 'Ricarica eliminata';

  @override
  String get chargeEdited => 'Ricarica modificata';

  @override
  String get login => 'ACCEDI';

  @override
  String get logout => 'Esci dall\'account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Password dimenticata?';

  @override
  String get noAccount => 'Non hai un account?';

  @override
  String get signUp => 'Registrati';

  @override
  String get settings => 'Impostazioni';

  @override
  String get statistics => 'Statistiche';

  @override
  String get settingsSystem => 'IMPOSTAZIONI SISTEMA';

  @override
  String get cloudSync => 'SINCRONIZZAZIONE CLOUD';

  @override
  String get userId => 'ID SINCRONIZZAZIONE';

  @override
  String get userName => 'NOME UTENTE / AZIENDA';

  @override
  String get selectedCar => 'AUTO SELEZIONATA';

  @override
  String get batteryCapacity => 'CAPACITÀ BATTERIA';

  @override
  String get account => 'ACCOUNT';

  @override
  String get saveAllChanges => 'CONFERMA TUTTE LE MODIFICHE';

  @override
  String get batteryChemistry => 'CHIMICA DELLE CELLE';

  @override
  String get contracts => 'GESTIONE CONTRATTI ENERGIA';

  @override
  String get contractDetails => 'DETTAGLI E TRASPARENZA COSTI';

  @override
  String get yourPlans => 'I TUOI PIANI TARIFFARI';

  @override
  String get addContract => 'AGGIUNGI NUOVO CONTRATTO';

  @override
  String get batteryChemistryNmc => 'NMC / NCA';

  @override
  String get batteryChemistryLfp => 'LFP';

  @override
  String get batteryChemistryUnknown => 'SCONOSCIUTA';

  @override
  String get adviceLfpFull =>
      'CONSIGLIO LFP: Mantieni tra 20-80% quotidianamente. Carica al 100% una volta a settimana per calibrare il BMS.';

  @override
  String get adviceNmcFull =>
      'CONSIGLIO NMC: Evita di superare l\'80% per l\'uso quotidiano. Carica al 100% solo per lunghi viaggi.';

  @override
  String get adviceGenericFull =>
      'CONSIGLIO: Se non conosci la chimica, resta tra il 20% e l\'80%. È la fascia di sicurezza universale per ogni batteria al litio.';

  @override
  String get import => 'IMPORTA';

  @override
  String get download => 'SCARICA';

  @override
  String get upload => 'CARICA';

  @override
  String get syncInProgress => 'Sincronizzazione in corso...';

  @override
  String get confirmDelete => 'Confermi eliminazione?';

  @override
  String get confirmLogout => 'Confermi logout?';

  @override
  String get yes => 'SÌ';

  @override
  String get no => 'NO';

  @override
  String get chargingSlowdown => 'Rallentamento della ricarica';

  @override
  String get chargingVerySlow => 'Rallentamento significativo';

  @override
  String get today => 'OGGI';

  @override
  String get yesterday => 'IERI';

  @override
  String get thisMonth => 'QUESTO MESE';

  @override
  String get total => 'TOTALE';

  @override
  String get average => 'MEDIA';

  @override
  String get monthly => 'MENSILE';

  @override
  String get yearly => 'ANNUALE';

  @override
  String get fasciaF1 => 'F1';

  @override
  String get fasciaF2 => 'F2';

  @override
  String get fasciaF3 => 'F3';

  @override
  String get fasciaDistribution => 'DISTRIBUZIONE FASCE ORARIE';

  @override
  String get comingSoon => 'sarà disponibile nella prossima release';
}
