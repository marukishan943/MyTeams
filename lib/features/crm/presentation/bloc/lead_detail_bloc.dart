import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/lead_note.dart';
import '../../domain/repositories/lead_repository.dart';
import 'lead_detail_event.dart';
import 'lead_detail_state.dart';
import 'lead_event.dart';
import 'lead_bloc.dart';

class LeadDetailBloc extends Bloc<LeadDetailEvent, LeadDetailState> {
  final LeadRepository leadRepository;
  final LeadBloc leadBloc;

  LeadDetailBloc({
    required this.leadRepository,
    required this.leadBloc,
  }) : super(const LeadDetailInitial()) {
    on<LoadLeadDetail>(_onLoadLeadDetail);
    on<UpdateLeadStageEvent>(_onUpdateLeadStage);
    on<AddNoteEvent>(_onAddNote);
    on<AddVisitEvent>(_onAddVisit);
    on<UpdateVisitEvent>(_onUpdateVisit);
    on<DeleteVisitEvent>(_onDeleteVisit);
    on<AddTaskEvent>(_onAddTask);
    on<UpdateTaskEvent>(_onUpdateTask);
    on<AddTaskLogEvent>(_onAddTaskLog);
    on<DeleteLeadDetailEvent>(_onDeleteLead);
    on<RefreshLeadDetail>(_onRefresh);
    on<AddOrderEvent>(_onAddOrder);
    on<UpdateOrderEvent>(_onUpdateOrder);
    on<DeleteOrderEvent>(_onDeleteOrder);
    on<AddPaymentEvent>(_onAddPayment);
    on<UpdatePaymentEvent>(_onUpdatePayment);
    on<DeletePaymentEvent>(_onDeletePayment);
  }

  Future<void> _onLoadLeadDetail(
      LoadLeadDetail event, Emitter<LeadDetailState> emit) async {
    emit(const LeadDetailLoading());
    try {
      final lead = await leadRepository.getLeadById(event.leadId);
      final notes = await leadRepository.getLeadNotes(event.leadId);
      final visits = await leadRepository.getLeadVisits(event.leadId);
      final tasks = await leadRepository.getLeadTasks(event.leadId);
      final orders = await leadRepository.getLeadOrders(event.leadId);

      emit(LeadDetailLoaded(
        lead: lead,
        notes: notes,
        visits: visits,
        tasks: tasks,
        orders: orders,
      ));
    } catch (e) {
      emit(LeadDetailError(e.toString()));
    }
  }

  Future<void> _onUpdateLeadStage(
      UpdateLeadStageEvent event, Emitter<LeadDetailState> emit) async {
    try {
      final existing = await leadRepository.getLeadById(event.leadId);
      final data = event.leadData;
      final updated = existing.copyWith(
        staffName: data['staffName'] ?? existing.staffName,
        name: data['name'] ?? existing.name,
        company: data['company'] ?? existing.company,
        phone: data['phone'] ?? existing.phone,
        email: data['email'] ?? existing.email,
        website: data['website'] ?? existing.website,
        gst: data['gst'] ?? existing.gst,
        territory: data['territory'] ?? existing.territory,
        address: data['address'] ?? existing.address,
        city: data['city'] ?? existing.city,
        state: data['state'] ?? existing.state,
        pincode: data['pincode'] ?? existing.pincode,
        country: data['country'] ?? existing.country,
        date: data['date'] ?? existing.date,
        source: data['source'] ?? existing.source,
        stage: data['stage'] ?? existing.stage,
        rating: data['rating'] ?? existing.rating,
        title: data['title'] ?? existing.title,
        value: data['value'] ?? existing.value,
        note: data['note'] ?? existing.note,
        isClosed: data['isClosed'] ?? existing.isClosed,
      );
      await leadRepository.updateLead(updated);
      leadBloc.add(const LoadLeads());
      add(LoadLeadDetail(event.leadId));
      emit(const LeadDetailOperationSuccess('Lead updated successfully'));
    } catch (e) {
      emit(LeadDetailError(e.toString()));
    }
  }

  Future<void> _onAddNote(
      AddNoteEvent event, Emitter<LeadDetailState> emit) async {
    try {
      final note = LeadNote(
        id: '',
        leadId: event.leadId,
        content: event.content,
        createdAt: DateTime.now(),
      );
      await leadRepository.addLeadNote(note);
      final updatedNotes = await leadRepository.getLeadNotes(event.leadId);
      if (state is LeadDetailLoaded) {
        final current = state as LeadDetailLoaded;
        emit(current.copyWith(notes: updatedNotes));
      }
    } catch (e) {
      emit(LeadDetailError(e.toString()));
    }
  }

  Future<void> _onAddVisit(
      AddVisitEvent event, Emitter<LeadDetailState> emit) async {
    try {
      await leadRepository.addLeadVisit(event.visit);
      final updatedVisits = await leadRepository.getLeadVisits(event.visit.leadId);
      if (state is LeadDetailLoaded) {
        final current = state as LeadDetailLoaded;
        emit(current.copyWith(visits: updatedVisits));
      }
      emit(const LeadDetailOperationSuccess('Visit added successfully'));
    } catch (e) {
      emit(LeadDetailError(e.toString()));
    }
  }

  Future<void> _onUpdateVisit(
      UpdateVisitEvent event, Emitter<LeadDetailState> emit) async {
    try {
      await leadRepository.updateLeadVisit(event.visit);
      final updatedVisits = await leadRepository.getLeadVisits(event.visit.leadId);
      if (state is LeadDetailLoaded) {
        final current = state as LeadDetailLoaded;
        emit(current.copyWith(visits: updatedVisits));
      }
      emit(const LeadDetailOperationSuccess('Visit updated successfully'));
    } catch (e) {
      emit(LeadDetailError(e.toString()));
    }
  }

  Future<void> _onDeleteVisit(
      DeleteVisitEvent event, Emitter<LeadDetailState> emit) async {
    try {
      await leadRepository.deleteLeadVisit(event.visitId);
      final updatedVisits = await leadRepository.getLeadVisits(event.leadId);
      if (state is LeadDetailLoaded) {
        final current = state as LeadDetailLoaded;
        emit(current.copyWith(visits: updatedVisits));
      }
      emit(const LeadDetailOperationSuccess('Visit deleted successfully'));
    } catch (e) {
      emit(LeadDetailError(e.toString()));
    }
  }

  Future<void> _onAddTask(
      AddTaskEvent event, Emitter<LeadDetailState> emit) async {
    try {
      await leadRepository.addLeadTask(event.task);
      final updatedTasks = await leadRepository.getLeadTasks(event.task.leadId);
      if (state is LeadDetailLoaded) {
        final current = state as LeadDetailLoaded;
        emit(current.copyWith(tasks: updatedTasks));
      }
      emit(const LeadDetailOperationSuccess('Task added successfully'));
    } catch (e) {
      emit(LeadDetailError(e.toString()));
    }
  }

  Future<void> _onUpdateTask(
      UpdateTaskEvent event, Emitter<LeadDetailState> emit) async {
    try {
      await leadRepository.updateLeadTask(event.task);
      final updatedTasks = await leadRepository.getLeadTasks(event.task.leadId);
      if (state is LeadDetailLoaded) {
        final current = state as LeadDetailLoaded;
        emit(current.copyWith(tasks: updatedTasks));
      }
      emit(const LeadDetailOperationSuccess('Task updated successfully'));
    } catch (e) {
      emit(LeadDetailError(e.toString()));
    }
  }

  Future<void> _onAddTaskLog(
      AddTaskLogEvent event, Emitter<LeadDetailState> emit) async {
    try {
      await leadRepository.addTaskLog(event.taskId, event.log);
      final updatedTasks = await leadRepository.getLeadTasks(event.leadId);
      if (state is LeadDetailLoaded) {
        final current = state as LeadDetailLoaded;
        emit(current.copyWith(tasks: updatedTasks));
      }
      emit(const LeadDetailOperationSuccess('Log added successfully'));
    } catch (e) {
      emit(LeadDetailError(e.toString()));
    }
  }

  Future<void> _onDeleteLead(
      DeleteLeadDetailEvent event, Emitter<LeadDetailState> emit) async {
    try {
      await leadRepository.deleteLead(event.leadId);
      leadBloc.add(const LoadLeads());
      emit(const LeadDetailOperationSuccess('Lead deleted successfully'));
    } catch (e) {
      emit(LeadDetailError(e.toString()));
    }
  }

  Future<void> _onRefresh(
      RefreshLeadDetail event, Emitter<LeadDetailState> emit) async {
    add(LoadLeadDetail(event.leadId));
  }

  Future<void> _onAddOrder(
      AddOrderEvent event, Emitter<LeadDetailState> emit) async {
    try {
      await leadRepository.addLeadOrder(event.order);
      final updatedOrders = await leadRepository.getLeadOrders(event.order.leadId);
      if (state is LeadDetailLoaded) {
        final current = state as LeadDetailLoaded;
        emit(current.copyWith(orders: updatedOrders));
      }
      emit(const LeadDetailOperationSuccess('Order added successfully'));
    } catch (e) {
      emit(LeadDetailError(e.toString()));
    }
  }

  Future<void> _onUpdateOrder(
      UpdateOrderEvent event, Emitter<LeadDetailState> emit) async {
    try {
      await leadRepository.updateLeadOrder(event.order);
      final updatedOrders = await leadRepository.getLeadOrders(event.order.leadId);
      if (state is LeadDetailLoaded) {
        final current = state as LeadDetailLoaded;
        emit(current.copyWith(orders: updatedOrders));
      }
      emit(const LeadDetailOperationSuccess('Order updated successfully'));
    } catch (e) {
      emit(LeadDetailError(e.toString()));
    }
  }

  Future<void> _onDeleteOrder(
      DeleteOrderEvent event, Emitter<LeadDetailState> emit) async {
    try {
      await leadRepository.deleteLeadOrder(event.orderId);
      final updatedOrders = await leadRepository.getLeadOrders(event.leadId);
      if (state is LeadDetailLoaded) {
        final current = state as LeadDetailLoaded;
        emit(current.copyWith(orders: updatedOrders));
      }
      emit(const LeadDetailOperationSuccess('Order deleted successfully'));
    } catch (e) {
      emit(LeadDetailError(e.toString()));
    }
  }

  Future<void> _onAddPayment(
      AddPaymentEvent event, Emitter<LeadDetailState> emit) async {
    try {
      await leadRepository.addOrderPayment(event.payment);
      final updatedOrders = await leadRepository.getLeadOrders(event.leadId);
      if (state is LeadDetailLoaded) {
        final current = state as LeadDetailLoaded;
        emit(current.copyWith(orders: updatedOrders));
      }
      emit(const LeadDetailOperationSuccess('Payment added successfully'));
    } catch (e) {
      emit(LeadDetailError(e.toString()));
    }
  }

  Future<void> _onUpdatePayment(
      UpdatePaymentEvent event, Emitter<LeadDetailState> emit) async {
    try {
      await leadRepository.updateOrderPayment(event.payment);
      final updatedOrders = await leadRepository.getLeadOrders(event.leadId);
      if (state is LeadDetailLoaded) {
        final current = state as LeadDetailLoaded;
        emit(current.copyWith(orders: updatedOrders));
      }
      emit(const LeadDetailOperationSuccess('Payment updated successfully'));
    } catch (e) {
      emit(LeadDetailError(e.toString()));
    }
  }

  Future<void> _onDeletePayment(
      DeletePaymentEvent event, Emitter<LeadDetailState> emit) async {
    try {
      await leadRepository.deleteOrderPayment(event.paymentId);
      final updatedOrders = await leadRepository.getLeadOrders(event.leadId);
      if (state is LeadDetailLoaded) {
        final current = state as LeadDetailLoaded;
        emit(current.copyWith(orders: updatedOrders));
      }
      emit(const LeadDetailOperationSuccess('Payment deleted successfully'));
    } catch (e) {
      emit(LeadDetailError(e.toString()));
    }
  }
}
