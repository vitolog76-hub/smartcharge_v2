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
  
  // 1. Carichiamo le date italiane
  await initializeDateFormatting('it_IT', null);

  // 2. Inizializziamo Firebase PRIMA di far partire l'app
  try {
    if (kIsWeb) {
      // USIAMO LA TUA CHIAVE REALE DIRETTAMENTE (Basta rimpalli con .env o environment)
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDEY3p6_T-X_tW4p9QW9-R35N994658", // Inserisci qui la tua API KEY REALE del file .env
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
    
    // Carichiamo .env solo per altre utility, non per Firebase
    await dotenv.load(fileName: "assets/.env").catchError((_) => debugPrint("No .env"));
    
  } catch (e) {
    debugPrint('Firebase Init Critical Error: $e');
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
          if (!auth.isAuthenticated) return const LoginPage();
          
          return FutureBuilder(
            future: context.read<HomeProvider>().init(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) return const HomePage();
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.green)));
            },
          );
        },
      ),
    );
  }
}