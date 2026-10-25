import React from 'react';
import {
  Menu,
  Calendar,
  RotateCw,
  UserCheck,
  SlidersHorizontal,
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

interface NavbarProps {
  onToggleSidebar: () => void;
  currentTab: string;
  selectedStaff: string;
  setSelectedStaff: (staff: string) => void;
  staffList: string[];
  onRefresh: () => void;
  isRefreshing: boolean;
  onOpenModuleVisibility: () => void;
  visibleModulesCount: number;
  totalModulesCount: number;
}

export const Navbar: React.FC<NavbarProps> = ({
  onToggleSidebar,
  currentTab,
  selectedStaff,
  setSelectedStaff,
  staffList,
  onRefresh,
  isRefreshing,
  onOpenModuleVisibility,
  visibleModulesCount,
  totalModulesCount,
}) => {
  const { user } = useAuth();

  const formattedDate = new Intl.DateTimeFormat('en-GB', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  }).format(new Date());

  const getTabTitle = () => {
    switch (currentTab) {
      case 'dashboard':
        return 'Dashboard Overview';
      case 'leads':
        return 'Lead Management';
      case 'customers':
        return 'Customer Directory';
      case 'sales':
        return 'Sales & Invoices Management';
      case 'expenses':
        return 'Field Expenses Claims';
      case 'reports':
        return 'Reports & DSR Analytics';
      case 'settings':
        return 'Workspace Settings & Team Access';
      default:
        return 'MyTeams Administration';
    }
  };

  return (
    <header className="h-16 bg-white border-b border-gray-200 sticky top-0 z-30 flex items-center justify-between px-4 lg:px-8">
      {/* Left section: Hamburger & Title */}
      <div className="flex items-center space-x-3">
        <button
          onClick={onToggleSidebar}
          className="lg:hidden p-2 rounded-lg text-gray-600 hover:bg-gray-100 transition-colors"
          aria-label="Toggle Navigation"
        >
          <Menu className="w-5 h-5" />
        </button>
        <div>
          <h1 className="text-lg font-bold text-gray-800 leading-tight">
            {getTabTitle()}
          </h1>
          <p className="text-[11px] text-gray-400 hidden sm:block">
            Connected to Supabase Cloud • Live Sync
          </p>
        </div>
      </div>

      {/* Right section: Filters, Refresh, Date & Profile */}
      <div className="flex items-center space-x-2 sm:space-x-3">
        {/* Date Filter Badge (MyTeams format) */}
        <div className="hidden md:flex items-center space-x-1.5 px-3 py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-xs font-medium text-gray-700">
          <Calendar className="w-3.5 h-3.5 text-[#3949ab]" />
          <span>{formattedDate}</span>
        </div>

        {/* Staff Filter Dropdown (MyTeams top navbar feature) */}
        <div className="flex items-center space-x-1.5">
          <div className="relative">
            <select
              value={selectedStaff}
              onChange={(e) => setSelectedStaff(e.target.value)}
              className="text-xs font-medium bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-1.5 text-gray-700 hover:border-gray-300 focus:outline-hidden focus:ring-2 focus:ring-[#3949ab]/20 focus:border-[#3949ab]"
            >
              <option value="All">All Staff</option>
              {staffList.map((staff) => (
                <option key={staff} value={staff}>
                  {staff}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Module Customizer Button */}
        <button
          onClick={onOpenModuleVisibility}
          title="Show / Hide Modules & Dashboard Cards"
          className="inline-flex items-center space-x-1.5 px-2.5 py-1.5 rounded-lg border border-gray-200 bg-gray-50 hover:bg-gray-100 text-gray-700 text-xs font-semibold transition-colors cursor-pointer"
        >
          <SlidersHorizontal className="w-3.5 h-3.5 text-[#3949ab]" />
          <span className="hidden sm:inline">Modules</span>
          <span className="text-[10px] px-1.5 py-0.2 rounded-full bg-[#3949ab]/10 text-[#3949ab] font-bold">
            {visibleModulesCount}/{totalModulesCount}
          </span>
        </button>

        {/* Refresh Action */}
        <button
          onClick={onRefresh}
          disabled={isRefreshing}
          title="Refresh Data"
          className="p-2 rounded-lg text-gray-500 hover:text-[#3949ab] hover:bg-gray-100 transition-colors disabled:opacity-50"
        >
          <RotateCw
            className={`w-4 h-4 ${isRefreshing ? 'animate-spin text-[#3949ab]' : ''}`}
          />
        </button>

        {/* User initials & Role badge */}
        <div className="flex items-center space-x-2 pl-2 border-l border-gray-200">
          <div className="w-8 h-8 rounded-full bg-[#3949ab] text-white flex items-center justify-center font-bold text-xs shadow-xs">
            {user?.name?.slice(0, 2).toUpperCase() || 'AD'}
          </div>
          <div className="hidden xl:block text-left">
            <span className="block text-xs font-semibold text-gray-800 leading-none">
              {user?.name || 'Admin'}
            </span>
            <span className="text-[10px] text-emerald-600 font-medium inline-flex items-center gap-0.5 mt-0.5">
              <UserCheck className="w-2.5 h-2.5" />
              Admin
            </span>
          </div>
        </div>
      </div>
    </header>
  );
};
