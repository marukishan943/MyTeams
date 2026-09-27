import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_enums.dart';
import '../../domain/entities/lead_note.dart';
import '../../domain/entities/lead_visit.dart';
import '../../domain/entities/lead_task.dart';
import '../../domain/entities/lead_order.dart';
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () => _showConvertToCustomerDialog(context, state.lead),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF212121),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          child: const Text(
            'Convert to Customer',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton(
          heroTag: 'lead_share_fab',
          backgroundColor: _kPrimaryBlue,
          mini: false,
          onPressed: () => _showShareOptions(context, state.lead),
          child: const Icon(Icons.reply_outlined, color: Colors.white),
        ),
      ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source & Stage & Rating card
          Container(
            color: const Color(0xFFE8EAF6),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source label
                Text(
                  lead.source.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF616161),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Stage badge
                    GestureDetector(
                      onTap: () => _showStageSelector(context, lead),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: lead.stage.backgroundColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          lead.stage.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: lead.stage.color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Star rating
                    Row(
                      children: List.generate(
                        5,
                        (i) => GestureDetector(
                          onTap: () => _updateRating(context, lead, i + 1),
                          child: Icon(
                            i < lead.rating ? Icons.star : Icons.star_border,
                            color: i < lead.rating
                                ? const Color(0xFFFFA000)
                                : Colors.grey[400],
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Staff name
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          lead.staffName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lead name + location + contact actions
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.local_offer,
                      color: Color(0xFF1A237E),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          if (lead.city.isNotEmpty || lead.state.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                [lead.city, lead.state]
                                    .where((s) => s.isNotEmpty)
                                    .join(', '),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF757575),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    _buildCircleActionButton(
                      icon: Icons.phone_outlined,
                      onTap: () => _makeCall(lead.phone),
                    ),
                    const SizedBox(width: 12),
                    _buildCircleActionButton(
                      icon: Icons.chat_outlined,
                      onTap: () => _openWhatsApp(lead.phone),
                    ),
                    if (lead.email.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      _buildCircleActionButton(
                        icon: Icons.email_outlined,
                        onTap: () => _sendEmail(lead.email),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Details section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.access_time_outlined,
                  label: 'Created On',
                  value: DateFormat('dd MMM yyyy hh:mm a')
                      .format(lead.createdAt),
                ),
                if (lead.company.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.business_outlined,
                    label: 'Company',
                    value: lead.company,
                  ),
                if (lead.phone.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: lead.phone,
                  ),
                if (lead.email.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: lead.email,
                  ),
                if (lead.territory.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Territory',
                    value: lead.territory,
                  ),
                if (lead.value > 0)
                  _buildDetailRow(
                    icon: Icons.currency_rupee_outlined,
                    label: 'Value',
                    value: '₹${NumberFormat('#,##,###').format(lead.value)}',
                  ),
                if (lead.title.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.title_outlined,
                    label: 'Title',
                    value: lead.title,
                  ),
                if (lead.note.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.note_outlined,
                    label: 'Note',
                    value: lead.note,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 100), // bottom padding for FABs
        ],
      ),
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _kPrimaryBlue, width: 1.5),
        ),
        child: Icon(icon, color: _kPrimaryBlue, size: 22),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 2: Notes ─────────────────────────────────────────────────
  Widget _buildNotesTab(BuildContext context, LeadDetailLoaded state) {
    final notes = state.notes;
    return Column(
      children: [
        Expanded(
          child: notes.isEmpty
              ? const Center(
                  child: Text(
                    'No notes yet.\nStart the conversation below.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  reverse: false,
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    final showDateHeader = index == 0 ||
                        !_isSameDay(
                          notes[index - 1].createdAt,
                          note.createdAt,
                        );
                    return Column(
                      children: [
                        if (showDateHeader) _buildNoteDateHeader(note.createdAt),
                        _buildNoteItem(note),
                      ],
                    );
                  },
                ),
        ),
        // Bottom note input bar
        _buildNoteInputBar(context),
      ],
    );
  }

  Widget _buildNoteDateHeader(DateTime date) {
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
      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildNoteItem(LeadNote note) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateFormat('hh:mm a').format(note.createdAt).toLowerCase(),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          const SizedBox(height: 4),
          Container(
            margin: const EdgeInsets.only(bottom: 12, left: 60),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              note.content,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF212121),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInputBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 12,
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
                hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
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
            onTap: () => _sendNote(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: _kPrimaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  void _sendNote(BuildContext context) {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    context
        .read<LeadDetailBloc>()
        .add(AddNoteEvent(widget.leadId, text));
    _noteController.clear();
    _noteFocusNode.unfocus();
  }

  // ── TAB 3: Visits ────────────────────────────────────────────────
  Widget _buildVisitsTab(BuildContext context, LeadDetailLoaded state) {
    final visits = state.visits;
    if (visits.isEmpty) {
      return const Center(
        child: Text(
          'No visits recorded.\nTap + to add a visit.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
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
    return GestureDetector(
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Time block
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              DateFormat('hh:mm\na').format(visit.startTime).toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kPrimaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 15, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      visit.staffName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (visit.subject.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    visit.subject,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Purpose badge and Image Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF616161)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  visit.purpose.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF212121),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                visit.images.isEmpty ? Icons.error_outline : Icons.image_outlined,
                color: _kPrimaryBlue,
                size: 22,
              ),
            ],
          ),
        ],
      ),
    ));
  }

  // ── TAB 4: Tasks ─────────────────────────────────────────────────
  Widget _buildTasksTab(BuildContext context, LeadDetailLoaded state) {
    final tasks = state.tasks.where((t) => t.parentId == null).toList();
    if (tasks.isEmpty) {
      return const Center(
        child: Text(
          'No tasks yet.\nTap + to add a task.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
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
    return GestureDetector(
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time block
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              DateFormat('hh:mm\na').format(task.startTime).toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kPrimaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 15, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      task.staffName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (task.subject.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.subject,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              // Type badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF616161)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.type.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF212121),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Priority indicator
              Icon(
                Icons.error_outline,
                color: task.priority > 0 ? Colors.red : _kPrimaryBlue,
                size: 22,
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  // ── TAB 5: Sales ─────────────────────────────────────────────────
  Widget _buildSalesTab(BuildContext context, LeadDetailLoaded state) {
    final orders = state.orders;
    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'No Record Found!',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Change Stage',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: LeadStage.values.map((stage) {
                  final isSelected = lead.stage == stage;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      context.read<LeadDetailBloc>().add(
                            UpdateLeadStageEvent(
                                lead.id, {'stage': stage}),
                          );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: stage.backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? Border.all(color: stage.color, width: 2)
                            : null,
                      ),
                      child: Text(
                        stage.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: stage.color,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
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

  void _showEditLeadDialog(BuildContext context, Lead lead) {
    // Show the stage selector as the primary "edit" action for now.
    // Full edit screen can be added in a future iteration.
    _showStageSelector(context, lead);
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
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
