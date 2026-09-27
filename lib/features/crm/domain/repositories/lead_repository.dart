import '../entities/lead.dart';
import '../entities/lead_enums.dart';
import '../entities/lead_stats.dart';
import '../entities/lead_note.dart';
import '../entities/lead_visit.dart';
import '../entities/lead_task.dart';
import '../entities/lead_order.dart';

abstract class LeadRepository {
  // Leads
  Future<List<Lead>> getLeads({LeadStage? stage, bool? isClosed});
  Future<Lead> getLeadById(String id);
  Future<Lead> createLead(Lead lead);
  Future<Lead> updateLead(Lead lead);
  Future<void> deleteLead(String id);
  Future<LeadStats> getLeadStats();

  // Notes
  Future<List<LeadNote>> getLeadNotes(String leadId);
  Future<LeadNote> addLeadNote(LeadNote note);

  // Visits
  Future<List<LeadVisit>> getLeadVisits(String leadId);
  Future<LeadVisit> addLeadVisit(LeadVisit visit);
  Future<LeadVisit> updateLeadVisit(LeadVisit visit);
  Future<void> deleteLeadVisit(String id);

  // Tasks
  Future<List<LeadTask>> getLeadTasks(String leadId);
  Future<LeadTask> addLeadTask(LeadTask task);
  Future<LeadTask> updateLeadTask(LeadTask task);
  Future<void> addTaskLog(String taskId, Map<String, dynamic> log);

  // Orders
  Future<List<LeadOrder>> getLeadOrders(String leadId);
  Future<LeadOrder> addLeadOrder(LeadOrder order);
  Future<LeadOrder> updateLeadOrder(LeadOrder order);
  Future<void> deleteLeadOrder(String id);
  Future<OrderPayment> addOrderPayment(OrderPayment payment);
  Future<OrderPayment> updateOrderPayment(OrderPayment payment);
  Future<void> deleteOrderPayment(String id);
}
