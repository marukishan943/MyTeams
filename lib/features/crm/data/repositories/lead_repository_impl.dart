import 'dart:developer' as developer;
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_enums.dart';
import '../../domain/entities/lead_stats.dart';
import '../../domain/entities/lead_note.dart';
import '../../domain/entities/lead_visit.dart';
import '../../domain/entities/lead_task.dart';
import '../../domain/entities/lead_order.dart';
import '../../domain/repositories/lead_repository.dart';
import '../datasources/lead_remote_data_source.dart';
import '../models/lead_model.dart';
import '../models/lead_note_model.dart';
import '../models/lead_visit_model.dart';
import '../models/lead_task_model.dart';
import '../models/lead_order_model.dart';

class LeadRepositoryImpl implements LeadRepository {
  final LeadRemoteDataSource remoteDataSource;

  // In-memory fallback / cache
  final List<Lead> _localLeads = _generateDefaultLeads();
  final List<LeadNote> _localNotes = [];
  final List<LeadVisit> _localVisits = [];
  final List<LeadTask> _localTasks = [];
  final List<LeadOrder> _localOrders = [];

  LeadRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Lead>> getLeads({LeadStage? stage, bool? isClosed}) async {
    try {
      final remoteLeads = await remoteDataSource.getLeads(stage: stage, isClosed: isClosed);
      if (remoteLeads.isNotEmpty) {
        return remoteLeads;
      }
    } catch (e) {
      developer.log('Supabase fetch leads fallback: $e', name: 'LeadRepositoryImpl');
    }

    // Local fallback
    var result = List<Lead>.from(_localLeads);
    if (stage != null) {
      result = result.where((l) => l.stage == stage).toList();
    }
    if (isClosed != null) {
      result = result.where((l) => l.isClosed == isClosed).toList();
    }
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  @override
  Future<Lead> getLeadById(String id) async {
    try {
      return await remoteDataSource.getLeadById(id);
    } catch (e) {
      developer.log('Supabase getLeadById fallback: $e', name: 'LeadRepositoryImpl');
      return _localLeads.firstWhere(
        (l) => l.id == id,
        orElse: () => _generateDefaultLeads().first,
      );
    }
  }

  @override
  Future<Lead> createLead(Lead lead) async {
    try {
      final leadModel = LeadModel.fromEntity(lead);
      final created = await remoteDataSource.createLead(leadModel);
      _localLeads.insert(0, created);
      return created;
    } catch (e) {
      developer.log('Supabase createLead fallback: $e', name: 'LeadRepositoryImpl');
      final newNumber = (_localLeads.length + 1).toString().padLeft(3, '0');
      final fallbackLead = lead.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        leadNumber: lead.leadNumber.isEmpty ? newNumber : lead.leadNumber,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _localLeads.insert(0, fallbackLead);
      return fallbackLead;
    }
  }

  @override
  Future<Lead> updateLead(Lead lead) async {
    try {
      final leadModel = LeadModel.fromEntity(lead);
      final updated = await remoteDataSource.updateLead(leadModel);
      final index = _localLeads.indexWhere((l) => l.id == lead.id);
      if (index != -1) _localLeads[index] = updated;
      return updated;
    } catch (e) {
      developer.log('Supabase updateLead fallback: $e', name: 'LeadRepositoryImpl');
      final index = _localLeads.indexWhere((l) => l.id == lead.id);
      if (index != -1) {
        final updated = lead.copyWith(updatedAt: DateTime.now());
        _localLeads[index] = updated;
        return updated;
      }
      return lead;
    }
  }

  @override
  Future<void> deleteLead(String id) async {
    try {
      await remoteDataSource.deleteLead(id);
    } catch (e) {
      developer.log('Supabase deleteLead fallback: $e', name: 'LeadRepositoryImpl');
    }
    _localLeads.removeWhere((l) => l.id == id);
  }

  @override
  Future<LeadStats> getLeadStats() async {
    try {
      return await remoteDataSource.getLeadStats();
    } catch (e) {
      developer.log('Supabase getLeadStats fallback: $e', name: 'LeadRepositoryImpl');
      final now = DateTime.now();
      final thisMonth = _localLeads.where(
        (l) => l.date.month == now.month && l.date.year == now.year,
      );
      return LeadStats(
        newCount: thisMonth.where((l) => l.stage == LeadStage.newLead).length,
        contactedCount:
            thisMonth.where((l) => l.stage == LeadStage.contacted).length,
        proposalSentCount:
            thisMonth.where((l) => l.stage == LeadStage.proposalSent).length,
        disqualifiedCount:
            thisMonth.where((l) => l.stage == LeadStage.disqualified).length,
        convertedCount:
            thisMonth.where((l) => l.stage == LeadStage.converted).length,
      );
    }
  }

  // ── Notes ────────────────────────────────────────────────────────
  @override
  Future<List<LeadNote>> getLeadNotes(String leadId) async {
    try {
      final notes = await remoteDataSource.getLeadNotes(leadId);
      if (notes.isNotEmpty) return notes;
    } catch (e) {
      developer.log('Supabase getLeadNotes fallback: $e', name: 'LeadRepositoryImpl');
    }
    return _localNotes.where((n) => n.leadId == leadId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<LeadNote> addLeadNote(LeadNote note) async {
    try {
      final noteModel = LeadNoteModel.fromEntity(note);
      final created = await remoteDataSource.addLeadNote(noteModel);
      _localNotes.insert(0, created);
      return created;
    } catch (e) {
      developer.log('Supabase addLeadNote fallback: $e', name: 'LeadRepositoryImpl');
      _localNotes.insert(0, note);
      return note;
    }
  }

  // ── Visits ───────────────────────────────────────────────────────
  @override
  Future<List<LeadVisit>> getLeadVisits(String leadId) async {
    try {
      final visits = await remoteDataSource.getLeadVisits(leadId);
      if (visits.isNotEmpty) return visits;
    } catch (e) {
      developer.log('Supabase getLeadVisits fallback: $e', name: 'LeadRepositoryImpl');
    }
    return _localVisits.where((v) => v.leadId == leadId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<LeadVisit> addLeadVisit(LeadVisit visit) async {
    try {
      final visitModel = LeadVisitModel.fromEntity(visit);
      final created = await remoteDataSource.addLeadVisit(visitModel);
      _localVisits.insert(0, created);
      return created;
    } catch (e) {
      developer.log('Supabase addLeadVisit fallback: $e', name: 'LeadRepositoryImpl');
      _localVisits.insert(0, visit);
      return visit;
    }
  }

  @override
  Future<LeadVisit> updateLeadVisit(LeadVisit visit) async {
    try {
      final visitModel = LeadVisitModel.fromEntity(visit);
      final updated = await remoteDataSource.updateLeadVisit(visitModel);
      final index = _localVisits.indexWhere((v) => v.id == visit.id);
      if (index != -1) {
        _localVisits[index] = updated;
      }
      return updated;
    } catch (e) {
      developer.log('Supabase updateLeadVisit fallback: $e', name: 'LeadRepositoryImpl');
      final index = _localVisits.indexWhere((v) => v.id == visit.id);
      if (index != -1) {
        _localVisits[index] = visit;
      }
      return visit;
    }
  }

  @override
  Future<void> deleteLeadVisit(String id) async {
    try {
      await remoteDataSource.deleteLeadVisit(id);
    } catch (e) {
      developer.log('Supabase deleteLeadVisit fallback: $e', name: 'LeadRepositoryImpl');
    }
    _localVisits.removeWhere((v) => v.id == id);
  }

  // ── Tasks ────────────────────────────────────────────────────────
  @override
  Future<List<LeadTask>> getLeadTasks(String leadId) async {
    try {
      final tasks = await remoteDataSource.getLeadTasks(leadId);
      if (tasks.isNotEmpty) return tasks;
    } catch (e) {
      developer.log('Supabase getLeadTasks fallback: $e', name: 'LeadRepositoryImpl');
    }
    return _localTasks.where((t) => t.leadId == leadId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<LeadTask> addLeadTask(LeadTask task) async {
    try {
      final taskModel = LeadTaskModel.fromEntity(task);
      final created = await remoteDataSource.addLeadTask(taskModel);
      _localTasks.insert(0, created);
      return created;
    } catch (e) {
      developer.log('Supabase addLeadTask fallback: $e', name: 'LeadRepositoryImpl');
      _localTasks.insert(0, task);
      return task;
    }
  }

  @override
  Future<LeadTask> updateLeadTask(LeadTask task) async {
    try {
      final taskModel = LeadTaskModel.fromEntity(task);
      final updated = await remoteDataSource.updateLeadTask(taskModel);
      final index = _localTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _localTasks[index] = updated;
      }
      return updated;
    } catch (e) {
      developer.log('Supabase updateLeadTask fallback: $e', name: 'LeadRepositoryImpl');
      final index = _localTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _localTasks[index] = task;
      }
      return task;
    }
  }

  @override
  Future<void> addTaskLog(String taskId, Map<String, dynamic> log) async {
    try {
      await remoteDataSource.addTaskLog(taskId, log);
    } catch (e) {
      developer.log('Supabase addTaskLog fallback: $e', name: 'LeadRepositoryImpl');
      // No local fallback needed since we fetch freshly or they are updated locally anyway
    }
  }

  // ── Orders ───────────────────────────────────────────────────────
  @override
  Future<List<LeadOrder>> getLeadOrders(String leadId) async {
    try {
      final remoteOrders = await remoteDataSource.getLeadOrders(leadId);
      return remoteOrders;
    } catch (e) {
      developer.log('Supabase getLeadOrders fallback: $e', name: 'LeadRepositoryImpl');
      return _localOrders.where((o) => o.leadId == leadId).toList();
    }
  }

  @override
  Future<LeadOrder> addLeadOrder(LeadOrder order) async {
    try {
      final orderModel = LeadOrderModel.fromEntity(order);
      final created = await remoteDataSource.addLeadOrder(orderModel);
      _localOrders.insert(0, created);
      return created;
    } catch (e) {
      developer.log('Supabase addLeadOrder fallback: $e', name: 'LeadRepositoryImpl');
      _localOrders.insert(0, order);
      return order;
    }
  }

  @override
  Future<LeadOrder> updateLeadOrder(LeadOrder order) async {
    try {
      final orderModel = LeadOrderModel.fromEntity(order);
      final updated = await remoteDataSource.updateLeadOrder(orderModel);
      final index = _localOrders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _localOrders[index] = updated;
      }
      return updated;
    } catch (e) {
      developer.log('Supabase updateLeadOrder fallback: $e', name: 'LeadRepositoryImpl');
      final index = _localOrders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _localOrders[index] = order;
      }
      return order;
    }
  }

  @override
  Future<void> deleteLeadOrder(String id) async {
    try {
      await remoteDataSource.deleteLeadOrder(id);
      _localOrders.removeWhere((o) => o.id == id);
    } catch (e) {
      developer.log('Supabase deleteLeadOrder fallback: $e', name: 'LeadRepositoryImpl');
      _localOrders.removeWhere((o) => o.id == id);
    }
  }

  @override
  Future<OrderPayment> addOrderPayment(OrderPayment payment) async {
    try {
      final created = await remoteDataSource.addOrderPayment(payment);
      final index = _localOrders.indexWhere((o) => o.id == payment.orderId);
      if (index != -1) {
        final existing = _localOrders[index];
        final updatedPayments = List<OrderPayment>.from(existing.payments)..add(created);
        _localOrders[index] = existing.copyWith(payments: updatedPayments);
      }
      return created;
    } catch (e) {
      developer.log('Supabase addOrderPayment fallback: $e', name: 'LeadRepositoryImpl');
      final index = _localOrders.indexWhere((o) => o.id == payment.orderId);
      if (index != -1) {
        final existing = _localOrders[index];
        final updatedPayments = List<OrderPayment>.from(existing.payments)..add(payment);
        _localOrders[index] = existing.copyWith(payments: updatedPayments);
      }
      return payment;
    }
  }

  @override
  Future<OrderPayment> updateOrderPayment(OrderPayment payment) async {
    try {
      final updated = await remoteDataSource.updateOrderPayment(payment);
      final index = _localOrders.indexWhere((o) => o.id == payment.orderId);
      if (index != -1) {
        final existing = _localOrders[index];
        final updatedPayments = existing.payments.map((p) => p.id == payment.id ? updated : p).toList();
        _localOrders[index] = existing.copyWith(payments: updatedPayments);
      }
      return updated;
    } catch (e) {
      developer.log('Supabase updateOrderPayment fallback: $e', name: 'LeadRepositoryImpl');
      final index = _localOrders.indexWhere((o) => o.id == payment.orderId);
      if (index != -1) {
        final existing = _localOrders[index];
        final updatedPayments = existing.payments.map((p) => p.id == payment.id ? payment : p).toList();
        _localOrders[index] = existing.copyWith(payments: updatedPayments);
      }
      return payment;
    }
  }

  @override
  Future<void> deleteOrderPayment(String id) async {
    try {
      await remoteDataSource.deleteOrderPayment(id);
      for (int i = 0; i < _localOrders.length; i++) {
        final existing = _localOrders[i];
        if (existing.payments.any((p) => p.id == id)) {
          final updatedPayments = existing.payments.where((p) => p.id != id).toList();
          _localOrders[i] = existing.copyWith(payments: updatedPayments);
        }
      }
    } catch (e) {
      developer.log('Supabase deleteOrderPayment fallback: $e', name: 'LeadRepositoryImpl');
      for (int i = 0; i < _localOrders.length; i++) {
        final existing = _localOrders[i];
        if (existing.payments.any((p) => p.id == id)) {
          final updatedPayments = existing.payments.where((p) => p.id != id).toList();
          _localOrders[i] = existing.copyWith(payments: updatedPayments);
        }
      }
    }
  }

  static List<Lead> _generateDefaultLeads() {
    final now = DateTime.now();
    return [
      Lead(
        id: '1',
        leadNumber: '074',
        staffName: 'Bhavin Prajapati',
        name: 'abc',
        company: 'abc',
        phone: '+911234567891',
        email: 'marukishan67@gmail.com',
        website: 'www.abc.com',
        gst: '18',
        territory: 'METODA',
        source: LeadSource.call,
        stage: LeadStage.newLead,
        rating: 3,
        date: now,
        createdAt: now,
        updatedAt: now,
      ),
      Lead(
        id: '2',
        leadNumber: '073',
        staffName: 'Mehul Ajagya',
        name: 'Mr. Vinay Gajera',
        company: 'Gajera Enterprises',
        phone: '+919876543210',
        email: 'vinay.gajera@gmail.com',
        city: 'GONDAL',
        address: 'Nr. Gondal Bus Stand',
        territory: 'GONDAL',
        source: LeadSource.website,
        stage: LeadStage.newLead,
        rating: 4,
        date: DateTime(2026, 6, 21),
        createdAt: DateTime(2026, 6, 21),
        updatedAt: DateTime(2026, 6, 21),
      ),
      Lead(
        id: '3',
        leadNumber: '071',
        staffName: 'Mehul Ajagya',
        name: 'Narayanbhai - Petlad',
        company: 'Narayan Trading Co.',
        phone: '+919988776655',
        city: 'Petlad',
        territory: 'PETLAD',
        source: LeadSource.call,
        stage: LeadStage.newLead,
        rating: 2,
        date: DateTime(2026, 5, 8),
        createdAt: DateTime(2026, 5, 8),
        updatedAt: DateTime(2026, 5, 8),
      ),
    ];
  }
}
