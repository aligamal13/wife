import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'devices_manager.db');

    return await openDatabase(
      path,
      version: 3, // ✅ زدنا النسخة لـ 3 عشان نضيف رقم الهاتف
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            address TEXT,
            phone TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE devices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            name TEXT,
            ip TEXT,
            ssid TEXT,
            FOREIGN KEY(user_id) REFERENCES users(id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS devices (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER,
              name TEXT,
              ip TEXT,
              ssid TEXT,
              FOREIGN KEY(user_id) REFERENCES users(id)
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
        }
      },
    );
  }

  // User operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    final db = await database;
    return await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    await db.delete('devices', where: 'user_id = ?', whereArgs: [id]);
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // Device operations
  Future<int> insertDevice(Map<String, dynamic> device) async {
    final db = await database;
    return await db.insert('devices', device);
  }

  Future<List<Map<String, dynamic>>> getDevices(int userId) async {
    final db = await database;
    return await db.query(
      'devices',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateDevice(int id, Map<String, dynamic> device) async {
    final db = await database;
    return await db.update(
      'devices',
      device,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteDevice(int id) async {
    final db = await database;
    return await db.delete('devices', where: 'id = ?', whereArgs: [id]);
  }

  // Backup operations
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('devices');
    await db.delete('users');
  }

  Future<String> exportToJson() async {
    final db = await database;
    final users = await db.query('users');
    final devices = await db.query('devices');

    final data = {
      'users': users,
      'devices': devices,
    };

    return json.encode(data);
  }

  Future<void> importFromJson(String jsonData) async {
    final db = await database;
    final data = json.decode(jsonData) as Map<String, dynamic>;

    await clearAllData();

    final batch = db.batch();

    for (var user in data['users']) {
      batch.insert('users', user);
    }

    for (var device in data['devices']) {
      batch.insert('devices', device);
    }

    await batch.commit(noResult: true);
  }
}
