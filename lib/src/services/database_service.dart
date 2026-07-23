import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/health_profile.dart';
import '../models/chat_session.dart';
import '../models/medication.dart';

class DatabaseService {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'aura_health.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            tc TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            password_hash TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE profiles (
            tc TEXT PRIMARY KEY,
            data TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE medications (
            id TEXT PRIMARY KEY,
            tc TEXT NOT NULL,
            data TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE chat_sessions (
            id TEXT PRIMARY KEY,
            tc TEXT NOT NULL,
            data TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS chat_sessions (
              id TEXT PRIMARY KEY,
              tc TEXT NOT NULL,
              data TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // --- Auth ---
  Future<bool> registerUser(String tc, String name, String password) async {
    final db = await database;
    final existing = await db.query('users', where: 'tc = ?', whereArgs: [tc]);
    if (existing.isNotEmpty) {
      return false; // User already exists
    }
    
    await db.insert('users', {
      'tc': tc,
      'name': name,
      'password_hash': _hashPassword(password),
    });
    return true;
  }

  Future<Map<String, dynamic>?> loginUser(String tc, String password) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'tc = ? AND password_hash = ?',
      whereArgs: [tc, _hashPassword(password)],
    );
    
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUser(String tc) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'tc = ?',
      whereArgs: [tc],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  // --- Profile ---
  Future<HealthProfile> loadProfile(String tc) async {
    final db = await database;
    final results = await db.query('profiles', where: 'tc = ?', whereArgs: [tc]);
    if (results.isEmpty) {
      final userResults = await db.query('users', where: 'tc = ?', whereArgs: [tc]);
      final name = userResults.isNotEmpty ? userResults.first['name'] as String : '';
      return HealthProfile.initial(name: name);
    }
    final data = results.first['data'] as String;
    return HealthProfile.fromJson(data);
  }

  Future<void> saveProfile(String tc, HealthProfile profile) async {
    final db = await database;
    await db.insert(
      'profiles',
      {
        'tc': tc,
        'data': profile.toJson(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Medications ---
  Future<List<Medication>> loadMedications(String tc) async {
    final db = await database;
    final results = await db.query('medications', where: 'tc = ?', whereArgs: [tc]);
    
    if (results.isEmpty) {
      return [];
    }
    
    return results.map((row) {
      final source = row['data'] as String;
      return Medication.fromMap(jsonDecode(source) as Map<String, dynamic>);
    }).toList();
  }

  Future<void> saveMedications(String tc, List<Medication> medications) async {
    final db = await database;
    // Clear old medications for this user
    await db.delete('medications', where: 'tc = ?', whereArgs: [tc]);
    
    // Insert new list
    final batch = db.batch();
    for (final med in medications) {
      batch.insert('medications', {
        'id': med.id,
        'tc': tc,
        'data': jsonEncode(med.toMap()),
      });
    }
    await batch.commit(noResult: true);
  }

  // --- Chat Sessions ---
  Future<List<ChatSession>> loadChatSessions(String tc) async {
    final db = await database;
    final results = await db.query('chat_sessions', where: 'tc = ?', whereArgs: [tc], orderBy: 'data');
    if (results.isEmpty) return [];
    
    return results.map((row) {
      final source = row['data'] as String;
      return ChatSession.fromJson(source);
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveChatSession(String tc, ChatSession session) async {
    final db = await database;
    await db.insert(
      'chat_sessions',
      {
        'id': session.id,
        'tc': tc,
        'data': session.toJson(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteChatSession(String tc, String sessionId) async {
    final db = await database;
    await db.delete('chat_sessions', where: 'tc = ? AND id = ?', whereArgs: [tc, sessionId]);
  }
}
