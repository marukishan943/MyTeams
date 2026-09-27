import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import 'customer_event.dart';
import 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository customerRepository;
  RealtimeChannel? _realtimeChannel;

  CustomerBloc({required this.customerRepository})
      : super(const CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<SearchCustomers>(_onSearchCustomers);
    on<FilterCustomers>(_onFilterCustomers);
    on<CreateCustomerEvent>(_onCreateCustomer);
    on<UpdateCustomerEvent>(_onUpdateCustomer);
    on<DeleteCustomerEvent>(_onDeleteCustomer);
    on<RefreshCustomers>(_onRefreshCustomers);

    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    try {
      _realtimeChannel = Supabase.instance.client
          .channel('customers_realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'customers',
            callback: (payload) {
              add(const RefreshCustomers());
            },
          )
          .subscribe();
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _realtimeChannel?.unsubscribe();
    return super.close();
  }

  List<Customer> _applyFilters({
    required List<Customer> customers,
    required String query,
    required String staff,
    required String category,
    required String status,
    required String territory,
    DateTime? start,
    DateTime? end,
  }) {
    var result = List<Customer>.from(customers);

    if (category.isNotEmpty && category != 'All') {
      result = result.where((c) => c.category.toLowerCase() == category.toLowerCase()).toList();
    }

    if (status.isNotEmpty && status != 'All') {
      result = result.where((c) => c.status.toLowerCase() == status.toLowerCase()).toList();
    }

    if (territory.isNotEmpty && territory != 'All') {
      result = result.where((c) => c.territory.toLowerCase() == territory.toLowerCase()).toList();
    }

    if (staff.isNotEmpty && staff != 'All') {
      result = result.where((c) => c.staffName.toLowerCase().contains(staff.toLowerCase())).toList();
    }

    if (start != null) {
      final s = DateTime(start.year, start.month, start.day);
      result = result.where((c) => !c.createdAt.isBefore(s)).toList();
    }

    if (end != null) {
      final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
      result = result.where((c) => !c.createdAt.isAfter(e)).toList();
    }

    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.company.toLowerCase().contains(q) ||
            c.customerNumber.toLowerCase().contains(q) ||
            c.phone.toLowerCase().contains(q) ||
            c.city.toLowerCase().contains(q) ||
            c.territory.toLowerCase().contains(q) ||
            c.status.toLowerCase().contains(q) ||
            c.staffName.toLowerCase().contains(q);
      }).toList();
    }

    return result;
  }

  Future<void> _onLoadCustomers(
      LoadCustomers event, Emitter<CustomerState> emit) async {
    emit(const CustomerLoading());
    try {
      final customers = await customerRepository.getCustomers(
        searchQuery: event.searchQuery,
        category: event.category,
        staffName: event.staffName,
      );
      emit(CustomerLoaded(
        allCustomers: customers,
        filteredCustomers: customers,
      ));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  void _onSearchCustomers(
      SearchCustomers event, Emitter<CustomerState> emit) {
    if (state is CustomerLoaded) {
      final current = state as CustomerLoaded;
      final filtered = _applyFilters(
        customers: current.allCustomers,
        query: event.query,
        staff: current.selectedStaff,
        category: current.selectedCategory,
        status: current.selectedStatus,
        territory: current.selectedTerritory,
        start: current.startDate,
        end: current.endDate,
      );
      emit(current.copyWith(
        searchQuery: event.query,
        filteredCustomers: filtered,
      ));
    }
  }

  void _onFilterCustomers(
      FilterCustomers event, Emitter<CustomerState> emit) {
    if (state is CustomerLoaded) {
      final current = state as CustomerLoaded;
      final staff = event.staffName ?? current.selectedStaff;
      final category = event.category ?? current.selectedCategory;
      final status = event.status ?? current.selectedStatus;
      final territory = event.territory ?? current.selectedTerritory;
      final start = event.startDate;
      final end = event.endDate;

      final filtered = _applyFilters(
        customers: current.allCustomers,
        query: current.searchQuery,
        staff: staff,
        category: category,
        status: status,
        territory: territory,
        start: start,
        end: end,
      );

      emit(current.copyWith(
        selectedStaff: staff,
        selectedCategory: category,
        selectedStatus: status,
        selectedTerritory: territory,
        startDate: start,
        endDate: end,
        filteredCustomers: filtered,
      ));
    }
  }

  Future<void> _onCreateCustomer(
      CreateCustomerEvent event, Emitter<CustomerState> emit) async {
    try {
      final created = await customerRepository.createCustomer(event.customer);

      if (state is CustomerLoaded) {
        final current = state as CustomerLoaded;
        final updatedAll = [created, ...current.allCustomers];
        final filtered = _applyFilters(
          customers: updatedAll,
          query: current.searchQuery,
          staff: current.selectedStaff,
          category: current.selectedCategory,
          status: current.selectedStatus,
          territory: current.selectedTerritory,
          start: current.startDate,
          end: current.endDate,
        );
        emit(current.copyWith(
          allCustomers: updatedAll,
          filteredCustomers: filtered,
        ));
      } else {
        emit(CustomerLoaded(
          allCustomers: [created],
          filteredCustomers: [created],
        ));
      }

      emit(CustomerOperationSuccess('Customer added successfully', customer: created));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onUpdateCustomer(
      UpdateCustomerEvent event, Emitter<CustomerState> emit) async {
    try {
      final updated = await customerRepository.updateCustomer(event.customer);
      if (state is CustomerLoaded) {
        final current = state as CustomerLoaded;
        final updatedAll = current.allCustomers.map((c) => c.id == updated.id ? updated : c).toList();
        final filtered = _applyFilters(
          customers: updatedAll,
          query: current.searchQuery,
          staff: current.selectedStaff,
          category: current.selectedCategory,
          status: current.selectedStatus,
          territory: current.selectedTerritory,
          start: current.startDate,
          end: current.endDate,
        );
        emit(current.copyWith(
          allCustomers: updatedAll,
          filteredCustomers: filtered,
        ));
      }
      emit(CustomerOperationSuccess('Customer updated successfully', customer: updated));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onDeleteCustomer(
      DeleteCustomerEvent event, Emitter<CustomerState> emit) async {
    try {
      await customerRepository.deleteCustomer(event.id);
      if (state is CustomerLoaded) {
        final current = state as CustomerLoaded;
        final updatedAll = current.allCustomers.where((c) => c.id != event.id).toList();
        final filtered = _applyFilters(
          customers: updatedAll,
          query: current.searchQuery,
          staff: current.selectedStaff,
          category: current.selectedCategory,
          status: current.selectedStatus,
          territory: current.selectedTerritory,
          start: current.startDate,
          end: current.endDate,
        );
        emit(current.copyWith(
          allCustomers: updatedAll,
          filteredCustomers: filtered,
        ));
      }
      emit(const CustomerOperationSuccess('Customer deleted successfully'));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onRefreshCustomers(
      RefreshCustomers event, Emitter<CustomerState> emit) async {
    try {
      final customers = await customerRepository.getCustomers();
      if (state is CustomerLoaded) {
        final current = state as CustomerLoaded;
        final filtered = _applyFilters(
          customers: customers,
          query: current.searchQuery,
          staff: current.selectedStaff,
          category: current.selectedCategory,
          status: current.selectedStatus,
          territory: current.selectedTerritory,
          start: current.startDate,
          end: current.endDate,
        );
        emit(current.copyWith(
          allCustomers: customers,
          filteredCustomers: filtered,
        ));
      } else {
        emit(CustomerLoaded(
          allCustomers: customers,
          filteredCustomers: customers,
        ));
      }
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }
}
