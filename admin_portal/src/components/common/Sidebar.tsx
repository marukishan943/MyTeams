import React from 'react';
import {
  LayoutDashboard,
  Target,
  Users,
  FileText,
  Receipt,
  BarChart3,
  Settings,
  LogOut,
  Building2,
  ChevronRight,
  SlidersHorizontal,
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import type { ModuleVisibilityConfig } from '../../types/crm';

interface SidebarProps {
  currentTab: string;
  setCurrentTab: (tab: string) => void;
  isOpen: boolean;
  onCloseMobile: () => void;
  counts: {
    leads: number;
    customers: number;
    sales: number;
    expenses: number;
  };
  moduleVisibility: ModuleVisibilityConfig;
  onOpenModuleVisibility: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  currentTab,
  setCurrentTab,
  isOpen,
  onCloseMobile,
  counts,
  moduleVisibility,
  onOpenModuleVisibility,
}) => {
  const { user, logout } = useAuth();

  const navItems = [
    {
      id: 'dashboard',
      label: 'Dashboard',
      icon: LayoutDashboard,
      badge: null,
    },
    {
      id: 'leads',
      label: 'Leads',
      icon: Target,
      badge: counts.leads,
    },
    {
      id: 'customers',
      label: 'Customers',
      icon: Users,
      badge: counts.customers,
    },
    {
      id: 'sales',
      label: 'Sales & Invoices',
      icon: FileText,
      badge: counts.sales,
    },
    {
      id: 'expenses',
      label: 'Expenses',
      icon: Receipt,
      badge: counts.expenses,
    },
    {
      id: 'reports',
      label: 'Reports & DSR',
      icon: BarChart3,
      badge: null,
    },
    {
      id: 'settings',
      label: 'Settings',
      icon: Settings,
      badge: null,
    },
  ];

  const visibleNavItems = navItems.filter((item) => {
    if (item.id === 'dashboard') return true;
    return moduleVisibility[item.id as keyof ModuleVisibilityConfig] ?? true;
  });

  return (
    <>
      {/* Mobile backdrop */}
      {isOpen && (
        <div
          className="fixed inset-0 bg-black/50 z-40 lg:hidden"
          onClick={onCloseMobile}
        />
      )}

      <aside
        className={`fixed top-0 bottom-0 left-0 z-40 w-64 bg-[#1e2837] text-gray-300 flex flex-col transition-transform duration-200 ease-in-out lg:translate-x-0 ${
          isOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        {/* Brand Header */}
        <div className="h-16 flex items-center px-6 bg-[#18202c] border-b border-gray-800/80">
          <div className="flex items-center space-x-3">
            <div className="w-9 h-9 rounded-lg bg-[#3949ab] flex items-center justify-center text-white font-bold text-lg shadow-sm">
              MT
            </div>
            <div>
              <span className="font-bold text-white text-lg tracking-wide">
                MY TEAMS
              </span>
              <span className="block text-[10px] text-gray-400 uppercase tracking-widest font-semibold">
                Admin Portal
              </span>
            </div>
          </div>
        </div>

        {/* User Profile Card (MyTeams Style) */}
        <div className="p-4 mx-3 my-3 rounded-lg bg-[#263346]/60 border border-gray-700/40">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-full bg-[#3949ab] text-white flex items-center justify-center font-bold text-sm shrink-0 shadow-xs">
              AA
            </div>
            <div className="min-w-0 flex-1">
              <p className="text-sm font-semibold text-white truncate">
                {user?.name || 'ADMIN ADMIN'}
              </p>
              <p className="text-xs text-gray-400 truncate flex items-center gap-1 mt-0.5">
                <Building2 className="w-3 h-3 shrink-0" />
                <span className="truncate">
                  {user?.company || 'IV SQUARE STRUCTURE INDIA PVT LTD'}
                </span>
              </p>
            </div>
          </div>
        </div>

        {/* Navigation Section */}
        <div className="px-3 py-2 flex-1 overflow-y-auto space-y-1">
          <div className="px-3 py-1.5 text-[11px] font-semibold text-gray-400 uppercase tracking-wider">
            Main Menu
          </div>
          {visibleNavItems.map((item) => {
            const Icon = item.icon;
            const isActive = currentTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => {
                  setCurrentTab(item.id);
                  onCloseMobile();
                }}
                className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-lg text-sm font-medium transition-colors cursor-pointer ${
                  isActive
                    ? 'bg-[#3949ab] text-white shadow-sm'
                    : 'text-gray-300 hover:bg-[#263346] hover:text-white'
                }`}
              >
                <div className="flex items-center space-x-3">
                  <Icon className={`w-4 h-4 ${isActive ? 'text-white' : 'text-gray-400'}`} />
                  <span>{item.label}</span>
                </div>
                {item.badge !== null && item.badge !== undefined && (
                  <span
                    className={`text-xs px-2 py-0.5 rounded-full font-semibold ${
                      isActive
                        ? 'bg-white/20 text-white'
                        : 'bg-gray-800 text-gray-300'
                    }`}
                  >
                    {item.badge}
                  </span>
                )}
              </button>
            );
          })}
        </div>

        {/* Module Customizer Quick Action */}
        <div className="p-3 border-t border-gray-800/80 bg-[#18202c]/60">
          <button
            onClick={() => {
              onOpenModuleVisibility();
              onCloseMobile();
            }}
            className="w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium text-gray-400 hover:text-white hover:bg-[#263346] transition-colors cursor-pointer"
          >
            <div className="flex items-center space-x-2.5">
              <SlidersHorizontal className="w-4 h-4 text-[#3949ab]" />
              <span>Hide / Show Modules</span>
            </div>
            <span className="text-[10px] px-1.5 py-0.2 rounded-full bg-[#3949ab]/20 text-indigo-300 font-bold">
              Config
            </span>
          </button>
        </div>

        {/* Footer Logout */}
        <div className="p-3 border-t border-gray-800/80 bg-[#18202c]">
          <button
            onClick={logout}
            className="w-full flex items-center justify-between px-3.5 py-2.5 rounded-lg text-sm font-medium text-gray-300 hover:bg-rose-500/10 hover:text-rose-400 transition-colors cursor-pointer"
          >
            <div className="flex items-center space-x-3">
              <LogOut className="w-4 h-4 text-gray-400" />
              <span>Sign Out</span>
            </div>
            <ChevronRight className="w-4 h-4 text-gray-500" />
          </button>
        </div>
      </aside>
    </>
  );
};
