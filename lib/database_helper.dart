import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models/task_item.dart';

class DatabaseHelper {
  // Singleton pattern (Part B)
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _dbName = 'tasks.db';
  static const String _tableName = 'tasks';

  // Getter for the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Initialize the database (Part B)
  Future<Database> _initDB() async {
    try {
      // Standard path joining. Works correctly across platforms due to main.dart initialization.
      String path = join(await getDatabasesPath(), _dbName);
      
      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e) {
      print('Database initialization error: $e'); 
      rethrow;
    }
  }

  // Create the database table (Part B)
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        priority TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // --- CRUD Methods ---

  // CREATE: Insert a new task (Part B)
  Future<int> insertTask(TaskItem task) async {
    final db = await database;
    return await db.insert(
      _tableName,
      task.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ: Get all tasks (Part B)
  Future<List<TaskItem>> getTasks() async {
    final db = await database;
    // Order the tasks to show incomplete first, then by ID
    final List<Map<String, dynamic>> maps = 
        await db.query(_tableName, orderBy: 'isCompleted ASC, id DESC');

    // Convert the List<Map> into a List<TaskItem>
    return List.generate(maps.length, (i) {
      return TaskItem.fromJson(maps[i]);
    });
  }

  // UPDATE: Update an existing task (Part B)
  Future<int> updateTask(TaskItem task) async {
    final db = await database;
    return await db.update(
      _tableName,
      task.toJson(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // DELETE: Delete a task by ID (Bonus - Part B)
  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}