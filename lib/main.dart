import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartcharge_v2/providers/auth_provider.dart';
import 'package:smartcharge_v2/providers/home_provider.dart';
import 'package:smartcharge_v2/screens/login_page.dart';
import 'package:smartcharge_v2/screens/home_page.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Charge',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            backgroundColor: Colors.black.withOpacity(0.8),
            elevation: 0,
            titleTextStyle: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
            iconTheme: const IconThemeData(color: Colors.blueAccent),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (authProvider.isAuthenticated) {
          // 🔥 SE I DATI NON SONO ANCORA STATI SCARICATI, MOSTRA UN LOADING
          if (!authProvider.dataDownloaded) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      "Caricamento dati...",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // 🔥 DATI SCARICATI, MOSTRA LA HOME
          return ChangeNotifierProvider(
            create: (_) => HomeProvider()..init(),
            child: const HomePage(),
          );
        }
        
        return const LoginPage();
      },
    );
  }
}