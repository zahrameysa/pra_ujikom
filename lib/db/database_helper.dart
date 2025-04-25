import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/history_model.dart';
import '../models/check_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'absensi_ppkd.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        date TEXT,
        check_in TEXT,
        check_out TEXT,
        location TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE check_model (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        check_in TEXT,
        check_in_location TEXT,
        check_in_address TEXT,
        check_out TEXT,
        check_out_location TEXT,
        check_out_address TEXT,
        status TEXT,
        created_at TEXT,
        updated_at TEXT,
        check_in_lat REAL,
        check_in_lng REAL,
        check_out_lat REAL,
        check_out_lng REAL
      )
    ''');
  }

  // Insert User
  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  // Ambil user berdasarkan email & password (login)
  Future<UserModel?> getUserByEmailAndPassword(
    String email,
    String password,
  ) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  // Ambil user berdasarkan ID
  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  // Update user
  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Ambil user yang sedang login berdasarkan ID dari shared_preferences
  Future<UserModel?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return null;
    return await getUserById(userId);
  }

  // Insert History
  Future<int> insertHistory(HistoryModel history) async {
    final db = await database;
    return await db.insert('history', history.toMap());
  }

  // Get History by User ID
  Future<List<HistoryModel>> getHistoryByUserId(int userId) async {
    final db = await database;
    final result = await db.query(
      'history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return result.map((e) => HistoryModel.fromMap(e)).toList();
  }

  // Insert CheckModel
  Future<int> insertCheck(CheckModel check) async {
    final db = await database;
    return await db.insert('check_model', check.toMap());
  }

  // Get All CheckModel by User
  Future<List<CheckModel>> getChecksByUserId(int userId) async {
    final db = await database;
    final result = await db.query(
      'check_model',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return result.map((e) => CheckModel.fromMap(e)).toList();
  }

  // Update Check-Out Time
  Future<int> updateCheckOut(int id, String checkOut, String checkOutAddress, String checkOutLocation, double lat, double lng) async {
    final db = await database;
    return await db.update(
      'check_model',
      {
        'check_out': checkOut,
        'check_out_address': checkOutAddress,
        'check_out_location': checkOutLocation,
        'check_out_lat': lat,
        'check_out_lng': lng,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
