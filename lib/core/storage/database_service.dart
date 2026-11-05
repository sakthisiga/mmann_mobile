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
      version: 6,
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

        await _createPlotsTable(db);
        await _createDocumentsTable(db);
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
        if (oldVersion < 4) {
          try {
            await _createPlotsTable(db);
          } catch (_) {}
        }
        if (oldVersion < 5) {
          try {
            await _createDocumentsTable(db);
          } catch (_) {}
        }
        if (oldVersion < 6) {
          try {
            await db.execute(
                'ALTER TABLE farm_documents ADD COLUMN file_data_url TEXT');
          } catch (_) {}
        }
      },
    );
  }

  static Future<void> _createPlotsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS plots (
        id TEXT PRIMARY KEY,
        farm_id TEXT NOT NULL,
        name TEXT NOT NULL,
        survey_number TEXT,
        sub_division_number TEXT,
        patta_number TEXT,
        area_sqm REAL,
        entered_area REAL,
        entered_unit TEXT,
        soil_type TEXT,
        irrigation_source TEXT,
        tenure_type TEXT DEFAULT 'owned',
        lessor_name TEXT,
        lessor_mobile TEXT,
        annual_rent_inr REAL,
        crop_share_pct REAL,
        notes TEXT,
        rev INTEGER DEFAULT 1,
        updated_at TEXT
      )
    ''');
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
      await db.delete('plots');
      await db.delete('farm_documents');
    } catch (_) {}
  }

  static Future<void> _createDocumentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS farm_documents (
        id TEXT PRIMARY KEY,
        farm_id TEXT NOT NULL,
        plot_id TEXT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        document_number TEXT,
        issued_by TEXT,
        issue_date TEXT,
        expiry_date TEXT,
        renewal_status TEXT,
        days_until_expiry INTEGER,
        file_name TEXT,
        mime_type TEXT,
        file_size_bytes INTEGER,
        file_data_url TEXT,
        notes TEXT,
        rev INTEGER DEFAULT 1,
        updated_at TEXT
      )
    ''');
  }

  static Future<void> cacheDocuments(List<Map<String, dynamic>> docs) async {
    try {
      final db = await database;
      final batch = db.batch();
      batch.delete('farm_documents');
      for (final d in docs) {
        batch.insert('farm_documents', d, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> getCachedDocuments() async {
    try {
      final db = await database;
      return await db.query('farm_documents', orderBy: 'updated_at DESC');
    } catch (_) {
      return [];
    }
  }

  static Future<void> cachePlots(List<Map<String, dynamic>> plots) async {
    try {
      final db = await database;
      final batch = db.batch();
      batch.delete('plots');
      for (final plot in plots) {
        batch.insert('plots', plot, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> getCachedPlots() async {
    try {
      final db = await database;
      return await db.query('plots', orderBy: 'name ASC');
    } catch (_) {
      return [];
    }
  }
}
