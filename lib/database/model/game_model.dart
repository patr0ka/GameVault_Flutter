const String gameTable = 'games';

const String gameIdColumn = 'id';
const String gameUserIdColumn = 'user_id';
const String gameRawgIdColumn = 'rawg_id';
const String gameNameColumn = 'name';
const String gameStatusColumn = 'status';
const String gameImageColumn = 'background_image';
const String gameCreatedAtColumn = 'created_at';
const String gameUpdatedAtColumn = 'updated_at';
const String gameRemoteIdColumn = 'remote_id';
const String gameSyncedColumn = 'synced';
const String gameDeletedAtColumn = 'deleted_at';
const String gameStartedAtColumn = 'started_at';
const String gameCompletedAtColumn = 'completed_at';

class Game {
  Game({
    this.id,
    required this.userId,
    this.rawgId,
    required this.name,
    required this.status,
    this.backgroundImage,
    this.createdAt,
    this.updatedAt,
    this.remoteId,
    this.synced = false,
    this.deletedAt,
    this.startedAt,
    this.completedAt,
  });

  int? id;

  String userId;

  int? rawgId;

  String name;
  String status;
  String? backgroundImage;
  int? createdAt;
  int? updatedAt;
  String? remoteId;
  bool synced;
  int? deletedAt;
  int? startedAt;
  int? completedAt;

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map[gameIdColumn] as int?,
      userId: map[gameUserIdColumn] as String,
      rawgId: map[gameRawgIdColumn] as int?,
      name: map[gameNameColumn] as String,
      status: map[gameStatusColumn] as String,
      backgroundImage: map[gameImageColumn] as String?,
      createdAt: map[gameCreatedAtColumn] as int?,
      updatedAt: map[gameUpdatedAtColumn] as int?,
      remoteId: map[gameRemoteIdColumn] as String?,
      synced: (map[gameSyncedColumn] as int? ?? 0) == 1,
      deletedAt: map[gameDeletedAtColumn] as int?,
      startedAt: map[gameStartedAtColumn] as int?,
      completedAt: map[gameCompletedAtColumn] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    final now = DateTime.now().millisecondsSinceEpoch;

    final map = <String, dynamic>{
      gameUserIdColumn: userId,
      gameRawgIdColumn: rawgId,
      gameNameColumn: name,
      gameStatusColumn: status,
      gameImageColumn: backgroundImage,
      gameCreatedAtColumn: createdAt ?? now,
      gameUpdatedAtColumn: updatedAt ?? now,
      gameRemoteIdColumn: remoteId,
      gameSyncedColumn: synced ? 1 : 0,
      gameDeletedAtColumn: deletedAt,
      gameStartedAtColumn: startedAt,
      gameCompletedAtColumn: completedAt,
    };

    if (id != null) {
      map[gameIdColumn] = id;
    }

    return map;
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'rawgId': rawgId,
      'name': name,
      'status': status,
      'backgroundImage': backgroundImage,
      'startedAt': startedAt,
      'completedAt': completedAt,
    };
  }

  @override
  String toString() {
    return 'Game(id: $id, remoteId: $remoteId, userId: $userId, '
        'rawgId: $rawgId, name: $name, status: $status, synced: $synced)';
  }
}
