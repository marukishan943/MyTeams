import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_order.dart';
import '../bloc/lead_detail_bloc.dart';
import '../bloc/lead_detail_event.dart';
import '../bloc/lead_detail_state.dart';
import 'add_order_screen.dart';
import 'add_invoice_screen.dart';
import 'add_payment_screen.dart';

const Color _kPrimaryBlue = Color(0xFF3949AB);

class OrderDetailScreen extends StatefulWidget {
  final Lead lead;
  final LeadOrder order;
  final bool fromSales;

  const OrderDetailScreen({
    super.key,
    required this.lead,
    required this.order,
    this.fromSales = false,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late LeadOrder _currentOrder;
  int? _selectedPaymentIndex;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedPaymentIndex = null;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isProforma => _currentOrder.type == 'proforma_invoice';
  bool get _isInvoice => _currentOrder.type == 'invoice';

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return BlocListener<LeadDetailBloc, LeadDetailState>(
      listener: (context, state) {
        if (state is LeadDetailLoaded) {
          final found = state.orders.where((o) => o.id == _currentOrder.id);
          if (found.isNotEmpty) {
            setState(() => _currentOrder = found.first);
          }
        }
      },
      child: _isProforma
          ? Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: _kPrimaryBlue,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Proforma Invoice #${_currentOrder.orderNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    tooltip: 'Share',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share coming soon')),
                      );
                    },
                  ),
                ],
              ),
              body: _buildOrderTab(currencyFormat),
              floatingActionButton: _buildConvertFab(),
            )
          : Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: _kPrimaryBlue,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  _isInvoice
                      ? 'Invoice #${_currentOrder.orderNumber}'
                      : 'Order #${_currentOrder.orderNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: _tabController.index == 0
                    ? [
                        // Order / Invoice Tab Actions: Edit & Delete & Share
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.white),
                          onPressed: _navigateToEditOrder,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white),
                          onPressed: _showDeleteDialog,
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, color: Colors.white),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Share coming soon')),
                            );
                          },
                        ),
                      ]
                    : [
                        // Payments Tab Actions
                        if (_selectedPaymentIndex != null &&
                            _selectedPaymentIndex! < _currentOrder.payments.length) ...[
                          // Edit Selected Payment
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.white),
                            onPressed: () => _navigateToEditPayment(
                                _currentOrder.payments[_selectedPaymentIndex!]),
                          ),
                          // Delete Selected Payment
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.white),
                            onPressed: () => _showDeletePaymentDialog(
                                _currentOrder.payments[_selectedPaymentIndex!]),
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () {
                            context
                                .read<LeadDetailBloc>()
                                .add(LoadLeadDetail(widget.lead.id));
                          },
                        ),
                      ],
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: [
                    Tab(text: _isInvoice ? 'Invoice' : 'Order'),
                    const Tab(text: 'Payments'),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderTab(currencyFormat),
                  _buildPaymentsTab(currencyFormat),
                ],
              ),
              floatingActionButton: AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  if (_tabController.index == 1) {
                    if (_currentOrder.payments.isNotEmpty || _currentOrder.isPaid) {
                      return const SizedBox.shrink();
                    }
                    return FloatingActionButton(
                      backgroundColor: _kPrimaryBlue,
                      onPressed: _navigateToAddPayment,
                      child: const Icon(Icons.add, color: Colors.white, size: 28),
                    );
                  }
                  return _buildConvertFab() ?? const SizedBox.shrink();
                },
              ),
            ),
    );
  }

  // ── Order Tab ───────────────────────────────────────────────────────
  Widget _buildOrderTab(NumberFormat currencyFormat) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDate = DateTime(
      _currentOrder.date.year,
      _currentOrder.date.month,
      _currentOrder.date.day,
    );

    String dateLabel;
    if (orderDate == today) {
      dateLabel = 'TODAY';
    } else if (orderDate == today.subtract(const Duration(days: 1))) {
      dateLabel = 'YESTERDAY';
    } else {
      dateLabel =
          DateFormat('dd MMM yyyy').format(_currentOrder.date).toUpperCase();
    }

    final isPaid = _currentOrder.isPaid;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Card (Grey Header)
          Container(
            color: const Color(0xFFF4F5FA),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lead Name with Filter/Icon
                    const Icon(
                      Icons.filter_alt,
                      color: Color(0xFF1A237E),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.lead.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ),
                    // Payment Status Pill (Unpaid / Paid)
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPaid
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFE8EAF6),
                          ),
                          child: Icon(
                            isPaid ? Icons.check : Icons.priority_high,
                            color: isPaid
                                ? const Color(0xFF2E7D32)
                                : _kPrimaryBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPaid ? 'Paid' : 'Unpaid',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isPaid
                                ? const Color(0xFF2E7D32)
                                : _kPrimaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_isProforma) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFC5CAE9)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.description, size: 16, color: _kPrimaryBlue),
                        SizedBox(width: 8),
                        Text(
                          'Originated from Proforma Invoice',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kPrimaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Date Label
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),

                // Status Badge & Staff Name
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: _getStatusBgColor(_currentOrder.status),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _currentOrder.status.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _getStatusTextColor(_currentOrder.status),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _currentOrder.staffName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items Header
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              'Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
          ),

          // Items List
          if (_currentOrder.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'No items found.',
                style: TextStyle(color: Colors.grey[500]),
              ),
            )
          else
            ..._currentOrder.items.map((item) {
              final initials = item.product.trim().isNotEmpty
                  ? item.product
                      .trim()
                      .split(' ')
                      .map((e) => e.isNotEmpty ? e[0] : '')
                      .take(2)
                      .join()
                      .toUpperCase()
                  : 'IT';

              final qtyText = item.quantity.truncateToDouble() == item.quantity
                  ? item.quantity.toStringAsFixed(0)
                  : item.quantity.toStringAsFixed(2);

              return Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    // Product initials avatar block
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAF6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _kPrimaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Product name & Qty x Rate
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'QTY: $qtyText | ₹${item.rate.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Total Item Amount
                    Text(
                      currencyFormat.format(item.total),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

          const SizedBox(height: 24),

          // Taxable Amount Bar
          Container(
            color: const Color(0xFFF9FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Taxable Amount',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  currencyFormat.format(_currentOrder.taxableAmount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),

          // Total Bar
          Container(
            color: const Color(0xFFE8EAF6),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
                Text(
                  currencyFormat.format(_currentOrder.totalAmount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ── Payments Tab ────────────────────────────────────────────────────
  Widget _buildPaymentsTab(NumberFormat currencyFormat) {
    if (_currentOrder.payments.isEmpty) {
      return const Center(
        child: Text(
          'No Record Found!',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _currentOrder.payments.length,
      itemBuilder: (context, index) {
        final payment = _currentOrder.payments[index];
        final isSelected = _selectedPaymentIndex == index;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPaymentIndex = isSelected ? null : index;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: _kPrimaryBlue, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: Color(0xFF2E7D32),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.mode,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(payment.date),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormat.format(payment.amount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _navigateToEditPayment(payment);
                    } else if (val == 'delete') {
                      _showDeletePaymentDialog(payment);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusBgColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.open:
        return const Color(0xFFE8F5E9);
      case OrderStatus.pending:
        return const Color(0xFFFFF8E1);
      case OrderStatus.cancelled:
        return const Color(0xFFFFEBEE);
      case OrderStatus.deliveryDone:
        return const Color(0xFFE0F2F1);
      case OrderStatus.converted:
        return const Color(0xFFC8E6C9);
    }
  }

  Color _getStatusTextColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.open:
        return const Color(0xFF2E7D32);
      case OrderStatus.pending:
        return const Color(0xFFF57F17);
      case OrderStatus.cancelled:
        return const Color(0xFFC62828);
      case OrderStatus.deliveryDone:
        return const Color(0xFF00796B);
      case OrderStatus.converted:
        return const Color(0xFF2E7D32);
    }
  }

  void _navigateToEditOrder() async {
    final bloc = context.read<LeadDetailBloc>();
    final result = await Navigator.push<LeadOrder>(
      context,
      MaterialPageRoute(
        builder: (_) => (_isProforma || _isInvoice)
            ? AddInvoiceScreen(
                lead: widget.lead,
                isProforma: _isProforma,
                existingInvoice: _currentOrder,
              )
            : AddOrderScreen(
                lead: widget.lead,
                existingOrder: _currentOrder,
              ),
      ),
    );
    if (result != null && mounted) {
      bloc.add(UpdateOrderEvent(result));
      setState(() => _currentOrder = result);
    }
  }

  void _showDeleteDialog() {
    final itemTypeTitle = _isProforma
        ? 'Proforma Invoice'
        : (_isInvoice ? 'Invoice' : 'Order');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $itemTypeTitle'),
        content: Text(
            'Are you sure you want to delete $itemTypeTitle #${_currentOrder.orderNumber}?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LeadDetailBloc>().add(
                    DeleteOrderEvent(_currentOrder.id, widget.lead.id),
                  );
              Navigator.pop(context); // return to sales tab
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddPayment() async {
    final bloc = context.read<LeadDetailBloc>();
    final result = await Navigator.push<OrderPayment>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPaymentScreen(order: _currentOrder),
      ),
    );
    if (result != null && mounted) {
      bloc.add(AddPaymentEvent(result, widget.lead.id));
      setState(() {
        final updatedPayments = List<OrderPayment>.from(_currentOrder.payments)
          ..add(result);
        _currentOrder = _currentOrder.copyWith(payments: updatedPayments);
      });
    }
  }

  void _navigateToEditPayment(OrderPayment payment) async {
    final bloc = context.read<LeadDetailBloc>();
    final result = await Navigator.push<OrderPayment>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPaymentScreen(
          order: _currentOrder,
          existingPayment: payment,
        ),
      ),
    );
    if (result != null && mounted) {
      bloc.add(UpdatePaymentEvent(result, widget.lead.id));
      setState(() {
        final updatedPayments = _currentOrder.payments
            .map((p) => p.id == result.id ? result : p)
            .toList();
        _currentOrder = _currentOrder.copyWith(payments: updatedPayments);
        _selectedPaymentIndex = null;
      });
    }
  }

  void _showDeletePaymentDialog(OrderPayment payment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment'),
        content: Text(
            'Are you sure you want to delete payment of ₹${payment.amount.toStringAsFixed(0)}?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LeadDetailBloc>().add(
                    DeletePaymentEvent(payment.id, widget.lead.id),
                  );
              setState(() {
                final updatedPayments = _currentOrder.payments
                    .where((p) => p.id != payment.id)
                    .toList();
                _currentOrder = _currentOrder.copyWith(payments: updatedPayments);
                _selectedPaymentIndex = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  void _handleConvert({required bool toInvoice}) async {
    final title = toInvoice ? 'Convert to Invoice' : 'Convert to Order';
    final String content;
    if (_isProforma && toInvoice) {
      content = 'Are you sure you want to convert this Proforma Invoice to an Invoice?';
    } else if (_isInvoice && !toInvoice) {
      content = 'Are you sure you want to convert this Invoice to an Order?';
    } else if (!_isInvoice && !_isProforma && toInvoice) {
      content = 'Are you sure you want to convert this Order to an Invoice?';
    } else {
      content = 'Are you sure you want to convert this document?';
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Convert'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final bloc = context.read<LeadDetailBloc>();
      final now = DateTime.now();
      final randomNum = (1000 + (now.millisecondsSinceEpoch % 9000)).toString();

      final newOrder = _currentOrder.copyWith(
        id: now.millisecondsSinceEpoch.toString(),
        orderNumber: randomNum,
        type: toInvoice ? 'invoice' : 'order',
        status: OrderStatus.open,
        payments: const [],
        createdAt: now,
      );

      if (_isProforma) {
        final updatedCurrent = _currentOrder.copyWith(status: OrderStatus.converted);
        bloc.add(UpdateOrderEvent(updatedCurrent));
      }
      
      bloc.add(AddOrderEvent(newOrder));

      Navigator.pop(context);
    }
  }

  Widget? _buildConvertFab() {
    if (_currentOrder.status == OrderStatus.converted) return null;

    if (_isProforma) {
      return _ConvertFab(
        label: 'Convert to Invoice',
        onPressed: () => _handleConvert(toInvoice: true),
      );
    } else if (_isInvoice) {
      if (widget.fromSales) return null;
      return _ConvertFab(
        label: 'Convert to Order',
        onPressed: () => _handleConvert(toInvoice: false),
      );
    }
    return null;
  }
}

class _ConvertFab extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ConvertFab({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFF3949AB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shortcut,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
