import 'package:equatable/equatable.dart';
import '../../domain/entities/lead_visit.dart';
import '../../domain/entities/lead_task.dart';
import '../../domain/entities/lead_order.dart';

abstract class LeadDetailEvent extends Equatable {
  const LeadDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadLeadDetail extends LeadDetailEvent {
  final String leadId;

  const LoadLeadDetail(this.leadId);

  @override
  List<Object?> get props => [leadId];
}

class UpdateLeadStageEvent extends LeadDetailEvent {
  final String leadId;
  final Map<String, dynamic> leadData;

  const UpdateLeadStageEvent(this.leadId, this.leadData);

  @override
  List<Object?> get props => [leadId, leadData];
}

class AddNoteEvent extends LeadDetailEvent {
  final String leadId;
  final String content;

  const AddNoteEvent(this.leadId, this.content);

  @override
  List<Object?> get props => [leadId, content];
}

class AddVisitEvent extends LeadDetailEvent {
  final LeadVisit visit;

  const AddVisitEvent(this.visit);

  @override
  List<Object?> get props => [visit];
}

class UpdateVisitEvent extends LeadDetailEvent {
  final LeadVisit visit;

  const UpdateVisitEvent(this.visit);

  @override
  List<Object?> get props => [visit];
}

class DeleteVisitEvent extends LeadDetailEvent {
  final String visitId;
  final String leadId;

  const DeleteVisitEvent(this.visitId, this.leadId);

  @override
  List<Object?> get props => [visitId, leadId];
}

class AddTaskEvent extends LeadDetailEvent {
  final LeadTask task;

  const AddTaskEvent(this.task);

  @override
  List<Object?> get props => [task];
}

class UpdateTaskEvent extends LeadDetailEvent {
  final LeadTask task;

  const UpdateTaskEvent(this.task);

  @override
  List<Object?> get props => [task];
}

class AddTaskLogEvent extends LeadDetailEvent {
  final String taskId;
  final String leadId;
  final Map<String, dynamic> log;

  const AddTaskLogEvent(this.taskId, this.leadId, this.log);

  @override
  List<Object?> get props => [taskId, leadId, log];
}

class DeleteLeadDetailEvent extends LeadDetailEvent {
  final String leadId;

  const DeleteLeadDetailEvent(this.leadId);

  @override
  List<Object?> get props => [leadId];
}

class RefreshLeadDetail extends LeadDetailEvent {
  final String leadId;

  const RefreshLeadDetail(this.leadId);

  @override
  List<Object?> get props => [leadId];
}

class AddOrderEvent extends LeadDetailEvent {
  final LeadOrder order;

  const AddOrderEvent(this.order);

  @override
  List<Object?> get props => [order];
}

class UpdateOrderEvent extends LeadDetailEvent {
  final LeadOrder order;

  const UpdateOrderEvent(this.order);

  @override
  List<Object?> get props => [order];
}

class DeleteOrderEvent extends LeadDetailEvent {
  final String orderId;
  final String leadId;

  const DeleteOrderEvent(this.orderId, this.leadId);

  @override
  List<Object?> get props => [orderId, leadId];
}

class AddPaymentEvent extends LeadDetailEvent {
  final OrderPayment payment;
  final String leadId;

  const AddPaymentEvent(this.payment, this.leadId);

  @override
  List<Object?> get props => [payment, leadId];
}

class UpdatePaymentEvent extends LeadDetailEvent {
  final OrderPayment payment;
  final String leadId;

  const UpdatePaymentEvent(this.payment, this.leadId);

  @override
  List<Object?> get props => [payment, leadId];
}

class DeletePaymentEvent extends LeadDetailEvent {
  final String paymentId;
  final String leadId;

  const DeletePaymentEvent(this.paymentId, this.leadId);

  @override
  List<Object?> get props => [paymentId, leadId];
}
