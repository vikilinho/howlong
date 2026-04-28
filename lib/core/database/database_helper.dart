import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String databasesPath = await getDatabasesPath();
    final String path = join(databasesPath, DatabaseConstants.dbName);

    return await openDatabase(
      path,
      version: DatabaseConstants.dbVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // events
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableEvents} (
        ${DatabaseConstants.colEventsId} TEXT PRIMARY KEY,
        ${DatabaseConstants.colEventsTitle} TEXT NOT NULL,
        ${DatabaseConstants.colEventsEmoji} TEXT,
        ${DatabaseConstants.colEventsLastLoggedAt} INTEGER,
        ${DatabaseConstants.colEventsReminderAfterDays} INTEGER,
        ${DatabaseConstants.colEventsCreatedAt} INTEGER NOT NULL
      )
    ''');

    // event_logs
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableEventLogs} (
        ${DatabaseConstants.colEventLogsId} TEXT PRIMARY KEY,
        ${DatabaseConstants.colEventLogsEventId} TEXT NOT NULL,
        ${DatabaseConstants.colEventLogsLoggedAt} INTEGER NOT NULL,
        ${DatabaseConstants.colEventLogsNote} TEXT,
        FOREIGN KEY (${DatabaseConstants.colEventLogsEventId}) 
          REFERENCES ${DatabaseConstants.tableEvents}(${DatabaseConstants.colEventsId}) 
          ON DELETE CASCADE
      )
    ''');

    // habits
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableHabits} (
        ${DatabaseConstants.colHabitsId} TEXT PRIMARY KEY,
        ${DatabaseConstants.colHabitsTitle} TEXT NOT NULL,
        ${DatabaseConstants.colHabitsEmoji} TEXT,
        ${DatabaseConstants.colHabitsHabitType} TEXT NOT NULL,
        ${DatabaseConstants.colHabitsScheduleType} TEXT NOT NULL,
        ${DatabaseConstants.colHabitsScheduleDays} TEXT,
        ${DatabaseConstants.colHabitsScheduleEveryXDays} INTEGER,
        ${DatabaseConstants.colHabitsNotificationTime} TEXT,
        ${DatabaseConstants.colHabitsColorHex} TEXT,
        ${DatabaseConstants.colHabitsCreatedAt} INTEGER NOT NULL
      )
    ''');

    // habit_logs
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableHabitLogs} (
        ${DatabaseConstants.colHabitLogsId} TEXT PRIMARY KEY,
        ${DatabaseConstants.colHabitLogsHabitId} TEXT NOT NULL,
        ${DatabaseConstants.colHabitLogsCheckedAt} INTEGER NOT NULL,
        ${DatabaseConstants.colHabitLogsStatus} TEXT NOT NULL,
        FOREIGN KEY (${DatabaseConstants.colHabitLogsHabitId}) 
          REFERENCES ${DatabaseConstants.tableHabits}(${DatabaseConstants.colHabitsId}) 
          ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await instance.database;
    return await db.query(table);
  }

  Future<List<Map<String, dynamic>>> queryWhere(String table, String where, List<dynamic> whereArgs) async {
    final db = await instance.database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  Future<Map<String, dynamic>?> queryById(String table, String idColumn, String id) async {
    final db = await instance.database;
    final results = await db.query(table, where: '$idColumn = ?', whereArgs: [id]);
    if (results.isNotEmpty) return results.first;
    return null;
  }

  Future<int> update(String table, Map<String, dynamic> data, String where, List<dynamic> whereArgs) async {
    final db = await instance.database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, String where, List<dynamic> whereArgs) async {
    final db = await instance.database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> deleteAll(String table) async {
    final db = await instance.database;
    await db.delete(table);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
