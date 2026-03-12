// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'OriGO';

  @override
  String get home => 'Hogar';

  @override
  String get batteryRange => 'RANGO SOC';

  @override
  String get totalKwh => 'TOTAL kWh';

  @override
  String get totalCost => 'TOTAL €';

  @override
  String get totalCharges => 'N. CARGAS';

  @override
  String get dailyTrend => 'Tendencia Diaria (kWh)';

  @override
  String get monthlyTrend => 'Tendencia Mensual (kWh)';

  @override
  String get location => 'LUGAR';

  @override
  String get fascia => 'FRANJA';

  @override
  String get generatedOn => 'Generado el';

  @override
  String get month => 'RESUMEN';

  @override
  String get year => 'RESUMEN ANUAL';

  @override
  String get exportReport => 'Exportar Informe';

  @override
  String get exportSubtitle => 'Elige el período a incluir en el PDF';

  @override
  String get currentMonth => 'Mes Actual';

  @override
  String get currentYear => 'Año Actual';

  @override
  String get allHistory => 'Todo el Historial';

  @override
  String get public => 'Público';

  @override
  String get costEuro => 'Coste';

  @override
  String get hello => 'HOLA';

  @override
  String get contract => 'CONTRATO';

  @override
  String get readyAt => 'LISTO A LAS';

  @override
  String get charging => 'CARGANDO';

  @override
  String get waiting => 'ESPERANDO';

  @override
  String calculatedOnPower(Object power) {
    return 'Calculado sobre $power kW';
  }

  @override
  String get batteryIntelligence => '3 - INTELIGENCIA BATERÍA';

  @override
  String get nominalValue => 'VALOR NOMINAL';

  @override
  String get userVehicleData => '2 - DATOS USUARIO Y VEHÍCULO';

  @override
  String get languageSection => 'IDIOMA';

  @override
  String savingsMessage(Object amount) {
    return 'AHORRO: +$amount€';
  }

  @override
  String extraCostMessage(Object amount) {
    return 'COSTE EXTRA: $amount€';
  }

  @override
  String get history => 'HISTORIAL DE CARGAS';

  @override
  String get energy => 'ENERGÍA';

  @override
  String get cost => 'GASTO';

  @override
  String get kwh => 'kWh';

  @override
  String get euro => '€';

  @override
  String get noCharges => 'Sin cargas';

  @override
  String get start => 'INICIO';

  @override
  String get stop => 'PARAR';

  @override
  String get power => 'POTENCIA';

  @override
  String get duration => 'Duración';

  @override
  String get finalPrice => 'final';

  @override
  String get initialSoc => 'SOC INICIAL';

  @override
  String get finalSoc => 'SOC FINAL';

  @override
  String get currentSoc => 'SOC ACTUAL';

  @override
  String get targetSoc => 'OBJETIVO';

  @override
  String get simulate => 'SIMULAR CARGA';

  @override
  String get simulateCharging => 'SIMULAR CARGA';

  @override
  String get addHomeCharge => 'AÑADIR CARGA DOMÉSTICA';

  @override
  String get addPublicCharge => 'AÑADIR CARGA PÚBLICA';

  @override
  String get addManualCharge => 'Añadir Carga Manual';

  @override
  String get date => 'Fecha';

  @override
  String get end => 'Fin';

  @override
  String get edit => 'EDITAR';

  @override
  String get save => 'GUARDAR';

  @override
  String get cancel => 'CANCELAR';

  @override
  String get delete => 'ELIMINAR';

  @override
  String get confirm => 'CONFIRMAR';

  @override
  String get interrupt => 'INTERRUMPIR';

  @override
  String get discard => 'DESCARTAR';

  @override
  String interruptMessage(Object soc) {
    return 'Carga al $soc%. ¿Quieres guardar la sesión en el historial?';
  }

  @override
  String get close => 'CERRAR';

  @override
  String get batteryCoach => 'ANÁLISIS BATERÍA';

  @override
  String get batteryCoachLfp => 'ANÁLISIS BATERÍA LFP';

  @override
  String get batteryCoachNmc => 'ANÁLISIS BATERÍA NMC';

  @override
  String get batteryCoachGeneric => 'CONSEJO GENÉRICO';

  @override
  String get batteryAdviceEmpty =>
      'Empieza a cargar para recibir consejos basados en tu estilo de conducción.';

  @override
  String get batteryAdviceLfp =>
      '⚠️ No has cargado al 100% en más de una semana. Hazlo esta noche para alinear las celdas (BMS).';

  @override
  String get batteryAdviceLfpGood =>
      '✅ Batería bien calibrada. Mantén el objetivo entre 20-80% el resto de la semana.';

  @override
  String get batteryAdviceNmc =>
      '⚠️ Has cargado por encima del 80% %d veces en el último mes. Intenta limitarlo para reducir el degrado.';

  @override
  String get batteryAdviceNmcGood =>
      '✅ Excelente gestión: estás preservando la química de níquel limitando los picos de carga.';

  @override
  String get batteryAdviceGeneric =>
      'Mantén la carga entre 20-80% para una longevidad óptima.';

  @override
  String get taperingWarning => 'Por encima del 80% la carga se ralentiza';

  @override
  String get taperingWarningHigh => 'Por encima del 90% la carga es muy lenta';

  @override
  String get taperingWarning60 =>
      '🔋 Por encima del 80% la carga se ralentiza (60% de potencia)';

  @override
  String get taperingWarning20 =>
      '⚡ Por encima del 90% la carga es muy lenta (20% de potencia)';

  @override
  String get taperingSlowdown => 'Ralentización de la carga';

  @override
  String get taperingSignificant => 'Ralentización significativa';

  @override
  String get chargingComplete => '⚡ ¡CARGA COMPLETADA!';

  @override
  String get chargingInfo => 'Info Carga';

  @override
  String get readyBy => 'Listo para las';

  @override
  String get startsAt => 'Empieza a las';

  @override
  String get estimatedCost => 'Coste estimado';

  @override
  String get energyNeeded => 'Energía necesaria';

  @override
  String get chargingTime => 'Tiempo de carga';

  @override
  String get confirmCharging => 'CONFIRMAR CARGA';

  @override
  String get selectLocation => 'Seleccionar lugar';

  @override
  String get chargeAdded => 'Carga añadida con éxito';

  @override
  String get chargeDeleted => 'Carga eliminada';

  @override
  String get chargeEdited => 'Carga editada';

  @override
  String get login => 'INICIAR SESIÓN';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get email => 'Email';

  @override
  String get password => 'Contraseña';

  @override
  String get forgotPassword => '¿Olvidaste la contraseña?';

  @override
  String get noAccount => '¿No tienes cuenta?';

  @override
  String get signUp => 'Registrarse';

  @override
  String get settings => 'Ajustes';

  @override
  String get statistics => 'Estadísticas';

  @override
  String get settingsSystem => 'AJUSTES DEL SISTEMA';

  @override
  String get cloudSync => 'SINCRONIZACIÓN EN LA NUBE';

  @override
  String get userId => 'ID DE SINCRONIZACIÓN';

  @override
  String get userName => 'NOMBRE USUARIO / EMPRESA';

  @override
  String get selectedCar => 'COCHE SELECCIONADO';

  @override
  String get batteryCapacity => 'CAPACIDAD BATERÍA';

  @override
  String get account => 'CUENTA';

  @override
  String get saveAllChanges => 'GUARDAR TODOS LOS CAMBIOS';

  @override
  String get batteryChemistry => 'QUÍMICA DE LAS CELDAS';

  @override
  String get contracts => 'GESTIÓN CONTRATOS ENERGÍA';

  @override
  String get contractDetails => 'DETALLES Y TRANSPARENCIA DE COSTES';

  @override
  String get yourPlans => 'TUS PLANES TARIFARIOS';

  @override
  String get addContract => 'AÑADIR NUEVO CONTRATO';

  @override
  String get batteryChemistryNmc => 'NMC / NCA';

  @override
  String get batteryChemistryLfp => 'LFP';

  @override
  String get batteryChemistryUnknown => 'DESCONOCIDA';

  @override
  String get adviceLfpFull =>
      'CONSEJO LFP: Mantén entre 20-80% a diario. Carga al 100% una vez a la semana para calibrar el BMS.';

  @override
  String get adviceNmcFull =>
      'CONSEJO NMC: Evita superar el 80% para uso diario. Carga al 100% solo para viajes largos.';

  @override
  String get adviceGenericFull =>
      'CONSEJO: Si no conoces la química, mantente entre 20-80%. Es el rango de seguridad universal para todas las baterías de litio.';

  @override
  String get import => 'IMPORTAR';

  @override
  String get download => 'DESCARGAR';

  @override
  String get upload => 'SUBIR';

  @override
  String get syncInProgress => 'Sincronizando...';

  @override
  String get confirmDelete => '¿Confirmar eliminación?';

  @override
  String get confirmLogout => '¿Confirmar cierre de sesión?';

  @override
  String get yes => 'SÍ';

  @override
  String get no => 'NO';

  @override
  String get chargingSlowdown => 'Ralentización de la carga';

  @override
  String get chargingVerySlow => 'Ralentización significativa';

  @override
  String get today => 'HOY';

  @override
  String get yesterday => 'AYER';

  @override
  String get thisMonth => 'ESTE MES';

  @override
  String get total => 'TOTAL';

  @override
  String get average => 'MEDIA';

  @override
  String get monthly => 'MENSUAL';

  @override
  String get yearly => 'ANUAL';

  @override
  String get fasciaF1 => 'F1';

  @override
  String get fasciaF2 => 'F2';

  @override
  String get fasciaF3 => 'F3';

  @override
  String get fasciaDistribution => 'DISTRIBUCIÓN FRANJAS HORARIAS';

  @override
  String get comingSoon => 'estará disponible en la próxima versión';
}
