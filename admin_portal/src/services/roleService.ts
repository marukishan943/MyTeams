import { supabase } from '../lib/supabase';
import type { AppRole, ModuleVisibilityConfig, RolePermissions } from '../types/crm';

export const DEFAULT_ROLE_PERMISSIONS: Record<string, RolePermissions> = {
  admin: {
    location_tracking: false,
    visits: false,
    tasks: true,
    leads: { enabled: true, add: true, edit: true, delete: true, reports: true },
    customers: { enabled: true, add: true, edit: true, delete: true },
    quotations: true,
    proforma_invoices: { enabled: true, add: true, edit: true, delete: true },
    invoices: { enabled: true, add: true, edit: true, delete: true, reports: true },
    orders: true,
    inventory: { enabled: true, add: true },
    payments: true,
    attendance: false,
    leaves: true,
    expenses: { enabled: true, add: true, edit: true, decision: true, delete: true, reports: true },
    forms: true,
    pms: false,
    payroll: false,
    users: { enabled: true, add: true, edit: true, delete: true },
  },
  manager: {
    location_tracking: false,
    visits: false,
    tasks: true,
    leads: { enabled: true, add: true, edit: true, delete: false, reports: true },
    customers: { enabled: true, add: true, edit: true, delete: false },
    quotations: true,
    proforma_invoices: { enabled: true, add: true, edit: true, delete: false },
    invoices: { enabled: true, add: true, edit: true, delete: false, reports: true },
    orders: true,
    inventory: { enabled: true, add: false },
    payments: false,
    attendance: false,
    leaves: false,
    expenses: { enabled: true, add: true, edit: true, decision: true, delete: false, reports: true },
    forms: false,
    pms: false,
    payroll: false,
    users: { enabled: false, add: false, edit: false, delete: false },
  },
  staff: {
    location_tracking: true,
    visits: true,
    tasks: true,
    leads: { enabled: true, add: true, edit: true, delete: false, reports: false },
    customers: { enabled: true, add: true, edit: false, delete: false },
    quotations: true,
    proforma_invoices: { enabled: true, add: true, edit: false, delete: false },
    invoices: { enabled: false, add: false, edit: false, delete: false, reports: false },
    orders: true,
    inventory: { enabled: true, add: false },
    payments: false,
    attendance: true,
    leaves: true,
    expenses: { enabled: true, add: true, edit: false, decision: false, delete: false, reports: false },
    forms: true,
    pms: false,
    payroll: false,
    users: { enabled: false, add: false, edit: false, delete: false },
  },
};

export const DEFAULT_ROLES: AppRole[] = [
  {
    id: 'role-admin',
    name: 'Admin',
    access: 'Admin',
    users_count: 1,
    permissions: DEFAULT_ROLE_PERMISSIONS.admin,
    is_system: true,
  },
  {
    id: 'role-manager',
    name: 'Manager',
    access: 'Manager',
    users_count: 1,
    permissions: DEFAULT_ROLE_PERMISSIONS.manager,
    is_system: true,
  },
  {
    id: 'role-staff',
    name: 'Staff',
    access: 'Staff',
    users_count: 3,
    permissions: DEFAULT_ROLE_PERMISSIONS.staff,
    is_system: true,
  },
];

export const roleService = {
  async fetchRoles(): Promise<AppRole[]> {
    const local = localStorage.getItem('myteams_roles_config');
    let roles: AppRole[] = local ? JSON.parse(local) : DEFAULT_ROLES;

    // 1. Try Supabase 'roles' table
    try {
      const { data, error } = await supabase
        .from('roles')
        .select('*')
        .order('name');

      if (!error && data && data.length > 0) {
        roles = data.map((r: any) => ({
          id: r.id,
          name: r.name,
          access: r.access || r.name,
          users_count: r.users_count || 0,
          permissions: r.permissions || DEFAULT_ROLE_PERMISSIONS[r.name.toLowerCase()] || DEFAULT_ROLE_PERMISSIONS.staff,
          is_system: r.is_system ?? (['Admin', 'Manager', 'Staff'].includes(r.name)),
        }));
        localStorage.setItem('myteams_roles_config', JSON.stringify(roles));
        return roles;
      }
    } catch (_) {
      // ignore
    }

    // 2. Try SYS_CONFIG record in customers
    try {
      const { data } = await supabase
        .from('customers')
        .select('company')
        .eq('customer_number', 'SYS_CONFIG')
        .maybeSingle();

      if (data?.company) {
        const parsed = JSON.parse(data.company);
        if (parsed?.roles && Array.isArray(parsed.roles) && parsed.roles.length > 0) {
          roles = parsed.roles;
          localStorage.setItem('myteams_roles_config', JSON.stringify(roles));
          return roles;
        }
      }
    } catch (_) {
      // ignore
    }

    localStorage.setItem('myteams_roles_config', JSON.stringify(roles));
    return roles;
  },

  async saveRoles(roles: AppRole[]): Promise<boolean> {
    try {
      localStorage.setItem('myteams_roles_config', JSON.stringify(roles));

      // Try upsert to 'roles' table in Supabase
      try {
        const rows = roles.map((r) => ({
          id: r.id.startsWith('role-') ? undefined : r.id,
          name: r.name,
          access: r.access,
          users_count: r.users_count,
          permissions: r.permissions,
          is_system: r.is_system,
          updated_at: new Date().toISOString(),
        }));
        await supabase.from('roles').upsert(rows, { onConflict: 'name' });
      } catch (_) {
        // ignore
      }

      // Sync to SYS_CONFIG
      try {
        const { data } = await supabase
          .from('customers')
          .select('id, company')
          .eq('customer_number', 'SYS_CONFIG')
          .maybeSingle();

        if (data) {
          let conf: any = {};
          try {
            conf = JSON.parse(data.company || '{}');
          } catch (_) {
            conf = {};
          }
          conf.roles = roles;
          conf.updated_at = new Date().toISOString();

          await supabase
            .from('customers')
            .update({ company: JSON.stringify(conf) })
            .eq('id', data.id);
        }
      } catch (_) {
        // ignore
      }

      return true;
    } catch (e) {
      console.error('Failed to save roles:', e);
      return false;
    }
  },

  /**
   * Maps a role's permissions to module-level visibility.
   * IMPORTANT: Only drives Leads/Customers/Sales/Expenses visibility.
   * Reports and Settings are ALWAYS admin-controlled separately —
   * they are NEVER automatically toggled when role permissions change.
   */
  mapRoleToModuleVisibility(role: AppRole): Partial<ModuleVisibilityConfig> {
    const p = role.permissions;

    const hasSales =
      p.quotations ||
      (p.proforma_invoices && p.proforma_invoices.enabled) ||
      (p.invoices && p.invoices.enabled) ||
      p.orders ||
      (p.inventory && p.inventory.enabled) ||
      p.payments;

    return {
      leads: p.leads ? p.leads.enabled : true,
      customers: p.customers ? p.customers.enabled : true,
      sales: !!hasSales,
      expenses: p.expenses ? p.expenses.enabled : true,
      // reports and settings intentionally omitted — never auto-changed
    };
  },
};
