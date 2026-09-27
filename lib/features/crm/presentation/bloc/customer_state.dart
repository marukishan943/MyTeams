import 'package:equatable/equatable.dart';
import '../../domain/entities/customer.dart';

abstract class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {
  const CustomerInitial();
}

class CustomerLoading extends CustomerState {
  const CustomerLoading();
}

class CustomerLoaded extends CustomerState {
  final List<Customer> allCustomers;
  final List<Customer> filteredCustomers;
  final String searchQuery;
  final String selectedStaff;
  final String selectedCategory;
  final String selectedStatus;
  final String selectedTerritory;
  final DateTime? startDate;
  final DateTime? endDate;

  const CustomerLoaded({
    required this.allCustomers,
    required this.filteredCustomers,
    this.searchQuery = '',
    this.selectedStaff = 'All',
    this.selectedCategory = 'All',
    this.selectedStatus = 'All',
    this.selectedTerritory = 'All',
    this.startDate,
    this.endDate,
  });

  CustomerLoaded copyWith({
    List<Customer>? allCustomers,
    List<Customer>? filteredCustomers,
    String? searchQuery,
    String? selectedStaff,
    String? selectedCategory,
    String? selectedStatus,
    String? selectedTerritory,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return CustomerLoaded(
      allCustomers: allCustomers ?? this.allCustomers,
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStaff: selectedStaff ?? this.selectedStaff,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedTerritory: selectedTerritory ?? this.selectedTerritory,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => [
        allCustomers,
        filteredCustomers,
        searchQuery,
        selectedStaff,
        selectedCategory,
        selectedStatus,
        selectedTerritory,
        startDate,
        endDate,
      ];
}

class CustomerOperationSuccess extends CustomerState {
  final String message;
  final Customer? customer;

  const CustomerOperationSuccess(this.message, {this.customer});

  @override
  List<Object?> get props => [message, customer];
}

class CustomerError extends CustomerState {
  final String message;

  const CustomerError(this.message);

  @override
  List<Object?> get props => [message];
}
