import 'dart:convert';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcharge_v2/services/charge_engine.dart';
import 'package:smartcharge_v2/services/cost_calculator.dart';
import 'package:smartcharge_v2/core/constants.dart';
import 'package:smartcharge_v2/models/car_model.dart';
import 'package:smartcharge_v2/models/contract_model.dart';
import 'package:smartcharge_v2/models/charge_session.dart';
import 'package:smartcharge_v2/screens/settings_page.dart';
import 'package:smartcharge_v2/screens/history_page.dart';
import 'package:smartcharge_v2/widgets/battery_indicator.dart';
import 'package:smartcharge_v2/widgets/status_card.dart';
import 'package:smartcharge_v2/widgets/charging_controls.dart'; 
import 'package:smartcharge_v2/widgets/action_buttons.dart';    
import 'package:smartcharge_v2/services/sync_service.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartcharge_v2/services/simulation_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double currentSoc = 20.0;
  double targetSoc = 80.0;
  double _socAtStartOfSim = 20.0; 
  late CarModel selectedCar; 
  List<CarModel> _allCars = [];
  bool _carsLoaded = false;
  late TextEditingController _capacityController;
  double wallboxPwr = 3.7;
  TimeOfDay readyTime = const TimeOfDay(hour: 7, minute: 0);
  EnergyContract myContract = EnergyContract();
  List<ChargeSession> chargeHistory = [];
  final SimulationService _simService = SimulationService();
  bool _isSimulating = false;

  @override
  void initState() {
    super.initState();
    _capacityController = TextEditingController();
    _initializeApp();

    _simService.startChecking(
      onSocUpdate: (newSoc) => setState(() => currentSoc = newSoc),
      onStatusChange: (status) => setState(() => _isSimulating = status),
      onSimulationComplete: () => _showCompletionDialog(),
    );
  }

  @override
  void dispose() {
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _loadCarsFromJson();
    await _loadHistory();
    await _loadContract();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("TARGET RAGGIUNTO!", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
        content: const Text("La ricarica simulata è terminata con successo. Vuoi registrare la sessione nello storico?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CHIUDI", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () { 
              Navigator.pop(ctx); 
              _showAddChargeDialog("Home", customEndSoc: currentSoc); 
            }, 
            child: const Text("SALVA ORA", style: TextStyle(fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  Future<void> _saveSelectedCar(CarModel car) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_car_brand', car.brand);
    await prefs.setString('selected_car_model', car.model);
  }

  Future<void> _loadCarsFromJson() async {
    try {
      final String response = await rootBundle.loadString('assets/cars.json');
      final List<dynamic> data = json.decode(response);
      
      final prefs = await SharedPreferences.getInstance();
      String? savedBrand = prefs.getString('selected_car_brand');
      String? savedModel = prefs.getString('selected_car_model');
      
      setState(() {
        _allCars = data.map((item) => CarModel.fromJson(item)).toList();
        
        if (savedBrand != null && savedModel != null) {
          try {
            selectedCar = _allCars.firstWhere(
              (c) => c.brand == savedBrand && c.model == savedModel
            );
          } catch (e) {
            selectedCar = _allCars.first;
            debugPrint("Auto salvata non trovata, uso la prima disponibile");
          }
        } else {
          selectedCar = _allCars.first;
        }
        
        _capacityController.text = selectedCar.batteryCapacity.toString();
        _carsLoaded = true;
      });
    } catch (e) { 
      debugPrint("Errore caricamento auto: $e"); 
    }
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyData = prefs.getString('charge_history');
      
      debugPrint("🔄 Caricamento storico: historyData = $historyData");
      
      if (historyData != null && historyData.isNotEmpty) {
        final List<dynamic> decodedData = jsonDecode(historyData);
        debugPrint("📦 Dati decodificati: ${decodedData.length} elementi");
        
        setState(() {
          chargeHistory = decodedData.map((item) {
            try {
              return ChargeSession.fromJson(item);
            } catch (e) {
              debugPrint("Errore conversione sessione: $e");
              return null;
            }
          }).whereType<ChargeSession>().toList();
        });
        
        debugPrint("✅ Storico caricato: ${chargeHistory.length} sessioni valide");
      } else {
        debugPrint("⚠️ Nessuno storico trovato");
        setState(() {
          chargeHistory = [];
        });
      }
    } catch (e) {
      debugPrint("❌ ERRORE caricamento storico: $e");
      setState(() {
        chargeHistory = [];
      });
    }
  }
  
  Future<void> _loadContract() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? contractData = prefs.getString('energy_contract');
      
      if (contractData != null && contractData.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(contractData);
        setState(() {
          myContract.provider = decoded['provider'] ?? "";
          myContract.f1Price = (decoded['f1Price'] ?? 0.0).toDouble();
          myContract.f2Price = (decoded['f2Price'] ?? 0.0).toDouble();
          myContract.f3Price = (decoded['f3Price'] ?? 0.0).toDouble();
          myContract.isMonorario = decoded['isMonorario'] ?? true;
          myContract.userName = decoded['userName'] ?? "GIUSEPPE VITOLO";
        });
        debugPrint("✅ Contratto caricato: ${myContract.provider}");
      }
    } catch (e) {
      debugPrint("❌ ERRORE caricamento contratto: $e");
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String jsonData = jsonEncode(chargeHistory.map((s) => s.toJson()).toList());
      await prefs.setString('charge_history', jsonData);
      
      debugPrint("💾 Storico salvato: ${chargeHistory.length} sessioni");
      
      String? userId = prefs.getString('user_sync_id');
      if (userId != null && userId.isNotEmpty) {
        await SyncService().uploadData(userId, chargeHistory, myContract);
        debugPrint("☁️ Dati sincronizzati con cloud per user: $userId");
      }
    } catch (e) {
      debugPrint("❌ ERRORE salvataggio storico: $e");
    }
  }

  void _openCarSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text("SELEZIONA VEICOLO", style: GoogleFonts.inter(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 15),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _allCars.length,
                itemBuilder: (context, index) {
                  final car = _allCars[index];
                  bool isSelected = car.model == selectedCar.model;
                  return ListTile(
                    leading: Icon(Icons.directions_car_filled, color: isSelected ? Colors.blueAccent : Colors.white24),
                    title: Text("${car.brand} ${car.model}", style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text("${car.batteryCapacity} kWh", style: const TextStyle(color: Colors.white30)),
                    onTap: () {
                      setState(() { 
                        selectedCar = car; 
                        _capacityController.text = car.batteryCapacity.toString();
                      });
                      _saveSelectedCar(car);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context, initialTime: readyTime,
      builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Colors.blueAccent, surface: Color(0xFF1C1C1E))), child: child!),
    );
    if (picked != null) setState(() => readyTime = picked);
  }

  void _showAddChargeDialog(String tipo, {double? customEndSoc}) async {
    double currentBatteryCap = double.tryParse(_capacityController.text) ?? selectedCar.batteryCapacity;
    double startSoc = (customEndSoc != null) ? _socAtStartOfSim : currentSoc;
    double endSoc = customEndSoc ?? targetSoc;
    
    double suggestedKwh = ChargeEngine.calculateEnergy(startSoc, endSoc, currentBatteryCap);
    
    TextEditingController kwhCtrl = TextEditingController(text: suggestedKwh.toStringAsFixed(1));
    double defaultPrice = (tipo == "Home") ? myContract.f1Price : 0.65; 
    TextEditingController priceCtrl = TextEditingController(text: defaultPrice.toStringAsFixed(2));
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Registra $tipo", style: const TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTile(Icons.calendar_today, "Data", DateFormat('dd/MM/yyyy').format(selectedDate), () async {
                    final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2024), lastDate: DateTime.now());
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  }),
                  TextField(controller: kwhCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "kWh CARICATI")),
                  TextField(controller: priceCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.greenAccent), decoration: const InputDecoration(labelText: "PREZZO (€/kWh)")),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annulla")),
              ElevatedButton(
                onPressed: () {
                  double finalKwh = double.tryParse(kwhCtrl.text) ?? suggestedKwh;
                  
                  double finalCost;
                  if (tipo == "Home") {
                    finalCost = CostCalculator.calculate(
                      finalKwh, 
                      TimeOfDay.now(),
                      selectedDate, 
                      myContract
                    );
                  } else {
                    finalCost = finalKwh * (double.tryParse(priceCtrl.text) ?? 0.65);
                  }
                  
                  setState(() { 
                    chargeHistory.add(ChargeSession(
                      date: selectedDate, 
                      kwh: finalKwh, 
                      cost: finalCost, 
                      location: tipo, 
                      startTime: TimeOfDay.now(), 
                      endTime: TimeOfDay.now()
                    )); 
                  });
                  
                  _saveHistory(); 
                  Navigator.pop(context);
                },
                child: const Text("Salva")
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogTile(IconData icon, String label, String value, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent), 
      title: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)), 
      subtitle: Text(value, style: const TextStyle(color: Colors.white)), 
      onTap: onTap
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_carsLoaded) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));

    double currentBatteryCap = double.tryParse(_capacityController.text) ?? selectedCar.batteryCapacity;
    double energyNeeded = ChargeEngine.calculateEnergy(currentSoc, targetSoc, currentBatteryCap);
    Duration duration = ChargeEngine.calculateDuration(energyNeeded, wallboxPwr);

    final now = DateTime.now();
    DateTime targetReadyDateTime = DateTime(now.year, now.month, now.day, readyTime.hour, readyTime.minute);
    if (targetReadyDateTime.isBefore(now)) {
      targetReadyDateTime = targetReadyDateTime.add(const Duration(days: 1));
    }

    DateTime calculatedStartDateTime = targetReadyDateTime.subtract(duration);
    String startTimeDisplay = DateFormat('HH:mm').format(calculatedStartDateTime);
    TimeOfDay startTimeOfDay = TimeOfDay.fromDateTime(calculatedStartDateTime);

    double estimatedCost = CostCalculator.calculate(
      energyNeeded,
      startTimeOfDay,
      DateTime.now(),
      myContract
    );

    bool isChargingReal = _isSimulating && DateTime.now().isAfter(_simService.scheduledStart ?? DateTime.now());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Smart Charge", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.history, color: Colors.blueAccent), 
          onPressed: () {
            debugPrint("📋 Navigazione a HistoryPage con ${chargeHistory.length} sessioni");
            Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (context) => HistoryPage(
                  history: chargeHistory, 
                  contract: myContract, 
                  selectedCar: selectedCar
                )
              )
            );
          }
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.blueAccent), 
            onPressed: () async {
              // Aspetta che SettingsPage venga chiusa e ricevi il risultato
              final updated = await Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    contract: myContract, 
                    selectedCar: selectedCar, 
                    batteryValue: _capacityController.text
                  )
                )
              );
              
              // Se updated == true, significa che sono stati scaricati nuovi dati
              if (updated == true) {
                debugPrint("🔄 Dati aggiornati dal cloud, ricarico...");
                await _loadHistory();    // Ricarica lo storico
                await _loadContract();   // Ricarica il contratto
                setState(() {});         // Forza aggiornamento UI
              }
            }
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GestureDetector(
                onTap: _isSimulating ? null : () => _selectTime(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E), 
                    borderRadius: BorderRadius.circular(18), 
                    border: Border.all(
                      color: _isSimulating 
                        ? (isChargingReal ? Colors.greenAccent : Colors.orangeAccent) 
                        : Colors.blueAccent.withOpacity(0.2)
                    )
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          _isSimulating 
                            ? (isChargingReal ? "RICARICA IN CORSO..." : "IN ATTESA...") 
                            : "AUTO PRONTA PER LE ORE:", 
                          style: TextStyle(
                            color: _isSimulating 
                              ? (isChargingReal ? Colors.greenAccent : Colors.orangeAccent) 
                              : Colors.white38, 
                            fontSize: 9, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                        Text(
                          readyTime.format(context), 
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)
                        ),
                      ]),
                      Icon(
                        _isSimulating 
                          ? (isChargingReal ? Icons.bolt_rounded : Icons.timer) 
                          : Icons.access_time, 
                        color: _isSimulating 
                          ? (isChargingReal ? Colors.greenAccent : Colors.orangeAccent) 
                          : Colors.blueAccent, 
                        size: 36
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(flex: 2, child: BatteryIndicator(percent: currentSoc, isCharging: isChargingReal)),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: StatusCard(duration: duration, energy: energyNeeded, power: wallboxPwr)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildMiniStat("COSTO STIMATO", "${estimatedCost.toStringAsFixed(2)} €", Colors.greenAccent)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMiniStat("INIZIO CARICA", startTimeDisplay, Colors.orangeAccent)),
                ],
              ),
              const SizedBox(height: 16),
              ChargingControls(
                wallboxPwr: wallboxPwr, 
                currentSoc: currentSoc, 
                targetSoc: targetSoc,
                onPwrChanged: _isSimulating ? (v) {} : (v) => setState(() => wallboxPwr = v),
                onCurrentSocChanged: _isSimulating ? (v) {} : (v) => setState(() => currentSoc = v),
                onTargetSocChanged: _isSimulating ? (v) {} : (v) => setState(() => targetSoc = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_isSimulating) {
                      if (isChargingReal && currentSoc > _socAtStartOfSim) {
                        final double captureSoc = currentSoc;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF1C1C1E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text("RICARICA INTERROTTA", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                            content: Text("Hai caricato fino al ${captureSoc.toStringAsFixed(1)}%. Vuoi salvare?"),
                            actions: [
                              TextButton(
                                onPressed: () { 
                                  _simService.stopSimulation(); 
                                  Navigator.pop(ctx); 
                                }, 
                                child: const Text("SCARTA", style: TextStyle(color: Colors.redAccent))
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                                onPressed: () { 
                                  _simService.stopSimulation(); 
                                  Navigator.pop(ctx); 
                                  _showAddChargeDialog("Home", customEndSoc: captureSoc); 
                                }, 
                                child: const Text("SALVA")
                              ),
                            ],
                          ),
                        );
                      } else {
                        _simService.stopSimulation();
                      }
                    } else {
                      final double startVal = currentSoc;
                      setState(() { _socAtStartOfSim = startVal; });
                      _simService.initSimulation(
                        startDateTime: calculatedStartDateTime,
                        currentSoc: startVal, 
                        targetSoc: targetSoc, 
                        pwr: wallboxPwr, 
                        cap: currentBatteryCap,
                      );
                    }
                  },
                  icon: Icon(_isSimulating ? Icons.stop_rounded : Icons.play_arrow_rounded),
                  label: Text(_isSimulating ? "STOP" : "AVVIA SIMULAZIONE", style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSimulating ? Colors.redAccent : Colors.blueAccent, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ActionButtons(
                onHomeTap: _isSimulating ? () {} : () => _showAddChargeDialog("Home"), 
                onPublicTap: _isSimulating ? () {} : () => _showAddChargeDialog("Pubblica")
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _isSimulating ? null : _openCarSelection,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E), 
                          borderRadius: BorderRadius.circular(15), 
                          border: Border.all(color: Colors.white10)
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text("VEICOLO", style: TextStyle(color: Colors.white38, fontSize: 9)),
                          Text(selectedCar.model.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 100,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E), 
                      borderRadius: BorderRadius.circular(15), 
                      border: Border.all(color: Colors.white10)
                    ),
                    child: Column(children: [
                      const Text("CAPACITÀ", style: TextStyle(color: Colors.white38, fontSize: 9)),
                      TextField(
                        controller: _capacityController, 
                        enabled: !_isSimulating, 
                        keyboardType: TextInputType.number, 
                        textAlign: TextAlign.center, 
                        style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold), 
                        decoration: const InputDecoration(
                          isDense: true, 
                          border: InputBorder.none, 
                          suffixText: " kWh"
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ], 
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ]),
    );
  }
}