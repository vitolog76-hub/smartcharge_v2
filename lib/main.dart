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
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Funzione che prepara tutto PRIMA di mostrare la UI
  Future<void> _initEverything() async {
    try {
      await dotenv.load(fileName: "assets/.env");
      await initializeDateFormatting('it_IT', null);
      
      if (Firebase.apps.isEmpty) {
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
            ),
          );
        } else {
          await Firebase.initializeApp();
        }
      }
    } catch (e) {
      debugPrint('Init Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
        // USA UN FUTUREBUILDER COME USCITA DI SICUREZZA
        home: FutureBuilder(
          future: _initEverything(),
          builder: (context, snapshot) {
            // Se sta caricando o ha dato errore, mostra solo sfondo nero (evita il grigio)
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(backgroundColor: Colors.black);
            }

            // Una volta che Firebase è pronto, decidiamo dove andare
            return Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (!auth.isAuthenticated) return const LoginPage();

                // Se loggato, avvia i dati locali e vai in Home
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
      ),
    );
  }
}