import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_enums.dart';
import '../bloc/lead_bloc.dart';
import '../bloc/lead_event.dart';
import '../bloc/lead_state.dart';
import '../widgets/crm_ui_constants.dart';
import '../widgets/crm_lead_card.dart';
import '../widgets/crm_stat_card.dart';
import '../widgets/crm_empty_state.dart';

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
      if (mounted) setState(() {});
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
    return BlocConsumer<LeadBloc, LeadState>(
      listener: (context, state) {
        if (state is LeadOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: CrmStyles.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else if (state is LeadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: CrmStyles.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final bool isFilterActive = state is LeadsLoaded &&
            (state.selectedSource != 'All' || state.selectedStage != 'All');

        int openCount = 0;
        int closedCount = 0;
        if (state is LeadsLoaded) {
          openCount = state.filteredOpenLeads.length;
          closedCount = state.filteredClosedLeads.length;
        }

        return Scaffold(
          backgroundColor: CrmStyles.background,
          appBar: AppBar(
            backgroundColor: CrmStyles.primary,
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
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh',
                onPressed: () {
                  context.read<LeadBloc>().add(const RefreshLeads());
                },
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_alt, color: Colors.white),
                    tooltip: 'Filter Leads',
                    onPressed: () => _showFilterDialog(context),
                  ),
                  if (isFilterActive)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107),
                          shape: BoxShape.circle,
                          border: Border.all(color: CrmStyles.primary, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 6),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: CrmStyles.primary,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.65),
                  labelStyle: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    const Tab(text: 'Stats'),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Open'),
                          if (state is LeadsLoaded && openCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                openCount.toString(),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Closed'),
                          if (state is LeadsLoaded && closedCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                closedCount.toString(),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: state is LeadLoading
              ? const Center(
                  child: CircularProgressIndicator(color: CrmStyles.primary),
                )
              : state is LeadsLoaded
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        _buildStatsTab(state),
                        _buildLeadsListTab(state, state.filteredOpenLeads, 'open'),
                        _buildLeadsListTab(state, state.filteredClosedLeads, 'closed'),
                      ],
                    )
                  : CrmEmptyState(
                      icon: Icons.error_outline,
                      title: 'Could not load leads',
                      message: 'An error occurred while loading your leads pipeline.',
                      buttonText: 'Retry',
                      onButtonPressed: () {
                        context.read<LeadBloc>().add(const LoadLeads());
                      },
                    ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'add_lead_fab',
            onPressed: () async {
              final bloc = context.read<LeadBloc>();
              await context.push('/leads/add');
              if (mounted) {
                bloc.add(const LoadLeads());
              }
            },
            backgroundColor: CrmStyles.primary,
            elevation: 4,
            tooltip: 'Add Lead',
            child: const Icon(Icons.add, color: Colors.white, size: 26),
          ),
        );
      },
    );
  }

  // ─── Stats Tab ──────────────────────────────────────────────────────
  Widget _buildStatsTab(LeadsLoaded state) {
    final stats = state.stats;
    final now = DateTime.now();
    final monthLabel = DateFormat('MMMM yyyy').format(now).toUpperCase();

    return RefreshIndicator(
      color: CrmStyles.primary,
      onRefresh: () async {
        context.read<LeadBloc>().add(const RefreshLeads());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Header Banner
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pipeline Analytics',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: CrmStyles.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CrmStyles.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: CrmStyles.primary),
                      const SizedBox(width: 5),
                      Text(
                        monthLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: CrmStyles.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Distribution Progress Bar
            CrmStageDistributionBar(stats: stats),
            const SizedBox(height: 16),

            // 2-column Grid of Stage Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                CrmStatCard(
                  label: 'New Leads',
                  count: stats.newCount,
                  color: const Color(0xFF1565C0),
                  icon: Icons.star_outline_rounded,
                  onTap: () => _filterByStageAndSwitchTab(LeadStage.newLead, 1),
                ),
                CrmStatCard(
                  label: 'Contacted',
                  count: stats.contactedCount,
                  color: const Color(0xFFF9A825),
                  icon: Icons.phone_in_talk_outlined,
                  onTap: () => _filterByStageAndSwitchTab(LeadStage.contacted, 1),
                ),
                CrmStatCard(
                  label: 'Proposal Sent',
                  count: stats.proposalSentCount,
                  color: const Color(0xFF0097A7),
                  icon: Icons.description_outlined,
                  onTap: () => _filterByStageAndSwitchTab(LeadStage.proposalSent, 1),
                ),
                CrmStatCard(
                  label: 'Converted',
                  count: stats.convertedCount,
                  color: const Color(0xFF2E7D32),
                  icon: Icons.check_circle_outline,
                  onTap: () => _filterByStageAndSwitchTab(LeadStage.converted, 2),
                ),
                CrmStatCard(
                  label: 'Disqualified',
                  count: stats.disqualifiedCount,
                  color: const Color(0xFFE53935),
                  icon: Icons.cancel_outlined,
                  onTap: () => _filterByStageAndSwitchTab(LeadStage.disqualified, 2),
                ),
                CrmStatCard(
                  label: 'Total Pipeline',
                  count: stats.newCount +
                      stats.contactedCount +
                      stats.proposalSentCount +
                      stats.disqualifiedCount +
                      stats.convertedCount,
                  color: CrmStyles.primary,
                  icon: Icons.pie_chart_outline_rounded,
                  onTap: () => _tabController.animateTo(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _filterByStageAndSwitchTab(LeadStage stage, int tabIndex) {
    context.read<LeadBloc>().add(FilterLeads(stage: stage.displayName));
    _tabController.animateTo(tabIndex);
  }

  // ─── Leads List Tab (Open / Closed) ────────────────────────────────
  Widget _buildLeadsListTab(LeadsLoaded state, List<Lead> leads, String type) {
    final bool isFilterActive =
        state.selectedSource != 'All' || state.selectedStage != 'All';

    return Column(
      children: [
        // Modern Search Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(CrmStyles.radiusMedium),
              border: Border.all(color: CrmStyles.border, width: 1),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                context.read<LeadBloc>().add(SearchLeads(query));
              },
              style: const TextStyle(fontSize: 14.5, color: CrmStyles.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by lead name, company, city...',
                hintStyle: const TextStyle(color: CrmStyles.textMuted, fontSize: 13.5),
                prefixIcon: const Icon(Icons.search, color: CrmStyles.textMuted, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          context.read<LeadBloc>().add(const SearchLeads(''));
                        },
                        child: const Icon(Icons.close, color: CrmStyles.textMuted, size: 18),
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // Active Filter Chips Bar (if any filter is applied)
        if (isFilterActive)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                const Text(
                  'Filters:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CrmStyles.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (state.selectedSource != 'All')
                          _buildActiveFilterChip(
                            'Source: ${state.selectedSource}',
                            onDeleted: () {
                              context.read<LeadBloc>().add(
                                FilterLeads(
                                  source: 'All',
                                  stage: state.selectedStage,
                                  startDate: state.filterStartDate,
                                  endDate: state.filterEndDate,
                                ),
                              );
                            },
                          ),
                        if (state.selectedStage != 'All')
                          _buildActiveFilterChip(
                            'Stage: ${state.selectedStage}',
                            onDeleted: () {
                              context.read<LeadBloc>().add(
                                FilterLeads(
                                  source: state.selectedSource,
                                  stage: 'All',
                                  startDate: state.filterStartDate,
                                  endDate: state.filterEndDate,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    context.read<LeadBloc>().add(
                      const FilterLeads(source: 'All', stage: 'All'),
                    );
                  },
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: CrmStyles.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const Divider(height: 1, color: CrmStyles.border),

        // Leads list
        Expanded(
          child: RefreshIndicator(
            color: CrmStyles.primary,
            onRefresh: () async {
              context.read<LeadBloc>().add(const RefreshLeads());
            },
            child: leads.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: CrmEmptyState(
                        icon: type == 'open'
                            ? Icons.assignment_outlined
                            : Icons.assignment_turned_in_outlined,
                        title: type == 'open' ? 'No Open Leads' : 'No Closed Leads',
                        message: isFilterActive
                            ? 'No leads match your current search or filter criteria.'
                            : 'There are currently no leads in this section.',
                        buttonText: isFilterActive ? 'Reset Filters' : 'Add Lead',
                        onButtonPressed: () {
                          if (isFilterActive) {
                            _searchController.clear();
                            context.read<LeadBloc>().add(
                              const FilterLeads(source: 'All', stage: 'All'),
                            );
                            context.read<LeadBloc>().add(const SearchLeads(''));
                          } else {
                            context.push('/leads/add');
                          }
                        },
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: leads.length,
                    itemBuilder: (context, index) {
                      final lead = leads[index];
                      final showDateHeader = index == 0 ||
                          !_isSameDay(leads[index - 1].date, lead.date);

                      return Column(
                        children: [
                          if (showDateHeader) _buildDateHeader(lead.date),
                          CrmLeadCard(
                            lead: lead,
                            onTap: () async {
                              final bloc = context.read<LeadBloc>();
                              await context.push('/leads/${lead.id}');
                              if (mounted) {
                                bloc.add(const LoadLeads());
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilterChip(String label, {required VoidCallback onDeleted}) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.fromLTRB(8, 3, 4, 3),
      decoration: BoxDecoration(
        color: CrmStyles.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CrmStyles.primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDeleted,
            child: const Icon(Icons.close, size: 14, color: CrmStyles.primary),
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
      label = '${DateFormat('dd MMM yyyy').format(date)} ($dayOfWeek)';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          const Expanded(child: Divider(color: CrmStyles.border, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: CrmStyles.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Expanded(child: Divider(color: CrmStyles.border, thickness: 1)),
        ],
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
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: CrmStyles.cardShadow,
                    ),
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Filter Leads',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: CrmStyles.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  selectedSource = 'All';
                                  selectedStage = 'All';
                                  startDate = DateTime(now.year, now.month, 1);
                                  endDate = now;
                                });
                              },
                              child: const Text(
                                'Reset',
                                style: TextStyle(
                                  color: CrmStyles.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Source Dropdown Section
                        const Text(
                          'Source',
                          style: TextStyle(
                            fontSize: 13,
                            color: CrmStyles.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            border: Border.all(color: CrmStyles.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedSource,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: CrmStyles.textMuted,
                              ),
                              style: const TextStyle(
                                fontSize: 14.5,
                                color: CrmStyles.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'All', child: Text('All Sources')),
                                DropdownMenuItem(value: 'Call', child: Text('Call')),
                                DropdownMenuItem(value: 'Email', child: Text('Email')),
                                DropdownMenuItem(value: 'Website', child: Text('Website')),
                                DropdownMenuItem(value: 'Others', child: Text('Others')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedSource = val);
                                }
                              },
                            ),
                          ),
                        ),

                        if (showStage) ...[
                          const SizedBox(height: 14),
                          const Text(
                            'Stage',
                            style: TextStyle(
                              fontSize: 13,
                              color: CrmStyles.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: CrmStyles.border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedStage,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: CrmStyles.textMuted,
                                ),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  color: CrmStyles.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                                items: [
                                  const DropdownMenuItem(
                                      value: 'All', child: Text('All Stages')),
                                  ...LeadStage.values.map(
                                    (stage) => DropdownMenuItem(
                                      value: stage.displayName,
                                      child: Text(stage.displayName),
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => selectedStage = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        // Date pickers
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
                                            primary: CrmStyles.primary,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setDialogState(() => startDate = picked);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
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
                                            primary: CrmStyles.primary,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setDialogState(() => endDate = picked);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(dialogContext).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: CrmStyles.border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: CrmStyles.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
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
                                  backgroundColor: CrmStyles.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Apply Filter',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Close Icon at top right
                  Positioned(
                    top: -12,
                    right: -12,
                    child: GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF212121),
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
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: CrmStyles.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CrmStyles.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('dd-MMM-yyyy').format(date),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: CrmStyles.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_month_outlined,
                  color: CrmStyles.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
