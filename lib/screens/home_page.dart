import 'dart:convert';
import 'dart:ui'; // NECESSARIO PER IL VETRO OPACO (ImageFilter)
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
import 'package:smartcharge_v2/widgets/car_selector.dart';
import 'package:smartcharge_v2/widgets/battery_indicator.dart';
import 'package:smartcharge_v2/widgets/status_card.dart';
import 'package:smartcharge_v2/widgets/charging_controls.dart'; 
import 'package:smartcharge_v2/widgets/action_buttons.dart';    
import 'package:smartcharge_v2/services/sync_service.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double currentSoc = 20.0;
  double targetSoc = 80.0;
  late CarModel selectedCar; 
  List<CarModel> _allCars = [];
  bool _carsLoaded = false;
  late TextEditingController _capacityController;
  double wallboxPwr = 3.7;
  TimeOfDay readyTime = const TimeOfDay(hour: 7, minute: 0);
  EnergyContract myContract = EnergyContract();
  List<ChargeSession> chargeHistory = [];

  @override
  void initState() {
    super.initState();
    _capacityController = TextEditingController();
    _initializeApp();
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

  Future<void> _loadCarsFromJson() async {
    try {
      final String response = await rootBundle.loadString('assets/cars.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        _allCars = data.map((item) => CarModel.fromJson(item)).toList();
        selectedCar = _allCars.firstWhere((c) => c.model == "Megane E-Tech", orElse: () => _allCars.first);
        _capacityController.text = selectedCar.batteryCapacity.toString();
        _carsLoaded = true;
      });
    } catch (e) { debugPrint("Errore: $e"); }
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyData = prefs.getString('charge_history');
    if (historyData != null) {
      final List<dynamic> decodedData = jsonDecode(historyData);
      setState(() => chargeHistory = decodedData.map((item) => ChargeSession.fromJson(item)).toList());
    }
  }
  
  Future<void> _loadContract() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contractData = prefs.getString('energy_contract');
    if (contractData != null) {
      final Map<String, dynamic> decoded = jsonDecode(contractData);
      setState(() {
        myContract.provider = decoded['provider'] ?? "";
        myContract.f1Price = (decoded['f1Price'] ?? 0.0).toDouble();
        myContract.f2Price = (decoded['f2Price'] ?? 0.0).toDouble();
        myContract.f3Price = (decoded['f3Price'] ?? 0.0).toDouble();
        myContract.isMonorario = decoded['isMonorario'] ?? true;
        myContract.userName = decoded['userName'] ?? "GIUSEPPE VITOLO";
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('charge_history', jsonEncode(chargeHistory.map((s) => s.toJson()).toList()));
    String? userId = prefs.getString('user_sync_id');
    if (userId != null && userId.isNotEmpty) await SyncService().uploadData(userId, chargeHistory, myContract);
  }

  void _openCarSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: CarSelector(
          selectedCar: selectedCar, 
          allCars: _allCars, 
          onCarChanged: (car) { 
            if (car != null) {
              setState(() { 
                selectedCar = car; 
                _capacityController.text = car.batteryCapacity.toString(); 
              });
              Navigator.pop(context);
            } 
          }
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context, 
      initialTime: readyTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Colors.blueAccent, surface: Color(0xFF1C1C1E))
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => readyTime = picked);
  }

  void _showAddChargeDialog(String tipo) async {
    double currentBatteryCap = double.tryParse(_capacityController.text) ?? selectedCar.batteryCapacity;
    double suggestedKwh = ChargeEngine.calculateEnergy(currentSoc, targetSoc, currentBatteryCap);
    
    TextEditingController kwhCtrl = TextEditingController(text: suggestedKwh.toStringAsFixed(1));
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(hour: (TimeOfDay.now().hour + 2) % 24, minute: TimeOfDay.now().minute);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Registra $tipo", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTile(Icons.calendar_today, "Data", DateFormat('dd/MM/yyyy').format(selectedDate), () async {
                    final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2024), lastDate: DateTime.now());
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  }),
                  _buildDialogTile(Icons.play_circle_outline, "Ora Inizio", startTime.format(context), () async {
                    final picked = await showTimePicker(context: context, initialTime: startTime);
                    if (picked != null) setDialogState(() => startTime = picked);
                  }),
                  _buildDialogTile(Icons.stop, "Ora Fine", endTime.format(context), () async {
                    final picked = await showTimePicker(context: context, initialTime: endTime);
                    if (picked != null) setDialogState(() => endTime = picked);
                  }),
                  const SizedBox(height: 15),
                  TextField(
                    controller: kwhCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "kWh CARICATI",
                      labelStyle: const TextStyle(color: Colors.blueAccent, fontSize: 12),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annulla", style: TextStyle(color: Colors.white38))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () {
                  final finalDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, startTime.hour, startTime.minute);
                  double finalKwh = double.tryParse(kwhCtrl.text) ?? suggestedKwh;
                  double finalCost = CostCalculator.calculate(finalKwh, const TimeOfDay(hour: 23, minute: 0), finalDateTime, myContract);
                  setState(() {
                    chargeHistory.add(ChargeSession(date: finalDateTime, kwh: finalKwh, cost: finalCost, location: tipo, startTime: startTime, endTime: endTime));
                    currentSoc = targetSoc;
                  });
                  _saveHistory();
                  Navigator.pop(context);
                },
                child: const Text("Salva", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogTile(IconData icon, String label, String value, VoidCallback onTap) {
    return ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(icon, color: Colors.blueAccent, size: 20), title: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)), subtitle: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), onTap: onTap);
  }

  @override
  Widget build(BuildContext context) {
    if (!_carsLoaded) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)));

    double currentBatteryCap = double.tryParse(_capacityController.text) ?? selectedCar.batteryCapacity;
    double energyNeeded = ChargeEngine.calculateEnergy(currentSoc, targetSoc, currentBatteryCap);
    Duration duration = ChargeEngine.calculateDuration(energyNeeded, wallboxPwr);

    // --- LOGICA SMART: CALCOLO ORA TARGET ---
    final now = DateTime.now();
    DateTime targetDateTime = DateTime(now.year, now.month, now.day, readyTime.hour, readyTime.minute);
    if (targetDateTime.isBefore(now)) {
      targetDateTime = targetDateTime.add(const Duration(days: 1));
    }

    String startTimeStr = ChargeEngine.calculateStartTime(targetDateTime, duration);
    double estimatedCost = CostCalculator.calculate(energyNeeded, const TimeOfDay(hour: 23, minute: 0), DateTime.now(), myContract);

    return Scaffold(
      backgroundColor: Colors.black, 
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Smart Charge", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.black.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.history, color: Colors.blueAccent), 
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryPage(history: chargeHistory, contract: myContract, selectedCar: selectedCar)))
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.blueAccent), 
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(contract: myContract, selectedCar: selectedCar, batteryValue: _capacityController.text)));
              _loadContract(); 
              _loadHistory();
            }
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // --- SELETTORE AUTO ---
              Row(
                children: [
                  Expanded(
                    flex: 3, 
                    child: GestureDetector(
                      onTap: () => _openCarSelection(),
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_car_filled, color: Colors.blueAccent, size: 20),
                            const SizedBox(width: 10),
                            Text("Cambia Auto".toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11, letterSpacing: 1.1)),
                          ],
                        ),
                      ),
                    )
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1, 
                    child: SizedBox(
                      height: 54, 
                      child: TextField(
                        controller: _capacityController, 
                        keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                        textAlign: TextAlign.center, 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), 
                        onChanged: (v) => setState(() {}), 
                        decoration: InputDecoration(
                          labelText: "BATTERIA", labelStyle: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          suffixText: "kWh", suffixStyle: const TextStyle(color: Colors.white24, fontSize: 9),
                          filled: true, fillColor: const Color(0xFF1C1C1E), 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), 
                          contentPadding: const EdgeInsets.symmetric(vertical: 10)
                        )
                      )
                    )
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- SELETTORE ORA TARGET (READY TIME) ---
              GestureDetector(
                onTap: () => _selectTime(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("AUTO PRONTA PER LE ORE:", style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                          const SizedBox(height: 4),
                          Text(
                            readyTime.format(context),
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const Icon(Icons.access_time_rounded, color: Colors.blueAccent, size: 36),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // --- BATTERIA E STATO ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 2, child: BatteryIndicator(percent: currentSoc)),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: StatusCard(duration: duration, energy: energyNeeded, power: wallboxPwr)),
                ],
              ),
              const SizedBox(height: 16),

              // --- MINI STATS ---
              Row(
                children: [
                  Expanded(child: _buildMiniStat("COSTO STIMATO", "${estimatedCost.toStringAsFixed(2)} €", Colors.greenAccent)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMiniStat("INIZIO CARICA", startTimeStr, Colors.orangeAccent)),
                ],
              ),
              const SizedBox(height: 16),

              // --- CONTROLLI ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(20)),
                child: ChargingControls(
                  wallboxPwr: wallboxPwr, currentSoc: currentSoc, targetSoc: targetSoc,
                  onPwrChanged: (v) => setState(() => wallboxPwr = v),
                  onCurrentSocChanged: (v) => setState(() => currentSoc = v),
                  onTargetSocChanged: (v) => setState(() => targetSoc = v),
                ),
              ),
              const SizedBox(height: 16),

              // --- AZIONI ---
              ActionButtons(
                onHomeTap: () => _showAddChargeDialog("Home"),
                onPublicTap: () => _showAddChargeDialog("Pubblica"),
              ),
              
              const SizedBox(height: 30),

              // --- NOME AUTO CON EFFETTO VETRO ---
              Column(
                children: [
                  Text(selectedCar.brand.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, letterSpacing: 3)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          selectedCar.model.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 22, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E), 
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value, 
              style: TextStyle(
                color: color, 
                fontWeight: FontWeight.bold, 
                fontSize: 18,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: color.withOpacity(0.5),
                    offset: const Offset(0, 0),
                  ),
                ],
              )
            ),
          ),
        ],
      ),
    );
  }
}