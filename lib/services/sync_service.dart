import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:smartcharge_v2/models/charge_session.dart';
import 'package:smartcharge_v2/models/contract_model.dart';

class SyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Verifica se l'ID esiste (Cerca nel documento principale dell'utente)
  Future<bool> checkIfUserExists(String userId) async {
    if (userId.isEmpty) return false;
    try {
      print("DEBUG SYNC: Verifica esistenza utente $userId...");
      DocumentSnapshot doc = await _db.collection("users").doc(userId).get();
      return doc.exists;
    } catch (e) {
      print("!!! ERRORE VERIFICA ID: $e");
      return false;
    }
  }

  // 2. Upload: Carica Cronologia e Contratto su Firestore
  Future<void> uploadData(String userId, List<ChargeSession> history, EnergyContract contract) async {
    print("--- INIZIO UPLOAD SYNC ---");
    if (userId.isEmpty) {
      print("DEBUG SYNC: ID Utente vuoto, annullo upload.");
      return;
    }

    try {
      // Prepariamo i dati
      List<Map<String, dynamic>> historyMap = history.map((s) => s.toJson()).toList();
      Map<String, dynamic> contractMap = contract.toJson();

      print("DEBUG SYNC: Preparazione dati per $userId...");
      print("DEBUG SYNC: Sessioni da inviare: ${historyMap.length}");
      print("DEBUG SYNC: Dati contratto: $contractMap");

      // Scrittura su Firestore (Percorso: users/ID/versions/v2)
      await _db
          .collection("users")
          .doc(userId)
          .collection("versions")
          .doc("v2")
          .set({
            'lastUpdate': FieldValue.serverTimestamp(),
            'history': historyMap,
            'contract': contractMap,
          }, SetOptions(merge: true));

      // Aggiorniamo anche il timestamp nell'anagrafica principale
      await _db.collection("users").doc(userId).set({
        'active': true,
        'lastAccess': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("--- SYNC COMPLETATO CON SUCCESSO SU FIREBASE ---");
    } catch (e) {
      print("!!! ERRORE CRITICO UPLOAD: $e");
      // Se vedi "Permission Denied" qui, devi cambiare le Rules su Firebase Console
    }
  }

  // 3. Download: Scarica tutto il pacchetto (Contratto + Cronologia)
  Future<Map<String, dynamic>?> downloadAllData(String userId) async {
    print("--- INIZIO DOWNLOAD SYNC ---");
    if (userId.isEmpty) return null;

    try {
      print("DEBUG SYNC: Recupero documento v2 per $userId...");
      DocumentSnapshot doc = await _db
          .collection("users")
          .doc(userId)
          .collection("versions")
          .doc("v2")
          .get();
      
      if (doc.exists && doc.data() != null) {
        print("DEBUG SYNC: Dati ricevuti correttamente!");
        return doc.data() as Map<String, dynamic>;
      } else {
        print("DEBUG SYNC: Documento v2 non trovato o vuoto su Firebase.");
        return null;
      }
    } catch (e) {
      print("!!! ERRORE CRITICO DOWNLOAD: $e");
      return null;
    }
  }
}