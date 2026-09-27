import 'package:equatable/equatable.dart';

class LeadNote extends Equatable {
  final String id;
  final String leadId;
  final String content;
  final DateTime createdAt;

  const LeadNote({
    required this.id,
    required this.leadId,
    required this.content,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, leadId, content, createdAt];
}
