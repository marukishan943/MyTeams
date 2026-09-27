import 'package:equatable/equatable.dart';

enum VisitPurpose {
  meeting,
  followup;

  String get displayName {
    switch (this) {
      case VisitPurpose.meeting:
        return 'Meeting';
      case VisitPurpose.followup:
        return 'Followup';
    }
  }
}

class LeadVisit extends Equatable {
  final String id;
  final String leadId;
  final String staffName;
  final VisitPurpose purpose;
  final DateTime date;
  final DateTime startTime;
  final DateTime? endTime;
  final String subject;
  final String description;
  final List<String> images;
  final DateTime createdAt;

  const LeadVisit({
    required this.id,
    required this.leadId,
    required this.staffName,
    required this.purpose,
    required this.date,
    required this.startTime,
    this.endTime,
    this.subject = '',
    this.description = '',
    this.images = const [],
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        leadId,
        staffName,
        purpose,
        date,
        startTime,
        endTime,
        subject,
        description,
        images,
        createdAt,
      ];
}
