import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mmann_offline.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE farms (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            village TEXT,
            taluk TEXT,
            district TEXT,
            state_code TEXT,
            pincode TEXT,
            total_area_sqm REAL,
            entered_area REAL,
            entered_unit TEXT,
            is_primary INTEGER DEFAULT 0,
            notes TEXT,
            rev INTEGER DEFAULT 1,
            created_at TEXT,
            updated_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE user_profile (
            id TEXT PRIMARY KEY,
            mobile TEXT NOT NULL,
            display_name TEXT,
            state_code TEXT,
            language TEXT,
            age INTEGER,
            active_org_id TEXT,
            role TEXT,
            village TEXT,
            district TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE user_profile ADD COLUMN village TEXT');
            await db.execute('ALTER TABLE user_profile ADD COLUMN district TEXT');
          } catch (_) {}
        }
        if (oldVersion < 3) {
          try {
            await db.execute('ALTER TABLE user_profile ADD COLUMN age INTEGER');
          } catch (_) {}
        }
      },
    );
  }

  static Future<void> cacheFarms(List<Map<String, dynamic>> farms) async {
    try {
      final db = await database;
      final batch = db.batch();
      batch.delete('farms');
      for (final farm in farms) {
        batch.insert('farms', farm, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      // Non-critical cache warning
    }
  }

  static Future<List<Map<String, dynamic>>> getCachedFarms() async {
    try {
      final db = await database;
      return await db.query('farms', orderBy: 'is_primary DESC, name ASC');
    } catch (_) {
      return [];
    }
  }

  static Future<void> cacheUserProfile(Map<String, dynamic> user) async {
    try {
      final db = await database;
      await db.delete('user_profile');
      await db.insert('user_profile', user,
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // Non-critical cache warning
    }
  }

  static Future<Map<String, dynamic>?> getCachedUserProfile() async {
    try {
      final db = await database;
      final list = await db.query('user_profile', limit: 1);
      if (list.isNotEmpty) return list.first;
    } catch (_) {}
    return null;
  }

  static Future<void> clearFarms() async {
    try {
      final db = await database;
      await db.delete('farms');
    } catch (_) {}
  }

  static Future<void> clearAll() async {
    try {
      final db = await database;
      await db.delete('farms');
      await db.delete('user_profile');
    } catch (_) {}
  }
}
