import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_order.dart';
import 'add_item_screen.dart';

const Color _kPrimaryBlue = Color(0xFF3949AB);

/// Reusable screen for both "Add Invoice" and "Add Proforma Invoice".
/// Pass [isProforma] = true for a Proforma Invoice.
class AddInvoiceScreen extends StatefulWidget {
  final Lead lead;
  final bool isProforma;
  final LeadOrder? existingInvoice;
  final bool isConverting;

  const AddInvoiceScreen({
    super.key,
    required this.lead,
    this.isProforma = false,
    this.existingInvoice,
    this.isConverting = false,
  });

  @override
  State<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends State<AddInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  DateTime? _selectedDueDate;
  late String _selectedStaff;

  final List<OrderItem> _items = [];

  String _discountType = 'fixed'; // 'fixed' or 'percent'
  late final TextEditingController _discountController;
  bool _roundOff = false;
  bool _isSaving = false;

  List<String> _staffList = [
    'ADMIN ADMIN',
    'JITESHBHAI VASANIYA',
    'Kishan Maru',
    'Mehul Ajagya',
    'Sachin Chauhan',
  ];

  Future<void> _fetchAdminUsers() async {
    try {
      final response = await Supabase.instance.client
          .from('team_users')
          .select('first_name, last_name, is_active')
          .order('first_name', ascending: true);

      final List<String> loaded = [];
      for (final item in response) {
        if (item['is_active'] == false) continue;
        final first = (item['first_name'] ?? '').toString().trim();
        final last = (item['last_name'] ?? '').toString().trim();
        final fullName = [first, last].where((s) => s.isNotEmpty).join(' ');
        if (fullName.isNotEmpty && !loaded.contains(fullName)) {
          loaded.add(fullName);
        }
      }

      if (loaded.isNotEmpty && mounted) {
        setState(() {
          _staffList = loaded;
          if (!_staffList.contains(_selectedStaff)) {
            _selectedStaff = _staffList.first;
          }
        });
      }
    } catch (_) {}
  }

  String get _screenTitle =>
      widget.isProforma ? 'Add Proforma Invoice' : 'Add Invoice';

  @override
  void initState() {
    super.initState();
    _fetchAdminUsers();
    if (widget.existingInvoice != null) {
      final o = widget.existingInvoice!;
      _selectedDate = o.date;
      _selectedDueDate = o.dueDate;
      _selectedStaff = o.staffName;
      _items.addAll(o.items);
      _discountType = o.discountType;
      _discountController =
          TextEditingController(text: o.discountValue.toStringAsFixed(0));
      _roundOff = o.roundOff;
    } else {
      _selectedDate = DateTime.now();
      _selectedDueDate = DateTime.now().add(const Duration(days: 6));
      _selectedStaff = _staffList.contains(widget.lead.staffName)
          ? widget.lead.staffName
          : (widget.lead.staffName.isNotEmpty
              ? widget.lead.staffName
              : _staffList.first);
      _discountController = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  // ── Calculation helpers ─────────────────────────────────────────────
  double get _taxableAmount {
    double sum = 0.0;
    for (final item in _items) {
      sum += item.taxableAmount;
    }
    return sum;
  }

  double get _totalDiscount {
    final discVal = double.tryParse(_discountController.text.trim()) ?? 0.0;
    if (_discountType == 'percent') {
      return (_taxableAmount * discVal) / 100.0;
    }
    return discVal;
  }

  double get _totalTax {
    double sum = 0.0;
    for (final item in _items) {
      sum += item.taxAmount;
    }
    return sum;
  }

  double get _calculatedTotal {
    double sub = _taxableAmount - _totalDiscount;
    if (sub < 0) sub = 0;
    double total = sub + _totalTax;
    if (_roundOff) {
      return total.roundToDouble();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _kPrimaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingInvoice != null
              ? (widget.isProforma ? 'Edit Proforma Invoice' : 'Edit Invoice')
              : _screenTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client Summary Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.business_outlined,
                              color: _kPrimaryBlue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.lead.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0E7FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        widget.isProforma
                                            ? 'PROFORMA'
                                            : 'INVOICE',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _kPrimaryBlue,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.lead.company.isNotEmpty ||
                                    widget.lead.phone.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    [widget.lead.company, widget.lead.phone]
                                        .where((s) => s.isNotEmpty)
                                        .join(' • '),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Date & Due Date row
                    Row(
                      children: [
                        // Date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Date'),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 11),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    border: Border.all(
                                        color: const Color(0xFFCBD5E1),
                                        width: 1.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined,
                                          color: _kPrimaryBlue, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          DateFormat('dd-MMM-yyyy')
                                              .format(_selectedDate),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Due Date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Due Date'),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: _pickDueDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 11),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    border: Border.all(
                                        color: const Color(0xFFCBD5E1),
                                        width: 1.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.event_outlined,
                                          color: _selectedDueDate != null
                                              ? _kPrimaryBlue
                                              : const Color(0xFF94A3B8),
                                          size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _selectedDueDate != null
                                              ? DateFormat('dd-MMM-yyyy')
                                                  .format(_selectedDueDate!)
                                              : 'Select due date',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: _selectedDueDate != null
                                                ? FontWeight.w500
                                                : FontWeight.w400,
                                            color: _selectedDueDate != null
                                                ? const Color(0xFF1E293B)
                                                : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Reference
                    _buildLabel('Reference'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        border: Border.all(
                            color: const Color(0xFFCBD5E1), width: 1.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _staffList.contains(_selectedStaff)
                            ? _selectedStaff
                            : (_staffList.isNotEmpty ? _staffList.first : null),
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: Color(0xFF475569)),
                        items: _staffList.map((staff) {
                          return DropdownMenuItem(
                            value: staff,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.badge_outlined,
                                  size: 18,
                                  color: _kPrimaryBlue,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    staff,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF1E293B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedStaff = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Items Section Header ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Text(
                        ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_items.length} added',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kPrimaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _navigateToAddItem,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Add Item',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),

            // ── Items List ────────────────────────────────────────────────
            if (_items.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 36, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      const Text(
                        'No items added yet',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap "+ Add Item" above to add products to this invoice',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                itemCount: _items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final initials = item.product.length >= 2
                      ? item.product.substring(0, 2).toUpperCase()
                      : item.product.toUpperCase();
                  final qtyText =
                      item.quantity.truncateToDouble() == item.quantity
                          ? item.quantity.toStringAsFixed(0)
                          : item.quantity.toStringAsFixed(2);
                  final hasDiscount = item.discount > 0;
                  final discPct = item.isPercentageDiscount
                      ? '-${item.discount.toStringAsFixed(0)}%'
                      : null;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar with initials
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _kPrimaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Qty: $qtyText | ${currencyFormat.format(item.taxableAmount)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (hasDiscount) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      currencyFormat.format(item.rate),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        decoration:
                                            TextDecoration.lineThrough,
                                      ),
                                    ),
                                    if (discPct != null) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          discPct,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFB45309),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(item.total),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            InkWell(
                              onTap: () =>
                                  setState(() => _items.removeAt(index)),
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.delete_outline,
                                    color: Color(0xFFEF4444), size: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

            // ── Totals Section ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Taxable Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Taxable Amount',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          currencyFormat.format(_taxableAmount),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Discount Field with unified selector & input
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Discount',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFCBD5E1), width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _discountType,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'fixed',
                                        child: Text('₹',
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                      DropdownMenuItem(
                                        value: 'percent',
                                        child: Text('%',
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _discountType = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              Container(
                                  width: 1,
                                  height: 24,
                                  color: const Color(0xFFCBD5E1)),
                              SizedBox(
                                width: 90,
                                child: TextField(
                                  controller: _discountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Total Discount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Discount',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          currencyFormat.format(_totalDiscount),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Round Off Switch
                    Row(
                      children: [
                        const Text(
                          'Round Off',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: _roundOff,
                          activeColor: _kPrimaryBlue,
                          onChanged: (val) =>
                              setState(() => _roundOff = val),
                        ),
                        const Spacer(),
                        Text(
                          currencyFormat.format(_roundOff
                              ? (_calculatedTotal -
                                      (_taxableAmount -
                                          _totalDiscount +
                                          _totalTax))
                                  .abs()
                              : 0),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFE2E8F0)),

                    // Total Banner inside summary card
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _kPrimaryBlue,
                            ),
                          ),
                          Text(
                            currencyFormat.format(_calculatedTotal),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _kPrimaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 12,
        ),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveInvoice,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF475569),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              const ColorScheme.light(primary: _kPrimaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              const ColorScheme.light(primary: _kPrimaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDueDate = picked);
  }

  void _navigateToAddItem() async {
    final result = await Navigator.push<OrderItem>(
      context,
      MaterialPageRoute(builder: (_) => const AddItemScreen()),
    );
    if (result != null && mounted) {
      setState(() => _items.add(result));
    }
  }

  void _saveInvoice() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final now = DateTime.now();
    final randomNum =
        (1000 + (now.millisecondsSinceEpoch % 9000)).toString();

    // We reuse LeadOrder entity to store invoices with status = open.
    // The difference is handled at the UI / display layer via type field.
    final invoiceType = (!widget.isConverting && widget.existingInvoice != null)
        ? widget.existingInvoice!.type
        : (widget.isProforma ? 'proforma_invoice' : 'invoice');

    final existing = (!widget.isConverting) ? widget.existingInvoice : null;

    final invoice = LeadOrder(
      id: existing?.id ?? now.millisecondsSinceEpoch.toString(),
      leadId: widget.lead.id,
      orderNumber: existing?.orderNumber ?? randomNum,
      staffName: _selectedStaff,
      date: _selectedDate,
      dueDate: _selectedDueDate,
      status: OrderStatus.open,
      taxableAmount: _taxableAmount,
      discountType: _discountType,
      discountValue:
          double.tryParse(_discountController.text.trim()) ?? 0.0,
      totalDiscount: _totalDiscount,
      roundOff: _roundOff,
      totalAmount: _calculatedTotal,
      items: List.from(_items),
      payments: existing?.payments ?? const [],
      createdAt: existing?.createdAt ?? now,
      type: invoiceType,
    );

    Navigator.pop(context, invoice);
  }
}
