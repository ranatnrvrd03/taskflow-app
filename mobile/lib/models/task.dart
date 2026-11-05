class TaskStatus {
  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String done = 'done';

  static const List<String> values = [pending, inProgress, done];

  static String label(String status) {
    switch (status) {
      case pending:
        return 'Bekliyor';
      case inProgress:
        return 'Devam ediyor';
      case done:
        return 'Tamamlandı';
      default:
        return status;
    }
  }
}

class TaskPriority {
  static const int low = 1;
  static const int medium = 2;
  static const int high = 3;

  static const List<int> values = [low, medium, high];

  static String label(int priority) {
    switch (priority) {
      case low:
        return 'Düşük';
      case medium:
        return 'Orta';
      case high:
        return 'Yüksek';
      default:
        return 'Öncelik $priority';
    }
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final String status;
  final int priority;
  final String assignee;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.assignee,
    required this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      status: (json['status'] as String?) ?? TaskStatus.pending,
      priority: (json['priority'] as num?)?.toInt() ?? TaskPriority.medium,
      assignee: (json['assignee'] as String?) ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  String get statusLabel => TaskStatus.label(status);
  String get priorityLabel => TaskPriority.label(priority);
  bool get isDone => status == TaskStatus.done;
}