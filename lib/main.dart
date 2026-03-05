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
  
  // Avviamo le inizializzazioni pesanti
  try {
    await dotenv.load(fileName: "assets/.env");
    await initializeDateFormatting('it_IT', null);
    
    if (kIsWeb) {
      String firebaseApiKey = const String.fromEnvironment('FIRESTORE_KEY');
      if (firebaseApiKey.isEmpty && dotenv.isInitialized) {
        firebaseApiKey = dotenv.env['FIRESTORE_KEY'] ?? '';
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
    } else {
      await Firebase.initializeApp();
    }

    final notificationService = NotificationService(); 
    await notificationService.init(); 
  } catch (e) {
    debugPrint('⚠️ Errore inizializzazione: $e');
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
        // Rimosso ..init() da qui per evitare blocchi all'avvio
        ChangeNotifierProvider(create: (_) => HomeProvider()),
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
        // Usiamo AppWrapper per gestire l'inizializzazione del Provider senza bloccare la UI
        home: const AppWrapper(),
      ),
    );
  }
}

// Questo Widget gestisce il passaggio tra Login e Home e lancia l'init()
class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  @override
  void initState() {
    super.initState();
    // Esegue l'init del HomeProvider subito dopo il primo frame disegnato
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        return auth.isAuthenticated ? const HomePage() : const LoginPage();
      },
    );
  }
}