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
      version: 4,
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
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE run_sessions ADD COLUMN rawTrackPoints TEXT');
      await db.execute('ALTER TABLE run_sessions ADD COLUMN filterExports TEXT');
    }
    if (oldVersion < 4) {
      await _createTrainingTables(db);
    }
  }

  Future<void> _createTrainingTables(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL';

    await db.execute('''
      CREATE TABLE IF NOT EXISTS training_programs (
        id $idType,
        name $textType,
        raceDate $integerType,
        distanceMeters $realType NOT NULL,
        targetTime $textType,
        targetPacePerKm TEXT,
        daysPerWeek $integerType,
        weeksTotal $integerType,
        generatedBy TEXT,
        createdAt $integerType,
        isActive $integerType DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS scheduled_days (
        id $idType,
        programId $textType,
        date $textType,
        type $textType,
        title $textType,
        description TEXT,
        targetDistanceMeters $realType,
        targetPacePerKm TEXT,
        workoutPlanId TEXT,
        status $textType DEFAULT 'pending'
      )
    ''');
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
          rawTrackPoints TEXT,
          filterExports TEXT,
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

    await _createTrainingTables(db);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
