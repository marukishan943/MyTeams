import { supabase, SUPABASE_URL, SUPABASE_ANON_KEY } from '../lib/supabase';
import type { TeamUser } from '../types/crm';

const INITIAL_USERS: TeamUser[] = [
  {
    id: 'u-001',
    user_code: '001',
    first_name: 'ADMIN',
    last_name: 'ADMIN',
    mobile: '9999999999',
    email: 'ivsquarestructure@gmail.com',
    role: 'Admin',
    reporting_head: '-',
    location_tracking: false,
    is_active: true,
    created_at: '2026-09-01T00:00:00Z',
    last_login: 'Today, 02:40 PM',
    device_info: 'Web Portal (Chrome Windows)',
    last_location: {
      lat: 22.3039,
      lng: 70.8022,
      address: 'Head Office, Gondal Road, Rajkot, Gujarat',
      updated_at: '15 mins ago',
    },
    permissions: {
      leads_view: 'all',
      leads_create: true,
      leads_edit: true,
      leads_delete: true,
      leads_export: true,
      customers_view: 'all',
      customers_create: true,
      customers_edit: true,
      customers_export: true,
      sales_pfi: true,
      sales_invoice: true,
      sales_payment: true,
      sales_export: true,
      visits_tracking: true,
      visits_routes: true,
    },
  },
  {
    id: 'u-002',
    user_code: '002',
    first_name: 'JITESHBHAI',
    last_name: 'VASANIYA',
    mobile: '9723793492',
    email: 'jitesh.ivsquare@isun.com',
    role: 'Manager',
    reporting_head: 'ADMIN ADMIN',
    location_tracking: true,
    is_active: true,
    created_at: '2026-09-02T00:00:00Z',
    last_login: 'Today, 01:15 PM',
    device_info: 'Android 14 (MyTeams v2.4)',
    last_location: {
      lat: 22.2882,
      lng: 70.7818,
      address: 'Yagnik Road, Rajkot, Gujarat 360001',
      updated_at: '35 mins ago',
    },
    permissions: {
      leads_view: 'all',
      leads_create: true,
      leads_edit: true,
      leads_delete: false,
      leads_export: true,
      customers_view: 'all',
      customers_create: true,
      customers_edit: true,
      customers_export: true,
      sales_pfi: true,
      sales_invoice: true,
      sales_payment: true,
      sales_export: true,
      visits_tracking: true,
      visits_routes: true,
    },
  },
  {
    id: 'u-003',
    user_code: '003',
    first_name: 'Kishan',
    last_name: 'Maru',
    mobile: '9876543210',
    email: 'marukishan943@gmail.com',
    role: 'Staff',
    reporting_head: 'JITESHBHAI VASANIYA',
    location_tracking: true,
    is_active: true,
    created_at: '2026-09-05T00:00:00Z',
    last_login: 'Today, 11:20 AM',
    device_info: 'Android 13 (MyTeams v2.4)',
    last_location: {
      lat: 22.3315,
      lng: 70.8124,
      address: 'Kuvadva GIDC Industrial Area, Rajkot',
      updated_at: '1 hour ago',
    },
    permissions: {
      leads_view: 'own',
      leads_create: true,
      leads_edit: true,
      leads_delete: false,
      leads_export: false,
      customers_view: 'own',
      customers_create: true,
      customers_edit: true,
      customers_export: false,
      sales_pfi: true,
      sales_invoice: false,
      sales_payment: true,
      sales_export: false,
      visits_tracking: true,
      visits_routes: false,
    },
  },
  {
    id: 'u-004',
    user_code: '004',
    first_name: 'Mehul',
    last_name: 'Ajagya',
    mobile: '9876543211',
    email: 'mehul.ivsquare@gmail.com',
    role: 'Staff',
    reporting_head: 'ADMIN ADMIN',
    location_tracking: true,
    is_active: true,
    created_at: '2026-09-10T00:00:00Z',
    last_login: 'Yesterday, 06:45 PM',
    device_info: 'Android 14 (MyTeams v2.4)',
    last_location: {
      lat: 22.2598,
      lng: 70.8037,
      address: 'Shapar-Veraval Industrial Zone, Rajkot',
      updated_at: 'Yesterday',
    },
    permissions: {
      leads_view: 'own',
      leads_create: true,
      leads_edit: true,
      leads_delete: false,
      leads_export: false,
      customers_view: 'own',
      customers_create: true,
      customers_edit: true,
      customers_export: false,
      sales_pfi: true,
      sales_invoice: false,
      sales_payment: true,
      sales_export: false,
      visits_tracking: true,
      visits_routes: false,
    },
  },
  {
    id: 'u-005',
    user_code: '005',
    first_name: 'Sachin',
    last_name: 'Chauhan',
    mobile: '8141926565',
    email: 'sachin.ivsquare@gmail.com',
    role: 'Staff',
    reporting_head: 'ADMIN ADMIN',
    location_tracking: true,
    is_active: true,
    created_at: '2026-09-15T00:00:00Z',
    last_login: 'Today, 09:30 AM',
    device_info: 'iOS 18.1 (MyTeams v2.4)',
    last_location: {
      lat: 22.3082,
      lng: 70.7677,
      address: '150 Feet Ring Road, Near Big Bazaar, Rajkot',
      updated_at: '4 hours ago',
    },
    permissions: {
      leads_view: 'own',
      leads_create: true,
      leads_edit: true,
      leads_delete: false,
      leads_export: false,
      customers_view: 'own',
      customers_create: true,
      customers_edit: true,
      customers_export: false,
      sales_pfi: true,
      sales_invoice: false,
      sales_payment: true,
      sales_export: false,
      visits_tracking: true,
      visits_routes: false,
    },
  },
];

export const usersService = {
  async syncAuthCredentials(email: string, password: string, fullName?: string): Promise<void> {
    const cleanEmail = email.trim().toLowerCase();
    const cleanPassword = password.trim();
    if (!cleanEmail || !cleanPassword) return;

    // 1. Try Supabase RPC 'admin_set_user_password' (works for both new and existing users)
    try {
      const { data, error } = await supabase.rpc('admin_set_user_password', {
        target_email: cleanEmail,
        new_password: cleanPassword,
      });
      if (!error && data?.success) {
        console.log('User password synced via RPC successfully:', data);
        return;
      }
    } catch (e) {
      console.warn('RPC admin_set_user_password attempt:', e);
    }

    // 2. Also attempt signup via Supabase REST API (with isolated headers so admin session is never affected)
    try {
      const res = await fetch(`${SUPABASE_URL}/auth/v1/signup`, {
        method: 'POST',
        headers: {
          apikey: SUPABASE_ANON_KEY,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: cleanEmail,
          password: cleanPassword,
          data: {
            full_name: fullName || 'Team Member',
          },
        }),
      });
      if (res.ok) {
        console.log('User registered in Supabase Auth via signup');
      } else {
        const errJson = await res.json().catch(() => ({}));
        console.log('Auth signup status:', res.status, errJson);
      }
    } catch (e) {
      console.warn('Direct auth signup attempt:', e);
    }
  },


  async fetchUsers(): Promise<TeamUser[]> {
    try {
      const { data, error } = await supabase
        .from('team_users')
        .select('*')
        .order('user_code', { ascending: true });

      if (error || !data || data.length === 0) {
        const local = localStorage.getItem('myteams_users');
        return local ? JSON.parse(local) : INITIAL_USERS;
      }
      return data;
    } catch {
      const local = localStorage.getItem('myteams_users');
      return local ? JSON.parse(local) : INITIAL_USERS;
    }
  },

  async createUser(user: Partial<TeamUser>): Promise<TeamUser> {
    const code = Math.floor(100 + Math.random() * 900).toString();
    const newUser: TeamUser = {
      id: `u-${Date.now()}`,
      user_code: code,
      first_name: user.first_name || '',
      last_name: user.last_name || '',
      mobile: user.mobile || '',
      email: user.email || '',
      role: user.role || 'Staff',
      reporting_head: user.reporting_head || 'ADMIN ADMIN',
      location_tracking: user.location_tracking ?? true,
      is_active: true,
      password: user.password || '',
      permissions: user.permissions,
      created_at: new Date().toISOString(),
    };

    // 1. Sync credentials to Supabase Auth so mobile app login works immediately
    if (newUser.email && newUser.password) {
      await this.syncAuthCredentials(
        newUser.email,
        newUser.password,
        `${newUser.first_name} ${newUser.last_name}`.trim()
      );
    }

    // 2. Persist in team_users table (with safe fallback if password column does not exist yet)
    try {
      const { error } = await supabase.from('team_users').insert([newUser]);
      if (error && error.message?.includes('password')) {
        // Retry without password column
        const { password: _, ...withoutPassword } = newUser;
        await supabase.from('team_users').insert([withoutPassword]);
      }
    } catch (e) {
      console.warn('team_users insert error:', e);
    }

    const current = await this.fetchUsers();
    const updated = [...current, newUser];
    localStorage.setItem('myteams_users', JSON.stringify(updated));
    return newUser;
  },

  async toggleTracking(id: string): Promise<void> {
    const current = await this.fetchUsers();
    const updated = current.map((u) =>
      u.id === id ? { ...u, location_tracking: !u.location_tracking } : u
    );
    localStorage.setItem('myteams_users', JSON.stringify(updated));
    try {
      const u = updated.find((x) => x.id === id);
      if (u) {
        await supabase
          .from('team_users')
          .update({ location_tracking: u.location_tracking })
          .eq('id', id);
      }
    } catch (e) {
      console.warn(e);
    }
  },

  async toggleActive(id: string): Promise<void> {
    const current = await this.fetchUsers();
    const updated = current.map((u) =>
      u.id === id ? { ...u, is_active: !u.is_active } : u
    );
    localStorage.setItem('myteams_users', JSON.stringify(updated));
    try {
      const u = updated.find((x) => x.id === id);
      if (u) {
        await supabase
          .from('team_users')
          .update({ is_active: u.is_active })
          .eq('id', id);
      }
    } catch (e) {
      console.warn(e);
    }
  },

  async updateUser(id: string, updates: Partial<TeamUser>): Promise<TeamUser> {
    const current = await this.fetchUsers();
    let updatedUser: TeamUser | null = null;
    const updated = current.map((u) => {
      if (u.id === id) {
        updatedUser = { ...u, ...updates };
        return updatedUser;
      }
      return u;
    });

    localStorage.setItem('myteams_users', JSON.stringify(updated));

    // 1. If password was updated, sync to Supabase Auth for mobile login
    if (updates.password && updatedUser) {
      const targetEmail = updates.email || (updatedUser as TeamUser).email;
      await this.syncAuthCredentials(
        targetEmail,
        updates.password,
        `${(updatedUser as TeamUser).first_name} ${(updatedUser as TeamUser).last_name}`.trim()
      );
    }

    try {
      if (updatedUser) {
        const u = updatedUser as TeamUser;
        const updatePayload: any = {
          first_name: u.first_name,
          last_name: u.last_name,
          mobile: u.mobile,
          email: u.email,
          role: u.role,
          reporting_head: u.reporting_head,
          location_tracking: u.location_tracking,
          is_active: u.is_active,
          permissions: u.permissions,
        };
        if (updates.password) {
          updatePayload.password = updates.password;
        }

        const { error } = await supabase.from('team_users').update(updatePayload).eq('id', id);
        if (error && error.message?.includes('password')) {
          delete updatePayload.password;
          await supabase.from('team_users').update(updatePayload).eq('id', id);
        }
      }
    } catch (e) {
      console.warn('Supabase updateUser error:', e);
    }

    return updatedUser || current.find((u) => u.id === id)!;
  },

  async deleteUser(id: string): Promise<void> {
    const current = await this.fetchUsers();
    const updated = current.filter((u) => u.id !== id);
    localStorage.setItem('myteams_users', JSON.stringify(updated));

    try {
      await supabase.from('team_users').delete().eq('id', id);
    } catch (e) {
      console.warn('Supabase deleteUser error:', e);
    }
  },
};
