import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final apiKey = "AIzaSyAvHJBYDZ1Xody4295ExIrJKGZOJRFBm_U";
  
  print("🔍 Cerco modelli disponibili...");
  
  final response = await http.get(
    Uri.parse("https://generativelanguage.googleapis.com/v1/models?key=$apiKey"),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print("\n✅ MODELLI DISPONIBILI:");
    for (var model in data['models']) {
      String name = model['name'].replaceAll('models/', '');
      print("   📌 $name");
      print("      metodi: ${model['supportedGenerationMethods']}");
      if (model['supportedGenerationMethods'].contains('generateContent')) {
        print("      ✅ supporta generateContent");
      }
    }
  } else {
    print("❌ Errore: ${response.statusCode}");
    print(response.body);
  }
}