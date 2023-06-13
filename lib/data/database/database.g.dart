// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AppDatabaseBuilder databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AppDatabaseBuilder inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  /// Adds migrations to the builder.
  _$AppDatabaseBuilder addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  /// Adds a database [Callback] to the builder.
  _$AppDatabaseBuilder addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  /// Creates the database and initializes it.
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  PointDAO? _pointDAOInstance;

  EdgeDAO? _edgeDAOInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Edge` (`id` INTEGER NOT NULL, `p1id` INTEGER NOT NULL, `p2id` INTEGER NOT NULL, `typeId` INTEGER NOT NULL, `diam` REAL NOT NULL, `len` REAL NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Point` (`id` INTEGER NOT NULL, `positionX` REAL NOT NULL, `positionY` REAL NOT NULL, PRIMARY KEY (`id`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  PointDAO get pointDAO {
    return _pointDAOInstance ??= _$PointDAO(database, changeListener);
  }

  @override
  EdgeDAO get edgeDAO {
    return _edgeDAOInstance ??= _$EdgeDAO(database, changeListener);
  }
}

class _$PointDAO extends PointDAO {
  _$PointDAO(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _pointInsertionAdapter = InsertionAdapter(
            database,
            'Point',
            (Point item) => <String, Object?>{
                  'id': item.id,
                  'positionX': item.positionX,
                  'positionY': item.positionY
                }),
        _pointUpdateAdapter = UpdateAdapter(
            database,
            'Point',
            ['id'],
            (Point item) => <String, Object?>{
                  'id': item.id,
                  'positionX': item.positionX,
                  'positionY': item.positionY
                }),
        _pointDeletionAdapter = DeletionAdapter(
            database,
            'Point',
            ['id'],
            (Point item) => <String, Object?>{
                  'id': item.id,
                  'positionX': item.positionX,
                  'positionY': item.positionY
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Point> _pointInsertionAdapter;

  final UpdateAdapter<Point> _pointUpdateAdapter;

  final DeletionAdapter<Point> _pointDeletionAdapter;

  @override
  Future<List<Point>> getAllPoints() async {
    return _queryAdapter.queryList('SELECT * FROM Point',
        mapper: (Map<String, Object?> row) => Point(
            id: row['id'] as int,
            positionX: row['positionX'] as double,
            positionY: row['positionY'] as double));
  }

  @override
  Future<List<Point>> getPointById(int id) async {
    return _queryAdapter.queryList('SELECT * FROM Point WHERE id=?1',
        mapper: (Map<String, Object?> row) => Point(
            id: row['id'] as int,
            positionX: row['positionX'] as double,
            positionY: row['positionY'] as double),
        arguments: [id]);
  }

  @override
  Future<void> deleteAllPoints() async {
    await _queryAdapter.queryNoReturn('DELETE FROM Point');
  }

  @override
  Future<void> insertPoint(Point point) async {
    await _pointInsertionAdapter.insert(point, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertPoints(List<Point> points) async {
    await _pointInsertionAdapter.insertList(points, OnConflictStrategy.abort);
  }

  @override
  Future<void> updatePoint(Point point) async {
    await _pointUpdateAdapter.update(point, OnConflictStrategy.abort);
  }

  @override
  Future<void> deletePoint(Point point) async {
    await _pointDeletionAdapter.delete(point);
  }
}

class _$EdgeDAO extends EdgeDAO {
  _$EdgeDAO(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _edgeInsertionAdapter = InsertionAdapter(
            database,
            'Edge',
            (Edge item) => <String, Object?>{
                  'id': item.id,
                  'p1id': item.p1id,
                  'p2id': item.p2id,
                  'typeId': item.typeId,
                  'diam': item.diam,
                  'len': item.len
                }),
        _edgeUpdateAdapter = UpdateAdapter(
            database,
            'Edge',
            ['id'],
            (Edge item) => <String, Object?>{
                  'id': item.id,
                  'p1id': item.p1id,
                  'p2id': item.p2id,
                  'typeId': item.typeId,
                  'diam': item.diam,
                  'len': item.len
                }),
        _edgeDeletionAdapter = DeletionAdapter(
            database,
            'Edge',
            ['id'],
            (Edge item) => <String, Object?>{
                  'id': item.id,
                  'p1id': item.p1id,
                  'p2id': item.p2id,
                  'typeId': item.typeId,
                  'diam': item.diam,
                  'len': item.len
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Edge> _edgeInsertionAdapter;

  final UpdateAdapter<Edge> _edgeUpdateAdapter;

  final DeletionAdapter<Edge> _edgeDeletionAdapter;

  @override
  Future<List<Edge>> getAllEdges() async {
    return _queryAdapter.queryList('SELECT * FROM Edge',
        mapper: (Map<String, Object?> row) => Edge(
            id: row['id'] as int,
            p1id: row['p1id'] as int,
            p2id: row['p2id'] as int,
            typeId: row['typeId'] as int,
            diam: row['diam'] as double,
            len: row['len'] as double));
  }

  @override
  Future<List<Edge>> getEdgeById(int id) async {
    return _queryAdapter.queryList('SELECT * FROM Edge WHERE id=?1',
        mapper: (Map<String, Object?> row) => Edge(
            id: row['id'] as int,
            p1id: row['p1id'] as int,
            p2id: row['p2id'] as int,
            typeId: row['typeId'] as int,
            diam: row['diam'] as double,
            len: row['len'] as double),
        arguments: [id]);
  }

  @override
  Future<void> deleteAllEdges() async {
    await _queryAdapter.queryNoReturn('DELETE FROM Edge');
  }

  @override
  Future<void> insertEdge(Edge edge) async {
    await _edgeInsertionAdapter.insert(edge, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertEdges(List<Edge> edges) async {
    await _edgeInsertionAdapter.insertList(edges, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateEdge(Edge edge) async {
    await _edgeUpdateAdapter.update(edge, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteEdge(Edge edge) async {
    await _edgeDeletionAdapter.delete(edge);
  }
}
