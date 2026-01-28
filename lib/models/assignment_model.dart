import 'dart:math';

enum AssignmentStatus {
  notStarted,
  inProgress,
  submitted,
}

class Assignment {
  final String id;
  final String subject;
  final String title;
  final String description;
  final DateTime dueDate;
  final AssignmentStatus status;
  final int progress; // 0–100

  Assignment({
    required this.id,
    required this.subject,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.progress = 0,
  });

  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  int get urgencyScore => max(0, daysLeft);

  Assignment copyWith({
    String? subject,
    String? title,
    String? description,
    DateTime? dueDate,
    AssignmentStatus? status,
    int? progress,
  }) {
    return Assignment(
      id: id,
      subject: subject ?? this.subject,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }
}