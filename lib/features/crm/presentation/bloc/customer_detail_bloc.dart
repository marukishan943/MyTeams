import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/customer_note.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/utils/customer_audit_helper.dart';
import 'customer_detail_event.dart';
import 'customer_detail_state.dart';

class CustomerDetailBloc
    extends Bloc<CustomerDetailEvent, CustomerDetailState> {
  final CustomerRepository customerRepository;

  CustomerDetailBloc({required this.customerRepository})
      : super(const CustomerDetailInitial()) {
    on<LoadCustomerDetail>(_onLoadCustomerDetail);
    on<AddCustomerNoteEvent>(_onAddCustomerNote);
    on<RefreshCustomerDetail>(_onRefreshCustomerDetail);
    on<DeleteCustomerNoteEvent>(_onDeleteCustomerNote);
  }

  Future<void> _onLoadCustomerDetail(
    LoadCustomerDetail event,
    Emitter<CustomerDetailState> emit,
  ) async {
    emit(const CustomerDetailLoading());
    try {
      final customer =
          await customerRepository.getCustomerById(event.customerId);
      final notes =
          await customerRepository.getCustomerNotes(event.customerId);
      emit(CustomerDetailLoaded(customer: customer, notes: notes));
    } catch (e) {
      emit(CustomerDetailError(e.toString()));
    }
  }

  Future<void> _onAddCustomerNote(
    AddCustomerNoteEvent event,
    Emitter<CustomerDetailState> emit,
  ) async {
    try {
      final author = event.authorName ?? CustomerAuditHelper.getAuthorName();
      final note = CustomerNote(
        id: '',
        customerId: event.customerId,
        content: CustomerAuditHelper.formatNoteContent(
          text: event.content,
          authorName: author,
        ),
        createdAt: DateTime.now(),
      );
      await customerRepository.addCustomerNote(note);
      final updatedNotes =
          await customerRepository.getCustomerNotes(event.customerId);
      if (state is CustomerDetailLoaded) {
        final current = state as CustomerDetailLoaded;
        emit(current.copyWith(notes: updatedNotes));
      }
    } catch (e) {
      emit(CustomerDetailError(e.toString()));
    }
  }

  Future<void> _onRefreshCustomerDetail(
    RefreshCustomerDetail event,
    Emitter<CustomerDetailState> emit,
  ) async {
    try {
      final customer =
          await customerRepository.getCustomerById(event.customerId);
      final notes =
          await customerRepository.getCustomerNotes(event.customerId);
      emit(CustomerDetailLoaded(customer: customer, notes: notes));
    } catch (e) {
      emit(CustomerDetailError(e.toString()));
    }
  }

  Future<void> _onDeleteCustomerNote(
    DeleteCustomerNoteEvent event,
    Emitter<CustomerDetailState> emit,
  ) async {
    try {
      await customerRepository.deleteCustomerNote(event.noteId);
      final updatedNotes =
          await customerRepository.getCustomerNotes(event.customerId);
      if (state is CustomerDetailLoaded) {
        final current = state as CustomerDetailLoaded;
        emit(current.copyWith(notes: updatedNotes));
      }
    } catch (e) {
      emit(CustomerDetailError(e.toString()));
    }
  }
}
