import '../../../../core/services/role_permission_service.dart';
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
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final isSmall = screenWidth < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: _kPrimaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Leads',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmall ? 18 : 20,
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
          labelStyle: TextStyle(
            fontSize: isSmall ? 14 : 15,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: isSmall ? 14 : 15,
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
                _buildStatsTab(context, state),
                _buildLeadsListTab(context, state.filteredOpenLeads, 'open'),
                _buildLeadsListTab(context, state.filteredClosedLeads, 'closed'),
              ],
            );
          }

          return const Center(
            child: Text('Something went wrong'),
          );
        },
      ),
      floatingActionButton: (_tabController.index == 0 && RolePermissionService.instance.canAddLead)
          ? FloatingActionButton(
              onPressed: () async {
                final leadBloc = context.read<LeadBloc>();
                await context.push('/leads/add');
                if (mounted) {
                  leadBloc.add(const LoadLeads());
                }
              },
              backgroundColor: _kPrimaryBlue,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  // ─── Stats Tab ──────────────────────────────────────────────────────
  Widget _buildStatsTab(BuildContext context, LeadsLoaded state) {
    final stats = state.stats;
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final isSmall = screenWidth < 360;
    final isTablet = screenWidth >= 600;

    final hPadding = (screenWidth * 0.05).clamp(12.0, 32.0);
    final cardSpacing = isSmall ? 8.0 : (isTablet ? 16.0 : 12.0);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'THIS MONTH',
              style: TextStyle(
                fontSize: isSmall ? 12 : 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF475569),
                letterSpacing: 0.8,
              ),
            ),
          ),
          SizedBox(height: isSmall ? 14 : 18),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'New',
                  count: stats.newCount,
                  countColor: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                  borderColor: const Color(0xFFBFDBFE),
                  icon: Icons.fiber_new_outlined,
                  screenWidth: screenWidth,
                  onTap: () => _tabController.animateTo(1),
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildStatCard(
                  label: 'Contacted',
                  count: stats.contactedCount,
                  countColor: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFFFBEB),
                  borderColor: const Color(0xFFFDE68A),
                  icon: Icons.phone_in_talk_outlined,
                  screenWidth: screenWidth,
                  onTap: () => _tabController.animateTo(1),
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildStatCard(
                  label: 'Proposal Sent',
                  count: stats.proposalSentCount,
                  countColor: const Color(0xFF0891B2),
                  bgColor: const Color(0xFFECFEFF),
                  borderColor: const Color(0xFFA5F3FC),
                  icon: Icons.send_outlined,
                  screenWidth: screenWidth,
                  onTap: () => _tabController.animateTo(1),
                ),
              ),
            ],
          ),
          SizedBox(height: cardSpacing),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'Disqualified',
                  count: stats.disqualifiedCount,
                  countColor: const Color(0xFFDC2626),
                  bgColor: const Color(0xFFFEF2F2),
                  borderColor: const Color(0xFFFECACA),
                  icon: Icons.cancel_outlined,
                  screenWidth: screenWidth,
                  onTap: () => _tabController.animateTo(2),
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildStatCard(
                  label: 'Converted',
                  count: stats.convertedCount,
                  countColor: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFF0FDF4),
                  borderColor: const Color(0xFFBBF7D0),
                  icon: Icons.check_circle_outline,
                  screenWidth: screenWidth,
                  onTap: () => _tabController.animateTo(2),
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildStatCard(
                  label: 'Total Leads',
                  count: stats.total,
                  countColor: const Color(0xFF475569),
                  bgColor: const Color(0xFFF8FAFC),
                  borderColor: const Color(0xFFCBD5E1),
                  icon: Icons.people_alt_outlined,
                  screenWidth: screenWidth,
                  onTap: () => _tabController.animateTo(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required Color countColor,
    required Color bgColor,
    required Color borderColor,
    required IconData icon,
    required double screenWidth,
    VoidCallback? onTap,
  }) {
    final isSmall = screenWidth < 360;
    final isTablet = screenWidth >= 600;

    final vPadding = isSmall ? 12.0 : (isTablet ? 20.0 : 16.0);
    final hPadding = isSmall ? 6.0 : (isTablet ? 14.0 : 10.0);
    final labelSize = isSmall ? 10.5 : (isTablet ? 13.5 : 12.0);
    final countSize = isSmall ? 22.0 : (isTablet ? 30.0 : 25.0);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: vPadding, horizontal: hPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: isSmall ? 16 : 18, color: countColor.withValues(alpha: 0.8)),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: labelSize,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
              SizedBox(height: isSmall ? 6 : 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: countSize,
                    fontWeight: FontWeight.w800,
                    color: countColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Leads List Tab (Open / Closed) ────────────────────────────────
  Widget _buildLeadsListTab(BuildContext context, List<Lead> leads, String type) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final hPadding = (screenWidth * 0.04).clamp(12.0, 20.0);

    return Column(
      children: [
        // Search bar
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(hPadding, 10, hPadding, 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                context.read<LeadBloc>().add(SearchLeads(query));
                setState(() {});
              },
              style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search leads by name, company, city...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          context.read<LeadBloc>().add(const SearchLeads(''));
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                fillColor: Colors.transparent,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
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
                        if (showDateHeader) _buildDateHeader(context, lead.date),
                        _buildLeadCard(context, lead),
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

  Widget _buildDateHeader(BuildContext context, DateTime date) {
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

    final media = MediaQuery.of(context);
    final hPadding = (media.size.width * 0.04).clamp(12.0, 20.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 8),
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

  Widget _buildLeadCard(BuildContext context, Lead lead) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final isSmall = screenWidth < 360;

    final boxSize = (screenWidth * 0.12).clamp(44.0, 52.0);
    final cardHPadding = (screenWidth * 0.035).clamp(10.0, 16.0);
    final cardHMargin = (screenWidth * 0.03).clamp(8.0, 16.0);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: cardHMargin, vertical: 4.5),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final leadBloc = context.read<LeadBloc>();
            await context.push('/leads/${lead.id}');
            if (mounted) {
              leadBloc.add(const LoadLeads());
            }
          },
          child: Container(
            padding: EdgeInsets.all(cardHPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Lead number block with soft blue container
                Container(
                  width: boxSize,
                  height: boxSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC7D2FE), width: 0.8),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          lead.leadNumber,
                          style: TextStyle(
                            fontSize: isSmall ? 13 : 15,
                            fontWeight: FontWeight.w700,
                            color: _kPrimaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isSmall ? 10 : 12),
                // Lead info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.name,
                        style: TextStyle(
                          fontSize: isSmall ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (lead.company.isNotEmpty && lead.company.toLowerCase() != lead.name.toLowerCase()) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.business_outlined, size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lead.company,
                                style: TextStyle(
                                  fontSize: isSmall ? 11.5 : 12.5,
                                  color: const Color(0xFF475569),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (lead.city.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lead.city,
                                style: TextStyle(
                                  fontSize: isSmall ? 11 : 12,
                                  color: const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              size: 12,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                lead.staffName.isNotEmpty ? lead.staffName : 'No Reference',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF475569),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Stage badge & star rating indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmall ? 8 : 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: lead.stage.backgroundColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        lead.stage.displayName,
                        style: TextStyle(
                          fontSize: isSmall ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          color: lead.stage.color,
                        ),
                      ),
                    ),
                    if (lead.rating > 0) ...[
                      const SizedBox(height: 5),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          lead.rating,
                          (_) => const Icon(Icons.star, size: 12, color: Color(0xFFF59E0B)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
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
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final isSmall = screenWidth < 360;

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
              insetPadding: EdgeInsets.symmetric(
                horizontal: (screenWidth * 0.06).clamp(16.0, 36.0),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          isSmall ? 16 : 20,
                          26,
                          isSmall ? 16 : 20,
                          26,
                        ),
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
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    border: Border.all(
                                      color: const Color(0xFFCBD5E1),
                                      width: 1.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedSource,
                                      isExpanded: true,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Color(0xFF475569),
                                        size: 22,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF1E293B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'All', child: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('All'))),
                                        DropdownMenuItem(
                                            value: 'Call', child: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Call'))),
                                        DropdownMenuItem(
                                            value: 'Email', child: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Email'))),
                                        DropdownMenuItem(
                                            value: 'Website',
                                            child: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Website'))),
                                        DropdownMenuItem(
                                            value: 'Others', child: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Others'))),
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
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      border: Border.all(
                                        color: const Color(0xFFCBD5E1),
                                        width: 1.2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedStage,
                                        isExpanded: true,
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down,
                                          color: Color(0xFF475569),
                                          size: 22,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Color(0xFF1E293B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        items: [
                                          const DropdownMenuItem(
                                              value: 'All', child: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('All'))),
                                          ...LeadStage.values.map(
                                            (stage) => DropdownMenuItem(
                                              value: stage.displayName,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: Text(stage.displayName),
                                              ),
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
                                    isSmall: isSmall,
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
                                SizedBox(width: isSmall ? 10 : 16),
                                Expanded(
                                  child: _buildDateFilterField(
                                    label: 'End Date',
                                    date: endDate,
                                    isSmall: isSmall,
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
                                width: (screenWidth * 0.45).clamp(140.0, 190.0),
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
                ),
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
    required bool isSmall,
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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  DateFormat('dd-MMM-yyyy').format(date),
                  style: TextStyle(
                    fontSize: isSmall ? 13 : 15,
                    color: const Color(0xFF212121),
                    fontWeight: FontWeight.w400,
                  ),
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
