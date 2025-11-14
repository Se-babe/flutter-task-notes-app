// lib/models/task_item.dart

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

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as int?,
      title: json['title'] as String,
      priority: json['priority'] as String,
      description: json['description'] as String,
      isCompleted: json['isCompleted'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title,
      'priority': priority,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
    };

    // Only add ID if it's not null
    if (id != null) {
      map['id'] = id!;
    }
    return map;
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
}