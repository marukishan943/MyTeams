import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_enums.dart';
import '../bloc/lead_bloc.dart';
import '../bloc/lead_event.dart';
import '../bloc/lead_state.dart';

const Color _kPrimaryBlue = Color(0xFF3949AB);

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    context.read<LeadBloc>().add(const LoadLeads());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: _kPrimaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Leads',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<LeadBloc>().add(const RefreshLeads());
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onPressed: () => _showFilterDialog(context),
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
          tabs: const [
            Tab(text: 'Stats'),
            Tab(text: 'Open'),
            Tab(text: 'Closed'),
          ],
        ),
      ),
      body: BlocConsumer<LeadBloc, LeadState>(
        listener: (context, state) {
          if (state is LeadOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFF2E7D32),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          } else if (state is LeadError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is LeadLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _kPrimaryBlue),
            );
          }

          if (state is LeadsLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildStatsTab(state),
                _buildLeadsListTab(state.filteredOpenLeads, 'open'),
                _buildLeadsListTab(state.filteredClosedLeads, 'closed'),
              ],
            );
          }

          return const Center(
            child: Text('Something went wrong'),
          );
        },
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () async {
                await context.push('/leads/add');
                if (mounted) {
                  context.read<LeadBloc>().add(const LoadLeads());
                }
              },
              backgroundColor: _kPrimaryBlue,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  // ─── Stats Tab ──────────────────────────────────────────────────────
  Widget _buildStatsTab(LeadsLoaded state) {
    final stats = state.stats;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Text(
            'THIS MONTH',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'New',
                  stats.newCount,
                  const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Contacted',
                  stats.contactedCount,
                  const Color(0xFFF9A825),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Proposal Sent',
                  stats.proposalSentCount,
                  const Color(0xFF0097A7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Disqualified',
                  stats.disqualifiedCount,
                  const Color(0xFFE53935),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Converted',
                  stats.convertedCount,
                  const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()), // Empty placeholder
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color countColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: countColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Leads List Tab (Open / Closed) ────────────────────────────────
  Widget _buildLeadsListTab(List<Lead> leads, String type) {
    return Column(
      children: [
        // Search bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: TextField(
            controller: _searchController,
            onChanged: (query) {
              context.read<LeadBloc>().add(SearchLeads(query));
            },
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFBDBDBD)),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        // Leads list
        Expanded(
          child: leads.isEmpty
              ? _buildEmptyState(type)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: leads.length,
                  itemBuilder: (context, index) {
                    final lead = leads[index];
                    final showDateHeader = index == 0 ||
                        !_isSameDay(leads[index - 1].date, lead.date);

                    return Column(
                      children: [
                        if (showDateHeader) _buildDateHeader(lead.date),
                        _buildLeadCard(lead),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 72,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No ${type == 'open' ? 'open' : 'closed'} leads',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    String label;
    if (dateOnly == today) {
      label = 'TODAY';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      label = 'YESTERDAY';
    } else {
      final dayOfWeek = DateFormat('EEE').format(date).toUpperCase();
      label = '${DateFormat('dd MMM').format(date)} ($dayOfWeek)';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: Colors.grey[300], thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: Colors.grey[300], thickness: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadCard(Lead lead) {
    return GestureDetector(
      onTap: () async {
        await context.push('/leads/${lead.id}');
        if (mounted) {
          context.read<LeadBloc>().add(const LoadLeads());
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Lead number block
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _kPrimaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  lead.leadNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimaryBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Lead info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (lead.city.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      lead.city,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lead.staffName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Stage badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: lead.stage.backgroundColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                lead.stage.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: lead.stage.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showFilterDialog(BuildContext context) {
    final now = DateTime.now();
    final leadBloc = context.read<LeadBloc>();
    final currentState = leadBloc.state;
    final bool showStage = _tabController.index != 0;

    String selectedSource = 'All';
    String selectedStage = 'All';
    DateTime startDate = DateTime(now.year, now.month, 1);
    DateTime endDate = now;

    if (currentState is LeadsLoaded) {
      selectedSource = currentState.selectedSource;
      selectedStage = currentState.selectedStage;
      startDate =
          currentState.filterStartDate ?? DateTime(now.year, now.month, 1);
      endDate = currentState.filterEndDate ?? now;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Filter',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Source Dropdown Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Source',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF757575),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 44,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFBDBDBD),
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedSource,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Color(0xFF616161),
                                    size: 24,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF212121),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'All', child: Text('All')),
                                    DropdownMenuItem(
                                        value: 'Call', child: Text('Call')),
                                    DropdownMenuItem(
                                        value: 'Email', child: Text('Email')),
                                    DropdownMenuItem(
                                        value: 'Website',
                                        child: Text('Website')),
                                    DropdownMenuItem(
                                        value: 'Others', child: Text('Others')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() {
                                        selectedSource = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (showStage) ...[
                          const SizedBox(height: 16),
                          // Stage Dropdown Section (LeadStage)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Stage',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF757575),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 44,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFBDBDBD),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedStage,
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Color(0xFF616161),
                                      size: 24,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF212121),
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                          value: 'All', child: Text('All')),
                                      ...LeadStage.values.map(
                                        (stage) => DropdownMenuItem(
                                          value: stage.displayName,
                                          child: Text(stage.displayName),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setDialogState(() {
                                          selectedStage = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                        // Dates Section (Start Date and End Date)
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateFilterField(
                                label: 'Start Date',
                                date: startDate,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: startDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                    builder: (ctx, child) {
                                      return Theme(
                                        data: Theme.of(ctx).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: Color(0xFF2E3EAF),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      startDate = picked;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDateFilterField(
                                label: 'End Date',
                                date: endDate,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: endDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                    builder: (ctx, child) {
                                      return Theme(
                                        data: Theme.of(ctx).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: Color(0xFF2E3EAF),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      endDate = picked;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        // Apply Button
                        Center(
                          child: SizedBox(
                            width: 170,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                leadBloc.add(
                                  FilterLeads(
                                    source: selectedSource,
                                    stage: showStage ? selectedStage : 'All',
                                    startDate: startDate,
                                    endDate: endDate,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E3EAF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Apply',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Circular close button at top-right
                  Positioned(
                    top: -12,
                    right: -8,
                    child: GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
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

  Widget _buildDateFilterField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF757575),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd-MMM-yyyy').format(date),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF212121),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFF2E3EAF),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 1.5,
            color: const Color(0xFF2E3EAF),
          ),
        ],
      ),
    );
  }
}
