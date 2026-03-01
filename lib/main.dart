import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smartcharge_v2/providers/auth_provider.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';
import 'package:smartcharge_v2/screens/login_page.dart';
import 'package:smartcharge_v2/screens/home_page.dart';
import 'package:smartcharge_v2/services/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Carica .env da assets/
  try {
    await dotenv.load(fileName: "assets/.env");
    debugPrint('✅ .env caricato da assets/');
  } catch (e) {
    debugPrint('📢 .env non trovato in assets/ (Normale in produzione)');
  }

  try {
    if (kIsWeb) {
      debugPrint('🌐 Inizializzazione Firebase per WEB...');
      
      // RECUPERO CHIAVE DINAMICO
      String firebaseApiKey = '';
      
      // 1. Prova da String.fromEnvironment (Passata durante il build)
      firebaseApiKey = const String.fromEnvironment('FIRESTORE_KEY');

      // 2. Se vuota, prova dal file .env (Sviluppo locale o se caricato)
      if (firebaseApiKey.isEmpty && dotenv.isInitialized) {
        firebaseApiKey = dotenv.env['FIRESTORE_KEY'] ?? '';
      }
      
      if (firebaseApiKey.isEmpty) {
        debugPrint('❌ ERRORE: FIRESTORE_KEY non trovata!');
        debugPrint('💡 Assicurati di aver impostato FIRESTORE_KEY su Vercel o nel file .env');
      } else {
        // Stampa di controllo sicura
        debugPrint('🔑 Chiave caricata correttamente (inizia con: ${firebaseApiKey.substring(0, 6)})');
      }
      
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: firebaseApiKey,
          authDomain: "smartcharge-c5b34.firebaseapp.com",
          projectId: "smartcharge-c5b34",
          storageBucket: "smartcharge-c5b34.firebasestorage.app",
          messagingSenderId: "25947690562",
          appId: "1:25947690562:web:613953180d63919a677fdb",
          measurementId: "G-R35N994658",
        ),
      );
      debugPrint('✅ Firebase WEB inizializzato');
    } else {
      debugPrint('📱 Inizializzazione Firebase per MOBILE...');
      await Firebase.initializeApp();
      debugPrint('✅ Firebase MOBILE inizializzato');
    }
  } catch (e, stack) {
    debugPrint('❌ ERRORE Firebase: $e');
    debugPrint('📍 Stack: $stack');
  }

  await initializeDateFormatting('it_IT', null);
  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()..init()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Charge',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        home: Consumer<AuthProvider>(
          builder: (_, auth, __) {
            return auth.isAuthenticated ? const HomePage() : const LoginPage();
          },
        ),
      ),
    );
  }
}