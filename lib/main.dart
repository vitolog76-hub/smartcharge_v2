import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
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

  // 🔥 Inizializza le date in italiano
  await initializeDateFormatting('it_IT', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: Colors.blueAccent),
          ),
        ),
        home: Consumer<AuthProvider>(
          builder: (_, auth, __) {
            if (auth.isAuthenticated) {
              return ChangeNotifierProvider(
                create: (_) => HomeProvider()..init(),
                child: const HomePage(),
              );
            }
            return const LoginPage();
          },
        ),
      ),
    );
  }
}