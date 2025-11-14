# Task Notes Manager

**Name:** [SWALE SEBABE ABDU]  
**Student Number:** [2300723779]  
**Registration Number:** [23/U/23779]

## Description
A Flutter task management application that allows users to create, view, update, and delete tasks with priorities. Features include:
- Add new tasks with title, description, and priority
- Mark tasks as complete/incomplete
- Delete tasks with swipe gesture
- Dark/Light theme toggle that persists across app restarts
- Local database storage using SQLite
- Web and mobile support

## Features
- ✅ Create tasks with title, description, and priority levels (High, Medium, Low)
- ✅ View all tasks in a scrollable list
- ✅ Toggle task completion status
- ✅ Delete tasks with swipe-to-dismiss gesture
- ✅ Dark/Light theme with persistent preference
- ✅ SQLite local database for data persistence
- ✅ Web platform support

## Technologies Used
- Flutter SDK
- SQLite (sqflite package)
- SharedPreferences
- Material Design 3

## How to Run

### Prerequisites
- Flutter SDK installed (version 3.9.2 or higher)
- Chrome browser (for web) or Android/iOS emulator

### Installation Steps
1. Clone the repository:
```bash
   git clone https://github.com/YOUR_USERNAME/flutter-task-notes-app.git
   cd flutter-task-notes-app
```

2. Install dependencies:
```bash
   flutter pub get
```

3. Run the app:
   
   **For Web:**
```bash
   flutter run -d chrome
```
   
   **For Android:**
```bash
   flutter run -d android
```
   
   **For iOS:**
```bash
   flutter run -d ios
```

## Project Structure
```
lib/
├── main.dart                 # Main app entry and UI screens
├── database_helper.dart      # SQLite database operations
└── models/
    └── task_item.dart       # Task data model

web/
├── index.html               # Web configuration
└── sqflite_sw.js           # Service worker for web database
```

## Assignment Requirements Met
- ✅ Task 1: Git & GitHub setup
- ✅ Task 2: UI with forms and dynamic lists
- ✅ Task 3: Data modeling with JSON serialization
- ✅ Task 4A: SharedPreferences for theme
- ✅ Task 4B: SQLite database with CRUD operations
- ✅ Bonus: Delete functionality implemented