import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/customer.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import 'customer_detail_screen.dart';

const Color _kPrimaryBlue = Color(0xFF3949AB);

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(const LoadCustomers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterDialog(List<Customer> allCustomers) {
    final state = context.read<CustomerBloc>().state;
    String currentStaff = 'All';
    String currentCategory = 'All';
    String currentStatus = 'All';
    String currentTerritory = 'All';
    DateTime? currentStartDate;
    DateTime? currentEndDate;

    if (state is CustomerLoaded) {
      currentStaff = state.selectedStaff;
      currentCategory = state.selectedCategory;
      currentStatus = state.selectedStatus;
      currentTerritory = state.selectedTerritory;
      currentStartDate = state.startDate;
      currentEndDate = state.endDate;
    }

    final uniqueStaff = {'All', ...allCustomers.map((c) => c.staffName).where((s) => s.isNotEmpty)};
    final staffList = uniqueStaff.toList();

    final uniqueTerritories = {
      'All',
      'PAL/RAVKI/LODHIKA',
      'METODA',
      'RAJKOT',
      'GONDAL',
      'AHMEDABAD',
      'SURAT',
      'VADODARA',
      'BHAVNAGAR',
      ...allCustomers.map((c) => c.territory).where((t) => t.isNotEmpty && t != 'Please Select')
    };
    final territoryList = uniqueTerritories.toList();

    showDialog(
      context: context,
      builder: (ctx) {
        String tempStaff = currentStaff;
        String tempCategory = currentCategory;
        String tempStatus = currentStatus;
        String tempTerritory = currentTerritory;
        DateTime? tempStart = currentStartDate;
        DateTime? tempEnd = currentEndDate;

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topRight,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 20, right: 20),
                    padding: const EdgeInsets.all(22),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
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
                          const SizedBox(height: 18),

                          // Staff
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
                                value: staffList.contains(tempStaff) ? tempStaff : 'All',
                                items: staffList.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    setDialogState(() => tempStaff = newValue);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Category
                          const Text('Category', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                                value: tempCategory,
                                items: const [
                                  DropdownMenuItem(value: 'All', child: Text('All')),
                                  DropdownMenuItem(value: 'Retailer', child: Text('Retailer')),
                                  DropdownMenuItem(value: 'Distributor', child: Text('Distributor')),
                                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                                ],
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    setDialogState(() => tempCategory = newValue);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Status
                          const Text('Status', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                                value: tempStatus,
                                items: const [
                                  DropdownMenuItem(value: 'All', child: Text('All')),
                                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                                ],
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    setDialogState(() => tempStatus = newValue);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Territory
                          const Text('Territory', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                                value: territoryList.contains(tempTerritory) ? tempTerritory : 'All',
                                items: territoryList.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    setDialogState(() => tempTerritory = newValue);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Date Pickers
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Start Date', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: tempStart ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                        );
                                        if (picked != null) {
                                          setDialogState(() => tempStart = picked);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                        decoration: const BoxDecoration(
                                          border: Border(bottom: BorderSide(color: Colors.blue)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              tempStart != null ? DateFormat('dd-MMM-yyyy').format(tempStart!) : 'Select',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: tempStart != null ? Colors.black : Colors.grey),
                                            ),
                                            const Icon(Icons.calendar_today, color: Colors.blue, size: 18),
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
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: tempEnd ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                        );
                                        if (picked != null) {
                                          setDialogState(() => tempEnd = picked);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                        decoration: const BoxDecoration(
                                          border: Border(bottom: BorderSide(color: Colors.blue)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              tempEnd != null ? DateFormat('dd-MMM-yyyy').format(tempEnd!) : 'Select',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: tempEnd != null ? Colors.black : Colors.grey),
                                            ),
                                            const Icon(Icons.calendar_today, color: Colors.blue, size: 18),
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

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            onPressed: () {
                              context.read<CustomerBloc>().add(FilterCustomers(
                                    staffName: tempStaff,
                                    category: tempCategory,
                                    status: tempStatus,
                                    territory: tempTerritory,
                                    startDate: tempStart,
                                    endDate: tempEnd,
                                  ));
                              Navigator.pop(ctx);
                            },
                            child: const Text('Apply', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _kPrimaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Customers',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () {
              _searchController.clear();
              context.read<CustomerBloc>().add(const FilterCustomers(
                    staffName: 'All',
                    category: 'All',
                    status: 'All',
                    territory: 'All',
                    startDate: null,
                    endDate: null,
                  ));
              context.read<CustomerBloc>().add(const RefreshCustomers());
            },
          ),
          BlocBuilder<CustomerBloc, CustomerState>(
            builder: (context, state) {
              final allCustomers = state is CustomerLoaded ? state.allCustomers : <Customer>[];
              return IconButton(
                icon: const Icon(Icons.filter_alt, color: Colors.white),
                tooltip: 'Filter',
                onPressed: () => _showFilterDialog(allCustomers),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Search Bar ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade400, width: 1),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.search, color: Colors.grey, size: 22),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (query) {
                        context.read<CustomerBloc>().add(SearchCustomers(query));
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        context.read<CustomerBloc>().add(const SearchCustomers(''));
                      },
                    ),
                ],
              ),
            ),
          ),

          // ─── Customer List ───────────────────────────────────────────
          Expanded(
            child: BlocBuilder<CustomerBloc, CustomerState>(
              builder: (context, state) {
                if (state is CustomerLoading || state is CustomerInitial) {
                  return const Center(
                    child: CircularProgressIndicator(color: _kPrimaryBlue),
                  );
                }

                if (state is CustomerError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(state.message, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimaryBlue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => context.read<CustomerBloc>().add(const LoadCustomers()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is CustomerLoaded) {
                  final customers = state.filteredCustomers;

                  if (customers.isEmpty) {
                    return const Center(
                      child: Text(
                        'No customers found',
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(top: 4, bottom: 84),
                    itemCount: customers.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF0F0F0),
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return _buildCustomerItem(context, customer);
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimaryBlue,
        elevation: 4,
        onPressed: () => context.push('/customers/add'),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildCustomerItem(BuildContext context, Customer customer) {
    // Formatting title: "Name, Company" or just Name
    final hasCompany = customer.company.isNotEmpty;
    final hasCity = customer.city.isNotEmpty;
    final hasTerritory = customer.territory.isNotEmpty;

    String subtitleLocation = '';
    if (hasCity) {
      subtitleLocation = customer.city;
    } else if (hasTerritory) {
      subtitleLocation = customer.territory;
    }

    String displayName = customer.name;
    if (hasCompany && customer.name.toLowerCase() != customer.company.toLowerCase()) {
      displayName = '${customer.name}, ${customer.company}';
    } else if (hasCompany && customer.name.toLowerCase() == customer.company.toLowerCase()) {
      displayName = '${customer.name}, ${customer.company}';
    }

    // Category styling
    Color categoryBg;
    Color categoryTextColor;
    final catLower = customer.category.toLowerCase();
    if (catLower == 'distributor') {
      categoryBg = const Color(0xFFE0F7FA);
      categoryTextColor = const Color(0xFF00ACC1);
    } else if (catLower == 'other') {
      categoryBg = const Color(0xFFE8F5E9);
      categoryTextColor = const Color(0xFF2E7D32);
    } else {
      // Retailer default
      categoryBg = const Color(0xFFE1F5FE);
      categoryTextColor = const Color(0xFF0288D1);
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<CustomerBloc>(),
              child: CustomerDetailScreen(customer: customer),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ─── Customer Code Badge ─────────────────────────────────────
            Container(
              width: 52,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                customer.customerNumber,
                style: const TextStyle(
                  color: _kPrimaryBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 14),

            // ─── Info Column ─────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E1E1E),
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitleLocation.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitleLocation,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          customer.staffName.isNotEmpty ? customer.staffName : 'Mehul',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ─── Category Badge ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: categoryBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                customer.category.isNotEmpty ? customer.category : 'Retailer',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: categoryTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
