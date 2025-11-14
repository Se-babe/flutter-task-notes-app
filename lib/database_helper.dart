import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models/task_item.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _dbName = 'tasks.db';
  static const String _tableName = 'tasks';

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), _dbName);
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

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

  Future<int> insertTask(TaskItem task) async {
    final db = await database;
    return await db.insert(_tableName, task.toJson());
  }

  Future<List<TaskItem>> getTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = 
        await db.query(_tableName, orderBy: 'isCompleted ASC, id DESC');
    
    // Convert the List<Map> into a List<TaskItem>
    return List.generate(maps.length, (i) {
      return TaskItem(
        id: maps[i]['id'] as int?,
        title: maps[i]['title'] as String,
        priority: maps[i]['priority'] as String,
        description: maps[i]['description'] as String,
        isCompleted: maps[i]['isCompleted'] == 1,
      );
    });
  }

  Future<int> updateTask(TaskItem task) async {
    final db = await database;
    return await db.update(
      _tableName,
      task.toJson(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}