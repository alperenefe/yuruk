import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('yuruk.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add workout_plans table if upgrading from v1
      const idType = 'TEXT PRIMARY KEY';
      const textType = 'TEXT NOT NULL';
      const integerType = 'INTEGER NOT NULL';
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS workout_plans (
          id $idType,
          name $textType,
          description TEXT,
          steps $textType,
          createdAt $integerType
        )
      ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE run_sessions (
        id $idType,
        startTime $integerType,
        endTime INTEGER,
        status $textType,
        trackPoints $textType,
        totalDistance $realType,
        elapsedTime $integerType,
        averageBpm INTEGER,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_plans (
        id $idType,
        name $textType,
        description TEXT,
        steps $textType,
        createdAt $integerType
      )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
