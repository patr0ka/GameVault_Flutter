import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../model/game_model.dart';

class GameHelper {
  GameHelper._internal();

  static final GameHelper _instance = GameHelper._internal();

  factory GameHelper() => _instance;

  Database? _db;

  String get _userId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Faça login para acessar sua biblioteca.');
    }
    return user.uid;
  }

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final databaseFolder = await getDatabasesPath();
    final databasePath = p.join(databaseFolder, 'game_vault.db');

    return openDatabase(
      databasePath,
      version: 3,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE $gameTable (
            $gameIdColumn INTEGER PRIMARY KEY AUTOINCREMENT,
            $gameUserIdColumn TEXT NOT NULL,
            $gameRawgIdColumn INTEGER,
            $gameNameColumn TEXT NOT NULL,
            $gameStatusColumn TEXT NOT NULL,
            $gameImageColumn TEXT,
            $gameCreatedAtColumn INTEGER NOT NULL,
            $gameUpdatedAtColumn INTEGER NOT NULL,
            $gameRemoteIdColumn TEXT,
            $gameSyncedColumn INTEGER NOT NULL DEFAULT 0,
            $gameDeletedAtColumn INTEGER,
            $gameStartedAtColumn INTEGER,
            $gameCompletedAtColumn INTEGER
          )
        ''');
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute(
            'ALTER TABLE $gameTable ADD COLUMN $gameRemoteIdColumn TEXT',
          );
          await database.execute(
            'ALTER TABLE $gameTable ADD COLUMN '
            '$gameSyncedColumn INTEGER NOT NULL DEFAULT 0',
          );
          await database.execute(
            'ALTER TABLE $gameTable ADD COLUMN $gameDeletedAtColumn INTEGER',
          );
        }
        if (oldVersion < 3) {
          await database.execute(
            'ALTER TABLE $gameTable ADD COLUMN $gameStartedAtColumn INTEGER',
          );
          await database.execute(
            'ALTER TABLE $gameTable ADD COLUMN $gameCompletedAtColumn INTEGER',
          );
        }
      },
    );
  }

  Future<int> saveGame(Game game) async {
    final userId = _userId;
    if (game.userId != userId) {
      throw StateError('O jogo pertence a outra conta.');
    }
    _validate(game);

    final now = DateTime.now().millisecondsSinceEpoch;
    game
      ..createdAt ??= now
      ..updatedAt = now
      ..synced = false
      ..deletedAt = null;

    final data = game.toMap()..remove(gameIdColumn);
    final id = await (await db).insert(gameTable, data);
    game.id = id;
    return id;
  }

  Future<Game?> getGame(int id) async {
    final rows = await (await db).query(
      gameTable,
      where: '$gameIdColumn = ? AND $gameUserIdColumn = ?',
      whereArgs: [id, _userId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return Game.fromMap(rows.first);
  }

  Future<List<Game>> getAllGames() async {
    final rows = await (await db).query(
      gameTable,
      where: '$gameUserIdColumn = ? AND $gameDeletedAtColumn IS NULL',
      whereArgs: [_userId],
      orderBy: '$gameNameColumn COLLATE NOCASE ASC',
    );

    return rows.map(Game.fromMap).toList();
  }

  Future<List<Game>> getPendingGames() async {
    final rows = await (await db).query(
      gameTable,
      where: '$gameUserIdColumn = ? AND $gameSyncedColumn = 0',
      whereArgs: [_userId],
      orderBy: '$gameUpdatedAtColumn ASC',
    );

    return rows.map(Game.fromMap).toList();
  }

  Future<int> updateGame(Game game) async {
    final userId = _userId;
    if (game.id == null) {
      throw ArgumentError('O jogo não tem ID local para edição.');
    }
    if (game.userId != userId) {
      throw StateError('O jogo pertence a outra conta.');
    }
    _validate(game);

    game
      ..updatedAt = DateTime.now().millisecondsSinceEpoch
      ..synced = false
      ..deletedAt = null;

    final data = game.toMap()..remove(gameIdColumn);
    return (await db).update(
      gameTable,
      data,
      where: '$gameIdColumn = ? AND $gameUserIdColumn = ?',
      whereArgs: [game.id, userId],
    );
  }

  Future<int> deleteGame(Game game) async {
    final userId = _userId;
    if (game.userId != userId) {
      throw StateError('O jogo pertence a outra conta.');
    }

    final database = await db;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (game.id == null) {
      if (game.remoteId == null) return 0;

      final deletedGame = Game(
        userId: userId,
        rawgId: game.rawgId,
        name: game.name,
        status: game.status,
        backgroundImage: game.backgroundImage,
        remoteId: game.remoteId,
        createdAt: game.createdAt ?? now,
        updatedAt: now,
        synced: false,
        deletedAt: now,
      );
      return database.insert(gameTable, deletedGame.toMap());
    }

    final rows = await database.query(
      gameTable,
      where: '$gameIdColumn = ? AND $gameUserIdColumn = ?',
      whereArgs: [game.id, userId],
      limit: 1,
    );
    if (rows.isEmpty) return 0;

    final localGame = Game.fromMap(rows.first);
    if (localGame.remoteId == null) {
      return database.delete(
        gameTable,
        where: '$gameIdColumn = ? AND $gameUserIdColumn = ?',
        whereArgs: [game.id, userId],
      );
    }

    return database.update(
      gameTable,
      {gameDeletedAtColumn: now, gameUpdatedAtColumn: now, gameSyncedColumn: 0},
      where: '$gameIdColumn = ? AND $gameUserIdColumn = ?',
      whereArgs: [game.id, userId],
    );
  }

  Future<int> setRemoteId(int localId, String remoteId) async {
    return (await db).update(
      gameTable,
      {gameRemoteIdColumn: remoteId},
      where: '$gameIdColumn = ? AND $gameUserIdColumn = ?',
      whereArgs: [localId, _userId],
    );
  }

  Future<int> markSynced(int localId) async {
    return (await db).update(
      gameTable,
      {gameSyncedColumn: 1},
      where: '$gameIdColumn = ? AND $gameUserIdColumn = ?',
      whereArgs: [localId, _userId],
    );
  }

  Future<int> removeLocalGame(int localId) async {
    return (await db).delete(
      gameTable,
      where: '$gameIdColumn = ? AND $gameUserIdColumn = ?',
      whereArgs: [localId, _userId],
    );
  }

  void _validate(Game game) {
    if (game.name.trim().isEmpty) {
      throw ArgumentError('O nome do jogo é obrigatório.');
    }
    if (game.rawgId != null && game.rawgId! <= 0) {
      throw ArgumentError('O ID da RAWG deve ser maior que zero.');
    }
  }
}
