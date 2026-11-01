import 'package:equatable/equatable.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_note.dart';

abstract class CustomerDetailState extends Equatable {
  const CustomerDetailState();

  @override
  List<Object?> get props => [];
}

class CustomerDetailInitial extends CustomerDetailState {
  const CustomerDetailInitial();
}

class CustomerDetailLoading extends CustomerDetailState {
  const CustomerDetailLoading();
}

class CustomerDetailLoaded extends CustomerDetailState {
  final Customer customer;
  final List<CustomerNote> notes;

  const CustomerDetailLoaded({
    required this.customer,
    required this.notes,
  });

  CustomerDetailLoaded copyWith({
    Customer? customer,
    List<CustomerNote>? notes,
  }) {
    return CustomerDetailLoaded(
      customer: customer ?? this.customer,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [customer, notes];
}

class CustomerDetailOperationSuccess extends CustomerDetailState {
  final String message;

  const CustomerDetailOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CustomerDetailError extends CustomerDetailState {
  final String message;

  const CustomerDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
