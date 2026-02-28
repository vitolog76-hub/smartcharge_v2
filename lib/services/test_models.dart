import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIBillingService {
  // 🔥 LA TUA CHIAVE GEMINI
  final String _apiKey = "AIzaSyAvHJBYDZ1Xody4295ExIrJKGZOJRFBm_U";

  Future<Map<String, dynamic>?> analyzeBill(Uint8List fileBytes, String mimeType) async {
    String mime = mimeType;
    if (mime.isEmpty || !mime.startsWith('image/')) {
      mime = 'image/jpeg';
    }

    String base64Image = base64Encode(fileBytes);

    final prompt = '''
    Analizza questa bolletta elettrica italiana.
    Restituisci ESCLUSIVAMENTE un JSON valido con questi campi:
    {
      "provider": "nome del gestore",
      "f1": 0.25,
      "f2": 0.18,
      "f3": 0.15,
      "is_monoraria": false,
      "consiglio_esperto": "breve consiglio"
    }
    ''';

    // 🔥 MODELLO CORRETTO dalla lista che hai ottenuto
    const String url = "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent";

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt},
            {
              "inline_data": {
                "mime_type": mime,
                "data": base64Image
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.1,
        "max_output_tokens": 1024,
      }
    });

    try {
      print("🚀 Invio richiesta a Gemini 2.5 Flash...");
      
      final response = await http.post(
        Uri.parse("$url?key=$_apiKey"),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String text = data['candidates'][0]['content']['parts'][0]['text'];
        String cleanText = text.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(cleanText) as Map<String, dynamic>;
      } else {
        print("❌ Errore Gemini (${response.statusCode}): ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Errore: $e");
      return null;
    }
  }
}