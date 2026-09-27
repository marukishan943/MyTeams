import '../../domain/entities/lead_visit.dart';

class LeadVisitModel extends LeadVisit {
  const LeadVisitModel({
    required super.id,
    required super.leadId,
    required super.staffName,
    required super.purpose,
    required super.date,
    required super.startTime,
    super.endTime,
    super.subject,
    super.description,
    super.images,
    required super.createdAt,
  });

  factory LeadVisitModel.fromEntity(LeadVisit visit) {
    return LeadVisitModel(
      id: visit.id,
      leadId: visit.leadId,
      staffName: visit.staffName,
      purpose: visit.purpose,
      date: visit.date,
      startTime: visit.startTime,
      endTime: visit.endTime,
      subject: visit.subject,
      description: visit.description,
      images: visit.images,
      createdAt: visit.createdAt,
    );
  }

  factory LeadVisitModel.fromJson(Map<String, dynamic> json) {
    final purposeStr = json['purpose'] as String? ?? 'meeting';
    final purpose = VisitPurpose.values.firstWhere(
      (e) => e.name.toLowerCase() == purposeStr.toLowerCase(),
      orElse: () => VisitPurpose.meeting,
    );

    return LeadVisitModel(
      id: json['id']?.toString() ?? '',
      leadId: json['lead_id']?.toString() ?? '',
      staffName: json['staff_name']?.toString() ?? '',
      purpose: purpose,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.tryParse(json['end_time'].toString())
          : null,
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'lead_id': leadId,
      'staff_name': staffName,
      'purpose': purpose.name,
      'date': date.toIso8601String(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'subject': subject,
      'description': description,
      'images': images,
      'created_at': createdAt.toIso8601String(),
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
}
