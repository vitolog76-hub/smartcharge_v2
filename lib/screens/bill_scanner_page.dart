import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smartcharge_v2/services/ai_billing_service.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Aggiunto per l'ID utente
import 'package:intl/intl.dart';
import 'package:smartcharge_v2/models/contract_model.dart';

class BillScannerPage extends StatefulWidget {
  final HomeProvider provider;

  const BillScannerPage({super.key, required this.provider});

  @override
  State<BillScannerPage> createState() => _BillScannerPageState();
}

class _BillScannerPageState extends State<BillScannerPage> {
  final ImagePicker _picker = ImagePicker();
  final AIBillingService _aiService = AIBillingService();
  
  bool _isLoading = false;
  Uint8List? _fileBytes;
  String? _fileName;
  Map<String, dynamic>? _analysisResult;

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _fileBytes = bytes;
          _fileName = 'Foto dalla fotocamera';
        });
        await _analyzeFile(bytes, 'image/jpeg');
      }
    } catch (e) {
      _showError("Errore fotocamera: $e");
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _fileBytes = bytes;
          _fileName = image.name;
        });
        await _analyzeFile(bytes, 'image/jpeg');
      }
    } catch (e) {
      _showError("Errore galleria: $e");
    }
  }

  Future<void> _pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true,
      );
      
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _fileBytes = result.files.single.bytes;
          _fileName = result.files.single.name;
        });
        await _analyzeFile(result.files.single.bytes!, 'application/pdf');
      }
    } catch (e) {
      _showError("Errore selezione PDF: $e");
    }
  }

  Future<void> _analyzeFile(Uint8List bytes, String mimeType) async {
    setState(() => _isLoading = true);
    try {
      debugPrint("🚀 Inizio analisi bolletta...");
      
      // ✅ FIX: Prendi l'ID dell'utente attualmente loggato
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError("Devi essere loggato per analizzare la bolletta.");
        setState(() => _isLoading = false);
        return;
      }
      
      final String userId = user.uid;
      debugPrint("🔍 Analisi per utente UID: $userId");
      
      final result = await _aiService.processBill(bytes, mimeType, userId);
      
      setState(() => _isLoading = false);

      if (result == null) {
        _showError("Analisi fallita. Il file potrebbe non essere leggibile.");
        return;
      }

      // ✅ Gestione errore limite (basata su Firebase e non sul dispositivo)
      if (result.containsKey('error') && result['error'] == 'limit_reached') {
        _showError("⛔ Limite raggiunto per questo account (max 3/mese).");
        return;
      }

      setState(() {
        _analysisResult = result;
      });

    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Errore durante l'analisi: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _saveToContract() {
    if (_analysisResult == null) return;

    try {
      final provider = widget.provider;
      final res = _analysisResult!;
      
      // 1. DETERMINA SE IL NUOVO CONTRATTO È MONORARIO O A FASCE
      double f1 = (res['f1'] ?? 0.0).toDouble();
      double f2 = (res['f2'] ?? 0.0).toDouble();
      double f3 = (res['f3'] ?? 0.0).toDouble();
      bool isRealmenteMonorario = (f1 == f2 && f2 == f3);

      // 2. CREA UN NUOVO OGGETTO CONTRATTO (Invece di modificare l'esistente)
      final String newId = DateTime.now().millisecondsSinceEpoch.toString();
      final String dateLabel = DateFormat('dd/MM').format(DateTime.now());
      final String providerName = res['provider']?.toString() ?? 'Nuovo Gestore';

      final newContract = EnergyContract(
        id: newId,
        contractName: "Bolletta $providerName $dateLabel",
        provider: providerName,
        userName: "Utente", 
        isMonorario: res['is_monorario'] ?? isRealmenteMonorario,
        f1Price: (res['f1'] ?? 0.0).toDouble(),
        f2Price: (res['f2'] ?? 0.0).toDouble(),
        f3Price: (res['f3'] ?? 0.0).toDouble(),
        f1Pure: (res['f1_puro'] ?? 0.0).toDouble(),
        f2Pure: (res['f2_puro'] ?? 0.0).toDouble(),
        f3Pure: (res['f3_puro'] ?? 0.0).toDouble(),
        fixedMonthlyFee: (res['fixed_monthly_fee'] ?? 0.0).toDouble(),
        powerFee: (res['power_fee'] ?? 0.0).toDouble(),
        transportFee: (res['transport_fee'] ?? 0.0).toDouble(), // Aggiunto
        systemCharges: (res['system_charges'] ?? 0.0).toDouble(), // Aggiunto
        vat: (res['vat'] ?? 10.0).toDouble(),
        createdAt: DateTime.now(),
      );
      // 3. SALVATAGGIO NELLA LISTA E ATTIVAZIONE
      provider.addOrUpdateContract(newContract);
      provider.selectActiveContract(newId);
      
      ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text("✅ Contratto '${newContract.contractName}' aggiunto! Il vecchio contratto è stato salvato in archivio."),
    backgroundColor: Colors.green,
    duration: const Duration(seconds: 4),
  ),
);
      
      Navigator.pop(context, true);
    } catch (e) {
      _showError("Errore nel salvataggio: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("ANALISI DOCUMENTO", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading 
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.blueAccent),
                SizedBox(height: 20),
                Text("Analisi in corso...", style: TextStyle(color: Colors.white70))
              ],
            ))
          : _analysisResult != null ? _buildResultView() : _buildUploadView(),
      ),
    );
  }

  Widget _buildUploadView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.document_scanner, size: 80, color: Colors.blueAccent),
        const SizedBox(height: 20),
        const Text("Seleziona la bolletta", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const Text("Puoi caricare fino a 3 bollette al mese", style: TextStyle(fontSize: 12, color: Colors.white38)),
        const SizedBox(height: 40),
        _buildActionButton("SCATTA FOTO", Icons.camera_alt, _pickFromCamera, Colors.blueAccent),
        const SizedBox(height: 12),
        _buildActionButton("GALLERIA IMMAGINI", Icons.photo_library, _pickFromGallery, Colors.white10),
        const SizedBox(height: 12),
        _buildActionButton("CARICA PDF", Icons.picture_as_pdf, _pickPdf, Colors.orangeAccent.withOpacity(0.8)),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback action, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: action,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final data = _analysisResult!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              _buildSectionTitle("DATI ESTRATTI"),
              _buildInfoTile("Fornitore", data['provider'] ?? "Non rilevato", Icons.business),
              const SizedBox(height: 20),
              _buildSectionTitle("TARIFFE IVATE (€/kWh)"),
              _buildPriceRow("F1", data['f1'], Colors.blueAccent),
              _buildPriceRow("F2", data['f2'], Colors.orangeAccent),
              _buildPriceRow("F3", data['f3'], Colors.greenAccent),
              const SizedBox(height: 20),
              _buildSectionTitle("PREZZI MATERIA (€/kWh)"),
              _buildPureRow("Prezzo F1 Puro", data['f1_puro']),
              _buildPureRow("Prezzo F2 Puro", data['f2_puro']),
              _buildPureRow("Prezzo F3 Puro", data['f3_puro']),
              const SizedBox(height: 20),
              _buildSectionTitle("ALTRI COSTI"),
              _buildInfoTile("Fisso Mensile", "${data['fixed_monthly_fee']} €", Icons.calendar_today),
              _buildInfoTile("Quota Potenza", "${data['power_fee']} €/kW", Icons.speed),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: TextButton(onPressed: () => setState(() => _analysisResult = null), child: const Text("ANNULLA", style: TextStyle(color: Colors.white54)))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(onPressed: _saveToContract, style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("CONFERMA E SALVA"))),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String fascia, dynamic price, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Fascia $fascia", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text("${price?.toStringAsFixed(4)} €/kWh", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPureRow(String label, dynamic price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text("${price?.toString()} €", style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}