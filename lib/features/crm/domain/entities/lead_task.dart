import 'package:equatable/equatable.dart';

enum TaskType {
  call,
  email;

  String get displayName {
    switch (this) {
      case TaskType.call:
        return 'Call';
      case TaskType.email:
        return 'Email';
    }
  }
}

class LeadTask extends Equatable {
  final String id;
  final String leadId;
  final String staffName;
  final TaskType type;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime startTime;
  final DateTime? endTime;
  final String subject;
  final String description;
  final int priority;
  final List<String> checklist;
  final List<String> notes;
  final List<Map<String, dynamic>> logs;
  final String? parentId;
  final DateTime createdAt;

  const LeadTask({
    required this.id,
    required this.leadId,
    required this.staffName,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    this.endTime,
    this.subject = '',
    this.description = '',
    this.priority = 0,
    this.checklist = const [],
    this.notes = const [],
    this.logs = const [],
    this.parentId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        leadId,
        staffName,
        type,
        startDate,
        endDate,
        startTime,
        endTime,
        subject,
        description,
        priority,
        checklist,
        notes,
        logs,
        parentId,
        createdAt,
      ];
}
