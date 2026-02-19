import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcharge_v2/services/sync_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  
  // 🔥 FLAG PER DIRE CHE I DATI SONO STATI SCARICATI
  bool _dataDownloaded = false;
  bool get dataDownloaded => _dataDownloaded;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  String? get userId => _user?.uid;
  String? get userEmail => _user?.email;
  String? get userName => _user?.displayName;

  AuthProvider() {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    _user = _auth.currentUser;
    notifyListeners();
    
    if (_user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_sync_id', _user!.uid);
      await _downloadUserData(_user!.uid);
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _dataDownloaded = false;
    notifyListeners();

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_sync_id', _user!.uid);
      
      await _downloadUserData(_user!.uid);
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String displayName) async {
    _isLoading = true;
    _errorMessage = null;
    _dataDownloaded = false;
    notifyListeners();

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();
      
      _user = _auth.currentUser;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_sync_id', _user!.uid);
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<void> _downloadUserData(String userId) async {
    debugPrint("☁️ Auto-download dati per: $userId");
    
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
          
          // 🔥 SEGNALA CHE I DATI SONO STATI SCARICATI
          _dataDownloaded = true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("❌ Errore download: $e");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _dataDownloaded = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_sync_id');
    
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email già registrata';
      case 'invalid-email':
        return 'Email non valida';
      case 'weak-password':
        return 'Password troppo debole (minimo 6 caratteri)';
      case 'user-not-found':
        return 'Utente non trovato';
      case 'wrong-password':
        return 'Password errata';
      case 'network-request-failed':
        return 'Errore di connessione';
      default:
        return 'Errore: $code';
    }
  }
}