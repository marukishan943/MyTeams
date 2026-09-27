import '../../domain/entities/lead_task.dart';

class LeadTaskModel extends LeadTask {
  const LeadTaskModel({
    required super.id,
    required super.leadId,
    required super.staffName,
    required super.type,
    required super.startDate,
    required super.endDate,
    required super.startTime,
    super.endTime,
    super.subject,
    super.description,
    super.priority,
    super.checklist,
    super.notes,
    super.logs,
    super.parentId,
    required super.createdAt,
  });

  factory LeadTaskModel.fromEntity(LeadTask task) {
    return LeadTaskModel(
      id: task.id,
      leadId: task.leadId,
      staffName: task.staffName,
      type: task.type,
      startDate: task.startDate,
      endDate: task.endDate,
      startTime: task.startTime,
      endTime: task.endTime,
      subject: task.subject,
      description: task.description,
      priority: task.priority,
      checklist: task.checklist,
      notes: task.notes,
      logs: task.logs,
      parentId: task.parentId,
      createdAt: task.createdAt,
    );
  }

  factory LeadTaskModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'call';
    final type = TaskType.values.firstWhere(
      (e) => e.name.toLowerCase() == typeStr.toLowerCase(),
      orElse: () => TaskType.call,
    );

    return LeadTaskModel(
      id: json['id']?.toString() ?? '',
      leadId: json['lead_id']?.toString() ?? '',
      staffName: json['staff_name']?.toString() ?? '',
      type: type,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.tryParse(json['end_time'].toString())
          : null,
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      checklist: (json['checklist'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      notes: (json['notes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      logs: (json['task_logs'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      parentId: json['parent_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'lead_id': leadId,
      'staff_name': staffName,
      'type': type.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'subject': subject,
      'description': description,
      'priority': priority,
      'checklist': checklist,
      'notes': notes,
      'parent_id': parentId,
      'created_at': createdAt.toIso8601String(),
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
}
