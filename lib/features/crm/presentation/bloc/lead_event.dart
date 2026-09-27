import 'package:equatable/equatable.dart';
import '../../domain/entities/lead_enums.dart';

abstract class LeadEvent extends Equatable {
  const LeadEvent();

  @override
  List<Object?> get props => [];
}

class LoadLeads extends LeadEvent {
  final bool? isClosed;

  const LoadLeads({this.isClosed});

  @override
  List<Object?> get props => [isClosed];
}

class LoadLeadStats extends LeadEvent {
  const LoadLeadStats();
}

class CreateLeadEvent extends LeadEvent {
  final Map<String, dynamic> leadData;

  const CreateLeadEvent(this.leadData);

  @override
  List<Object?> get props => [leadData];
}

class UpdateLeadEvent extends LeadEvent {
  final String leadId;
  final Map<String, dynamic> leadData;

  const UpdateLeadEvent(this.leadId, this.leadData);

  @override
  List<Object?> get props => [leadId, leadData];
}

class DeleteLeadEvent extends LeadEvent {
  final String id;

  const DeleteLeadEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class FilterLeadsByStage extends LeadEvent {
  final LeadStage? stage;

  const FilterLeadsByStage(this.stage);

  @override
  List<Object?> get props => [stage];
}

class SearchLeads extends LeadEvent {
  final String query;

  const SearchLeads(this.query);

  @override
  List<Object?> get props => [query];
}

class RefreshLeads extends LeadEvent {
  const RefreshLeads();
}
