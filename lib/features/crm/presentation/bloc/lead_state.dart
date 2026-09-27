import 'package:equatable/equatable.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_stats.dart';

abstract class LeadState extends Equatable {
  const LeadState();

  @override
  List<Object?> get props => [];
}

class LeadInitial extends LeadState {
  const LeadInitial();
}

class LeadLoading extends LeadState {
  const LeadLoading();
}

class LeadsLoaded extends LeadState {
  final List<Lead> allLeads;
  final List<Lead> openLeads;
  final List<Lead> closedLeads;
  final List<Lead> filteredOpenLeads;
  final List<Lead> filteredClosedLeads;
  final LeadStats stats;
  final String searchQuery;

  const LeadsLoaded({
    required this.allLeads,
    required this.openLeads,
    required this.closedLeads,
    required this.filteredOpenLeads,
    required this.filteredClosedLeads,
    required this.stats,
    this.searchQuery = '',
  });

  LeadsLoaded copyWith({
    List<Lead>? allLeads,
    List<Lead>? openLeads,
    List<Lead>? closedLeads,
    List<Lead>? filteredOpenLeads,
    List<Lead>? filteredClosedLeads,
    LeadStats? stats,
    String? searchQuery,
  }) {
    return LeadsLoaded(
      allLeads: allLeads ?? this.allLeads,
      openLeads: openLeads ?? this.openLeads,
      closedLeads: closedLeads ?? this.closedLeads,
      filteredOpenLeads: filteredOpenLeads ?? this.filteredOpenLeads,
      filteredClosedLeads: filteredClosedLeads ?? this.filteredClosedLeads,
      stats: stats ?? this.stats,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        allLeads,
        openLeads,
        closedLeads,
        filteredOpenLeads,
        filteredClosedLeads,
        stats,
        searchQuery,
      ];
}

class LeadOperationSuccess extends LeadState {
  final String message;

  const LeadOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class LeadError extends LeadState {
  final String message;

  const LeadError(this.message);

  @override
  List<Object?> get props => [message];
}
