import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/lead_order_model.dart';
import '../../domain/entities/lead_order.dart';

// ─── Events ──────────────────────────────────────────────────────────────────
abstract class SalesEvent {}

class LoadSales extends SalesEvent {}

class RefreshSales extends SalesEvent {}

// ─── States ──────────────────────────────────────────────────────────────────
abstract class SalesState {}

class SalesInitial extends SalesState {}

class SalesLoading extends SalesState {}

class SalesLoaded extends SalesState {
  final List<LeadOrder> orders;
  final List<LeadOrder> invoices;
  final List<LeadOrder> proformaInvoices;

  /// Maps leadId → 'Name, Company' (or just Name when company is empty)
  final Map<String, String> leadNames;

  SalesLoaded({
    required this.orders,
    required this.invoices,
    required this.proformaInvoices,
    required this.leadNames,
  });
}

class SalesError extends SalesState {
  final String message;
  SalesError(this.message);
}

// ─── BLoC ────────────────────────────────────────────────────────────────────
class SalesBloc extends Bloc<SalesEvent, SalesState> {
  RealtimeChannel? _realtimeChannel;
  Map<String, String> _cachedLeadNames = {};

  SalesBloc() : super(SalesInitial()) {
    on<LoadSales>(_onLoad);
    on<RefreshSales>(_onLoad);
    _subscribeToRealtime();
  }

  /// Subscribe to Supabase Realtime so any INSERT / UPDATE / DELETE on
  /// lead_orders (from Lead module or Sales module) triggers a silent refresh.
  void _subscribeToRealtime() {
    _realtimeChannel = Supabase.instance.client
        .channel('sales_lead_orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'lead_orders',
          callback: (payload) {
            // Only re-fetch if we have already loaded once (avoid double fetch on init)
            if (state is SalesLoaded) {
              add(RefreshSales());
            }
          },
        )
        .subscribe();
  }

  @override
  Future<void> close() {
    _realtimeChannel?.unsubscribe();
    return super.close();
  }

  Future<void> _onLoad(SalesEvent event, Emitter<SalesState> emit) async {
    // Show loading only on first load, not on silent realtime refresh
    if (state is! SalesLoaded) emit(SalesLoading());

    try {
      final client = Supabase.instance.client;

      // Fetch all orders with their payments in one query
      final ordersResponse = await client
          .from('lead_orders')
          .select('*, order_payments(*)')
          .order('created_at', ascending: false);

      // Fetch lead names (cache them to avoid re-fetching on every realtime ping)
      if (_cachedLeadNames.isEmpty || event is LoadSales) {
        final leadsResponse = await client
            .from('leads')
            .select('id, name, company');

        _cachedLeadNames = {};
        for (final lead in leadsResponse as List) {
          final id = lead['id'].toString();
          final name = lead['name']?.toString() ?? '';
          final company = lead['company']?.toString() ?? '';
          _cachedLeadNames[id] = company.isNotEmpty ? '$name, $company' : name;
        }
      }

      final allOrders = (ordersResponse as List)
          .map((e) => LeadOrderModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final orders =
          allOrders.where((o) => o.type == 'order').toList();
      final invoices =
          allOrders.where((o) => o.type == 'invoice').toList();
      final proformaInvoices =
          allOrders.where((o) => o.type == 'proforma_invoice').toList();

      emit(SalesLoaded(
        orders: orders,
        invoices: invoices,
        proformaInvoices: proformaInvoices,
        leadNames: _cachedLeadNames,
      ));
    } catch (e) {
      emit(SalesError('Failed to load sales: $e'));
    }
  }
}
