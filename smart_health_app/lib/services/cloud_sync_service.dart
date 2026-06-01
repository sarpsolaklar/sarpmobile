import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_health_app/database/database_helper.dart';
import 'package:smart_health_app/models/activity.dart';
import 'package:smart_health_app/models/medication.dart';
import 'package:smart_health_app/services/profile_service.dart';

class CloudSyncService {
  static final CloudSyncService instance = CloudSyncService._init();

  CloudSyncService._init();

  CollectionReference<Map<String, dynamic>>? get _userRoot {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('data');
  }

  Future<void> syncMedication(Medication medication) async {
    final root = _userRoot;
    final id = medication.id;
    if (root == null || id == null) return;

    try {
      await root.doc('medications').collection('items').doc('$id').set({
        ...medication.toMap(),
        'localId': id,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Cloud medication sync failed: $e');
    }
  }

  Future<void> pullFromCloud() async {
    final root = _userRoot;
    if (root == null) return;

    try {
      await _pullMedications(root);
      await _pullMedicationLogs(root);
      await _pullActivities(root);
      await _pullProfile(root);
    } catch (e) {
      debugPrint('Cloud pull failed: $e');
    }
  }

  Future<void> deleteMedication(int medicationId) async {
    final root = _userRoot;
    if (root == null) return;

    try {
      await root
          .doc('medications')
          .collection('items')
          .doc('$medicationId')
          .delete();
    } catch (e) {
      debugPrint('Cloud medication delete failed: $e');
    }
  }

  Future<void> syncMedicationLog({
    required int medicationId,
    required String date,
    required bool isDone,
  }) async {
    final root = _userRoot;
    if (root == null) return;

    try {
      await root
          .doc('medication_logs')
          .collection('items')
          .doc('${date}_$medicationId')
          .set({
            'medicationId': medicationId,
            'date': date,
            'isDone': isDone,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Cloud medication log sync failed: $e');
    }
  }

  Future<void> syncActivity(Activity activity) async {
    final root = _userRoot;
    if (root == null) return;

    try {
      await root.doc('activities').collection('items').doc(activity.date).set({
        ...activity.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Cloud activity sync failed: $e');
    }
  }

  Future<void> syncProfile(Map<String, String> profile) async {
    final root = _userRoot;
    if (root == null) return;

    try {
      await root.doc('profile').set({
        ...profile,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Cloud profile sync failed: $e');
    }
  }

  Future<void> deleteCloudData() async {
    final root = _userRoot;
    if (root == null) return;

    try {
      await _deleteCollection(root.doc('medications').collection('items'));
      await _deleteCollection(root.doc('medication_logs').collection('items'));
      await _deleteCollection(root.doc('activities').collection('items'));
      await root.doc('profile').delete();
    } catch (e) {
      debugPrint('Cloud data delete failed: $e');
    }
  }

  Future<void> _pullMedications(
    CollectionReference<Map<String, dynamic>> root,
  ) async {
    final snapshot = await root.doc('medications').collection('items').get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final id = _readInt(data['localId']) ?? _readInt(data['id']);
      if (id == null) continue;
      await DatabaseHelper.instance.upsertMedication(
        Medication(
          id: id,
          name: (data['name'] ?? '').toString(),
          dosage: (data['dosage'] ?? '').toString(),
          time: (data['time'] ?? '').toString(),
          isDone: data['isDone'] == 1 || data['isDone'] == true,
          notifyEnabled:
              data['notifyEnabled'] == 1 || data['notifyEnabled'] == true,
        ),
      );
    }
  }

  Future<void> _pullMedicationLogs(
    CollectionReference<Map<String, dynamic>> root,
  ) async {
    final snapshot = await root
        .doc('medication_logs')
        .collection('items')
        .get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final medicationId = _readInt(data['medicationId']);
      final date = data['date']?.toString();
      if (medicationId == null || date == null || date.isEmpty) continue;
      await DatabaseHelper.instance.setMedicationDoneForDate(
        medicationId: medicationId,
        date: date,
        isDone: data['isDone'] == true || data['isDone'] == 1,
      );
    }
  }

  Future<void> _pullActivities(
    CollectionReference<Map<String, dynamic>> root,
  ) async {
    final snapshot = await root.doc('activities').collection('items').get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final date = data['date']?.toString();
      if (date == null || date.isEmpty) continue;
      await DatabaseHelper.instance.upsertActivity(
        Activity(
          id: _readInt(data['id']),
          date: date,
          steps: _readInt(data['steps']) ?? 0,
          caloriesBurned: _readInt(data['caloriesBurned']) ?? 0,
          exerciseMinutes: _readInt(data['exerciseMinutes']) ?? 0,
          notes: (data['notes'] ?? '').toString(),
        ),
      );
    }
  }

  Future<void> _pullProfile(
    CollectionReference<Map<String, dynamic>> root,
  ) async {
    final doc = await root.doc('profile').get();
    final data = doc.data();
    if (data == null) return;

    await ProfileService.instance.saveProfile(
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      age: (data['age'] ?? '').toString(),
      weight: (data['weight'] ?? '').toString(),
      height: (data['height'] ?? '').toString(),
    );
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final snapshot = await collection.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
