import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_enums.dart';
import '../../domain/repositories/lead_repository.dart';
import 'lead_event.dart';
import 'lead_state.dart';

class LeadBloc extends Bloc<LeadEvent, LeadState> {
  final LeadRepository leadRepository;

  LeadBloc({required this.leadRepository}) : super(const LeadInitial()) {
    on<LoadLeads>(_onLoadLeads);
    on<LoadLeadStats>(_onLoadLeadStats);
    on<CreateLeadEvent>(_onCreateLead);
    on<UpdateLeadEvent>(_onUpdateLead);
    on<DeleteLeadEvent>(_onDeleteLead);
    on<SearchLeads>(_onSearchLeads);
    on<RefreshLeads>(_onRefreshLeads);
  }

  Future<void> _onLoadLeads(LoadLeads event, Emitter<LeadState> emit) async {
    emit(const LeadLoading());
    try {
      final allLeads = await leadRepository.getLeads();
      final openLeads = allLeads.where((l) => !l.isClosed).toList();
      final closedLeads = allLeads.where((l) => l.isClosed).toList();
      final stats = await leadRepository.getLeadStats();

      emit(LeadsLoaded(
        allLeads: allLeads,
        openLeads: openLeads,
        closedLeads: closedLeads,
        filteredOpenLeads: openLeads,
        filteredClosedLeads: closedLeads,
        stats: stats,
      ));
    } catch (e) {
      emit(LeadError(e.toString()));
    }
  }

  Future<void> _onLoadLeadStats(
      LoadLeadStats event, Emitter<LeadState> emit) async {
    try {
      final stats = await leadRepository.getLeadStats();
      if (state is LeadsLoaded) {
        emit((state as LeadsLoaded).copyWith(stats: stats));
      }
    } catch (e) {
      emit(LeadError(e.toString()));
    }
  }

  Future<void> _onCreateLead(
      CreateLeadEvent event, Emitter<LeadState> emit) async {
    try {
      final data = event.leadData;
      final lead = Lead(
        id: '',
        leadNumber: '',
        staffName: data['staffName'] ?? '',
        name: data['name'] ?? '',
        company: data['company'] ?? '',
        phone: data['phone'] ?? '',
        email: data['email'] ?? '',
        website: data['website'] ?? '',
        gst: data['gst'] ?? '',
        territory: data['territory'] ?? '',
        address: data['address'] ?? '',
        city: data['city'] ?? '',
        state: data['state'] ?? '',
        pincode: data['pincode'] ?? '',
        country: data['country'] ?? 'India',
        date: data['date'] ?? DateTime.now(),
        source: data['source'] ?? LeadSource.call,
        stage: data['stage'] ?? LeadStage.newLead,
        rating: data['rating'] ?? 0,
        title: data['title'] ?? '',
        value: data['value'] ?? 0.0,
        note: data['note'] ?? '',
        visitImages: data['visitImages'] ?? const <String>[],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await leadRepository.createLead(lead);
      emit(const LeadOperationSuccess('Lead created successfully'));
      add(const LoadLeads());
    } catch (e) {
      emit(LeadError(e.toString()));
    }
  }

  Future<void> _onUpdateLead(
      UpdateLeadEvent event, Emitter<LeadState> emit) async {
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
        source: data['source'] ?? existing.source,
        stage: data['stage'] ?? existing.stage,
        rating: data['rating'] ?? existing.rating,
        title: data['title'] ?? existing.title,
        value: data['value'] ?? existing.value,
        note: data['note'] ?? existing.note,
      );
      await leadRepository.updateLead(updated);
      emit(const LeadOperationSuccess('Lead updated successfully'));
      add(const LoadLeads());
    } catch (e) {
      emit(LeadError(e.toString()));
    }
  }

  Future<void> _onDeleteLead(
      DeleteLeadEvent event, Emitter<LeadState> emit) async {
    try {
      await leadRepository.deleteLead(event.id);
      emit(const LeadOperationSuccess('Lead deleted successfully'));
      add(const LoadLeads());
    } catch (e) {
      emit(LeadError(e.toString()));
    }
  }

  void _onSearchLeads(SearchLeads event, Emitter<LeadState> emit) {
    if (state is LeadsLoaded) {
      final currentState = state as LeadsLoaded;
      final query = event.query.toLowerCase().trim();

      if (query.isEmpty) {
        emit(currentState.copyWith(
          filteredOpenLeads: currentState.openLeads,
          filteredClosedLeads: currentState.closedLeads,
          searchQuery: '',
        ));
      } else {
        final filteredOpen = currentState.openLeads.where((lead) {
          return lead.name.toLowerCase().contains(query) ||
              lead.company.toLowerCase().contains(query) ||
              lead.phone.contains(query) ||
              lead.city.toLowerCase().contains(query) ||
              lead.staffName.toLowerCase().contains(query) ||
              lead.leadNumber.contains(query);
        }).toList();

        final filteredClosed = currentState.closedLeads.where((lead) {
          return lead.name.toLowerCase().contains(query) ||
              lead.company.toLowerCase().contains(query) ||
              lead.phone.contains(query) ||
              lead.city.toLowerCase().contains(query) ||
              lead.staffName.toLowerCase().contains(query) ||
              lead.leadNumber.contains(query);
        }).toList();

        emit(currentState.copyWith(
          filteredOpenLeads: filteredOpen,
          filteredClosedLeads: filteredClosed,
          searchQuery: query,
        ));
      }
    }
  }

  Future<void> _onRefreshLeads(
      RefreshLeads event, Emitter<LeadState> emit) async {
    add(const LoadLeads());
  }
}
