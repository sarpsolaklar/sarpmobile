import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_health_app/models/medication.dart';
import 'package:smart_health_app/models/activity.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const _webMedicationsKey = 'web_medications';
  static const _webMedicationLogsKey = 'web_medication_logs';
  static const _webActivitiesKey = 'web_activities';
  static const _webMedicationIdKey = 'web_medication_next_id';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('health_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await databaseFactory.getDatabasesPath();
    final path = join(dbPath, filePath);
    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE medications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  dosage TEXT NOT NULL,
  time TEXT NOT NULL,
  isDone INTEGER NOT NULL,
  notifyEnabled INTEGER NOT NULL DEFAULT 0
)
''');
    await db.execute('''
CREATE TABLE activities (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL UNIQUE,
  steps INTEGER NOT NULL DEFAULT 0,
  caloriesBurned INTEGER NOT NULL DEFAULT 0,
  exerciseMinutes INTEGER NOT NULL DEFAULT 0,
  notes TEXT NOT NULL DEFAULT ''
)
''');
    await db.execute('''
CREATE TABLE medication_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  medicationId INTEGER NOT NULL,
  date TEXT NOT NULL,
  isDone INTEGER NOT NULL DEFAULT 0,
  UNIQUE(medicationId, date)
)
''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add notifyEnabled column if upgrading from v1
      try {
        await db.execute(
          'ALTER TABLE medications ADD COLUMN notifyEnabled INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
      // Create activities table
      await db.execute('''
CREATE TABLE IF NOT EXISTS activities (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL UNIQUE,
  steps INTEGER NOT NULL DEFAULT 0,
  caloriesBurned INTEGER NOT NULL DEFAULT 0,
  exerciseMinutes INTEGER NOT NULL DEFAULT 0,
  notes TEXT NOT NULL DEFAULT ''
)
''');
    }
    if (oldVersion < 3) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS medication_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  medicationId INTEGER NOT NULL,
  date TEXT NOT NULL,
  isDone INTEGER NOT NULL DEFAULT 0,
  UNIQUE(medicationId, date)
)
''');
    }
  }

  // ── Medications ───────────────────────────────────────────────────────────

  Future<Medication> createMedication(Medication med) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final nextId = prefs.getInt(_webMedicationIdKey) ?? 1;
      final saved = med.copyWith(id: nextId);
      final meds = await readAllMedications();
      meds.add(saved);
      await _saveWebMedications(meds);
      await prefs.setInt(_webMedicationIdKey, nextId + 1);
      return saved;
    }

    final db = await instance.database;
    final id = await db.insert('medications', med.toMap());
    return med.copyWith(id: id);
  }

  Future<Medication> upsertMedication(Medication med) async {
    if (kIsWeb) {
      final existing = await readAllMedications();
      final index = existing.indexWhere((item) => item.id == med.id);
      if (index == -1) {
        final saved = med.id == null ? await createMedication(med) : med;
        if (med.id != null) {
          existing.add(saved);
          await _saveWebMedications(existing);
        }
        return saved;
      }
      existing[index] = med;
      await _saveWebMedications(existing);
      return med;
    }

    final db = await instance.database;
    if (med.id == null) return createMedication(med);
    await db.insert(
      'medications',
      med.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return med;
  }

  Future<List<Medication>> readAllMedications() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_webMedicationsKey);
      if (raw == null || raw.isEmpty) return [];
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final meds = list.map(Medication.fromMap).toList();
      meds.sort((a, b) => a.time.compareTo(b.time));
      return meds;
    }

    final db = await instance.database;
    final result = await db.query('medications', orderBy: 'time ASC');
    return result.map((json) => Medication.fromMap(json)).toList();
  }

  Future<List<Medication>> readMedicationsForDate(String date) async {
    final meds = await readAllMedications();
    final logs = await readMedicationLogsForDate(date);
    return meds
        .map((med) => med.copyWith(isDone: logs[med.id] ?? false))
        .toList();
  }

  Future<Map<int, bool>> readMedicationLogsForDate(String date) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_webMedicationLogsKey);
      if (raw == null || raw.isEmpty) return {};
      final logs = (jsonDecode(raw) as Map).cast<String, dynamic>();
      return {
        for (final entry in logs.entries)
          if (entry.key.startsWith('$date:'))
            int.parse(entry.key.split(':').last): entry.value == true,
      };
    }

    final db = await instance.database;
    final result = await db.query(
      'medication_logs',
      where: 'date = ?',
      whereArgs: [date],
    );
    return {
      for (final row in result)
        row['medicationId'] as int: (row['isDone'] as int) == 1,
    };
  }

  Future<void> setMedicationDoneForDate({
    required int medicationId,
    required String date,
    required bool isDone,
  }) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_webMedicationLogsKey);
      final logs = raw == null || raw.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(raw) as Map).cast<String, dynamic>();
      logs['$date:$medicationId'] = isDone;
      await prefs.setString(_webMedicationLogsKey, jsonEncode(logs));
      return;
    }

    final db = await instance.database;
    await db.insert('medication_logs', {
      'medicationId': medicationId,
      'date': date,
      'isDone': isDone ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateMedication(Medication med) async {
    if (kIsWeb) {
      final existing = await readAllMedications();
      final index = existing.indexWhere((item) => item.id == med.id);
      if (index == -1) return 0;
      existing[index] = med;
      await _saveWebMedications(existing);
      return 1;
    }

    final db = await instance.database;
    return db.update(
      'medications',
      med.toMap(),
      where: 'id = ?',
      whereArgs: [med.id],
    );
  }

  Future<int> deleteMedication(int id) async {
    if (kIsWeb) {
      final meds = await readAllMedications();
      final before = meds.length;
      meds.removeWhere((med) => med.id == id);
      await _saveWebMedications(meds);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_webMedicationLogsKey);
      if (raw != null && raw.isNotEmpty) {
        final logs = (jsonDecode(raw) as Map).cast<String, dynamic>();
        logs.removeWhere((key, value) => key.endsWith(':$id'));
        await prefs.setString(_webMedicationLogsKey, jsonEncode(logs));
      }
      return before - meds.length;
    }

    final db = await instance.database;
    await db.delete(
      'medication_logs',
      where: 'medicationId = ?',
      whereArgs: [id],
    );
    return await db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearHealthData() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_webMedicationsKey);
      await prefs.remove(_webMedicationLogsKey);
      await prefs.remove(_webActivitiesKey);
      await prefs.remove(_webMedicationIdKey);
      return;
    }

    final db = await instance.database;
    await db.delete('medication_logs');
    await db.delete('medications');
    await db.delete('activities');
  }

  // ── Activities ────────────────────────────────────────────────────────────

  Future<Activity> upsertActivity(Activity activity) async {
    if (kIsWeb) {
      final activities = await getRecentActivities(days: 3650);
      final index = activities.indexWhere((item) => item.date == activity.date);
      final saved = activity.copyWith(
        id: index == -1 ? activities.length + 1 : activities[index].id,
      );
      if (index == -1) {
        activities.add(saved);
      } else {
        activities[index] = saved;
      }
      await _saveWebActivities(activities);
      return saved;
    }

    final db = await instance.database;
    final existing = await db.query(
      'activities',
      where: 'date = ?',
      whereArgs: [activity.date],
    );
    if (existing.isEmpty) {
      final id = await db.insert('activities', activity.toMap());
      return activity.copyWith(id: id);
    } else {
      final id = existing.first['id'] as int;
      await db.update(
        'activities',
        activity.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      return activity.copyWith(id: id);
    }
  }

  Future<Activity?> getActivityByDate(String date) async {
    if (kIsWeb) {
      final activities = await getRecentActivities(days: 3650);
      for (final activity in activities) {
        if (activity.date == date) return activity;
      }
      return null;
    }

    final db = await instance.database;
    final result = await db.query(
      'activities',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (result.isEmpty) return null;
    return Activity.fromMap(result.first);
  }

  Future<List<Activity>> getRecentActivities({int days = 7}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_webActivitiesKey);
      if (raw == null || raw.isEmpty) return [];
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final activities = list.map(Activity.fromMap).toList();
      activities.sort((a, b) => b.date.compareTo(a.date));
      return activities.take(days).toList();
    }

    final db = await instance.database;
    final result = await db.query(
      'activities',
      orderBy: 'date DESC',
      limit: days,
    );
    return result.map((m) => Activity.fromMap(m)).toList();
  }

  Future<void> _saveWebMedications(List<Medication> medications) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _webMedicationsKey,
      jsonEncode(medications.map((med) => med.toMap()).toList()),
    );
  }

  Future<void> _saveWebActivities(List<Activity> activities) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _webActivitiesKey,
      jsonEncode(activities.map((activity) => activity.toMap()).toList()),
    );
  }
}
