import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:origo/services/sync_service.dart';
import 'package:origo/models/contract_model.dart';

class AuthProvider extends ChangeNotifier {
  String? _userId;
  bool _isLoading = true;  // Inizia in caricamento
  String? _error;
  
  String? get userId => _userId;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _userId != null && _userId!.isNotEmpty;
  String? get error => _error;
  
  // 🔥 ID FISSO DELL'APP
  static const String FIXED_USER_ID = 'FaDG28xyaATUZR4J21kYO265uFm2';

  // Costruttore - avvia l'inizializzazione
  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Forza l'ID fisso
      _userId = FIXED_USER_ID;
      await prefs.setString('user_sync_id', _userId!);
      
      debugPrint('✅ Utente inizializzato con ID fisso: $_userId');
      
      // Carica i dati esistenti da Firestore
      await _downloadUserData(_userId!);
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Errore init AuthProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _downloadUserData(String userId) async {
    debugPrint("☁️ Download dati per utente: $userId");

    try {
      bool exists = await SyncService().checkIfUserExists(userId);

      if (exists) {
        var data = await SyncService().downloadAllData(userId);

        if (data != null) {
          final prefs = await SharedPreferences.getInstance();

          if (data['globalUserName'] != null) {
            await prefs.setString('global_user_name', data['globalUserName']);
            debugPrint("✅ Nome globale scaricato: ${data['globalUserName']}");
          }

          if (data['history'] != null) {
            await prefs.setString(
              'charge_history',
              jsonEncode(data['history']),
            );
          }

          if (data['allContracts'] != null) {
            await prefs.setString(
              'energy_contracts_list',
              jsonEncode(data['allContracts']),
            );
          }

          if (data['activeContractId'] != null) {
            await prefs.setString(
              'active_contract_id',
              data['activeContractId'],
            );
          }
        }
      } else {
        debugPrint("📝 Nessun dato esistente su Firestore per l'utente");
      }
    } catch (e) {
      debugPrint("❌ Errore download: $e");
    }
  }

  // Metodo per forzare il salvataggio dei dati su Firestore
  Future<void> syncToCloud() async {
    if (_userId == null || _userId!.isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getString('charge_history') ?? '[]';
      final contracts = prefs.getString('energy_contracts_list') ?? '[]';
      final activeContractId = prefs.getString('active_contract_id') ?? '';
      final userName = prefs.getString('global_user_name') ?? 'Utente';
      
      await SyncService().uploadData(
        _userId!,
        jsonDecode(history),
        (jsonDecode(contracts) as List).map((c) => EnergyContract.fromJson(c)).toList(),
        activeContractId,
        userName,
      );
      debugPrint('✅ Dati sincronizzati su Firestore');
    } catch (e) {
      debugPrint('❌ Errore sincronizzazione: $e');
    }
  }

  Future<void> signOut() async {
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
    
    _userId = null;
    notifyListeners();
    
    // Riavvia l'init
    await _init();
  }
}