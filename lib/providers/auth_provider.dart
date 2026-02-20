import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:smartcharge_v2/services/sync_service.dart';
import 'package:smartcharge_v2/models/contract_model.dart';

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
        // 🔥 Scarica i dati dal cloud appena l'utente si logga
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
      
      // 🔥 Scarica i dati dopo il login
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
      
      // 🔥 Crea dati iniziali per il nuovo utente
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
      provider: "Gestore",
      userName: displayName,
      f1Price: 0.20,
      f2Price: 0.18,
      f3Price: 0.15,
      isMonorario: false,
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('energy_contract', jsonEncode(defaultContract.toJson()));
    await prefs.setString('charge_history', jsonEncode([]));
    
    await SyncService().uploadData(userId, [], defaultContract);
  }

  Future<void> _downloadUserData(String userId) async {
    debugPrint("☁️ Download dati per utente: $userId");
    
    try {
      bool exists = await SyncService().checkIfUserExists(userId);
      
      if (exists) {
        var data = await SyncService().downloadAllData(userId);
        
        if (data != null) {
          final prefs = await SharedPreferences.getInstance();
          
          if (data['history'] != null) {
            await prefs.setString('charge_history', jsonEncode(data['history']));
            debugPrint("✅ Storico scaricato: ${(data['history'] as List).length} sessioni");
          }
          
          if (data['contract'] != null) {
            await prefs.setString('energy_contract', jsonEncode(data['contract']));
            debugPrint("✅ Contratto scaricato");
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Errore download: $e");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();  // Pulisce TUTTI i dati locali
  }
}