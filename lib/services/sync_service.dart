import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:origo/models/charge_session.dart';
import 'package:origo/models/contract_model.dart';

class SyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Verifica esistenza ID (controlla il documento v2 nella subcollection)
  Future<bool> checkIfUserExists(String userId) async {
    if (userId.isEmpty) return false;
    try {
      DocumentSnapshot doc = await _db
          .collection("users")
          .doc(userId)
          .collection("versions")
          .doc("v2")
          .get();
      return doc.exists;
    } catch (e) {
      print("!!! ERRORE VERIFICA ID: $e");
      return false;
    }
  }

  // 2. Upload: Sincronizza tutto il pacchetto dati
  Future<void> uploadData(
    String userId, 
    List<ChargeSession> history, 
    List<EnergyContract> allContracts, 
    String activeContractId,
    String userName, 
  ) async {
    if (userId.isEmpty) return;

    try {
      // Trasformazione in mappe JSON (senza userName se hai già modificato il modello)
      List<Map<String, dynamic>> historyMap = history.map((s) => s.toJson()).toList();
      List<Map<String, dynamic>> contractsMap = allContracts.map((c) => c.toJson()).toList();

      // 🔥 SALVATAGGIO STRUTTURATO: Il nome è al livello dell'ID, non del contratto
      await _db.collection("users").doc(userId).collection("versions").doc("v2").set({
      'lastUpdate': FieldValue.serverTimestamp(), 
      'globalUserName': userName,
      'history': historyMap,
      'allContracts': contractsMap,
      'activeContractId': activeContractId,
    }, SetOptions(merge: true));

      print("✅ SYNC OK: Utente [$userName] aggiornato su Cloud con ID: $userId");
    } catch (e) {
      print("!!! ERRORE UPLOAD: $e");
    }
  }

  // 3. Download (Inalterato ma pronto per il nuovo schema)
  Future<Map<String, dynamic>?> downloadAllData(String userId) async {
    if (userId.isEmpty) return null;
    try {
      DocumentSnapshot doc = await _db
          .collection("users")
          .doc(userId)
          .collection("versions")
          .doc("v2")
          .get();
      
      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("!!! ERRORE DOWNLOAD: $e");
      return null;
    }
  }
}