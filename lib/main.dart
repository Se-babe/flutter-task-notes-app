import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart'; // Needed for databaseFactory
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // Needed for databaseFactoryFfiWeb
import 'database_helper.dart'; 
import 'models/task_item.dart';

const String _themeKey = 'isDarkTheme';

// --- MAIN APP ENTRY POINT ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // FIX: Initialize the database factory for web only (solves Bad State error)
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  
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

  // Part A: Load persisted theme setting
  void _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  // Part A: Save theme setting and update state
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
  late final DatabaseHelper dbHelper;

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    _loadTasks();
  }

  void _loadTasks() {
    setState(() {
      // READ: Get all tasks
      _taskListFuture = dbHelper.getTasks();
    });
  }

  void _toggleCompletion(TaskItem task) async {
    // UPDATE: Toggle completion status
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await dbHelper.updateTask(updatedTask);
    _loadTasks();
  }

  void _deleteTask(int id) async {
    // DELETE: Delete task by ID
    await dbHelper.deleteTask(id);

    // Guard against using BuildContext after async gap
    if (!mounted) return;

    _loadTasks();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task deleted!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = widget.currentTheme == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks & Notes'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Welcome to My Tasks & Notes App",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          // Part A: Theme Toggle
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
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('You have no tasks. Tap + to add one!'));
                }

                final tasks = snapshot.data!;

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final item = tasks[index];

                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child:
                            const Icon(Icons.delete, color: Colors.white),
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
                        subtitle: Text(item.description,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text(item.priority),
                        onTap: () {
                          // Placeholder for Edit Navigation
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Edit feature not yet implemented!')),
                          );
                        },
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
          // Navigating to '/add' and waiting for result
          await Navigator.of(context).pushNamed('/add');
          // Refresh list after returning from Add/Edit screen
          _loadTasks(); 
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
  late final DatabaseHelper dbHelper;

  final List<String> _priorities = ['High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final newTask = TaskItem(
        title: _titleController.text,
        priority: _selectedPriority,
        description: _descriptionController.text,
        isCompleted: false,
      );

      // CREATE: Insert the new task
      await dbHelper.insertTask(newTask);

      // Guard against using BuildContext after async gap
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task saved successfully!')),
      );
      
      // Navigate back to the HomeScreen
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Note/Task'),
      ),
      body: SingleChildScrollView(
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
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
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
                ),
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
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
                initialValue: _selectedPriority,
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
                validator: (value) {
                  if (value == null) {
                    return 'Please select a priority';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveTask,
                  icon: const Icon(Icons.save),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  label: const Text('Save Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}