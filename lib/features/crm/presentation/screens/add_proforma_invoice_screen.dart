import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_order.dart';
import '../bloc/sales_bloc.dart';
import 'add_item_screen.dart';
import 'products_cart_screen.dart';
import 'add_lead_screen.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/lead_bloc.dart';

const Color _kPrimaryBlue = Color(0xFF2638B8);

class ProformaCustomer {
  final String id;
  final String customerNumber;
  final String staffName;
  final String name;
  final String company;
  final String phone;
  final String email;
  final String territory;
  final String city;

  const ProformaCustomer({
    required this.id,
    this.customerNumber = '',
    this.staffName = '',
    required this.name,
    this.company = '',
    this.phone = '',
    this.email = '',
    this.territory = '',
    this.city = '',
  });
}

class AddProformaInvoiceScreen extends StatefulWidget {
  final bool isProforma;
  const AddProformaInvoiceScreen({super.key, this.isProforma = true});

  @override
  State<AddProformaInvoiceScreen> createState() =>
      _AddProformaInvoiceScreenState();
}

class _AddProformaInvoiceScreenState extends State<AddProformaInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  // Party selection: 'Customer' or 'Lead'
  String _partyType = 'Customer';
  ProformaCustomer? _selectedCustomer;
  Lead? _selectedLead;

  // Cached lists for bottom sheet selection
  List<ProformaCustomer> _allCustomers = [];
  List<Lead> _allLeads = [];

  // Dates
  late DateTime _selectedDate;
  DateTime? _selectedDueDate;

  // Staff
  final List<String> _staffList = [
    'ISHA VORA',
    'Mehul Ajagya',
    'Bhavin Prajapati',
    'Kishan Maru',
    'Prashantkumar',
  ];
  late String _selectedStaff;

  // Items
  final List<OrderItem> _items = [];

  // Financial calculations
  String _discountType = 'fixed'; // 'fixed' or 'percent'
  final TextEditingController _discountController =
      TextEditingController(text: '0');
  bool _roundOff = false;

  // Reference & Notes
  final List<String> _referenceList = [
    'JITESHBHAI VASANIYA',
    'PRAFULBHAI',
    'VIPULBHAI',
    'DIRECT',
    'OTHER',
  ];
  late String _selectedReference;
  final TextEditingController _noteController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedStaff = _staffList.first;
    _selectedReference = _referenceList.first;
    _loadParties();
  }

  @override
  void dispose() {
    _discountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadParties() async {
    try {
      final client = Supabase.instance.client;

      // Load customers
      final custData = await client
          .from('customers')
          .select()
          .order('created_at', ascending: false);
      _allCustomers = (custData as List).map((e) {
        return ProformaCustomer(
          id: e['id']?.toString() ?? '',
          customerNumber: e['customer_number']?.toString() ?? '',
          staffName: e['staff_name']?.toString() ?? '',
          name: e['name']?.toString() ?? '',
          company: e['company']?.toString() ?? '',
          phone: e['phone']?.toString() ?? '',
          email: e['email']?.toString() ?? '',
          territory: e['territory']?.toString() ?? '',
          city: e['city']?.toString() ?? '',
        );
      }).toList();

      // Load leads
      final leadsData = await client
          .from('leads')
          .select()
          .order('created_at', ascending: false);
      _allLeads = (leadsData as List).map((e) {
        return Lead(
          id: e['id']?.toString() ?? '',
          leadNumber: e['lead_number']?.toString() ?? '',
          staffName: e['staff_name']?.toString() ?? '',
          name: e['name']?.toString() ?? '',
          company: e['company']?.toString() ?? '',
          phone: e['phone']?.toString() ?? '',
          email: e['email']?.toString() ?? '',
          city: e['city']?.toString() ?? '',
          territory: e['territory']?.toString() ?? '',
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();
    } catch (_) {
      // Ignored
    }
  }

  // ── Calculation helpers ─────────────────────────────────────────────────────

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

  double get _rawTotal {
    double sub = _taxableAmount - _totalDiscount;
    if (sub < 0) sub = 0;
    return sub + _totalTax;
  }

  double get _calculatedTotal {
    if (_roundOff) {
      return _rawTotal.roundToDouble();
    }
    return _rawTotal;
  }

  double get _roundOffDifference {
    if (!_roundOff) return 0.0;
    return (_calculatedTotal - _rawTotal);
  }

  // ── Date Pickers ────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _kPrimaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _kPrimaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  // ── Party Search / Selection Sheet ──────────────────────────────────────────

  void _showPartySelectionSheet() {
    final isCustomer = _partyType == 'Customer';
    final searchController = TextEditingController();
    List<dynamic> filtered = isCustomer ? List.from(_allCustomers) : List.from(_allLeads);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isCustomer ? 'Select Customer' : 'Select Lead',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name or company...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (query) {
                        setSheetState(() {
                          final q = query.toLowerCase().trim();
                          if (isCustomer) {
                            filtered = _allCustomers.where((c) {
                              return c.name.toLowerCase().contains(q) ||
                                  c.company.toLowerCase().contains(q) ||
                                  c.phone.contains(q);
                            }).toList();
                          } else {
                            filtered = _allLeads.where((l) {
                              return l.name.toLowerCase().contains(q) ||
                                  l.company.toLowerCase().contains(q) ||
                                  l.phone.contains(q);
                            }).toList();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                isCustomer
                                    ? 'No customers found'
                                    : 'No leads found',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final name = isCustomer
                                    ? (item as ProformaCustomer).name
                                    : (item as Lead).name;
                                final company = isCustomer
                                    ? (item as ProformaCustomer).company
                                    : (item as Lead).company;
                                final phone = isCustomer
                                    ? (item as ProformaCustomer).phone
                                    : (item as Lead).phone;
                                final staff = isCustomer
                                    ? (item as ProformaCustomer).staffName
                                    : (item as Lead).staffName;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFEEF0FB),
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: _kPrimaryBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Text(
                                    company.isNotEmpty ? '$company • $phone' : phone,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (isCustomer) {
                                        _selectedCustomer =
                                            item as ProformaCustomer;
                                        if (staff.isNotEmpty &&
                                            _staffList.contains(staff)) {
                                          _selectedStaff = staff;
                                        }
                                      } else {
                                        _selectedLead = item as Lead;
                                        if (staff.isNotEmpty &&
                                            _staffList.contains(staff)) {
                                          _selectedStaff = staff;
                                        }
                                      }
                                    });
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showQuickAddCustomerDialog() async {
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final territoryCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bCtx) {
        return StatefulBuilder(
          builder: (context, setBState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add Customer',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(bCtx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Customer Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: companyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Company Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: territoryCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Territory',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: cityCtrl,
                              decoration: const InputDecoration(
                                labelText: 'City',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimaryBlue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (formKey.currentState!.validate()) {
                                    setBState(() => isSubmitting = true);
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    try {
                                      final client = Supabase.instance.client;
                                      final inserted = await client
                                          .from('customers')
                                          .insert({
                                        'name': nameCtrl.text.trim(),
                                        'company': companyCtrl.text.trim(),
                                        'phone': phoneCtrl.text.trim(),
                                        'territory': territoryCtrl.text.trim(),
                                        'city': cityCtrl.text.trim(),
                                        'staff_name': _selectedStaff,
                                        'status': 'Active',
                                      }).select().single();

                                      final newCust = ProformaCustomer(
                                        id: inserted['id'].toString(),
                                        name:
                                            inserted['name']?.toString() ?? '',
                                        company:
                                            inserted['company']?.toString() ??
                                                '',
                                        phone:
                                            inserted['phone']?.toString() ?? '',
                                        territory:
                                            inserted['territory']?.toString() ??
                                                '',
                                        city:
                                            inserted['city']?.toString() ?? '',
                                        staffName: _selectedStaff,
                                      );

                                      if (!mounted) return;
                                      setState(() {
                                        _allCustomers.insert(0, newCust);
                                        _selectedCustomer = newCust;
                                      });
                                      if (bCtx.mounted) {
                                        Navigator.pop(bCtx);
                                      }
                                    } catch (e) {
                                      setBState(() => isSubmitting = false);
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to add: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: isSubmitting
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('Save & Select'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onAddNewParty() async {
    if (_partyType == 'Customer') {
      try {
        await context.push('/customers/add');
      } catch (_) {
        await _showQuickAddCustomerDialog();
      }
      if (!mounted) return;
      await _loadParties();
      if (_allCustomers.isNotEmpty && mounted) {
        setState(() {
          _selectedCustomer = _allCustomers.first;
          if (_selectedCustomer!.staffName.isNotEmpty &&
              _staffList.contains(_selectedCustomer!.staffName)) {
            _selectedStaff = _selectedCustomer!.staffName;
          }
        });
      }
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: sl<LeadBloc>(),
            child: const AddLeadScreen(),
          ),
        ),
      );
      if (!mounted) return;
      await _loadParties();
      if (_allLeads.isNotEmpty && mounted) {
        setState(() {
          _selectedLead = _allLeads.first;
          if (_selectedLead!.staffName.isNotEmpty &&
              _staffList.contains(_selectedLead!.staffName)) {
            _selectedStaff = _selectedLead!.staffName;
          }
        });
      }
    }
  }

  // ── Add Item Navigation ─────────────────────────────────────────────────────

  void _navigateToAddItem() async {
    final result = await Navigator.push<OrderItem>(
      context,
      MaterialPageRoute(builder: (_) => const AddItemScreen()),
    );
    if (result != null && mounted) {
      setState(() => _items.add(result));
    }
  }

  void _navigateToProductsCart() async {
    final result = await Navigator.push<List<OrderItem>>(
      context,
      MaterialPageRoute(builder: (_) => const ProductsCartScreen()),
    );
    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        _items.addAll(result);
      });
    }
  }

  // ── Save Proforma Invoice ───────────────────────────────────────────────────

  Future<void> _saveProformaInvoice() async {
    // 1. Validation
    if (_partyType == 'Customer' && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Customer'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_partyType == 'Lead' && _selectedLead == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Lead'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final client = Supabase.instance.client;
      final now = DateTime.now();

      // Generate a unique 4-digit sequential/random proforma invoice number
      final orderNumber =
          (100 + (now.millisecondsSinceEpoch % 900)).toString();

      String leadIdToUse = '';

      if (_partyType == 'Customer') {
        final cust = _selectedCustomer!;
        // Ensure a lead record exists with this name so foreign key constraint is satisfied
        final existingLeads = await client
            .from('leads')
            .select('id')
            .eq('name', cust.name)
            .limit(1);

        if ((existingLeads as List).isNotEmpty) {
          leadIdToUse = existingLeads.first['id'].toString();
        } else {
          final insertedLead = await client.from('leads').insert({
            'name': cust.name,
            'company': cust.company,
            'phone': cust.phone,
            'email': cust.email,
            'staff_name': _selectedStaff,
            'city': cust.city,
            'territory': cust.territory,
            'stage': 'customer',
            'status': 'active',
          }).select('id').single();
          leadIdToUse = insertedLead['id'].toString();
        }
      } else {
        leadIdToUse = _selectedLead!.id;
      }

      final insertData = {
        'lead_id': leadIdToUse,
        'order_number': orderNumber,
        'staff_name': _selectedStaff,
        'date': _selectedDate.toIso8601String().split('T')[0],
        'due_date': _selectedDueDate?.toIso8601String().split('T')[0],
        'status': 'open',
        'taxable_amount': _taxableAmount,
        'discount_type': _discountType,
        'discount_value':
            double.tryParse(_discountController.text.trim()) ?? 0.0,
        'total_discount': _totalDiscount,
        'round_off': _roundOff,
        'total_amount': _calculatedTotal,
        'items': _items.map((i) => i.toJson()).toList(),
        'type': widget.isProforma ? 'proforma_invoice' : 'invoice',
      };

      await client.from('lead_orders').insert(insertData);

      if (mounted) {
        // Refresh Sales BLoC so the new Proforma Invoice is instantly displayed
        context.read<SalesBloc>().add(RefreshSales());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Proforma Invoice #$orderNumber created successfully!'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save proforma invoice: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Build UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final zeroCurrency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

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
          widget.isProforma ? 'Add Proforma Invoice' : 'Add Invoice',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Segmented Toggle: Customer / Lead ─────────────────────
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (_partyType != 'Customer') {
                                  setState(() => _partyType = 'Customer');
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _partyType == 'Customer'
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _partyType == 'Customer'
                                      ? const [
                                          BoxShadow(
                                            color: Color(0x0A000000),
                                            blurRadius: 4,
                                            offset: Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      size: 18,
                                      color: _partyType == 'Customer'
                                          ? _kPrimaryBlue
                                          : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Customer',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: _partyType == 'Customer'
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: _partyType == 'Customer'
                                            ? _kPrimaryBlue
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (_partyType != 'Lead') {
                                  setState(() => _partyType = 'Lead');
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _partyType == 'Lead'
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _partyType == 'Lead'
                                      ? const [
                                          BoxShadow(
                                            color: Color(0x0A000000),
                                            blurRadius: 4,
                                            offset: Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.contact_mail_outlined,
                                      size: 18,
                                      color: _partyType == 'Lead'
                                          ? _kPrimaryBlue
                                          : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Lead',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: _partyType == 'Lead'
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: _partyType == 'Lead'
                                            ? _kPrimaryBlue
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Party Label: Customer * or Lead * ───────────────────────
                    _buildRequiredLabel(
                        _partyType == 'Customer' ? 'Customer' : 'Lead'),
                    const SizedBox(height: 6),

                    // ── Party Selector / Selected Party Card ───────────────────
                    if ((_partyType == 'Customer' &&
                            _selectedCustomer != null) ||
                        (_partyType == 'Lead' && _selectedLead != null))
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFCBD5E1), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                (_partyType == 'Customer'
                                    ? (_selectedCustomer!.name.isNotEmpty
                                        ? _selectedCustomer!.name[0]
                                            .toUpperCase()
                                        : 'C')
                                    : (_selectedLead!.name.isNotEmpty
                                        ? _selectedLead!.name[0].toUpperCase()
                                        : 'L')),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
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
                                    _partyType == 'Customer'
                                        ? _selectedCustomer!.name
                                        : _selectedLead!.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _partyType == 'Customer'
                                        ? [
                                            _selectedCustomer!.company,
                                            _selectedCustomer!.phone
                                          ]
                                            .where((s) => s.isNotEmpty)
                                            .join(' • ')
                                        : [
                                            _selectedLead!.company,
                                            _selectedLead!.phone
                                          ]
                                            .where((s) => s.isNotEmpty)
                                            .join(' • '),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _showPartySelectionSheet,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: const Text('Change',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _kPrimaryBlue)),
                            ),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _showPartySelectionSheet,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFCBD5E1), width: 1.2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search,
                                  color: Color(0xFF64748B), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _partyType == 'Customer'
                                      ? 'Select customer...'
                                      : 'Select lead...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: _onAddNewParty,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '+ Add',
                                    style: TextStyle(
                                      color: _kPrimaryBlue,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // ── Date & Due Date Row ────────────────────────────────────
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

                    // ── Reference Dropdown ──────────────────────────────────────
                    _buildLabel('Reference'),
                    const SizedBox(height: 6),
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

            // ── Items Section Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Row(
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
                  const Spacer(),
                  // Add Item Button
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
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Shopping Cart Button
                  InkWell(
                    onTap: _navigateToProductsCart,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        color: _kPrimaryBlue,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Items List ────────────────────────────────────────────────────
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
                        'Tap "+ Add Item" or the cart icon to add products',
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
                separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                  final discText = item.isPercentageDiscount
                      ? '${item.discount}%'
                      : '₹${item.discount.toStringAsFixed(0)}';

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
                        // Initials avatar
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
                                    'Qty: $qtyText | ${currencyFormat.format(item.rate)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (hasDiscount) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Disc: $discText',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFB45309),
                                        ),
                                      ),
                                    ),
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
                              currencyFormat.format(item.taxableAmount),
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

            // ── Financial Calculation Section ─────────────────────────────────
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
                          zeroCurrency.format(_taxableAmount),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Discount Row with unified selector & input
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
                                                  fontWeight:
                                                      FontWeight.w600))),
                                      DropdownMenuItem(
                                          value: 'percent',
                                          child: Text('%',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.w600))),
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
                          zeroCurrency.format(_totalDiscount),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Round Off Toggle
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
                          onChanged: (val) => setState(() => _roundOff = val),
                        ),
                        const Spacer(),
                        Text(
                          zeroCurrency.format(_roundOffDifference.abs()),
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
                            zeroCurrency.format(_calculatedTotal),
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

            // ── Reference Section ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRequiredLabel('Reference'),
                  const SizedBox(height: 6),
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
                      value: _referenceList.contains(_selectedReference)
                          ? _selectedReference
                          : (_referenceList.isNotEmpty
                              ? _referenceList.first
                              : null),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Color(0xFF475569)),
                      items: _referenceList.map((ref) {
                        return DropdownMenuItem(
                          value: ref,
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
                                  ref,
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
                          setState(() => _selectedReference = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── Note Section ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Note'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Add an optional note...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1), width: 1.2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1), width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: _kPrimaryBlue, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Save Button ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProformaInvoice,
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
                          'Save Proforma Invoice',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
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

  Widget _buildRequiredLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF475569),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(
              color: Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
