import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

const String _themeKey = 'isDarkTheme';

// --- TASK ITEM MODEL ---
class TaskItem {
  final int? id;
  final String title;
  final String priority;
  final String description;
  final bool isCompleted;

  TaskItem({
    this.id,
    required this.title,
    required this.priority,
    required this.description,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'priority': priority,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'],
      title: map['title'],
      priority: map['priority'],
      description: map['description'],
      isCompleted: map['isCompleted'] == 1,
    );
  }

  TaskItem copyWith({
    int? id,
    String? title,
    String? priority,
    String? description,
    bool? isCompleted,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  String toString() {
    return 'TaskItem(id: $id, title: $title, completed: $isCompleted)';
  }
}

// --- DATABASE HELPER ---
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _dbName = 'tasks.db';
  static const String _tableName = 'tasks';
  static bool _isInitialized = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    // Initialize database factory for web only once
    if (kIsWeb && !_isInitialized) {
      databaseFactory = databaseFactoryFfiWeb;
      _isInitialized = true;
    }

    try {
      if (kIsWeb) {
        // For web, use simplified path
        return await openDatabase(
          _dbName,
          version: 1,
          onCreate: _onCreate,
        );
      } else {
        // For mobile/desktop
        String databasesPath = await getDatabasesPath();
        String path = '$databasesPath/$_dbName';
        return await openDatabase(
          path,
          version: 1,
          onCreate: _onCreate,
        );
      }
    } catch (e) {
      print('Database initialization failed: $e');
      rethrow;
    }
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
    print('Database table created successfully');
  }

  Future<int> insertTask(TaskItem task) async {
    try {
      final db = await database;
      final id = await db.insert(_tableName, task.toMap());
      print('Task inserted with ID: $id');
      return id;
    } catch (e) {
      print('Error inserting task: $e');
      rethrow;
    }
  }

  Future<List<TaskItem>> getTasks() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = 
          await db.query(_tableName, orderBy: 'isCompleted ASC, id DESC');
      
      print('Retrieved ${maps.length} tasks from database');
      return maps.map((map) => TaskItem.fromMap(map)).toList();
    } catch (e) {
      print('Error getting tasks: $e');
      rethrow;
    }
  }

  Future<int> updateTask(TaskItem task) async {
    try {
      final db = await database;
      return await db.update(
        _tableName,
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }

  Future<int> deleteTask(int id) async {
    try {
      final db = await database;
      return await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }
}

// --- MAIN APP ENTRY POINT ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const TaskNotesManagerApp());
}

class TaskNotesManagerApp extends StatefulWidget {
  const TaskNotesManagerApp({super.key});

  @override
  State<TaskNotesManagerApp> createState() => _TaskNotesManagerAppState();
}

class _TaskNotesManagerAppState extends State<TaskNotesManagerApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  void _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Notes Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black87),
        scaffoldBackgroundColor: Colors.grey[900],
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(
              currentTheme: _themeMode,
              onThemeToggle: _toggleTheme,
            ),
        '/add': (context) => const AddEditScreen(),
      },
    );
  }
}

// --- HOME SCREEN (TASK LIST) ---
class HomeScreen extends StatefulWidget {
  final ThemeMode currentTheme;
  final Function(bool) onThemeToggle;

  const HomeScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeToggle,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<TaskItem>> _taskListFuture;
  final DatabaseHelper dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    print('Loading tasks...');
    setState(() {
      _taskListFuture = dbHelper.getTasks();
    });
  }

  void _toggleCompletion(TaskItem task) async {
    try {
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      await dbHelper.updateTask(updatedTask);
      _loadTasks();
    } catch (e) {
      _showErrorSnackbar('Error updating task');
    }
  }

  void _deleteTask(int id) async {
    try {
      await dbHelper.deleteTask(id);
      if (!mounted) return;
      _loadTasks();
      _showSuccessSnackbar('Task deleted!');
    } catch (e) {
      _showErrorSnackbar('Error deleting task');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = widget.currentTheme == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks & Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
            tooltip: 'Refresh tasks',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Welcome to My Tasks & Notes",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: Text(isDark ? 'Dark Theme Enabled' : 'Light Theme Enabled'),
            subtitle: const Text('Remembers choice across restarts'),
            secondary: Icon(isDark ? Icons.brightness_3 : Icons.wb_sunny),
            value: isDark,
            onChanged: widget.onThemeToggle,
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<TaskItem>>(
              future: _taskListFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading tasks...'),
                      ],
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load tasks',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadTasks,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.note_add, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No tasks yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap the + button to add your first task!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final tasks = snapshot.data!;
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final item = tasks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          if (item.id != null) {
                            _deleteTask(item.id!);
                          }
                        },
                        child: ListTile(
                          leading: Checkbox(
                            value: item.isCompleted,
                            onChanged: (bool? newValue) {
                              _toggleCompletion(item);
                            },
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: item.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Chip(
                                label: Text(
                                  item.priority,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: item.priority == 'High'
                                    ? Colors.red[100]
                                    : item.priority == 'Medium'
                                        ? Colors.orange[100]
                                        : Colors.green[100],
                              ),
                            ],
                          ),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Edit feature not yet implemented!'),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).pushNamed('/add');
          if (result == true) {
            _loadTasks();
          }
        },
        tooltip: 'Add New Task/Note',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- ADD/EDIT SCREEN ---
class AddEditScreen extends StatefulWidget {
  const AddEditScreen({super.key});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedPriority = 'Medium';
  final DatabaseHelper dbHelper = DatabaseHelper();
  bool _isSaving = false;

  final List<String> _priorities = ['High', 'Medium', 'Low'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final newTask = TaskItem(
          title: _titleController.text.trim(),
          priority: _selectedPriority,
          description: _descriptionController.text.trim(),
          isCompleted: false,
        );

        final id = await dbHelper.insertTask(newTask);
        print('Task saved successfully with ID: $id');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop(true);
      } catch (e) {
        print('Error saving task: $e');
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Note/Task'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                        hintText: 'Enter task title',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                        hintText: 'Enter task description',
                      ),
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedPriority,
                      items: _priorities.map((String priority) {
                        return DropdownMenuItem<String>(
                          value: priority,
                          child: Text(priority),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPriority = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveTask,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.save),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        label: Text(_isSaving ? 'Saving...' : 'Save Task'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}