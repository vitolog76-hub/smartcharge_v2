import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smartcharge_v2/screens/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBdZ7j1pMuabOd47xeBzCPq0g9wBi4jg3A",
      authDomain: "smartcharge-c5b34.firebaseapp.com",
      projectId: "smartcharge-c5b34",
      storageBucket: "smartcharge-c5b34.firebasestorage.app",
      messagingSenderId: "25947690562",
      appId: "1:25947690562:web:613953180d63919a677fdb",
      measurementId: "G-R35N994658",
    ),
  );

  await initializeDateFormatting('it_IT', null); 

  runApp(const SmartChargeApp());
}

class SmartChargeApp extends StatelessWidget {
  const SmartChargeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Charge',
      theme: ThemeData.dark().copyWith(
        // Fondamentale: Apple usa il nero assoluto (OLED) o un grigio scurissimo
        scaffoldBackgroundColor: Colors.black,
        
        // Font principale: Inter (molto simile al San Francisco di iOS)
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.black.withOpacity(0.8), // Effetto semi-trasparente
          elevation: 0,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 17, // Dimensione standard Apple per AppBar
            fontWeight: FontWeight.w600, // Semi-bold elegante
            letterSpacing: -0.5, // Apple usa kerning stretto per un look premium
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.blueAccent), // Icone blu iOS
        ),
      ),
      home: const HomePage(),
    );
  }
}