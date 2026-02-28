import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIBillingService {
  final String _apiKey = dotenv.env['GEMINIKEY'] ?? '';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Metodo principale che gestisce limiti e analisi
  Future<Map<String, dynamic>?> processBill(Uint8List fileBytes, String mimeType, String userId) async {
    // 1. Controllo limite upload (max 3 al mese)
    bool canUpload = await _checkUploadLimit(userId);
    if (!canUpload) {
      print("🚫 Limite upload raggiunto per questo mese.");
      return {'error': 'limit_reached'};
    }

    // 2. Analisi (PDF o Immagine)
    Map<String, dynamic>? result;
    if (mimeType == 'application/pdf') {
      result = await _analyzePdf(fileBytes);
    } else {
      // Se aggiungi analisi immagini in futuro, andrebbe qui
      result = await _analyzePdf(fileBytes); 
    }
    
    // 3. Incremento contatore solo se l'analisi ha prodotto risultati validi
    if (result != null && !result.containsKey('error')) {
      await _incrementUploadCount(userId);
    }
    return result;
  }

  Future<bool> _checkUploadLimit(String userId) async {
    try {
      final now = DateTime.now();
      final String currentMonth = "${now.year}-${now.month}";

      DocumentReference userRef = _db.collection('users').doc(userId);
      DocumentSnapshot doc = await userRef.get();

      if (!doc.exists) return true;

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String lastMonth = data['lastUploadMonth'] ?? "";
      int count = data['billUploadsCount'] ?? 0;

      if (lastMonth != currentMonth) {
        await userRef.update({
          'billUploadsCount': 0,
          'lastUploadMonth': currentMonth,
        });
        return true;
      }
      return count < 3;
    } catch (e) {
      print("Errore controllo limiti: $e");
      return true; // In caso di errore DB, permettiamo l'upload per non bloccare l'utente
    }
  }

  Future<void> _incrementUploadCount(String userId) async {
    final now = DateTime.now();
    final String currentMonth = "${now.year}-${now.month}";
    await _db.collection('users').doc(userId).set({
      'billUploadsCount': FieldValue.increment(1),
      'lastUploadMonth': currentMonth,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> _analyzePdf(Uint8List bytes) async {
    try {
      PdfDocument document = PdfDocument(inputBytes: bytes);
      String testoGrezzo = '';
      for (int i = 0; i < document.pages.count; i++) {
        testoGrezzo += PdfTextExtractor(document).extractText(startPageIndex: i, layoutText: true);
      }
      document.dispose();

      final prompt = '''
Analizza questa bolletta con precisione assoluta. Non arrotondare i decimali.
1. IDENTIFICA: Energia F1, F2, F3 (usa 6 decimali se presenti, es. 0.118292).
2. IDENTIFICA: Componente Omega (Spread), Dispacciamento, Oneri di sistema (€/kWh).
3. IDENTIFICA: Quota Fissa Totale (€) e Quota Potenza (€/kW).
4. CALCOLA PREZZI FINALI:
   - Prezzo_con_Perdite = Prezzo_Energia * 1.10
   - Imponibile = Prezzo_con_Perdite + Omega + Dispacciamento + Oneri
   - FINALE_IVATO = Imponibile * 1.10 (IVA 10%)
5. QUOTE FISSE: Applica IVA 10% a Quota Fissa e Quota Potenza.

Restituisci SOLO questo JSON:
{
  "provider": "[Nome del fornitore trovato]",
  "f1": [calcolato], "f2": [calcolato], "f3": [calcolato],
  "f1_puro": [originale], "f2_puro": [originale], "f3_puro": [originale],
  "fixed_monthly_fee": [ivato], "power_fee": [ivato], "vat": 10
}
Testo bolletta:
$testoGrezzo
''';

      final response = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [{"parts": [{"text": prompt}]}],
          "generationConfig": {"temperature": 0.0, "responseMimeType": "application/json"}
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['candidates'][0]['content']['parts'][0]['text']);
      }
      return null;
    } catch (e) {
      print('❌ Errore Gemini: $e');
      return null;
    }
  }
}