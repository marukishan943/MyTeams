import React, { createContext, useContext, useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import type { UserProfile } from '../types/crm';

interface AuthContextType {
  user: UserProfile | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, pass: string) => Promise<{ success: boolean; error?: string }>;
  logout: () => Promise<void>;
}

const DEFAULT_ADMIN: UserProfile = {
  id: 'admin-super-01',
  email: 'admin@myteams.com',
  name: 'ADMIN ADMIN',
  role: 'admin',
  company: 'IV SQUARE STRUCTURE INDIA PVT LTD',
};

const AuthContext = createContext<AuthContextType>({
  user: null,
  isAuthenticated: false,
  isLoading: true,
  login: async () => ({ success: false }),
  logout: async () => {},
});

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<UserProfile | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    // Check saved session in localStorage
    const savedUser = localStorage.getItem('myteams_admin_user');
    if (savedUser) {
      try {
        setUser(JSON.parse(savedUser));
      } catch (e) {
        console.error('Failed to parse saved user', e);
      }
    }
    setIsLoading(false);
  }, []);

  const login = async (email: string, pass: string) => {
    setIsLoading(true);
    const cleanEmail = email.trim().toLowerCase();
    const cleanPass = pass.trim();

    if (!cleanEmail || !cleanPass) {
      setIsLoading(false);
      return { success: false, error: 'Please enter both email and password.' };
    }

    try {
      // 1. Try Supabase Auth first
      const { data, error } = await supabase.auth.signInWithPassword({
        email: cleanEmail,
        password: cleanPass,
      });

      if (!error && data?.user) {
        const authUser: UserProfile = {
          id: data.user.id,
          email: data.user.email || cleanEmail,
          name: data.user.user_metadata?.full_name || 'Admin User',
          role: 'admin',
          company: 'IV SQUARE STRUCTURE INDIA PVT LTD',
        };
        setUser(authUser);
        localStorage.setItem('myteams_admin_user', JSON.stringify(authUser));
        setIsLoading(false);
        return { success: true };
      }

      // 2. Strict check for pre-configured Admin credentials
      // ONLY allow authorized admin emails with the exact correct password 'admin123'
      const authorizedAdminEmails = [
        'admin@myteams.com',
        'ivsquarestructure@gmail.com',
        'admin',
      ];

      if (authorizedAdminEmails.includes(cleanEmail) && cleanPass === 'admin123') {
        const adminUser: UserProfile = {
          ...DEFAULT_ADMIN,
          email: cleanEmail === 'admin' ? 'admin@myteams.com' : cleanEmail,
        };
        setUser(adminUser);
        localStorage.setItem('myteams_admin_user', JSON.stringify(adminUser));
        setIsLoading(false);
        return { success: true };
      }

      // If credentials do not match, REJECT with error
      setIsLoading(false);
      return {
        success: false,
        error: 'Invalid email or password. Please enter correct credentials.',
      };
    } catch (err: unknown) {
      setIsLoading(false);
      const message = err instanceof Error ? err.message : 'Login failed';
      return { success: false, error: message };
    }
  };

  const logout = async () => {
    await supabase.auth.signOut();
    localStorage.removeItem('myteams_admin_user');
    setUser(null);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        isAuthenticated: !!user,
        isLoading,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
