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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carica .env solo se esiste (in locale funziona, in Vercel ignora)
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ .env caricato con successo');
  } catch (e) {
    debugPrint('📢 .env non trovato - normale su Vercel, continuo comunque');
  }

  // Inizializza Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
      debugPrint('✅ Firebase inizializzato');
    }
  } catch (e) {
    debugPrint('❌ Errore Firebase: $e');
  }

  // Inizializza formati data
  try {
    await initializeDateFormatting('it_IT', null);
    debugPrint('✅ Formati data inizializzati');
  } catch (e) {
    debugPrint('⚠️ Errore formati data: $e');
  }

  // Inizializza notifiche
  try {
    await NotificationService().init();
    debugPrint('✅ Notifiche inizializzate');
  } catch (e) {
    debugPrint('⚠️ Errore notifiche: $e');
  }

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