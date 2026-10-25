import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized role-based access control and permissions service for MyTeams.
/// Controls what Admins, Managers, and Staff can view, add, edit, and delete.
class RolePermissionService extends ChangeNotifier {
  RolePermissionService._();
  static final RolePermissionService instance = RolePermissionService._();

  String _currentRole = 'Staff';
  Map<String, dynamic> _permissions = {};
  bool _isInitialized = false;

  String get currentRole => _currentRole;
  Map<String, dynamic> get permissions => Map.unmodifiable(_permissions);
  bool get isInitialized => _isInitialized;

  bool get isAdmin => _currentRole.toLowerCase() == 'admin';
  bool get isManager => _currentRole.toLowerCase() == 'manager';
  bool get isStaff => _currentRole.toLowerCase() == 'staff';

  // ─── Default Fallback Permissions ──────────────────────────────────
  static final Map<String, dynamic> defaultAdminPermissions = {
    'location_tracking': false,
    'visits': false,
    'tasks': true,
    'leads': {'enabled': true, 'add': true, 'edit': true, 'delete': true, 'reports': true},
    'customers': {'enabled': true, 'add': true, 'edit': true, 'delete': true},
    'quotations': true,
    'proforma_invoices': {'enabled': true, 'add': true, 'edit': true, 'delete': true},
    'invoices': {'enabled': true, 'add': true, 'edit': true, 'delete': true, 'reports': true},
    'orders': true,
    'inventory': {'enabled': true, 'add': true},
    'payments': true,
    'attendance': false,
    'leaves': true,
    'expenses': {'enabled': true, 'add': true, 'edit': true, 'decision': true, 'delete': true, 'reports': true},
    'forms': true,
    'pms': false,
    'payroll': false,
    'users': {'enabled': true, 'add': true, 'edit': true, 'delete': true},
  };

  static final Map<String, dynamic> defaultManagerPermissions = {
    'location_tracking': false,
    'visits': false,
    'tasks': true,
    'leads': {'enabled': true, 'add': true, 'edit': true, 'delete': false, 'reports': true},
    'customers': {'enabled': true, 'add': true, 'edit': true, 'delete': false},
    'quotations': true,
    'proforma_invoices': {'enabled': true, 'add': true, 'edit': true, 'delete': false},
    'invoices': {'enabled': true, 'add': true, 'edit': true, 'delete': false, 'reports': true},
    'orders': true,
    'inventory': {'enabled': true, 'add': false},
    'payments': false,
    'attendance': false,
    'leaves': false,
    'expenses': {'enabled': true, 'add': true, 'edit': true, 'decision': true, 'delete': false, 'reports': true},
    'forms': false,
    'pms': false,
    'payroll': false,
    'users': {'enabled': false, 'add': false, 'edit': false, 'delete': false},
  };

  static final Map<String, dynamic> defaultStaffPermissions = {
    'location_tracking': true,
    'visits': true,
    'tasks': true,
    'leads': {'enabled': true, 'add': true, 'edit': true, 'delete': false, 'reports': false},
    'customers': {'enabled': true, 'add': true, 'edit': false, 'delete': false},
    'quotations': true,
    'proforma_invoices': {'enabled': true, 'add': true, 'edit': false, 'delete': false},
    'invoices': {'enabled': false, 'add': false, 'edit': false, 'delete': false, 'reports': false},
    'orders': true,
    'inventory': {'enabled': true, 'add': false},
    'payments': false,
    'attendance': true,
    'leaves': true,
    'expenses': {'enabled': true, 'add': true, 'edit': false, 'decision': false, 'delete': false, 'reports': false},
    'forms': true,
    'pms': false,
    'payroll': false,
    'users': {'enabled': false, 'add': false, 'edit': false, 'delete': false},
  };

  // ─── Cloud Sync ───────────────────────────────────────────────────
  Future<void> syncPermissions() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      final email = user?.email ?? '';

      String roleName = 'Staff';
      Map<String, dynamic>? customUserPerms;

      // 1. Match current user in team_users
      if (email.isNotEmpty) {
        try {
          final teamRes = await client
              .from('team_users')
              .select('role, permissions')
              .eq('email', email)
              .maybeSingle();

          if (teamRes != null) {
            if (teamRes['role'] != null) {
              roleName = teamRes['role'].toString();
            }
            if (teamRes['permissions'] is Map && (teamRes['permissions'] as Map).isNotEmpty) {
              customUserPerms = Map<String, dynamic>.from(teamRes['permissions'] as Map);
            }
          } else if (email.toLowerCase().contains('admin')) {
            roleName = 'Admin';
          }
        } catch (_) {}
      }

      _currentRole = roleName;

      // If user has specific overrides, apply them
      if (customUserPerms != null && customUserPerms.isNotEmpty) {
        _permissions = customUserPerms;
        _isInitialized = true;
        notifyListeners();
        return;
      }

      // 2. Fetch role permissions from Supabase 'roles' table
      try {
        final roleRes = await client
            .from('roles')
            .select('permissions')
            .ilike('name', roleName)
            .maybeSingle();

        if (roleRes != null && roleRes['permissions'] is Map) {
          _permissions = Map<String, dynamic>.from(roleRes['permissions'] as Map);
          _isInitialized = true;
          notifyListeners();
          return;
        }
      } catch (_) {}

      // 3. Fallback to SYS_CONFIG customer record
      try {
        final sysRes = await client
            .from('customers')
            .select('company')
            .eq('customer_number', 'SYS_CONFIG')
            .maybeSingle();

        if (sysRes != null && sysRes['company'] != null) {
          final parsed = jsonDecode(sysRes['company'] as String);
          if (parsed is Map && parsed['roles'] is List) {
            final rolesList = parsed['roles'] as List;
            final matched = rolesList.firstWhere(
              (r) => r is Map && r['name'].toString().toLowerCase() == roleName.toLowerCase(),
              orElse: () => null,
            );
            if (matched != null && matched['permissions'] is Map) {
              _permissions = Map<String, dynamic>.from(matched['permissions'] as Map);
              _isInitialized = true;
              notifyListeners();
              return;
            }
          }
        }
      } catch (_) {}

      // 4. Fallback defaults by role
      if (roleName.toLowerCase() == 'admin') {
        _permissions = Map<String, dynamic>.from(defaultAdminPermissions);
      } else if (roleName.toLowerCase() == 'manager') {
        _permissions = Map<String, dynamic>.from(defaultManagerPermissions);
      } else {
        _permissions = Map<String, dynamic>.from(defaultStaffPermissions);
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing role permissions: $e');
    }
  }

  // ─── Granular Permission Checks ───────────────────────────────────

  /// Checks if a module is enabled for the current role
  bool canViewModule(String module) {
    if (isAdmin) return true;
    final mod = _permissions[module];
    if (mod is bool) return mod;
    if (mod is Map) return mod['enabled'] != false;
    return true;
  }

  /// Checks if the current role can add records in [module]
  bool canAdd(String module) {
    if (isAdmin) return true;
    final mod = _permissions[module];
    if (mod is Map) return mod['add'] == true;
    return false;
  }

  /// Checks if the current role can edit records in [module]
  bool canEdit(String module) {
    if (isAdmin) return true;
    final mod = _permissions[module];
    if (mod is Map) return mod['edit'] == true;
    return false;
  }

  /// Checks if the current role can delete records in [module]
  bool canDelete(String module) {
    if (isAdmin) return true;
    final mod = _permissions[module];
    if (mod is Map) return mod['delete'] == true;
    return false;
  }

  /// Checks if the current role can view reports / export in [module]
  bool canReport(String module) {
    if (isAdmin) return true;
    final mod = _permissions[module];
    if (mod is Map) return mod['reports'] == true;
    return false;
  }

  /// Checks if the current role has decision power (e.g. Approve/Reject expenses)
  bool canDecide(String module) {
    if (isAdmin) return true;
    final mod = _permissions[module];
    if (mod is Map) return mod['decision'] == true;
    return false;
  }

  // ─── High-Level Convenience Getters ──────────────────────────────
  bool get canAddLead => canAdd('leads');
  bool get canEditLead => canEdit('leads');
  bool get canDeleteLead => canDelete('leads');
  bool get canReportLead => canReport('leads');

  bool get canAddCustomer => canAdd('customers');
  bool get canEditCustomer => canEdit('customers');
  bool get canDeleteCustomer => canDelete('customers');

  bool get canAddSales =>
      isAdmin ||
      canAdd('proforma_invoices') ||
      canAdd('invoices') ||
      _permissions['orders'] == true;

  bool get canAddExpense => canAdd('expenses');
  bool get canDecideExpense => canDecide('expenses');
  bool get canDeleteExpense => canDelete('expenses');
}
