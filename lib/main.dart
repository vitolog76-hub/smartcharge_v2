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
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Ignora
  }

  try {
    if (kIsWeb) {
      // Per Vercel - prende le chiavi dalle environment variables
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: const String.fromEnvironment('FIREBASE_API_KEY'), // ✅ CORRETTO!
          authDomain: const String.fromEnvironment('FIREBASE_AUTH_DOMAIN', 
              defaultValue: 'smartcharge-c5b34.firebaseapp.com'),
          projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID',
              defaultValue: 'smartcharge-c5b34'),
          storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET',
              defaultValue: 'smartcharge-c5b34.firebasestorage.app'),
          messagingSenderId: const String.fromEnvironment('FIREBASE_SENDER_ID',
              defaultValue: '25947690562'),
          appId: const String.fromEnvironment('FIREBASE_APP_ID',
              defaultValue: '1:25947690562:web:613953180d63919a677fdb'),
          measurementId: const String.fromEnvironment('FIREBASE_MEASUREMENT_ID',
              defaultValue: 'G-R35N994658'),
        ),
      );
    } else {
      // Per mobile - usa i file google-services.json e GoogleService-Info.plist
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint("Firebase error: $e");
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