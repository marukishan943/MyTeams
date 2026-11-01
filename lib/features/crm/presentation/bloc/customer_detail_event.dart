import 'package:equatable/equatable.dart';

abstract class CustomerDetailEvent extends Equatable {
  const CustomerDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadCustomerDetail extends CustomerDetailEvent {
  final String customerId;

  const LoadCustomerDetail(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class AddCustomerNoteEvent extends CustomerDetailEvent {
  final String customerId;
  final String content;
  final String? authorName;

  const AddCustomerNoteEvent(this.customerId, this.content, [this.authorName]);

  @override
  List<Object?> get props => [customerId, content, authorName];
}

class RefreshCustomerDetail extends CustomerDetailEvent {
  final String customerId;

  const RefreshCustomerDetail(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class DeleteCustomerNoteEvent extends CustomerDetailEvent {
  final String customerId;
  final String noteId;

  const DeleteCustomerNoteEvent(this.customerId, this.noteId);

  @override
  List<Object?> get props => [customerId, noteId];
}
