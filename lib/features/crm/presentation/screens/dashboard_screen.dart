import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../theme/app_colors.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';

const Color _kPrimaryBlue = Color(0xFF3949AB);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, bool> _moduleVisibility = {
    'leads': true,
    'customers': true,
    'sales': true,
    'expenses': true,
    'reports': true,
    'settings': true,
  };

  @override
  void initState() {
    super.initState();
    _fetchModuleVisibility();
  }

  Future<void> _fetchModuleVisibility() async {
    // 1. Try company_settings table
    try {
      final res = await Supabase.instance.client
          .from('company_settings')
          .select('enabled_modules')
          .limit(1)
          .maybeSingle();

      if (res != null && res['enabled_modules'] != null && mounted) {
        final Map<String, dynamic> raw =
            res['enabled_modules'] as Map<String, dynamic>;
        setState(() {
          _moduleVisibility = {
            'leads': raw['leads'] != false,
            'customers': raw['customers'] != false,
            'sales': raw['sales'] != false,
            'expenses': raw['expenses'] != false,
            'reports': raw['reports'] != false,
            'settings': raw['settings'] != false,
          };
        });
        return;
      }
    } catch (_) {}

    // 2. Fallback to SYS_CONFIG customer record (guaranteed cloud sync)
    try {
      final res = await Supabase.instance.client
          .from('customers')
          .select('company')
          .eq('customer_number', 'SYS_CONFIG')
          .maybeSingle();

      if (res != null && res['company'] != null && mounted) {
        final parsed = jsonDecode(res['company'] as String);
        Map<String, dynamic>? raw;
        if (parsed is Map) {
          if (parsed['modules'] is Map) {
            raw = Map<String, dynamic>.from(parsed['modules'] as Map);
          } else {
            raw = Map<String, dynamic>.from(parsed);
          }
        }
        final config = raw;
        if (config != null && mounted) {
          setState(() {
            _moduleVisibility = {
              'leads': config['leads'] != false,
              'customers': config['customers'] != false,
              'sales': config['sales'] != false,
              'expenses': config['expenses'] != false,
              'reports': config['reports'] != false,
              'settings': config['settings'] != false,
            };
          });
        }
      }
    } catch (_) {
      // Keep defaults on connection issues
    }
  }

  Future<void> _updateModuleVisibility(String moduleKey, bool isVisible) async {
    final updated = Map<String, bool>.from(_moduleVisibility);
    updated[moduleKey] = isVisible;

    setState(() {
      _moduleVisibility = updated;
    });

    // Write to company_settings (primary – used by web admin)
    await _saveToCompanySettings(updated);

    // Also write to SYS_CONFIG fallback record for backward compat
    await _saveToSysConfig(updated);
  }

  Future<void> _setAllModules(bool visible) async {
    final updated = {
      'leads': visible,
      'customers': visible,
      'sales': visible,
      'expenses': visible,
      'reports': visible,
      'settings': visible,
    };

    setState(() {
      _moduleVisibility = updated;
    });

    // Write to company_settings (primary – used by web admin)
    await _saveToCompanySettings(updated);

    // Also write to SYS_CONFIG fallback record for backward compat
    await _saveToSysConfig(updated);
  }

  /// Saves module visibility to [company_settings] table.
  /// This is the primary store used by the web admin panel.
  Future<void> _saveToCompanySettings(Map<String, bool> modules) async {
    try {
      final existing = await Supabase.instance.client
          .from('company_settings')
          .select('id')
          .limit(1)
          .maybeSingle();

      if (existing != null && existing['id'] != null) {
        await Supabase.instance.client
            .from('company_settings')
            .update({
              'enabled_modules': modules,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
      } else {
        await Supabase.instance.client.from('company_settings').insert({
          'enabled_modules': modules,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  /// Saves module visibility to the [customers] SYS_CONFIG record.
  /// This is the legacy fallback store for backward compatibility.
  Future<void> _saveToSysConfig(Map<String, bool> modules) async {
    try {
      final res = await Supabase.instance.client
          .from('customers')
          .select('id, company')
          .eq('customer_number', 'SYS_CONFIG')
          .maybeSingle();

      Map<String, dynamic> currentPayload = {};
      if (res != null && res['company'] != null) {
        try {
          final parsed = jsonDecode(res['company'] as String);
          if (parsed is Map) {
            currentPayload = Map<String, dynamic>.from(parsed);
          }
        } catch (_) {}
      }

      currentPayload['modules'] = modules;
      final jsonStr = jsonEncode(currentPayload);

      if (res != null && res['id'] != null) {
        await Supabase.instance.client
            .from('customers')
            .update({
              'company': jsonStr,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', res['id']);
      } else {
        await Supabase.instance.client.from('customers').insert({
          'customer_number': 'SYS_CONFIG',
          'name': '__SYSTEM_SETTINGS__',
          'company': jsonStr,
          'phone': '0000000000',
          'category': 'Other',
          'status': 'Active',
          'country': 'India',
          'created_by': 'ISUN BEVERAGES',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  void _showCustomizeModulesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final modulesList = [
              {
                'key': 'leads',
                'name': 'Leads',
                'desc': 'Pipelines, stages & inquiries',
                'icon': Icons.monetization_on_outlined,
                'color': const Color(0xFF3949AB),
              },
              {
                'key': 'customers',
                'name': 'Customers',
                'desc': 'Client accounts, retailers & distributors',
                'icon': Icons.person_pin_outlined,
                'color': const Color(0xFF00897B),
              },
              {
                'key': 'sales',
                'name': 'Sales & Invoices',
                'desc': 'Proforma, invoices, orders & payments',
                'icon': Icons.attach_money_outlined,
                'color': const Color(0xFF7B1FA2),
              },
              {
                'key': 'expenses',
                'name': 'Expenses',
                'desc': 'Field expense claims & reimbursements',
                'icon': Icons.receipt_long_outlined,
                'color': const Color(0xFFF57C00),
              },
            ];

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customize Modules',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF212121),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Show or hide modules on your dashboard',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    ...modulesList.map((m) {
                      final key = m['key'] as String;
                      final isVisible = _moduleVisibility[key] != false;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isVisible ? const Color(0xFFF8F9FA) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isVisible ? Colors.grey.shade200 : Colors.grey.shade100,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (m['color'] as Color).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                m['icon'] as IconData,
                                color: m['color'] as Color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m['name'] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isVisible ? const Color(0xFF212121) : Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    m['desc'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: isVisible,
                              activeColor: _kPrimaryBlue,
                              onChanged: (val) {
                                setModalState(() {});
                                _updateModuleVisibility(key, val);
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {});
                            _setAllModules(true);
                          },
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('Show All'),
                          style: TextButton.styleFrom(
                            foregroundColor: _kPrimaryBlue,
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {});
                            _setAllModules(false);
                          },
                          icon: const Icon(Icons.visibility_off_outlined, size: 16),
                          label: const Text('Hide All'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: _kPrimaryBlue,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'MY TEAMS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined, color: Colors.white),
            tooltip: 'Customize Modules',
            onPressed: _showCustomizeModulesBottomSheet,
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '35',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: RefreshIndicator(
            onRefresh: _fetchModuleVisibility,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome banner
                _buildWelcomeBanner(context),
                const SizedBox(height: 16),

                // Summary cards
                _buildSummaryCards(context),
                const SizedBox(height: 20),

                // GEO Section
                _buildSection(
                  context,
                  title: 'GEO',
                  items: [
                    _DashboardItem(
                      icon: Icons.people_outline,
                      label: 'My Team',
                      onTap: () {},
                    ),
                    _DashboardItem(
                      icon: Icons.location_on_outlined,
                      label: 'Visits',
                      onTap: () {},
                    ),
                    _DashboardItem(
                      icon: Icons.checklist_outlined,
                      label: 'Tasks',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // CRM Section
                if (_moduleVisibility['leads'] != false ||
                    _moduleVisibility['customers'] != false ||
                    _moduleVisibility['sales'] != false) ...[
                  _buildSection(
                    context,
                    title: 'CRM',
                    items: [
                      if (_moduleVisibility['leads'] != false)
                        _DashboardItem(
                          icon: Icons.monetization_on_outlined,
                          label: 'Leads',
                          onTap: () => context.push('/leads'),
                        ),
                      if (_moduleVisibility['customers'] != false)
                        _DashboardItem(
                          icon: Icons.person_pin_outlined,
                          label: 'Customers',
                          onTap: () => context.push('/customers'),
                        ),
                      if (_moduleVisibility['sales'] != false)
                        _DashboardItem(
                          icon: Icons.attach_money_outlined,
                          label: 'Sales',
                          onTap: () => context.push('/sales'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // HRM Section
                _buildSection(
                  context,
                  title: 'HRM',
                  items: [
                    _DashboardItem(
                      icon: Icons.calendar_today_outlined,
                      label: 'Attendance',
                      onTap: () {},
                    ),
                    _DashboardItem(
                      icon: Icons.event_busy_outlined,
                      label: 'Leaves',
                      onTap: () {},
                    ),
                    if (_moduleVisibility['expenses'] != false)
                      _DashboardItem(
                        icon: Icons.receipt_long_outlined,
                        label: 'Expenses',
                        onTap: () {},
                      ),
                    _DashboardItem(
                      icon: Icons.payments_outlined,
                      label: 'Payroll',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Miscellaneous Section
                _buildSection(
                  context,
                  title: 'Miscellaneous',
                  items: [
                    _DashboardItem(
                      icon: Icons.inventory_2_outlined,
                      label: 'Products',
                      onTap: () {},
                    ),
                    _DashboardItem(
                      icon: Icons.description_outlined,
                      label: 'Orders',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalMargin = screenWidth < 360 ? 12.0 : 16.0;
    final padding = screenWidth < 360 ? 16.0 : 20.0;
    final avatarSize = screenWidth < 360 ? 48.0 : 56.0;
    final iconSize = screenWidth < 360 ? 24.0 : 30.0;
    final titleSize = screenWidth < 360 ? 16.0 : 18.0;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(horizontalMargin, 16, horizontalMargin, 0),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kPrimaryBlue, Color(0xFF5C6BC0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Welcome MY TEAMS,',
              style: TextStyle(
                color: Colors.white,
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.business,
              color: Colors.white,
              size: iconSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalMargin = screenWidth < 360 ? 12.0 : 16.0;
    final cardPadding = screenWidth < 360 ? 12.0 : 16.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSummaryItem(
              context, 'Attendance', Icons.check_box_outlined, '0', '/5'),
          _buildDivider(),
          _buildSummaryItem(
              context, 'Visits', Icons.location_on_outlined, '0', '/0'),
          _buildDivider(),
          _buildSummaryItem(
              context, 'Tasks', Icons.checklist, '0', '/0'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label,
      IconData icon, String count, String total) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 360;
    final indicatorSize = isSmall ? 52.0 : 60.0;
    final labelSize = isSmall ? 11.5 : 13.0;

    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: isSmall ? 14 : 16, color: _kPrimaryBlue),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: indicatorSize,
            height: indicatorSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: indicatorSize,
                  height: indicatorSize,
                  child: CircularProgressIndicator(
                    value: 0,
                    strokeWidth: isSmall ? 3.5 : 4,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_kPrimaryBlue),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      count,
                      style: TextStyle(
                        fontSize: isSmall ? 17 : 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF212121),
                      ),
                    ),
                    Text(
                      total,
                      style: TextStyle(
                        fontSize: isSmall ? 11 : 12,
                        color: Colors.grey[500],
                      ),
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

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 70,
      color: Colors.grey[200],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_DashboardItem> items,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalMargin = screenWidth < 360 ? 12.0 : 16.0;
    final cardPadding = screenWidth < 360 ? 14.0 : 18.0;

    // Group items into rows of 3 to guarantee a consistent 3-column grid
    // across all devices regardless of screen width, density, or font scaling.
    final List<List<_DashboardItem>> rows = [];
    for (int i = 0; i < items.length; i += 3) {
      final end = (i + 3 > items.length) ? items.length : i + 3;
      rows.add(items.sublist(i, end));
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9E9E9E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              for (int r = 0; r < rows.length; r++) ...[
                if (r > 0) const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int c = 0; c < 3; c++)
                      Expanded(
                        child: c < rows[r].length
                            ? _buildDashboardIcon(context, rows[r][c])
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardIcon(BuildContext context, _DashboardItem item) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 360;
    final iconBoxSize = isSmall ? 46.0 : 52.0;
    final iconSize = isSmall ? 22.0 : 26.0;
    final fontSize = isSmall ? 11.5 : 13.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EAF6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  item.icon,
                  color: _kPrimaryBlue,
                  size: iconSize,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = sl<AuthRepository>().currentUser;
    final userEmail = user?.email ?? 'user@example.com';
    final userInitial = userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U';

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 20,
              20,
              20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kPrimaryBlue, Color(0xFF5C6BC0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withAlpha(50),
                  child: Text(
                    userInitial,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'ISUN BEVERAGES LLP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Drawer Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerTile(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  isSelected: true,
                  onTap: () => Navigator.pop(context),
                ),
                if (_moduleVisibility['leads'] != false) ...[
                  _buildDrawerTile(
                    icon: Icons.monetization_on_outlined,
                    title: 'Leads (CRM)',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/leads');
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.person_add_outlined,
                    title: 'Add Lead',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/leads/add');
                    },
                  ),
                ],
                if (_moduleVisibility['customers'] != false)
                  _buildDrawerTile(
                    icon: Icons.person_pin_outlined,
                    title: 'Customers',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/customers');
                    },
                  ),
                if (_moduleVisibility['sales'] != false)
                  _buildDrawerTile(
                    icon: Icons.attach_money_outlined,
                    title: 'Sales',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/sales');
                    },
                  ),
                _buildDrawerTile(
                  icon: Icons.people_outline,
                  title: 'My Team',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerTile(
                  icon: Icons.location_on_outlined,
                  title: 'Visits',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerTile(
                  icon: Icons.calendar_today_outlined,
                  title: 'Attendance',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerTile(
                  icon: Icons.tune_outlined,
                  title: 'Customize Modules',
                  onTap: () {
                    Navigator.pop(context);
                    _showCustomizeModulesBottomSheet();
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Divider(color: Color(0xFFEEEEEE), height: 1),
                ),
                if (user?.isGoogleAuth != true)
                  _buildDrawerTile(
                    icon: Icons.lock_reset_outlined,
                    title: 'Change Password',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/change-password');
                    },
                  ),
              ],
            ),
          ),

          // Logout Action at bottom
          const Divider(color: Color(0xFFEEEEEE), height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              tileColor: const Color(0xFFFFEBEE),
              leading: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFD32F2F),
              ),
              title: const Text(
                'Log Out',
                style: TextStyle(
                  color: Color(0xFFD32F2F),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? _kPrimaryBlue.withAlpha(25) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isSelected ? _kPrimaryBlue : const Color(0xFF616161),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? _kPrimaryBlue : const Color(0xFF212121),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFD32F2F)),
              SizedBox(width: 10),
              Text(
                'Log Out',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out of your workspace?',
            style: TextStyle(fontSize: 14, color: Color(0xFF616161)),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  context.read<AuthBloc>().add(AuthSignOutRequested());
                } catch (_) {
                  await sl<AuthRepository>().signOut();
                }
                if (context.mounted) {
                  context.go('/login');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logged out successfully'),
                      backgroundColor: AppColors.secondary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _DashboardItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
