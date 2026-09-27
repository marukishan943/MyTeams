import '../../domain/entities/lead_note.dart';

class LeadNoteModel extends LeadNote {
  const LeadNoteModel({
    required super.id,
    required super.leadId,
    required super.content,
    required super.createdAt,
  });

  factory LeadNoteModel.fromEntity(LeadNote note) {
    return LeadNoteModel(
      id: note.id,
      leadId: note.leadId,
      content: note.content,
      createdAt: note.createdAt,
    );
  }

  factory LeadNoteModel.fromJson(Map<String, dynamic> json) {
    return LeadNoteModel(
      id: json['id']?.toString() ?? '',
      leadId: json['lead_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'lead_id': leadId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
}
