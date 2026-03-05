import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smartcharge_v2/providers/auth_provider.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';
import 'package:smartcharge_v2/screens/login_page.dart';
import 'package:smartcharge_v2/screens/home_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  // 1. Inizializza il framework Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Carica le date italiane
  await initializeDateFormatting('it_IT', null);

  // 3. Avvia l'app subito (Niente più attese infinite nel main)
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Funzione interna per inizializzare i servizi pesanti "sotto il cofano"
  Future<void> _prepareApp() async {
    // Carica .env
    try {
      await dotenv.load(fileName: "assets/.env");
    } catch (e) {
      debugPrint("Asset .env non trovato, procedo comunque.");
    }

    // Inizializza Firebase
    if (Firebase.apps.isEmpty) {
      if (kIsWeb) {
        final key = dotenv.env['FIRESTORE_KEY'] ?? '';
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: key,
            authDomain: "smartcharge-c5b34.firebaseapp.com",
            projectId: "smartcharge-c5b34",
            storageBucket: "smartcharge-c5b34.firebasestorage.app",
            messagingSenderId: "25947690562",
            appId: "1:25947690562:web:613953180d63919a677fdb",
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      // FutureBuilder avvolge TUTTA l'app: finché _prepareApp non finisce, vedi nero.
      // Appena finisce, lo schermo si accende. NIENTE PAGINA GRIGIA.
      home: FutureBuilder(
        future: _prepareApp(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(backgroundColor: Colors.black);
          }

          return Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (!auth.isAuthenticated) return const LoginPage();
              
              // Se loggato, avvia i dati del provider e vai alla Home
              return FutureBuilder(
                future: context.read<HomeProvider>().init(),
                builder: (context, homeSnap) {
                  if (homeSnap.connectionState == ConnectionState.done) {
                    return const HomePage();
                  }
                  return const Scaffold(
                    backgroundColor: Colors.black,
                    body: Center(child: CircularProgressIndicator(color: Colors.green)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}