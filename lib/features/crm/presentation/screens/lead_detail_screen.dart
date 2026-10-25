import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_enums.dart';
import '../../domain/entities/lead_note.dart';
import '../../domain/entities/lead_visit.dart';
import '../../domain/entities/lead_task.dart';
import '../../domain/entities/lead_order.dart';
import '../../domain/utils/lead_audit_helper.dart';
import '../widgets/crm_ui_constants.dart';
import '../widgets/crm_empty_state.dart';
import '../bloc/lead_detail_bloc.dart';
import '../bloc/lead_detail_event.dart';
import '../bloc/lead_detail_state.dart';
import 'add_visit_screen.dart';
import 'visit_detail_screen.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';
import 'edit_lead_screen.dart';
import 'add_order_screen.dart';
import 'add_invoice_screen.dart';
import 'order_detail_screen.dart';

const Color _kPrimaryBlue = Color(0xFF3949AB);

class LeadDetailScreen extends StatefulWidget {
  final String leadId;

  const LeadDetailScreen({super.key, required this.leadId});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  final ScrollController _notesScrollController = ScrollController();
  bool _salesFabExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _salesFabExpanded = false;
      });
    });
    context.read<LeadDetailBloc>().add(LoadLeadDetail(widget.leadId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    _noteFocusNode.dispose();
    _notesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LeadDetailBloc, LeadDetailState>(
      listener: (context, state) {
        if (state is LeadDetailOperationSuccess) {
          // After success, reload if coming back to lead detail
          if (state.message == 'Lead deleted successfully') {
            context.pop();
            return;
          }
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
          // Reload detail
          context
              .read<LeadDetailBloc>()
              .add(LoadLeadDetail(widget.leadId));
        } else if (state is LeadDetailError) {
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
        if (state is LeadDetailLoading || state is LeadDetailInitial) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: _kPrimaryBlue,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              title: const Text(
                'Lead Detail',
                style: TextStyle(color: Colors.white),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(color: _kPrimaryBlue),
            ),
          );
        }

        if (state is LeadDetailLoaded) {
          return _buildScaffold(context, state);
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: _kPrimaryBlue,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Lead Detail',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: const Center(child: Text('Failed to load lead')),
        );
      },
    );
  }

  Widget _buildScaffold(BuildContext context, LeadDetailLoaded state) {
    final lead = state.lead;
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
          'Lead #${lead.leadNumber} - ${lead.name}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: _tabController.index == 0
            ? [
                // Lead tab — Edit + Delete
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<LeadDetailBloc>(),
                          child: EditLeadScreen(lead: lead),
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white),
                  onPressed: () => _showShareOptions(context, lead),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: () => _showDeleteDialog(context, lead),
                ),
              ]
            : [
                // All other tabs (Notes, Visits, Tasks, Sales) — Refresh icon
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => context
                      .read<LeadDetailBloc>()
                      .add(LoadLeadDetail(widget.leadId)),
                ),
              ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Lead'),
            Tab(text: 'Notes'),
            Tab(text: 'Visits'),
            Tab(text: 'Tasks'),
            Tab(text: 'Sales'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeadTab(context, state),
          _buildNotesTab(context, state),
          _buildVisitsTab(context, state),
          _buildTasksTab(context, state),
          _buildSalesTab(context, state),
        ],
      ),
      floatingActionButton: _buildFAB(context, state),
    );
  }

  // ── FAB logic based on active tab ─────────────────────────────────
  Widget? _buildFAB(BuildContext context, LeadDetailLoaded state) {
    final tabIndex = _tabController.index;

    // Lead tab — shows two FABs (convert + actions)
    if (tabIndex == 0) {
      return _buildLeadTabFABs(context, state);
    }
    // Notes tab — no FAB (send via bottom bar)
    if (tabIndex == 1) return null;
    // Visits tab — add visit FAB
    if (tabIndex == 2) {
      return FloatingActionButton(
        backgroundColor: _kPrimaryBlue,
        onPressed: () => _navigateToAddVisit(context, state.lead),
        child: const Icon(Icons.add, color: Colors.white),
      );
    }
    // Tasks tab — add task FAB
    if (tabIndex == 3) {
      return FloatingActionButton(
        backgroundColor: _kPrimaryBlue,
        onPressed: () => _navigateToAddTask(context, state.lead),
        child: const Icon(Icons.add, color: Colors.white),
      );
    }
    // Sales tab — expandable FAB
    if (tabIndex == 4) {
      return _buildSalesFAB(context, state.lead);
    }
    return null;
  }

  Widget? _buildLeadTabFABs(BuildContext context, LeadDetailLoaded state) {
    final isClosedOrConverted =
        state.lead.isClosed || state.lead.stage == LeadStage.converted;

    if (isClosedOrConverted) {
      return null;
    }

    return Container(
      margin: const EdgeInsets.only(left: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showConvertToCustomerDialog(context, state.lead),
            icon: const Icon(Icons.check_circle_outline, size: 20, color: Color(0xFF047857)),
            label: const Text(
              'Convert to Customer',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 3,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFFA7F3D0), width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesFAB(BuildContext context, Lead lead) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_salesFabExpanded) ...[
          _buildSalesOption(
            context,
            'Add Order',
            Icons.shopping_bag_outlined,
            onTap: () {
              setState(() => _salesFabExpanded = false);
              _navigateToAddOrder(context, lead);
            },
          ),
          const SizedBox(height: 12),
          _buildSalesOption(
            context,
            'Add Invoice',
            Icons.monetization_on_outlined,
            onTap: () {
              setState(() => _salesFabExpanded = false);
              _navigateToAddInvoice(context, lead, isProforma: false);
            },
          ),
          const SizedBox(height: 12),
          _buildSalesOption(
            context,
            'Add Proforma Invoice',
            Icons.description_outlined,
            onTap: () {
              setState(() => _salesFabExpanded = false);
              _navigateToAddInvoice(context, lead, isProforma: true);
            },
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          heroTag: 'sales_fab',
          backgroundColor: _kPrimaryBlue,
          onPressed: () {
            setState(() {
              _salesFabExpanded = !_salesFabExpanded;
            });
          },
          child: AnimatedRotation(
            turns: _salesFabExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _salesFabExpanded ? Icons.close : Icons.add,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesOption(
    BuildContext context,
    String label,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF212121),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton(
          heroTag: label,
          mini: false,
          backgroundColor: _kPrimaryBlue,
          onPressed: onTap,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ],
    );
  }

  // ── TAB 1: Lead ──────────────────────────────────────────────────
  Widget _buildLeadTab(BuildContext context, LeadDetailLoaded state) {
    final lead = state.lead;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero Lead Profile Card
          _buildHeroProfileCard(context, lead),
          const SizedBox(height: 14),

          // 2. Action Buttons Row (Call, WhatsApp, Email)
          _buildContactActionCard(lead),
          const SizedBox(height: 14),

          // 3. Contact Information Card
          _buildSectionCard(
            title: 'Contact Information',
            icon: Icons.contact_phone_outlined,
            children: [
              if (lead.phone.isNotEmpty)
                _buildModernDetailRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone Number',
                  value: lead.phone,
                  actionIcon: Icons.phone,
                  onAction: () => _makeCall(lead.phone),
                ),
              if (lead.email.isNotEmpty)
                _buildModernDetailRow(
                  icon: Icons.email_outlined,
                  label: 'Email Address',
                  value: lead.email,
                  actionIcon: Icons.send,
                  onAction: () => _sendEmail(lead.email, lead.name),
                ),
              if (lead.territory.isNotEmpty)
                _buildModernDetailRow(
                  icon: Icons.map_outlined,
                  label: 'Territory',
                  value: lead.territory,
                ),
              if (lead.address.isNotEmpty || lead.city.isNotEmpty || lead.state.isNotEmpty)
                _buildModernDetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: [lead.address, lead.city, lead.state, lead.pincode]
                      .where((s) => s.isNotEmpty)
                      .join(', '),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // 4. Lead Pipeline Details Card
          _buildSectionCard(
            title: 'Lead Details',
            icon: Icons.info_outline_rounded,
            children: [
              _buildModernDetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Created Date',
                value: DateFormat('dd MMM yyyy, hh:mm a').format(lead.createdAt),
              ),
              if (lead.company.isNotEmpty)
                _buildModernDetailRow(
                  icon: Icons.business_outlined,
                  label: 'Company',
                  value: lead.company,
                ),
              if (lead.title.isNotEmpty)
                _buildModernDetailRow(
                  icon: Icons.badge_outlined,
                  label: 'Job Title / Designation',
                  value: lead.title,
                ),
              if (lead.value > 0)
                _buildModernDetailRow(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Estimated Value',
                  value: '₹${NumberFormat('#,##,###').format(lead.value)}',
                  valueColor: const Color(0xFF047857),
                ),
              if (lead.website.isNotEmpty)
                _buildModernDetailRow(
                  icon: Icons.language_outlined,
                  label: 'Website',
                  value: lead.website,
                ),
              if (lead.gst.isNotEmpty)
                _buildModernDetailRow(
                  icon: Icons.receipt_long_outlined,
                  label: 'GST Number',
                  value: lead.gst,
                ),
            ],
          ),

          // 5. Initial Remarks Card (if present)
          if (lead.note.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildSectionCard(
              title: 'Initial Remarks',
              icon: Icons.sticky_note_2_outlined,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CrmStyles.border),
                  ),
                  child: Text(
                    lead.note,
                    style: const TextStyle(
                      fontSize: 14,
                      color: CrmStyles.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroProfileCard(BuildContext context, Lead lead) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CrmStyles.radiusLarge),
        border: Border.all(color: CrmStyles.border),
        boxShadow: CrmStyles.cardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Source chip + Interactive Stage pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Source Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getSourceIcon(lead.source.displayName),
                      size: 13,
                      color: CrmStyles.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      lead.source.displayName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CrmStyles.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Interactive Stage Pill with dropdown arrow
              GestureDetector(
                onTap: () => _showStageSelector(context, lead),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: lead.stage.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: lead.stage.color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: lead.stage.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        lead.stage.displayName,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: lead.stage.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: lead.stage.color,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Lead Name
          Text(
            lead.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: CrmStyles.textPrimary,
              letterSpacing: -0.3,
            ),
          ),

          // Company
          if (lead.company.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.business_outlined,
                  size: 15,
                  color: CrmStyles.textMuted,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    lead.company,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: CrmStyles.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Location
          if (lead.city.isNotEmpty || lead.state.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: CrmStyles.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  [lead.city, lead.state].where((s) => s.isNotEmpty).join(', '),
                  style: const TextStyle(
                    fontSize: 13,
                    color: CrmStyles.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1, color: CrmStyles.borderLight),
          const SizedBox(height: 12),

          // Footer Row: Rating Stars + Assigned Staff
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Interactive Star Rating
              Row(
                children: List.generate(5, (i) {
                  final starNum = i + 1;
                  return GestureDetector(
                    onTap: () => _updateRating(context, lead, starNum),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Icon(
                        starNum <= lead.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: starNum <= lead.rating
                            ? const Color(0xFFFFB300)
                            : const Color(0xFFCBD5E1),
                        size: 22,
                      ),
                    ),
                  );
                }),
              ),

              // Staff assignment tag
              if (lead.staffName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CrmStyles.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person,
                        size: 13,
                        color: CrmStyles.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lead.staffName,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: CrmStyles.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactActionCard(Lead lead) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CrmStyles.radiusLarge),
        border: Border.all(color: CrmStyles.border),
        boxShadow: CrmStyles.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            label: 'Call',
            icon: Icons.phone,
            color: CrmStyles.primary,
            bgColor: CrmStyles.primaryLight,
            onTap: () => _makeCall(lead.phone),
          ),
          _buildActionButton(
            label: 'WhatsApp',
            customIcon: _buildWhatsAppIcon(size: 22),
            color: const Color(0xFF25D366),
            bgColor: const Color(0xFFDCFCE7),
            onTap: () => _openWhatsApp(lead.phone),
          ),
          _buildActionButton(
            label: 'Email',
            icon: Icons.email_outlined,
            color: CrmStyles.primary,
            bgColor: CrmStyles.primaryLight,
            onTap: () => _sendEmail(lead.email, lead.name),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    IconData? icon,
    Widget? customIcon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: customIcon ?? Icon(icon, color: color, size: 22),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CrmStyles.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CrmStyles.radiusLarge),
        border: Border.all(color: CrmStyles.border),
        boxShadow: CrmStyles.cardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: CrmStyles.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: CrmStyles.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: CrmStyles.borderLight),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    IconData? actionIcon,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: CrmStyles.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CrmStyles.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? CrmStyles.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (actionIcon != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: CrmStyles.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(actionIcon, size: 16, color: CrmStyles.primary),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getSourceIcon(String source) {
    final s = source.toLowerCase();
    if (s.contains('call')) return Icons.phone_outlined;
    if (s.contains('email')) return Icons.email_outlined;
    if (s.contains('web')) return Icons.language_outlined;
    return Icons.tag_outlined;
  }

  Widget _buildWhatsAppIcon({double size = 22}) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.chat_bubble,
            size: size,
            color: const Color(0xFF25D366),
          ),
          Icon(
            Icons.phone,
            size: size * 0.52,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  // ── TAB 2: Notes ─────────────────────────────────────────────────
  Widget _buildNotesTab(BuildContext context, LeadDetailLoaded state) {
    // Sort chronologically (oldest to newest) to display timeline downwards matching reference
    final notes = List<LeadNote>.from(state.notes)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Column(
      children: [
        Expanded(
          child: notes.isEmpty
              ? const Center(
                  child: Text(
                    'No notes or activity yet.\nAdd a note below or change lead details.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                )
              : ListView.builder(
                  controller: _notesScrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    final showDateHeader = index == 0 ||
                        !_isSameDay(
                          notes[index - 1].createdAt,
                          note.createdAt,
                        );

                    final parsed = LeadAuditHelper.parseNoteContent(
                      note.content,
                      state.lead.staffName,
                    );
                    final formattedTime =
                        DateFormat('hh:mm a').format(note.createdAt).toLowerCase();

                    bool showAuthorHeader = true;
                    if (index > 0) {
                      final prev = notes[index - 1];
                      final prevParsed = LeadAuditHelper.parseNoteContent(
                        prev.content,
                        state.lead.staffName,
                      );
                      final prevTime =
                          DateFormat('hh:mm a').format(prev.createdAt).toLowerCase();
                      if (_isSameDay(prev.createdAt, note.createdAt) &&
                          prevParsed.author == parsed.author &&
                          prevTime == formattedTime) {
                        showAuthorHeader = false;
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDateHeader) _buildNoteDateHeader(note.createdAt),
                        if (showAuthorHeader)
                          Padding(
                            padding: EdgeInsets.only(
                              top: showDateHeader ? 0 : 8,
                              bottom: 6,
                            ),
                            child: Text(
                              '${parsed.author.toUpperCase()}, $formattedTime',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF757575),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        _buildNoteItem(parsed.text),
                      ],
                    );
                  },
                ),
        ),
        // Bottom note input bar
        _buildNoteInputBar(context, state.lead.staffName),
      ],
    );
  }

  Widget _buildNoteDateHeader(DateTime date) {
    final dayMonth = DateFormat('dd MMM').format(date);
    final dayOfWeek = DateFormat('EEE').format(date).toUpperCase();
    final label = '$dayMonth ($dayOfWeek)';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Expanded(
            child: Divider(
              color: Color(0xFFE0E0E0),
              thickness: 0.8,
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF757575),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const Expanded(
            child: Divider(
              color: Color(0xFFE0E0E0),
              thickness: 0.8,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14.5,
          color: Color(0xFF212121),
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildNoteInputBar(BuildContext context, [String? staffName]) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _noteController,
              focusNode: _noteFocusNode,
              decoration: InputDecoration(
                hintText: 'Enter Note',
                hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 15),
                filled: true,
                fillColor: const Color(0xFFF5F6F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendNote(context, staffName),
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: _kPrimaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _sendNote(BuildContext context, [String? staffName]) {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    final author = LeadAuditHelper.getAuthorName(staffName);
    context.read<LeadDetailBloc>().add(AddNoteEvent(widget.leadId, text, author));
    _noteController.clear();
    _noteFocusNode.unfocus();
  }

  // ── TAB 3: Visits ────────────────────────────────────────────────
  Widget _buildVisitsTab(BuildContext context, LeadDetailLoaded state) {
    final visits = state.visits;
    if (visits.isEmpty) {
      return CrmEmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'No Visits Recorded',
        message: 'Schedule a site visit or log a meeting with this lead.',
        buttonText: 'Schedule Visit',
        onButtonPressed: () => _navigateToAddVisit(context, state.lead),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: visits.length,
      itemBuilder: (context, index) {
        final visit = visits[index];
        final showHeader = index == 0 ||
            !_isSameDay(
              visits[index - 1].createdAt,
              visit.createdAt,
            );
        return Column(
          children: [
            if (showHeader) _buildActivityDateHeader(visit.date),
            _buildVisitCard(context, state, visit),
          ],
        );
      },
    );
  }

  Widget _buildActivityDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    String label;
    if (dateOnly == today) {
      label = 'TODAY';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      label = 'YESTERDAY';
    } else {
      label = DateFormat('dd MMM yyyy').format(date).toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
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
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildVisitCard(BuildContext context, LeadDetailLoaded state, LeadVisit visit) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CrmStyles.radiusLarge),
        border: Border.all(color: CrmStyles.border),
        boxShadow: CrmStyles.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(CrmStyles.radiusLarge),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<LeadDetailBloc>(),
                  child: VisitDetailScreen(
                    lead: state.lead,
                    visit: visit,
                  ),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(CrmStyles.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Time block
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: CrmStyles.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    DateFormat('hh:mm\na').format(visit.startTime).toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: CrmStyles.primary,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.subject.isNotEmpty ? visit.subject : 'Site Visit',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: CrmStyles.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: CrmStyles.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            visit.staffName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: CrmStyles.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Purpose badge & Image
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CrmStyles.border),
                      ),
                      child: Text(
                        visit.purpose.displayName,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: CrmStyles.textSecondary,
                        ),
                      ),
                    ),
                    if (visit.images.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_outlined, size: 14, color: CrmStyles.primary),
                          const SizedBox(width: 3),
                          Text(
                            '${visit.images.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: CrmStyles.primary,
                            ),
                          ),
                        ],
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

  // ── TAB 4: Tasks ─────────────────────────────────────────────────
  Widget _buildTasksTab(BuildContext context, LeadDetailLoaded state) {
    final tasks = state.tasks.where((t) => t.parentId == null).toList();
    if (tasks.isEmpty) {
      return CrmEmptyState(
        icon: Icons.checklist_rounded,
        title: 'No Tasks Scheduled',
        message: 'Create follow-ups, calls, or reminders for this lead.',
        buttonText: 'Add New Task',
        onButtonPressed: () => _navigateToAddTask(context, state.lead),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final showHeader = index == 0 ||
            !_isSameDay(
              tasks[index - 1].createdAt,
              task.createdAt,
            );
        return Column(
          children: [
            if (showHeader) _buildActivityDateHeader(task.startDate),
            _buildTaskCard(context, state, task),
          ],
        );
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, LeadDetailLoaded state, LeadTask task) {
    Color priorityColor = CrmStyles.primary;
    String priorityText = 'Normal';
    if (task.priority == 3) {
      priorityColor = CrmStyles.danger;
      priorityText = 'High';
    } else if (task.priority == 2) {
      priorityColor = CrmStyles.warning;
      priorityText = 'Medium';
    } else if (task.priority == 1) {
      priorityColor = const Color(0xFF0284C7);
      priorityText = 'Low';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CrmStyles.radiusLarge),
        border: Border.all(color: CrmStyles.border),
        boxShadow: CrmStyles.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(CrmStyles.radiusLarge),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<LeadDetailBloc>(),
                  child: TaskDetailScreen(
                    lead: state.lead,
                    task: task,
                  ),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(CrmStyles.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Time block
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: CrmStyles.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    DateFormat('hh:mm\na').format(task.startTime).toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: CrmStyles.primary,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.subject.isNotEmpty ? task.subject : 'Task',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: CrmStyles.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: CrmStyles.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            task.staffName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: CrmStyles.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CrmStyles.border),
                      ),
                      child: Text(
                        task.type.displayName,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: CrmStyles.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        priorityText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── TAB 5: Sales ─────────────────────────────────────────────────
  Widget _buildSalesTab(BuildContext context, LeadDetailLoaded state) {
    final orders = state.orders;
    if (orders.isEmpty) {
      return const CrmEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No Commercial Records',
        message: 'Orders, invoices, and quotations created for this lead will appear here.',
      );
    }

    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final double totalDue = orders
        .where((o) => o.status != OrderStatus.cancelled && 
                      o.status != OrderStatus.converted && 
                      o.type != 'proforma_invoice')
        .fold(0.0, (sum, o) => sum + o.dueBalance);

    final List<LeadOrder> invoices = orders.where((o) => o.type == 'invoice').toList();
    final List<LeadOrder> orderDocs = orders.where((o) => o.type == 'order').toList();
    final List<LeadOrder> pfis = orders.where((o) => o.type == 'proforma_invoice').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'INV: ${invoices.length}  |  ORD: ${orderDocs.length}  |  PFI: ${pfis.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _kPrimaryBlue,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: Text(
                    'Due ${currencyFormat.format(totalDue)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6D4C41),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (orderDocs.isNotEmpty) _buildTypeGroup(context, state, orderDocs, currencyFormat),
          if (invoices.isNotEmpty) _buildTypeGroup(context, state, invoices, currencyFormat),
          if (pfis.isNotEmpty) _buildTypeGroup(context, state, pfis, currencyFormat),
        ],
      ),
    );
  }

  Widget _buildTypeGroup(BuildContext context, LeadDetailLoaded state, List<LeadOrder> typeOrders, NumberFormat currencyFormat) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: typeOrders.length,
      itemBuilder: (context, index) {
        final order = typeOrders[index];
        final showHeader = index == 0 || !_isSameDay(typeOrders[index - 1].date, order.date);

        return Column(
          children: [
            if (showHeader) _buildActivityDateHeader(order.date),
            _buildOrderCard(context, state, order, currencyFormat),
          ],
        );
      },
    );
  }

  Widget _buildOrderCard(
      BuildContext context,
      LeadDetailLoaded state,
      LeadOrder order,
      NumberFormat currencyFormat) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<LeadDetailBloc>(),
              child: OrderDetailScreen(
                lead: state.lead,
                order: order,
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
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
          // Type badge (ORD / INV / PRO)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  order.typeLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kPrimaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.orderNumber,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _kPrimaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Staff Name
          Expanded(
            child: Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.staffName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF424242),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Amount & Status Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currencyFormat.format(order.totalAmount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (order.status == OrderStatus.converted)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.sync_alt, size: 16, color: Colors.black87),
                    ),
                  Builder(builder: (context) {
                    String text = order.status.displayName;
                    Color bgColor = _getOrderStatusBgColor(order.status);
                    Color textColor = _getOrderStatusTextColor(order.status);
                    
                    if (order.type == 'invoice' && order.status != OrderStatus.converted && order.status != OrderStatus.cancelled) {
                      if (order.isPaid) {
                        text = 'Fully Paid';
                        bgColor = const Color(0xFFC8E6C9);
                        textColor = const Color(0xFF2E7D32);
                      } else {
                        text = 'Unpaid';
                        bgColor = const Color(0xFFE8EAF6);
                        textColor = const Color(0xFF3949AB);
                      }
                    }

                    return Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Color _getOrderStatusBgColor(OrderStatus status) {
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

  Color _getOrderStatusTextColor(OrderStatus status) {
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

  // ── Dialogs & Actions ─────────────────────────────────────────────
  void _showStageSelector(BuildContext context, Lead lead) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Update Lead Stage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CrmStyles.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select the new status in the conversion pipeline',
                  style: TextStyle(
                    fontSize: 13,
                    color: CrmStyles.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ...LeadStage.values.map((stage) {
                  final isSelected = lead.stage == stage;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected ? stage.backgroundColor : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          context.read<LeadDetailBloc>().add(
                                UpdateLeadStageEvent(lead.id, {'stage': stage}),
                              );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? stage.color : CrmStyles.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: stage.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  stage.displayName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? stage.color : CrmStyles.textPrimary,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle_rounded, color: stage.color, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateRating(BuildContext context, Lead lead, int rating) {
    context.read<LeadDetailBloc>().add(
          UpdateLeadStageEvent(lead.id, {'rating': rating}),
        );
  }

  void _showDeleteDialog(BuildContext context, Lead lead) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Lead'),
        content: Text(
            'Are you sure you want to delete "${lead.name}"? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<LeadDetailBloc>()
                  .add(DeleteLeadDetailEvent(lead.id));
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



  void _showConvertToCustomerDialog(BuildContext context, Lead lead) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Convert to Customer'),
        content: Text(
            'Convert "${lead.name}" to a customer? This will mark the lead as converted.'),
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
                    UpdateLeadStageEvent(
                      lead.id,
                      {'stage': LeadStage.converted, 'isClosed': true},
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Convert'),
          ),
        ],
      ),
    );
  }

  void _showShareOptions(BuildContext context, Lead lead) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon')),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────
  void _navigateToAddVisit(BuildContext context, Lead lead) async {
    final bloc = context.read<LeadDetailBloc>();
    final result = await Navigator.push<LeadVisit>(
      context,
      MaterialPageRoute(
        builder: (_) => AddVisitScreen(lead: lead),
      ),
    );
    if (result != null && mounted) {
      bloc.add(AddVisitEvent(result));
    }
  }

  void _navigateToAddTask(BuildContext context, Lead lead) async {
    final bloc = context.read<LeadDetailBloc>();
    final result = await Navigator.push<LeadTask>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTaskScreen(lead: lead),
      ),
    );
    if (result != null && mounted) {
      bloc.add(AddTaskEvent(result));
    }
  }

  void _navigateToAddOrder(BuildContext context, Lead lead) async {
    final bloc = context.read<LeadDetailBloc>();
    final result = await Navigator.push<LeadOrder>(
      context,
      MaterialPageRoute(
        builder: (_) => AddOrderScreen(lead: lead),
      ),
    );
    if (result != null && mounted) {
      bloc.add(AddOrderEvent(result));
    }
  }

  void _navigateToAddInvoice(
    BuildContext context,
    Lead lead, {
    required bool isProforma,
  }) async {
    final bloc = context.read<LeadDetailBloc>();
    final result = await Navigator.push<LeadOrder>(
      context,
      MaterialPageRoute(
        builder: (_) => AddInvoiceScreen(lead: lead, isProforma: isProforma),
      ),
    );
    if (result != null && mounted) {
      bloc.add(AddOrderEvent(result));
    }
  }

  // ── URL Launchers ─────────────────────────────────────────────────
  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No phone number provided for this lead'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open phone dialer: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    var cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No phone number provided for WhatsApp'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Default to country code 91 if 10 digits
    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }

    final nativeUri = Uri.parse('whatsapp://send?phone=$cleanPhone');
    final webUri = Uri.parse('https://wa.me/$cleanPhone');

    try {
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open WhatsApp on this device'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _sendEmail(String email, [String? leadName]) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No email address provided for this lead'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    String? currentUserEmail;
    try {
      currentUserEmail = Supabase.instance.client.auth.currentUser?.email;
    } catch (_) {}

    final queryParameters = <String, String>{};
    if (currentUserEmail != null && currentUserEmail.isNotEmpty) {
      queryParameters['from'] = currentUserEmail;
    }
    queryParameters['subject'] = (leadName != null && leadName.trim().isNotEmpty)
        ? 'Inquiry Follow-up - ${leadName.trim()}'
        : 'Inquiry Follow-up';

    final uri = Uri(
      scheme: 'mailto',
      path: cleanEmail,
      query: queryParameters.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&'),
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open email client: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
