import 'package:equatable/equatable.dart';
import '../../domain/entities/customer.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object?> get props => [];
}

class LoadCustomers extends CustomerEvent {
  final String? searchQuery;
  final String? category;
  final String? staffName;

  const LoadCustomers({this.searchQuery, this.category, this.staffName});

  @override
  List<Object?> get props => [searchQuery, category, staffName];
}

class SearchCustomers extends CustomerEvent {
  final String query;

  const SearchCustomers(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterCustomers extends CustomerEvent {
  final String? staffName;
  final String? category;
  final String? status;
  final String? territory;
  final DateTime? startDate;
  final DateTime? endDate;

  const FilterCustomers({
    this.staffName,
    this.category,
    this.status,
    this.territory,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [staffName, category, status, territory, startDate, endDate];
}

class CreateCustomerEvent extends CustomerEvent {
  final Customer customer;

  const CreateCustomerEvent(this.customer);

  @override
  List<Object?> get props => [customer];
}

class UpdateCustomerEvent extends CustomerEvent {
  final Customer customer;

  const UpdateCustomerEvent(this.customer);

  @override
  List<Object?> get props => [customer];
}

class DeleteCustomerEvent extends CustomerEvent {
  final String id;

  const DeleteCustomerEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class RefreshCustomers extends CustomerEvent {
  const RefreshCustomers();
}
