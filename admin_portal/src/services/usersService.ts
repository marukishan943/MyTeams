import { supabase } from '../lib/supabase';
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
  },
];

export const usersService = {
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
      created_at: new Date().toISOString(),
    };

    try {
      await supabase.from('team_users').insert([newUser]);
    } catch (e) {
      console.warn(e);
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
};
