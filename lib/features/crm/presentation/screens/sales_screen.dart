import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/lead_model.dart';
import '../../domain/entities/lead_order.dart';
import '../bloc/lead_detail_bloc.dart';
import '../bloc/lead_detail_event.dart';
import '../bloc/sales_bloc.dart';
import '../../../../core/di/injection_container.dart';
import 'order_detail_screen.dart';
import 'add_proforma_invoice_screen.dart';

const Color _kPrimaryBlue = Color(0xFF3949AB);

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStaff = 'All';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    context.read<SalesBloc>().add(LoadSales());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _navigateToDetail(BuildContext context, LeadOrder order) async {
    // Show a brief loading indicator
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final client = Supabase.instance.client;
      Map<String, dynamic>? leadMap;

      try {
        final res = await client
            .from('leads')
            .select()
            .eq('id', order.leadId)
            .maybeSingle();
        if (res != null) leadMap = res;
      } catch (_) {}

      if (leadMap == null) {
        try {
          final custRes = await client
              .from('customers')
              .select()
              .eq('id', order.leadId)
              .maybeSingle();
          if (custRes != null) {
            final c = custRes;
            leadMap = {
              'id': c['id'],
              'name': c['name'] ?? 'Customer',
              'company': c['company'] ?? '',
              'phone': c['phone'] ?? '',
              'email': c['email'] ?? '',
              'staff_name': c['staff_name'] ?? order.staffName,
              'city': c['city'] ?? '',
              'territory': c['territory'] ?? '',
              'stage': 'customer',
              'status': 'active',
            };
          }
        } catch (_) {}
      }

      leadMap ??= {
        'id': order.leadId,
        'name': 'Client',
        'company': '',
        'phone': '',
        'email': '',
        'staff_name': order.staffName,
        'city': '',
        'territory': '',
        'stage': 'customer',
        'status': 'active',
      };

      if (!context.mounted) return;

      final lead = LeadModel.fromJson(leadMap);
      final bloc = sl<LeadDetailBloc>();
      bloc.add(LoadLeadDetail(lead.id));

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: bloc,
            child: OrderDetailScreen(
              lead: lead,
              order: order,
              fromSales: true,
            ),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Could not open detail: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showFilterDialog(List<String> staffList) {
    showDialog(
      context: context,
      builder: (context) {
        return _SalesFilterDialog(
          staffList: staffList,
          initialStaff: _selectedStaff,
          initialStartDate: _startDate,
          initialEndDate: _endDate,
          onApply: (staff, start, end) {
            setState(() {
              _selectedStaff = staff;
              _startDate = start;
              _endDate = end;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesBloc, SalesState>(
      builder: (context, state) {
        List<String> staffList = ['All'];
        if (state is SalesLoaded) {
          final allOrders = [...state.orders, ...state.invoices, ...state.proformaInvoices];
          final uniqueStaff = allOrders.map((o) => o.staffName).where((s) => s.isNotEmpty).toSet().toList();
          uniqueStaff.sort();
          staffList.addAll(uniqueStaff);
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: _kPrimaryBlue,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Sales',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _selectedStaff = 'All';
                    _startDate = null;
                    _endDate = null;
                  });
                  context.read<SalesBloc>().add(RefreshSales());
                },
              ),
              IconButton(
                icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
                onPressed: () => _showFilterDialog(staffList),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(text: 'Stats'),
                Tab(text: 'Proforma Invoices'),
                Tab(text: 'Invoices'),
                Tab(text: 'Orders'),
                Tab(text: 'Payments'),
                Tab(text: 'Inventory'),
              ],
            ),
          ),
          body: () {
            if (state is SalesLoading || state is SalesInitial) {
              return const Center(
                child: CircularProgressIndicator(color: _kPrimaryBlue),
              );
            }
            if (state is SalesError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () =>
                          context.read<SalesBloc>().add(RefreshSales()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (state is SalesLoaded) {
              // Apply filters
              List<LeadOrder> filterOrders(List<LeadOrder> orders) {
                return orders.where((o) {
                  if (_selectedStaff != 'All' && o.staffName != _selectedStaff) return false;
                  if (_startDate != null && o.date.isBefore(_startDate!)) return false;
                  if (_endDate != null && o.date.isAfter(_endDate!)) return false;
                  return true;
                }).toList();
              }

              final filteredProforma = filterOrders(state.proformaInvoices);
              final filteredInvoices = filterOrders(state.invoices);
              final filteredOrders = filterOrders(state.orders);

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildStatsTab(state, filteredProforma, filteredInvoices, filteredOrders),
                  _buildListTab(filteredProforma, state.leadNames),
                  _buildListTab(filteredInvoices, state.leadNames),
                  _buildListTab(filteredOrders, state.leadNames),
                  _buildPaymentsTab(state, filteredProforma, filteredInvoices, filteredOrders),
                  _buildInventoryTab(),
                ],
              );
            }
            return const SizedBox.shrink();
          }(),
          floatingActionButton: (_tabController.index == 1 || _tabController.index == 2)
              ? FloatingActionButton(
                  backgroundColor: _kPrimaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  child: const Icon(Icons.add, size: 28),
                  onPressed: () async {
                    final isProforma = _tabController.index == 1;
                    final salesBloc = context.read<SalesBloc>();
                    final res = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddProformaInvoiceScreen(isProforma: isProforma),
                      ),
                    );
                    if (res == true) {
                      salesBloc.add(RefreshSales());
                    }
                  },
                )
              : null,
        );
      },
    );
  }

  // ─── Stats Tab ─────────────────────────────────────────────────────────────

  Widget _buildStatsTab(SalesLoaded state, List<LeadOrder> proformas, List<LeadOrder> invoices, List<LeadOrder> orders) {
    final currencyFormat =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    double pfiTotal = 0;
    double invTotal = 0;
    double ordTotal = 0;
    
    bool hasDateFilter = _startDate != null || _endDate != null;

    for (final o in proformas) {
      if (hasDateFilter || !o.date.isBefore(startOfMonth)) pfiTotal += o.totalAmount;
    }
    for (final o in invoices) {
      if (hasDateFilter || !o.date.isBefore(startOfMonth)) invTotal += o.totalAmount;
    }
    for (final o in orders) {
      if (hasDateFilter || !o.date.isBefore(startOfMonth)) ordTotal += o.totalAmount;
    }

    String headerText = 'THIS MONTH';
    if (hasDateFilter) {
      if (_startDate != null && _endDate != null) {
        headerText = '${DateFormat('dd-MMM-yyyy').format(_startDate!)} to ${DateFormat('dd-MMM-yyyy').format(_endDate!)}';
      } else if (_startDate != null) {
        headerText = 'Since ${DateFormat('dd-MMM-yyyy').format(_startDate!)}';
      } else if (_endDate != null) {
        headerText = 'Until ${DateFormat('dd-MMM-yyyy').format(_endDate!)}';
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Text(
              headerText.toUpperCase(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Proforma\nInvoices',
                  currencyFormat.format(pfiTotal),
                  onTap: () => _tabController.animateTo(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Invoices',
                  currencyFormat.format(invTotal),
                  onTap: () => _tabController.animateTo(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Orders',
                  currencyFormat.format(ordTotal),
                  onTap: () => _tabController.animateTo(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String amount, {VoidCallback? onTap}) {
    return Material(
      color: const Color(0xFFEEF0FB),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF757575),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _kPrimaryBlue,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  // ─── List Tabs (Proforma / Invoices / Orders) ───────────────────────────────

  Widget _buildListTab(
      List<LeadOrder> items, Map<String, String> leadNames) {
    final currencyFormat =
        NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No records found',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final order = items[index];
        final showHeader = index == 0 ||
            !_isSameDay(items[index - 1].date, order.date);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) _buildDateHeader(order.date),
            GestureDetector(
              onTap: () => _navigateToDetail(context, order),
              child: _buildSalesCard(order, leadNames, currencyFormat),
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    String label;
    if (d == today) {
      label = 'TODAY';
    } else if (d == yesterday) {
      label = 'YESTERDAY';
    } else {
      label = DateFormat('dd MMM (EEE)').format(date).toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildSalesCard(
    LeadOrder order,
    Map<String, String> leadNames,
    NumberFormat currencyFormat,
  ) {
    final leadName = leadNames[order.leadId] ?? 'Unknown Lead';
    final isInvoice = order.type == 'invoice';
    final isConverted = order.status == OrderStatus.converted;

    // ── Status badge logic ────────────────────────────────────────────────────
    String statusText;
    Color statusBg;
    Color statusTextColor;
    bool showConvertIcon = false;

    if (isConverted) {
      statusText = 'Converted';
      statusBg = const Color(0xFFC8E6C9);
      statusTextColor = const Color(0xFF2E7D32);
      showConvertIcon = true;
    } else if (isInvoice) {
      if (order.isPaid) {
        statusText = 'Fully Paid';
        statusBg = const Color(0xFFC8E6C9);
        statusTextColor = const Color(0xFF2E7D32);
      } else {
        statusText = 'Unpaid';
        statusBg = const Color(0xFFE8EAF6);
        statusTextColor = _kPrimaryBlue;
      }
    } else {
      switch (order.status) {
        case OrderStatus.open:
          statusText = 'Open';
          statusBg = const Color(0xFFE8F5E9);
          statusTextColor = const Color(0xFF2E7D32);
        case OrderStatus.pending:
          statusText = 'Pending';
          statusBg = const Color(0xFFFFF8E1);
          statusTextColor = const Color(0xFFF57F17);
        case OrderStatus.cancelled:
          statusText = 'Cancelled';
          statusBg = const Color(0xFFFFEBEE);
          statusTextColor = const Color(0xFFC62828);
        case OrderStatus.deliveryDone:
          statusText = 'Delivered';
          statusBg = const Color(0xFFE0F2F1);
          statusTextColor = const Color(0xFF00796B);
        case OrderStatus.converted:
          statusText = 'Converted';
          statusBg = const Color(0xFFC8E6C9);
          statusTextColor = const Color(0xFF2E7D32);
          showConvertIcon = true;
      }
    }
    // ─────────────────────────────────────────────────────────────────────────

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Order number badge ──────────────────────────────────────────────
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              order.orderNumber,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _kPrimaryBlue,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          // ── Lead name + staff ───────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.business, size: 14, color: Colors.black87),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        leadName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 13, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.staffName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ── Amount + status badge ───────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currencyFormat.format(order.totalAmount),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showConvertIcon)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.sync_alt,
                        size: 14,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Payments Tab ─────────────────────────────────────────────────────────────

  Widget _buildPaymentsTab(SalesLoaded state, List<LeadOrder> proformas, List<LeadOrder> invoices, List<LeadOrder> orders) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final List<_PaymentItem> allPayments = [];

    // Combine all filtered orders that could have payments
    final allOrders = [...orders, ...invoices, ...proformas];

    for (final order in allOrders) {
      final leadName = state.leadNames[order.leadId] ?? 'Unknown Lead';
      for (final payment in order.payments) {
        allPayments.add(_PaymentItem(payment, order, leadName));
      }
    }

    // Sort by date descending
    allPayments.sort((a, b) => b.payment.date.compareTo(a.payment.date));

    if (allPayments.isEmpty) {
      return const Center(
        child: Text(
          'No payments found',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: allPayments.length,
      itemBuilder: (context, index) {
        final item = allPayments[index];
        final showHeader = index == 0 || !_isSameDay(allPayments[index - 1].payment.date, item.payment.date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) _buildDateHeader(item.payment.date),
            GestureDetector(
              onTap: () => _navigateToDetail(context, item.order),
              child: _buildPaymentCard(item, currencyFormat),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentCard(_PaymentItem item, NumberFormat currencyFormat) {
    String prefix = '';
    String suffix = item.order.orderNumber;

    // Try to extract a non-digit prefix and digit suffix (e.g., 'ORD-2283' -> 'ORD-', '2283')
    final match = RegExp(r'^([^\d]+)?(\d+)$').firstMatch(item.order.orderNumber);
    if (match != null) {
      prefix = match.group(1) ?? '';
      suffix = match.group(2) ?? '';
    }

    // If no prefix was found, use the type label (e.g., 'ORD-', 'INV-', 'PFI-')
    if (prefix.isEmpty) {
      prefix = '${item.order.typeLabel}-';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Order number badge ──────────────────────────────────────────────
          Container(
            width: 60,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  prefix,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _kPrimaryBlue,
                  ),
                ),
                Text(
                  suffix,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _kPrimaryBlue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ── Lead name + staff ───────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.business, size: 14, color: Colors.black87),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.leadName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 13, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.order.staffName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ── Amount + Mode badge ───────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currencyFormat.format(item.payment.amount),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _kPrimaryBlue),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.payment.mode,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildInventoryTab() {
    // Mock inventory data matching the design
    final List<Map<String, dynamic>> products = [
      {
        'name': 'TRANSPORT',
        'subname': 'Stock Out',
        'initials': 'TR',
        'stock': -10,
        'isStockOut': true,
      },
      {
        'name': 'ZINC SPRAY 200ML',
        'subname': 'ZINC SPRAY',
        'initials': 'ZS',
        'stock': 2924,
        'isStockOut': false,
      },
      {
        'name': 'ZINC SPRAY 400ML',
        'subname': 'ZINC SPRAY',
        'initials': 'ZS',
        'stock': 2980,
        'isStockOut': false,
      },
      {
        'name': 'ZINC SPRAY 500ML',
        'subname': 'ZINC SPRAY',
        'initials': 'ZS',
        'stock': 2639,
        'isStockOut': false,
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: products.length,
      separatorBuilder: (context, index) => const Divider(height: 32),
      itemBuilder: (context, index) {
        final p = products[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                p['initials'],
                style: const TextStyle(color: _kPrimaryBlue, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['name'],
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p['subname'],
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  p['stock'].toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: p['isStockOut'] ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: p['isStockOut'] ? Colors.red.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    p['isStockOut'] ? 'Low Stock' : 'In Stock',
                    style: TextStyle(
                      color: p['isStockOut'] ? Colors.red.shade700 : Colors.green.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PaymentItem {
  final OrderPayment payment;
  final LeadOrder order;
  final String leadName;

  _PaymentItem(this.payment, this.order, this.leadName);
}

class _SalesFilterDialog extends StatefulWidget {
  final List<String> staffList;
  final String initialStaff;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(String, DateTime?, DateTime?) onApply;

  const _SalesFilterDialog({
    required this.staffList,
    required this.initialStaff,
    this.initialStartDate,
    this.initialEndDate,
    required this.onApply,
  });

  @override
  State<_SalesFilterDialog> createState() => _SalesFilterDialogState();
}

class _SalesFilterDialogState extends State<_SalesFilterDialog> {
  late String _selectedStaff;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedStaff = widget.initialStaff;
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _startDate!.isAfter(_endDate!)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topRight,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 20, right: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    'Filter',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Staff', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedStaff,
                      items: widget.staffList.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() => _selectedStaff = newValue);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Date', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _selectDate(context, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.blue)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _startDate != null ? DateFormat('dd-MMM-yyyy').format(_startDate!) : 'Select',
                                    style: TextStyle(color: _startDate != null ? Colors.black : Colors.grey),
                                  ),
                                  const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('End Date', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _selectDate(context, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.blue)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _endDate != null ? DateFormat('dd-MMM-yyyy').format(_endDate!) : 'Select',
                                    style: TextStyle(color: _endDate != null ? Colors.black : Colors.grey),
                                  ),
                                  const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3949AB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: () {
                    widget.onApply(_selectedStaff, _startDate, _endDate);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
