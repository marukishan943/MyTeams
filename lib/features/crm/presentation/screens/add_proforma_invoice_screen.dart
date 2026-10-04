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
                    // ── Radio Options: Customer / Lead ─────────────────────────
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            if (_partyType != 'Customer') {
                              setState(() => _partyType = 'Customer');
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: 'Customer',
                                groupValue: _partyType,
                                activeColor: _kPrimaryBlue,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _partyType = val);
                                  }
                                },
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Customer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF212121),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        InkWell(
                          onTap: () {
                            if (_partyType != 'Lead') {
                              setState(() => _partyType = 'Lead');
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: 'Lead',
                                groupValue: _partyType,
                                activeColor: _kPrimaryBlue,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _partyType = val);
                                  }
                                },
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Lead',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF212121),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ── Party Label: Customer * or Lead * ───────────────────────
                    _buildRequiredLabel(
                        _partyType == 'Customer' ? 'Customer' : 'Lead'),
                    const SizedBox(height: 4),

                    // ── Search & + Add Row ──────────────────────────────────────
                    GestureDetector(
                      onTap: _showPartySelectionSheet,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Color(0xFFBDBDBD), width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search,
                                color: Color(0xFF757575), size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _partyType == 'Customer'
                                    ? (_selectedCustomer != null
                                        ? '${_selectedCustomer!.name}${_selectedCustomer!.company.isNotEmpty ? ' (${_selectedCustomer!.company})' : ''}'
                                        : 'Search customer...')
                                    : (_selectedLead != null
                                        ? '${_selectedLead!.name}${_selectedLead!.company.isNotEmpty ? ' (${_selectedLead!.company})' : ''}'
                                        : 'Search lead...'),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: (_partyType == 'Customer' &&
                                              _selectedCustomer != null) ||
                                          (_partyType == 'Lead' &&
                                              _selectedLead != null)
                                      ? const Color(0xFF212121)
                                      : Colors.grey[500],
                                  fontWeight: (_partyType == 'Customer' &&
                                              _selectedCustomer != null) ||
                                          (_partyType == 'Lead' &&
                                              _selectedLead != null)
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: _onAddNewParty,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                child: Text(
                                  '+ Add',
                                  style: TextStyle(
                                    color: _kPrimaryBlue,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Date & Due Date Row ────────────────────────────────────
                    Row(
                      children: [
                        // Date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Date'),
                              const SizedBox(height: 4),
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
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF212121),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.calendar_month_outlined,
                                          color: Colors.grey, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Due Date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Due Date'),
                              const SizedBox(height: 4),
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
                                            fontWeight: _selectedDueDate != null
                                                ? FontWeight.w500
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.calendar_month_outlined,
                                          color: Colors.grey, size: 20),
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

                    // ── Staff Dropdown ─────────────────────────────────────────
                    _buildLabel('Staff'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFBDBDBD)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedStaff,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: Color(0xFF757575)),
                        items: _staffList.map((staff) {
                          return DropdownMenuItem(
                            value: staff,
                            child: Text(
                              staff,
                              style: const TextStyle(
                                fontSize: 15,
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

            // ── Section Divider ───────────────────────────────────────────────
            Container(height: 12, color: const Color(0xFFF0F2FA)),

            // ── Items Section Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
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
                  const Spacer(),
                  // Blue Plus Button
                  GestureDetector(
                    onTap: _navigateToAddItem,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: _kPrimaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Blue Shopping Cart Button
                  GestureDetector(
                    onTap: _navigateToProductsCart,
                    child: const Icon(
                      Icons.shopping_cart,
                      color: _kPrimaryBlue,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // ── Items List ────────────────────────────────────────────────────
            if (_items.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Initials avatar
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF0FB),
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF212121),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Qty: $qtyText | Rate: ${currencyFormat.format(item.rate)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormat.format(item.taxableAmount),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() => _items.removeAt(index));
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),

            // ── Section Divider ───────────────────────────────────────────────
            Container(height: 12, color: const Color(0xFFF0F2FA)),

            // ── Financial Calculation Section ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Taxable Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Taxable Amount',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        zeroCurrency.format(_taxableAmount),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Discount Row
                  Row(
                    children: [
                      Text(
                        'Discount',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      // Type dropdown (₹ or %)
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFBDBDBD)),
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(4)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _discountType,
                            items: const [
                              DropdownMenuItem(value: 'fixed', child: Text('₹')),
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
                      // Value input
                      Container(
                        width: 90,
                        height: 38,
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0xFFBDBDBD)),
                            right: BorderSide(color: Color(0xFFBDBDBD)),
                            bottom: BorderSide(color: Color(0xFFBDBDBD)),
                          ),
                          borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(4)),
                        ),
                        child: TextField(
                          controller: _discountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 15),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Total Discount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Discount',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        zeroCurrency.format(_totalDiscount),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Round Off Toggle
                  Row(
                    children: [
                      Text(
                        'Round Off',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w400,
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
                          color: Color(0xFF212121),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Total Bar ─────────────────────────────────────────────────────
            Container(
              color: const Color(0xFFF0F2FA),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                    zeroCurrency.format(_calculatedTotal),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                ],
              ),
            ),

            // ── Section Divider ───────────────────────────────────────────────
            Container(height: 12, color: const Color(0xFFF0F2FA)),

            // ── Referance Section ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'REFERANCE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRequiredLabel('REFERANCE'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFBDBDBD)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedReference,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Color(0xFF757575)),
                      items: _referenceList.map((ref) {
                        return DropdownMenuItem(
                          value: ref,
                          child: Text(
                            ref,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF212121),
                              fontWeight: FontWeight.w500,
                            ),
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

            // ── Section Divider ───────────────────────────────────────────────
            Container(height: 12, color: const Color(0xFFF0F2FA)),

            // ── Note Section ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NOTE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLabel('NOTE'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      hintText: '',
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFBDBDBD)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: _kPrimaryBlue, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

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
                      borderRadius: BorderRadius.circular(8),
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
        color: Color(0xFF757575),
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildRequiredLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF757575),
          fontWeight: FontWeight.w400,
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
