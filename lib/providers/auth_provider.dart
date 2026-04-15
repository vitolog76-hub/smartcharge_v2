import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:origo/services/sync_service.dart';
import 'package:origo/models/contract_model.dart';
import 'package:google_sign_in/google_sign_in.dart'; // 🔥 IMPORT AGGIUNTO

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get userId => _user?.uid;
  String? get userEmail => _user?.email;
  String? get userName => _user?.displayName;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_sync_id', user.uid);
        await _downloadUserData(user.uid);
      }
      notifyListeners();
    });
  }

  Future<String?> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_sync_id', userCredential.user!.uid);
      
      await _downloadUserData(userCredential.user!.uid);
      
      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    }
  }

  // 🔥 METODO PER LOGIN CON GOOGLE (AGGIUNTO)
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_sync_id', userCredential.user!.uid);
      
      await _downloadUserData(userCredential.user!.uid);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> signUp(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      await userCredential.user?.updateDisplayName(name);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_sync_id', userCredential.user!.uid);
      
      await _createInitialUserData(userCredential.user!.uid, name);
      
      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    }
  }

  Future<void> _createInitialUserData(String userId, String displayName) async {
    debugPrint("🆕 Creazione dati iniziali per nuovo utente: $displayName");
    
    final defaultContract = EnergyContract(
      id: "default_contract_${DateTime.now().millisecondsSinceEpoch}", 
      contractName: "Contratto Base",
      provider: "Esempio",
      // userName: displayName, // Possiamo anche smettere di passarlo qui se vuoi pulire il modello
      f1Price: 0.20,
      f2Price: 0.18,
      f3Price: 0.15,
      isMonorario: false,
    );
    
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Salviamo il nome globale nelle SharedPreferences (quello che userà HomeProvider)
    await prefs.setString('global_user_name', displayName);
    
    // 2. Salvataggio locale MacBook
    await prefs.setString('energy_contracts_list', jsonEncode([defaultContract.toJson()]));
    await prefs.setString('active_contract_id', defaultContract.id);
    await prefs.setString('charge_history', jsonEncode([]));
    
    // 🔥 FIX: Passiamo i 5 argomenti richiesti dal nuovo SyncService
    await SyncService().uploadData(
      userId,               // 1. ID Utente
      [],                   // 2. History vuota
      [defaultContract],    // 3. Lista con il contratto di default
      defaultContract.id,   // 4. ID del contratto attivo
      displayName           // 5. Nome Globale (Aggiunto!)
    );
  }

  Future<void> _downloadUserData(String userId) async {
    debugPrint("☁️ Download dati per utente: $userId");
    
    try {
      bool exists = await SyncService().checkIfUserExists(userId);
      
      if (exists) {
        var data = await SyncService().downloadAllData(userId);
        
        if (data != null) {
          final prefs = await SharedPreferences.getInstance();
          
          // --- RECUPERO NOME GLOBALE DAL CLOUD ---
          if (data['globalUserName'] != null) {
            await prefs.setString('global_user_name', data['globalUserName']);
            debugPrint("✅ Nome globale scaricato: ${data['globalUserName']}");
          }
          
          if (data['history'] != null) {
            await prefs.setString('charge_history', jsonEncode(data['history']));
          }
          
          if (data['allContracts'] != null) {
            await prefs.setString('energy_contracts_list', jsonEncode(data['allContracts']));
          }

          if (data['activeContractId'] != null) {
            await prefs.setString('active_contract_id', data['activeContractId']);
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Errore download: $e");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    
    // Cancella solo i dati utente, preserva impostazioni dispositivo
    // (auto selezionata, chimica batteria, potenza wallbox, orari, ecc.)
    final prefs = await SharedPreferences.getInstance();
    final userKeys = [
      'user_sync_id',
      'global_user_name',
      'charge_history',
      'energy_contracts_list',
      'active_contract_id',
      'last_local_update',
      'soc_iniziale_congelato',
      'timestamp_inizio_congelato',
      'frozen_start_time',
      'simulation_active',
      'simulation_start',
      'simulation_end',
      'simulation_start_soc',
    ];
    for (final key in userKeys) {
      await prefs.remove(key);
    }
  }
}