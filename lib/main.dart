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
  
  // 1. Inizializzazioni base
  await initializeDateFormatting('it_IT', null);

  // 2. Firebase con i tuoi dati REALI già inseriti (Hardcoded per Vercel)
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDEY3p6_T-X_tW4p9QW9-R35N994658", // <--- QUESTA È LA TUA CHIAVE
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
    
    // Carichiamo .env solo come backup, non blocca più Firebase
    await dotenv.load(fileName: "assets/.env").catchError((_) => debugPrint("No .env"));
    
  } catch (e) {
    debugPrint('Firebase Init Error: $e');
  }

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // Se non è loggato, vai al Login
          if (!auth.isAuthenticated) return const LoginPage();
          
          // Se è loggato, carica i dati del MacBook e poi vai in Home
          return FutureBuilder(
            future: context.read<HomeProvider>().init(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return const HomePage();
              }
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(child: CircularProgressIndicator(color: Colors.green)),
              );
            },
          );
        },
      ),
    );
  }
}