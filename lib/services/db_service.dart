import 'package:flowchat/models/my_account.dart';
import 'package:flowchat/models/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat_message.dart';

class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  Database? _db;

  Future<void> init() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'chat_app.db');
    _db = await openDatabase(
      path,
      version: 5, // bump version if adding new table
      onCreate: (db, version) async {
        // Messages table
        await db.execute('''
        CREATE TABLE IF NOT EXISTS messages (
          id TEXT PRIMARY KEY,
          receiverId TEXT,
          senderId TEXT,
          content TEXT,
          timestamp TEXT,
          status TEXT
        )
      ''');

        // Recent chats table
        await db.execute('''
        CREATE TABLE IF NOT EXISTS recent_chats (
          contactNo TEXT PRIMARY KEY,
          name TEXT,
          lastMessage TEXT,
          timestamp INTEGER,
          profileImage TEXT
        )
      ''');

        // MyAccount table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS my_account (
            contactNo TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            about TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < newVersion) {
          // Add recent_chats table if upgrading from <4
          await db.execute('''
          CREATE TABLE IF NOT EXISTS recent_chats (
            contactNo TEXT PRIMARY KEY,
            name TEXT,
            lastMessage TEXT,
            timestamp INTEGER,
            profileImage TEXT
          )
        ''');

          // Add my_account table if upgrading from <4
          await db.execute('''
          CREATE TABLE IF NOT EXISTS my_account (
            contactNo TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            about TEXT
          )
        ''');
        }
      },
    );
  }


  Future<Database> get database async {
    if (_db != null) return _db!;
    await init();
    return _db!;
  }

  Future<void> insertMessage(ChatMessage m) async {
    final db = await database;
    await db.insert('messages', m.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveMyAccount(MyAccount account) async {
    debugPrint("saving account ${account.toJson()}");
    final db = await database;
    await db.insert('my_account', account.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChatMessage>> getMessages(String senderId) async {
    final db = await database;
    final rows = await db.query('messages', where: 'senderId = ? or receiverId=?', whereArgs: [senderId,senderId]);
    return rows.map((r) => ChatMessage.fromMap(r)).toList();
  }

  Future<List<ChatMessage>> getAllMessages() async {
    final db = await database;
    final rows = await db.query('messages',orderBy: 'timestamp ASC');
    return rows.map((r) => ChatMessage.fromMap(r)).toList();
  }
  Future<void> updateMessageStatus(String messageId, String status) async {
    debugPrint('Updating message status: $messageId to $status');
    final db = await database;
    await db.update(
      'messages',
      {'status': status},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }
  Future<void> listAllTables() async {
    final db = await database;

    // Query sqlite master table to get all user-created tables
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;"
    );

    for (var t in tables) {
      debugPrint("Table: ${t['name']}");
    }
  }
  Future<List<User>> getChats() async {
    final db = await database;
    final result = await db.query(
      'recent_chats',
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => User.fromJson(map)).toList();
  }

  Future<void> clearRecentChats() async {
    final db = await database;
    await db.delete('recent_chats');
  }
  Future<List<MyAccount>> getMyAccount(String contactNo) async {
    final db = await database;
    final result = await db.query(
      'my_account',
      where: 'contactNo = ?',
      whereArgs: [contactNo],
    );
    debugPrint("result=$result");
    return result.map((map) => MyAccount.fromJson(map)).toList();
  }
  Future<List<MyAccount>> getAllMyAccount() async {
    final db = await database;
    final result = await db.query('my_account',);
    return result.map((map) => MyAccount.fromJson(map)).toList();
  }

  Future<void> clearMyAccount() async {
    final db = await database;
    await db.delete('my_account');
    debugPrint("my_account table cleared.");
  }
}
