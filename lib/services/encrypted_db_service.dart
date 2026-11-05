import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class EncryptedDbService {
  Database? _db;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _keyAlias = 'jarvis_sqlcipher_aes256_key';

  Future<void> initDb() async {
    if (_db != null) return;

    String? passphrase = await _secureStorage.read(key: _keyAlias);
    if (passphrase == null) {
      final randomBytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      passphrase = base64UrlEncode(randomBytes);
      await _secureStorage.write(key: _keyAlias, value: passphrase);
    }

    final dbPath = join(await getDatabasesPath(), 'jarvis_topg_vault.db');
    _db = await openDatabase(
      dbPath,
      password: passphrase,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user_preferences (
            pref_key TEXT PRIMARY KEY,
            pref_value TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE command_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            command TEXT NOT NULL,
            response TEXT NOT NULL,
            language TEXT NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        await db.insert('user_preferences', {
          'pref_key': 'favorite_song',
          'pref_value': 'Tujhe Kitna Chahne Lage',
        });
      },
    );
  }

  Future<String?> getFavoriteSong() async {
    final rows = await _db?.query(
      'user_preferences',
      where: 'pref_key = ?',
      whereArgs: ['favorite_song'],
    );
    if (rows != null && rows.isNotEmpty) {
      return rows.first['pref_value'] as String;
    }
    return null;
  }

  Future<void> logCommand(String command, String response, String lang) async {
    await _db?.insert('command_logs', {
      'command': command,
      'response': response,
      'language': lang,
    });
  }
}
