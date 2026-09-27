import 'package:equatable/equatable.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_note.dart';
import '../../domain/entities/lead_visit.dart';
import '../../domain/entities/lead_task.dart';
import '../../domain/entities/lead_order.dart';

abstract class LeadDetailState extends Equatable {
  const LeadDetailState();

  @override
  List<Object?> get props => [];
}

class LeadDetailInitial extends LeadDetailState {
  const LeadDetailInitial();
}

class LeadDetailLoading extends LeadDetailState {
  const LeadDetailLoading();
}

class LeadDetailLoaded extends LeadDetailState {
  final Lead lead;
  final List<LeadNote> notes;
  final List<LeadVisit> visits;
  final List<LeadTask> tasks;
  final List<LeadOrder> orders;

  const LeadDetailLoaded({
    required this.lead,
    required this.notes,
    required this.visits,
    required this.tasks,
    this.orders = const [],
  });

  LeadDetailLoaded copyWith({
    Lead? lead,
    List<LeadNote>? notes,
    List<LeadVisit>? visits,
    List<LeadTask>? tasks,
    List<LeadOrder>? orders,
  }) {
    return LeadDetailLoaded(
      lead: lead ?? this.lead,
      notes: notes ?? this.notes,
      visits: visits ?? this.visits,
      tasks: tasks ?? this.tasks,
      orders: orders ?? this.orders,
    );
  }

  @override
  List<Object?> get props => [lead, notes, visits, tasks, orders];
}

class LeadDetailOperationSuccess extends LeadDetailState {
  final String message;

  const LeadDetailOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class LeadDetailError extends LeadDetailState {
  final String message;

  const LeadDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
