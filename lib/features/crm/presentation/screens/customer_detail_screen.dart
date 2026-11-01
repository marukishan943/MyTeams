import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/role_permission_service.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_note.dart';
import '../../domain/utils/customer_audit_helper.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_detail_bloc.dart';
import '../bloc/customer_detail_event.dart';
import '../bloc/customer_detail_state.dart';

const Color _kPrimaryBlue = Color(0xFF3949AB);

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CustomerDetailBloc>()..add(LoadCustomerDetail(customer.id)),
      child: _CustomerDetailView(initialCustomer: customer),
    );
  }
}

class _CustomerDetailView extends StatefulWidget {
  final Customer initialCustomer;

  const _CustomerDetailView({required this.initialCustomer});

  @override
  State<_CustomerDetailView> createState() => _CustomerDetailViewState();
}

class _CustomerDetailViewState extends State<_CustomerDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  final ScrollController _notesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    _noteFocusNode.dispose();
    _notesScrollController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDeleteDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete "${customer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CustomerBloc>().add(DeleteCustomerEvent(customer.id));
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _sendNote(BuildContext context, String customerId, [String? staffName]) {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    final author = CustomerAuditHelper.getAuthorName(staffName);
    context
        .read<CustomerDetailBloc>()
        .add(AddCustomerNoteEvent(customerId, text, author));
    _noteController.clear();
    _noteFocusNode.unfocus();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_notesScrollController.hasClients) {
        _notesScrollController.animateTo(
          _notesScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerDetailBloc, CustomerDetailState>(
      listener: (context, state) {
        if (state is CustomerDetailOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        } else if (state is CustomerDetailError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      },
      builder: (context, state) {
        final Customer customer = state is CustomerDetailLoaded
            ? state.customer
            : widget.initialCustomer;
        final List<CustomerNote> notes =
            state is CustomerDetailLoaded ? state.notes : const [];

        final titleText = '${customer.customerNumber} - ${customer.name}';

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
              titleText,
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
                    if (RolePermissionService.instance.canDeleteCustomer)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white),
                        tooltip: 'Delete',
                        onPressed: () => _showDeleteDialog(customer),
                      ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'Refresh',
                      onPressed: () => context
                          .read<CustomerDetailBloc>()
                          .add(RefreshCustomerDetail(customer.id)),
                    ),
                  ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Contact'),
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
              _buildContactTab(customer),
              _buildNotesTab(context, customer, notes),
              _buildPlaceholderTab('No visits recorded yet'),
              _buildPlaceholderTab('No tasks assigned yet'),
              _buildPlaceholderTab('No sales orders found'),
            ],
          ),
        );
      },
    );
  }

  // ── TAB 1: Contact ────────────────────────────────────────────────
  Widget _buildContactTab(Customer customer) {
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
      categoryBg = const Color(0xFFE1F5FE);
      categoryTextColor = const Color(0xFF0288D1);
    }

    final companyDisplay =
        customer.company.isNotEmpty ? customer.company : customer.name;
    final formattedDate =
        DateFormat('dd MMM yyyy hh:mm a').format(customer.createdAt);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header Info Card ──────────────────────────────────────────
          Container(
            color: const Color(0xFFF6F8FC),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  customer.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 8),

                // Company Row + Category Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.business, size: 20, color: Color(0xFF212121)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        companyDisplay,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        customer.category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: categoryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Territory + Staff Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (customer.territory.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: const Color(0xFF1A237E), width: 1.5),
                        ),
                        child: Text(
                          customer.territory,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.badge_outlined,
                              size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 5),
                          Text(
                            customer.staffName.isNotEmpty
                                ? customer.staffName
                                : 'No Reference',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Call & WhatsApp Buttons
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _makePhoneCall(customer.phone),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: _kPrimaryBlue, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.phone,
                          color: _kPrimaryBlue,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () => _openWhatsApp(customer.phone),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: _kPrimaryBlue, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          color: _kPrimaryBlue,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── ADDITIONAL DETAIL ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ADDITIONAL DETAIL',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF757575),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Visit Image',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                const SizedBox(height: 10),
                if (customer.visitImages.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: customer.visitImages.map((path) {
                        return Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: path.startsWith('http')
                                ? Image.network(path, fit: BoxFit.cover)
                                : Image.file(File(path), fit: BoxFit.cover),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                else
                  const Text(
                    'No visit images attached',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // ─── Created By / Created On ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.edit_note, size: 24, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Created By',
                          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customer.createdBy.isNotEmpty
                              ? customer.createdBy
                              : 'ISUN BEVERAGES',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.access_time, size: 22, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Created On',
                          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 2: Notes (Matching Lead Module) ───────────────────────────
  Widget _buildNotesTab(
    BuildContext context,
    Customer customer,
    List<CustomerNote> notesList,
  ) {
    // Sort chronologically (oldest to newest) to display timeline downwards matching reference
    final notes = List<CustomerNote>.from(notesList)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Column(
      children: [
        Expanded(
          child: notes.isEmpty
              ? const Center(
                  child: Text(
                    'No notes or activity yet.\nAdd a note below or change customer details.',
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

                    final parsed = CustomerAuditHelper.parseNoteContent(
                      note.content,
                      customer.staffName,
                    );
                    final formattedTime =
                        DateFormat('hh:mm a').format(note.createdAt).toLowerCase();

                    bool showAuthorHeader = true;
                    if (index > 0) {
                      final prev = notes[index - 1];
                      final prevParsed = CustomerAuditHelper.parseNoteContent(
                        prev.content,
                        customer.staffName,
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
        _buildNoteInputBar(context, customer.id, customer.staffName),
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14.5,
          color: Color(0xFF1E293B),
          height: 1.4,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildNoteInputBar(BuildContext context, String customerId,
      [String? staffName]) {
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
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
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
            onTap: () => _sendNote(context, customerId, staffName),
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

  Widget _buildPlaceholderTab(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }
}
