import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_enums.dart';
import '../../domain/entities/lead_stats.dart';
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
    on<FilterLeads>(_onFilterLeads);
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

  bool _matchesCriteria(
    Lead lead,
    String query,
    String source,
    String stage,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    // 1. Search Query
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      final matchesQuery = lead.name.toLowerCase().contains(q) ||
          lead.company.toLowerCase().contains(q) ||
          lead.phone.contains(q) ||
          lead.city.toLowerCase().contains(q) ||
          lead.staffName.toLowerCase().contains(q) ||
          lead.leadNumber.contains(q);
      if (!matchesQuery) return false;
    }

    // 2. Source Filter ('All', 'Call', 'Email', 'Website', 'Others')
    if (source.isNotEmpty && source.toLowerCase() != 'all') {
      if (lead.source.displayName.toLowerCase() != source.toLowerCase()) {
        return false;
      }
    }

    // 3. Stage Filter ('All', 'New', 'Contacted', 'Proposal Sent', 'Disqualified', 'Converted')
    if (stage.isNotEmpty && stage.toLowerCase() != 'all') {
      if (lead.stage.displayName.toLowerCase() != stage.toLowerCase()) {
        return false;
      }
    }

    // 4. Date Range
    if (startDate != null) {
      final start =
          DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
      if (lead.date.isBefore(start)) return false;
    }
    if (endDate != null) {
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      if (lead.date.isAfter(end)) return false;
    }

    return true;
  }

  void _onFilterLeads(FilterLeads event, Emitter<LeadState> emit) {
    if (state is LeadsLoaded) {
      final current = state as LeadsLoaded;
      final source = event.source ?? current.selectedSource;
      final stage = event.stage ?? current.selectedStage;
      final start = event.startDate ?? current.filterStartDate;
      final end = event.endDate ?? current.filterEndDate;
      final query = current.searchQuery;

      final filteredOpen = current.openLeads
          .where((l) => _matchesCriteria(l, query, source, stage, start, end))
          .toList();
      final filteredClosed = current.closedLeads
          .where((l) => _matchesCriteria(l, query, source, stage, start, end))
          .toList();

      final filteredAll = current.allLeads
          .where((l) => _matchesCriteria(l, query, source, stage, start, end))
          .toList();
      final updatedStats = LeadStats(
        newCount: filteredAll.where((l) => l.stage == LeadStage.newLead).length,
        contactedCount:
            filteredAll.where((l) => l.stage == LeadStage.contacted).length,
        proposalSentCount:
            filteredAll.where((l) => l.stage == LeadStage.proposalSent).length,
        disqualifiedCount:
            filteredAll.where((l) => l.stage == LeadStage.disqualified).length,
        convertedCount:
            filteredAll.where((l) => l.stage == LeadStage.converted).length,
      );

      emit(current.copyWith(
        filteredOpenLeads: filteredOpen,
        filteredClosedLeads: filteredClosed,
        selectedSource: source,
        selectedStage: stage,
        filterStartDate: start,
        filterEndDate: end,
        stats: updatedStats,
      ));
    }
  }

  void _onSearchLeads(SearchLeads event, Emitter<LeadState> emit) {
    if (state is LeadsLoaded) {
      final current = state as LeadsLoaded;
      final query = event.query.toLowerCase().trim();
      final source = current.selectedSource;
      final stage = current.selectedStage;
      final start = current.filterStartDate;
      final end = current.filterEndDate;

      final filteredOpen = current.openLeads
          .where((l) => _matchesCriteria(l, query, source, stage, start, end))
          .toList();
      final filteredClosed = current.closedLeads
          .where((l) => _matchesCriteria(l, query, source, stage, start, end))
          .toList();

      final filteredAll = current.allLeads
          .where((l) => _matchesCriteria(l, query, source, stage, start, end))
          .toList();
      final updatedStats = LeadStats(
        newCount: filteredAll.where((l) => l.stage == LeadStage.newLead).length,
        contactedCount:
            filteredAll.where((l) => l.stage == LeadStage.contacted).length,
        proposalSentCount:
            filteredAll.where((l) => l.stage == LeadStage.proposalSent).length,
        disqualifiedCount:
            filteredAll.where((l) => l.stage == LeadStage.disqualified).length,
        convertedCount:
            filteredAll.where((l) => l.stage == LeadStage.converted).length,
      );

      emit(current.copyWith(
        filteredOpenLeads: filteredOpen,
        filteredClosedLeads: filteredClosed,
        searchQuery: query,
        stats: updatedStats,
      ));
    }
  }

  Future<void> _onRefreshLeads(
      RefreshLeads event, Emitter<LeadState> emit) async {
    add(const LoadLeads());
  }
}
