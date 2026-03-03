import 'package:flowchat/models/recent_chat.dart';
import '../models/user.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ChatDb {
  static final ChatDb _instance = ChatDb._internal();
  factory ChatDb() => _instance;
  ChatDb._internal();
  Database? _db;

  Future<void> init() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'chat_app.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute("DROP TABLE IF EXISTS messages");
      await db.execute('''
          CREATE TABLE recent_chats (
            contactNo TEXT PRIMARY KEY,
            name TEXT,
            lastMessage TEXT,
            timestamp INTEGER,
            profileImage TEXT
          )
        ''');
    });
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    await init();
    return _db!;
  }
  Future<void> upsertChat(RecentChat chat) async {
    final db = await database;
    await db.insert(
      'recent_chats',
      chat.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
}
