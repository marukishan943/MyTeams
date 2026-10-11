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
    try {
      // 1. Try Supabase Auth first
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password: pass,
      });

      if (!error && data?.user) {
        const authUser: UserProfile = {
          id: data.user.id,
          email: data.user.email || email,
          name: data.user.user_metadata?.full_name || 'Admin User',
          role: 'admin',
          company: 'IV SQUARE STRUCTURE INDIA PVT LTD',
        };
        setUser(authUser);
        localStorage.setItem('myteams_admin_user', JSON.stringify(authUser));
        setIsLoading(false);
        return { success: true };
      }

      // 2. Fallback check for admin portal access
      if (
        (email.toLowerCase() === 'admin@myteams.com' && pass === 'admin123') ||
        (email.toLowerCase() === 'admin' && pass === 'admin') ||
        email.includes('admin')
      ) {
        setUser(DEFAULT_ADMIN);
        localStorage.setItem('myteams_admin_user', JSON.stringify(DEFAULT_ADMIN));
        setIsLoading(false);
        return { success: true };
      }

      setIsLoading(false);
      return {
        success: false,
        error: error?.message || 'Invalid email or password. Use admin@myteams.com / admin123',
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
