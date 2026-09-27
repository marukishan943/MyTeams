import 'package:flutter/material.dart';
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

  final List<String> _staffList = [
    'Bhavin Prajapati',
    'Mehul Ajagya',
    'Kishan Maru',
    'Rahul Sharma',
  ];

  String get _screenTitle =>
      widget.isProforma ? 'Add Proforma Invoice' : 'Add Invoice';

  @override
  void initState() {
    super.initState();
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
                    // Lead (Read-only)
                    _buildLabel('Lead'),
                    const SizedBox(height: 4),
                    Text(
                      widget.lead.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 24),

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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                          color: Color(0xFFBDBDBD), width: 1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          DateFormat('dd-MMM-yyyy')
                                              .format(_selectedDate),
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                      ),
                                      const Icon(
                                          Icons.calendar_month_outlined,
                                          color: Colors.grey,
                                          size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                          color: Color(0xFFBDBDBD), width: 1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedDueDate != null
                                              ? DateFormat('dd-MMM-yyyy')
                                                  .format(_selectedDueDate!)
                                              : 'Please Select',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: _selectedDueDate != null
                                                ? const Color(0xFF212121)
                                                : Colors.grey[500],
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                          Icons.calendar_month_outlined,
                                          color: Colors.grey,
                                          size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Staff
                    _buildLabel('Staff'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFBDBDBD)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedStaff,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: Color(0xFF757575)),
                        items: _staffList.map((staff) {
                          return DropdownMenuItem(
                            value: staff,
                            child: Text(
                              staff,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF212121),
                                fontWeight: FontWeight.w500,
                              ),
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
            Container(
              color: const Color(0xFFF8F9FA),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: const TextSpan(
                      text: 'Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                      children: [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _navigateToAddItem,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: _kPrimaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            // ── Items List ────────────────────────────────────────────────
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Text(
                  'No items added yet. Tap + to add item.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                itemCount: _items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
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

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar with initials
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EAF6),
                            borderRadius: BorderRadius.circular(6),
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF212121),
                                ),
                              ),
                              const SizedBox(height: 2),
                              // "Qty: 1 | ₹130.50 ₹145 (-10%)"
                              Row(
                                children: [
                                  Text(
                                    'Qty: $qtyText | ${currencyFormat.format(item.taxableAmount)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
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
                                      Text(
                                        '($discPct)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(item.total),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF212121),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _items.removeAt(index)),
                          child: const Icon(Icons.close,
                              color: Colors.grey, size: 20),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // ── Totals Section ────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  const Divider(color: Color(0xFFEEEEEE), height: 1),
                  const SizedBox(height: 16),

                  // Taxable Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Taxable Amount',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        currencyFormat.format(_taxableAmount),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Discount Field with ₹/% dropdown
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Discount',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Container(
                        width: 70,
                        height: 42,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFFBDBDBD)),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            bottomLeft: Radius.circular(4),
                          ),
                        ),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _discountType,
                            items: const [
                              DropdownMenuItem(
                                  value: 'fixed', child: Text('₹')),
                              DropdownMenuItem(
                                  value: 'percent', child: Text('%')),
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
                        width: 110,
                        height: 42,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFFBDBDBD)),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        child: TextField(
                          controller: _discountController,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          textAlign: TextAlign.end,
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
                  const SizedBox(height: 16),

                  // Total Discount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Discount',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        currencyFormat.format(_totalDiscount),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Round Off Switch
                  Row(
                    children: [
                      Text(
                        'Round Off',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                          color: Color(0xFF212121),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Total Bar ─────────────────────────────────────────────────
            Container(
              color: const Color(0xFFF0F2FA),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                  Text(
                    currencyFormat.format(_calculatedTotal),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                ],
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
        fontSize: 14,
        color: Color(0xFF757575),
        fontWeight: FontWeight.w400,
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
