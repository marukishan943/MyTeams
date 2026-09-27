import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/lead_enums.dart';
import '../../domain/entities/lead_stats.dart';
import '../models/lead_model.dart';
import '../models/lead_note_model.dart';
import '../models/lead_visit_model.dart';
import '../models/lead_task_model.dart';
import '../models/lead_order_model.dart';
import '../../domain/entities/lead_order.dart';

abstract class LeadRemoteDataSource {
  Future<List<LeadModel>> getLeads({LeadStage? stage, bool? isClosed});
  Future<LeadModel> getLeadById(String id);
  Future<LeadModel> createLead(LeadModel lead);
  Future<LeadModel> updateLead(LeadModel lead);
  Future<void> deleteLead(String id);
  Future<LeadStats> getLeadStats();

  Future<List<LeadNoteModel>> getLeadNotes(String leadId);
  Future<LeadNoteModel> addLeadNote(LeadNoteModel note);

  Future<List<LeadVisitModel>> getLeadVisits(String leadId);
  Future<LeadVisitModel> addLeadVisit(LeadVisitModel visit);
  Future<LeadVisitModel> updateLeadVisit(LeadVisitModel visit);
  Future<void> deleteLeadVisit(String id);

  Future<List<LeadTaskModel>> getLeadTasks(String leadId);
  Future<LeadTaskModel> addLeadTask(LeadTaskModel task);
  Future<LeadTaskModel> updateLeadTask(LeadTaskModel task);
  Future<void> addTaskLog(String taskId, Map<String, dynamic> log);

  Future<List<LeadOrderModel>> getLeadOrders(String leadId);
  Future<LeadOrderModel> addLeadOrder(LeadOrderModel order);
  Future<LeadOrderModel> updateLeadOrder(LeadOrderModel order);
  Future<void> deleteLeadOrder(String id);
  Future<OrderPayment> addOrderPayment(OrderPayment payment);
  Future<OrderPayment> updateOrderPayment(OrderPayment payment);
  Future<void> deleteOrderPayment(String id);
}

class LeadRemoteDataSourceImpl implements LeadRemoteDataSource {
  final SupabaseClient supabaseClient;

  LeadRemoteDataSourceImpl(this.supabaseClient);

  String? get _userId => supabaseClient.auth.currentUser?.id;

  @override
  Future<List<LeadModel>> getLeads({LeadStage? stage, bool? isClosed}) async {
    var query = supabaseClient.from('leads').select('*');

    if (_userId != null) {
      // If user is authenticated, query user's leads (or let RLS handle it)
      query = query.or('user_id.eq.$_userId,user_id.is.null');
    }

    if (stage != null) {
      query = query.eq('stage', stage.name);
    }
    if (isClosed != null) {
      query = query.eq('is_closed', isClosed);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List<dynamic>)
        .map((json) => LeadModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LeadModel> getLeadById(String id) async {
    final response = await supabaseClient
        .from('leads')
        .select('*')
        .eq('id', id)
        .single();
    return LeadModel.fromJson(response);
  }

  @override
  Future<LeadModel> createLead(LeadModel lead) async {
    final json = lead.toJson(includeId: false);
    if (_userId != null) {
      json['user_id'] = _userId;
    }
    
    // Auto-generate sequential lead number if empty
    if (lead.leadNumber.isEmpty) {
      final count = await supabaseClient
          .from('leads')
          .select('id')
          .count(CountOption.exact);
      json['lead_number'] = ((count.count) + 1).toString().padLeft(3, '0');
    }

    final response = await supabaseClient
        .from('leads')
        .insert(json)
        .select()
        .single();
    return LeadModel.fromJson(response);
  }

  @override
  Future<LeadModel> updateLead(LeadModel lead) async {
    final json = lead.toJson(includeId: false);
    final response = await supabaseClient
        .from('leads')
        .update(json)
        .eq('id', lead.id)
        .select()
        .single();
    return LeadModel.fromJson(response);
  }

  @override
  Future<void> deleteLead(String id) async {
    await supabaseClient.from('leads').delete().eq('id', id);
  }

  @override
  Future<LeadStats> getLeadStats() async {
    final response = await supabaseClient
        .from('leads')
        .select('stage');

    final list = response as List<dynamic>;
    int newCount = 0;
    int contactedCount = 0;
    int proposalSentCount = 0;
    int disqualifiedCount = 0;
    int convertedCount = 0;

    for (final item in list) {
      final stage = item['stage']?.toString();
      if (stage == LeadStage.newLead.name) newCount++;
      if (stage == LeadStage.contacted.name) contactedCount++;
      if (stage == LeadStage.proposalSent.name) proposalSentCount++;
      if (stage == LeadStage.disqualified.name) disqualifiedCount++;
      if (stage == LeadStage.converted.name) convertedCount++;
    }

    return LeadStats(
      newCount: newCount,
      contactedCount: contactedCount,
      proposalSentCount: proposalSentCount,
      disqualifiedCount: disqualifiedCount,
      convertedCount: convertedCount,
    );
  }

  // ── Notes ────────────────────────────────────────────────────────
  @override
  Future<List<LeadNoteModel>> getLeadNotes(String leadId) async {
    final response = await supabaseClient
        .from('lead_notes')
        .select('*')
        .eq('lead_id', leadId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => LeadNoteModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LeadNoteModel> addLeadNote(LeadNoteModel note) async {
    final json = note.toJson(includeId: false);
    if (_userId != null) {
      json['user_id'] = _userId;
    }
    final response = await supabaseClient
        .from('lead_notes')
        .insert(json)
        .select()
        .single();
    return LeadNoteModel.fromJson(response);
  }

  // ── Visits ───────────────────────────────────────────────────────
  @override
  Future<List<LeadVisitModel>> getLeadVisits(String leadId) async {
    final response = await supabaseClient
        .from('lead_visits')
        .select('*')
        .eq('lead_id', leadId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => LeadVisitModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LeadVisitModel> addLeadVisit(LeadVisitModel visit) async {
    final json = visit.toJson(includeId: false);
    if (_userId != null) {
      json['user_id'] = _userId;
    }
    final response = await supabaseClient
        .from('lead_visits')
        .insert(json)
        .select()
        .single();
    return LeadVisitModel.fromJson(response);
  }

  Future<LeadVisitModel> updateLeadVisit(LeadVisitModel visit) async {
    final json = visit.toJson(includeId: false);
    final response = await supabaseClient
        .from('lead_visits')
        .update(json)
        .eq('id', visit.id)
        .select()
        .single();
    return LeadVisitModel.fromJson(response);
  }

  @override
  Future<void> deleteLeadVisit(String id) async {
    await supabaseClient.from('lead_visits').delete().eq('id', id);
  }

  // ── Tasks ────────────────────────────────────────────────────────
  @override
  Future<List<LeadTaskModel>> getLeadTasks(String leadId) async {
    final response = await supabaseClient
        .from('lead_tasks')
        .select('*, task_logs(*)')
        .eq('lead_id', leadId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => LeadTaskModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LeadTaskModel> addLeadTask(LeadTaskModel task) async {
    final json = task.toJson(includeId: false);
    if (_userId != null) {
      json['user_id'] = _userId;
    }
    final response = await supabaseClient
        .from('lead_tasks')
        .insert(json)
        .select('*, task_logs(*)')
        .single();
    return LeadTaskModel.fromJson(response);
  }

  @override
  Future<LeadTaskModel> updateLeadTask(LeadTaskModel task) async {
    final json = task.toJson(includeId: false);
    final response = await supabaseClient
        .from('lead_tasks')
        .update(json)
        .eq('id', task.id)
        .select('*, task_logs(*)')
        .single();
    return LeadTaskModel.fromJson(response);
  }

  @override
  Future<void> addTaskLog(String taskId, Map<String, dynamic> log) async {
    final logData = {
      'task_id': taskId,
      'date': DateFormat('yyyy-MM-dd').format(DateFormat('dd-MMM-yyyy').parse(log['date'])),
      'start_time': log['start_time'],
      'end_time': log['end_time'],
      'note': log['note'],
    };
    await supabaseClient.from('task_logs').insert(logData);
  }

  // ── Orders ───────────────────────────────────────────────────────
  @override
  Future<List<LeadOrderModel>> getLeadOrders(String leadId) async {
    final response = await supabaseClient
        .from('lead_orders')
        .select('*, order_payments(*)')
        .eq('lead_id', leadId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => LeadOrderModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LeadOrderModel> addLeadOrder(LeadOrderModel order) async {
    final json = order.toJson(includeId: false);
    final response = await supabaseClient
        .from('lead_orders')
        .insert(json)
        .select('*, order_payments(*)')
        .single();
    return LeadOrderModel.fromJson(response);
  }

  @override
  Future<LeadOrderModel> updateLeadOrder(LeadOrderModel order) async {
    final json = order.toJson(includeId: false);
    final response = await supabaseClient
        .from('lead_orders')
        .update(json)
        .eq('id', order.id)
        .select('*, order_payments(*)')
        .single();
    return LeadOrderModel.fromJson(response);
  }

  @override
  Future<void> deleteLeadOrder(String id) async {
    await supabaseClient.from('lead_orders').delete().eq('id', id);
  }

  @override
  Future<OrderPayment> addOrderPayment(OrderPayment payment) async {
    final json = payment.toJson();
    json.remove('id');
    final response = await supabaseClient
        .from('order_payments')
        .insert(json)
        .select()
        .single();
    return OrderPayment.fromJson(response);
  }

  @override
  Future<OrderPayment> updateOrderPayment(OrderPayment payment) async {
    final json = payment.toJson();
    json.remove('id');
    final response = await supabaseClient
        .from('order_payments')
        .update(json)
        .eq('id', payment.id)
        .select()
        .single();
    return OrderPayment.fromJson(response);
  }

  @override
  Future<void> deleteOrderPayment(String id) async {
    await supabaseClient.from('order_payments').delete().eq('id', id);
  }
}
