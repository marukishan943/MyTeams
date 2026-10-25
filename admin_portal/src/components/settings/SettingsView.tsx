import React, { useState, useMemo, useRef, useEffect } from 'react';
import {
  Building2,
  Users,
  Settings as SettingsIcon,
  MessageSquare,
  Plus,
  CheckCircle,
  ToggleLeft,
  ToggleRight,
  Save,
  SlidersHorizontal,
  LayoutDashboard,
  Layers,
  RotateCcw,
  Loader2,
  Pencil,
  Trash2,
  X,
  Search,
  Download,
  ChevronLeft,
  ChevronRight,
  MapPin,
  ExternalLink,
  Shield,
  ShieldCheck,
  Phone,
  Mail,
  Smartphone,
  Clock,
  Lock,
} from 'lucide-react';
import * as XLSX from 'xlsx';
import type {
  TeamUser,
  UserModulePermissions,
  CompanyConfig,
  ModuleVisibilityConfig,
  DashboardCardsConfig,
} from '../../types/crm';

interface SettingsViewProps {
  users: TeamUser[];
  onAddUser: (user: Partial<TeamUser>) => Promise<void>;
  onUpdateUser?: (id: string, user: Partial<TeamUser>) => Promise<void>;
  onDeleteUser?: (id: string) => Promise<void>;
  onToggleTracking: (id: string) => void;
  onToggleActive: (id: string) => void;
  moduleVisibility?: ModuleVisibilityConfig;
  onToggleModule?: (key: keyof ModuleVisibilityConfig) => void;
  dashboardCards?: DashboardCardsConfig;
  onToggleCard?: (key: keyof DashboardCardsConfig) => void;
  onResetDefaults?: () => void;
  isSaving?: boolean;
}

const AVAILABLE_COLUMNS = [
  { key: 'user_code', label: 'User ID / Code' },
  { key: 'name', label: 'Member Name', locked: true },
  { key: 'mobile', label: 'Mobile Number' },
  { key: 'email', label: 'Email Address' },
  { key: 'role', label: 'Role & Hierarchy' },
  { key: 'reporting_head', label: 'Reporting Head' },
  { key: 'location_tracking', label: 'GPS Tracking' },
  { key: 'last_login', label: 'Last Login & Device' },
  { key: 'status', label: 'Status' },
  { key: 'actions', label: 'Actions' },
];

function getPageNumbers(currentPage: number, totalPages: number): (number | string)[] {
  if (totalPages <= 7) {
    return Array.from({ length: totalPages }, (_, i) => i + 1);
  }
  const pages: (number | string)[] = [];
  if (currentPage <= 4) {
    for (let i = 1; i <= 5; i++) pages.push(i);
    pages.push('...');
    pages.push(totalPages);
  } else if (currentPage >= totalPages - 3) {
    pages.push(1);
    pages.push('...');
    for (let i = totalPages - 4; i <= totalPages; i++) pages.push(i);
  } else {
    pages.push(1);
    pages.push('...');
    for (let i = currentPage - 1; i <= currentPage + 1; i++) pages.push(i);
    pages.push('...');
    pages.push(totalPages);
  }
  return pages;
}

function getDefaultPermissions(role: 'Admin' | 'Manager' | 'Staff'): UserModulePermissions {
  if (role === 'Admin') {
    return {
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
    };
  }
  if (role === 'Manager') {
    return {
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
    };
  }
  return {
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
  };
}

export const SettingsView: React.FC<SettingsViewProps> = ({
  users,
  onAddUser,
  onUpdateUser,
  onDeleteUser,
  onToggleTracking,
  onToggleActive,
  moduleVisibility,
  onToggleModule,
  dashboardCards,
  onToggleCard,
  onResetDefaults,
  isSaving = false,
}) => {
  const [activeTab, setActiveTab] = useState<
    'company' | 'users' | 'sales_settings' | 'templates' | 'modules'
  >('company');

  // Company Profile state
  const [company, setCompany] = useState<CompanyConfig>(() => {
    const saved = localStorage.getItem('myteams_company_config');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch {
        // ignore
      }
    }
    return {
      company_name: 'IV SQUARE STRUCTURE INDIA PVT LTD',
      brand_name: 'IV SQUARE STRUCTURE INDIA PVT LTD',
      phone: '9723793492',
      email: 'ivsquarestructure@gmail.com',
      website: 'https://ivsquarestructure.com/',
      gstin: '24AAFCI9953E1ZF',
      timezone: 'GMT+5:30',
      currency: 'INR',
      is_dsr_email: true,
      invoice_prefix: 'INV-',
      proforma_prefix: 'PFI-',
      order_prefix: 'ORD-',
      bank_name: 'State Bank of India',
      bank_account_no: '38920194819',
      bank_ifsc: 'SBIN0001234',
      upi_id: 'ivsquare@sbi',
      terms: '1. Goods once sold will not be taken back.\n2. Interest @ 18% p.a. after due date.\n3. Subject to Rajkot jurisdiction.',
    };
  });

  const [savedSuccess, setSavedSuccess] = useState(false);

  // Users Filters & Search State
  const [searchQuery, setSearchQuery] = useState('');
  const [roleFilter, setRoleFilter] = useState<'all' | 'Admin' | 'Manager' | 'Staff'>('all');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'inactive'>('all');
  const [trackingFilter, setTrackingFilter] = useState<'all' | 'active' | 'disabled'>('all');

  // Column Visibility State
  const [visibleColumns, setVisibleColumns] = useState<Record<string, boolean>>(() => {
    const saved = localStorage.getItem('myteams_users_visible_columns');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch {
        // ignore
      }
    }
    return {
      user_code: true,
      name: true,
      mobile: true,
      email: true,
      role: true,
      reporting_head: true,
      location_tracking: true,
      last_login: true,
      status: true,
      actions: true,
    };
  });
  const [isColumnsDropdownOpen, setIsColumnsDropdownOpen] = useState(false);
  const columnsDropdownRef = useRef<HTMLDivElement>(null);

  // Close columns dropdown on outside click
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (columnsDropdownRef.current && !columnsDropdownRef.current.contains(e.target as Node)) {
        setIsColumnsDropdownOpen(false);
      }
    };
    if (isColumnsDropdownOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isColumnsDropdownOpen]);

  const toggleColumnVisibility = (key: string) => {
    const updated = { ...visibleColumns, [key]: !visibleColumns[key] };
    setVisibleColumns(updated);
    localStorage.setItem('myteams_users_visible_columns', JSON.stringify(updated));
  };

  // Pagination State
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);

  // Live Location Preview Modal State
  const [selectedLocationUser, setSelectedLocationUser] = useState<TeamUser | null>(null);

  // User Modal state (Add & Edit)
  const [isUserModalOpen, setIsUserModalOpen] = useState(false);
  const [editingUser, setEditingUser] = useState<TeamUser | null>(null);
  const [userModalTab, setUserModalTab] = useState<'profile' | 'permissions'>('profile');
  const [isSubmittingUser, setIsSubmittingUser] = useState(false);
  const [newFirstName, setNewFirstName] = useState('');
  const [newLastName, setNewLastName] = useState('');
  const [newMobile, setNewMobile] = useState('');
  const [newEmail, setNewEmail] = useState('');
  const [newRole, setNewRole] = useState<'Admin' | 'Manager' | 'Staff'>('Staff');
  const [newReportingHead, setNewReportingHead] = useState('ADMIN ADMIN');
  const [newLocationTracking, setNewLocationTracking] = useState(true);
  const [newIsActive, setNewIsActive] = useState(true);
  const [newPermissions, setNewPermissions] = useState<UserModulePermissions>(() =>
    getDefaultPermissions('Staff')
  );

  const handleSaveCompany = (e: React.FormEvent) => {
    e.preventDefault();
    localStorage.setItem('myteams_company_config', JSON.stringify(company));
    setSavedSuccess(true);
    setTimeout(() => setSavedSuccess(false), 3000);
  };

  const handleOpenAddUser = () => {
    setEditingUser(null);
    setUserModalTab('profile');
    setNewFirstName('');
    setNewLastName('');
    setNewMobile('');
    setNewEmail('');
    setNewRole('Staff');
    setNewReportingHead('ADMIN ADMIN');
    setNewLocationTracking(true);
    setNewIsActive(true);
    setNewPermissions(getDefaultPermissions('Staff'));
    setIsUserModalOpen(true);
  };

  const handleOpenEditUser = (u: TeamUser) => {
    setEditingUser(u);
    setUserModalTab('profile');
    setNewFirstName(u.first_name);
    setNewLastName(u.last_name);
    setNewMobile(u.mobile);
    setNewEmail(u.email);
    setNewRole(u.role);
    setNewReportingHead(u.reporting_head || 'ADMIN ADMIN');
    setNewLocationTracking(u.location_tracking ?? true);
    setNewIsActive(u.is_active ?? true);
    setNewPermissions(u.permissions || getDefaultPermissions(u.role));
    setIsUserModalOpen(true);
  };

  const handleRoleChangeInModal = (role: 'Admin' | 'Manager' | 'Staff') => {
    setNewRole(role);
    setNewPermissions(getDefaultPermissions(role));
  };

  const handleDeleteUser = async (u: TeamUser) => {
    if (!onDeleteUser) return;
    const confirmDelete = window.confirm(
      `Are you sure you want to remove team member ${u.first_name} ${u.last_name}?`
    );
    if (confirmDelete) {
      await onDeleteUser(u.id);
    }
  };

  const handleSaveUser = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newFirstName.trim() || !newMobile.trim()) return;

    setIsSubmittingUser(true);
    try {
      if (editingUser) {
        if (onUpdateUser) {
          await onUpdateUser(editingUser.id, {
            first_name: newFirstName.trim(),
            last_name: newLastName.trim(),
            mobile: newMobile.trim(),
            email: newEmail.trim(),
            role: newRole,
            reporting_head: newReportingHead,
            location_tracking: newLocationTracking,
            is_active: newIsActive,
            permissions: newPermissions,
          });
        }
      } else {
        await onAddUser({
          first_name: newFirstName.trim(),
          last_name: newLastName.trim(),
          mobile: newMobile.trim(),
          email: newEmail.trim(),
          role: newRole,
          reporting_head: newReportingHead,
          location_tracking: newLocationTracking,
          is_active: newIsActive,
          permissions: newPermissions,
        });
      }
      setIsUserModalOpen(false);
      setEditingUser(null);
    } finally {
      setIsSubmittingUser(false);
    }
  };

  const reportingHeadOptions = useMemo(() => {
    return Array.from(
      new Set([
        'ADMIN ADMIN',
        'JITESHBHAI VASANIYA',
        '-',
        ...users
          .filter((u) => !editingUser || u.id !== editingUser.id)
          .map((u) => `${u.first_name} ${u.last_name}`.trim())
          .filter(Boolean),
      ])
    );
  }, [users, editingUser]);

  // Filtered Users List
  const filteredUsers = useMemo(() => {
    return users.filter((u) => {
      // Text Search
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase().trim();
        const fullName = `${u.first_name} ${u.last_name}`.toLowerCase();
        const code = (u.user_code || '').toLowerCase();
        const mobile = (u.mobile || '').toLowerCase();
        const email = (u.email || '').toLowerCase();
        const head = (u.reporting_head || '').toLowerCase();
        if (
          !fullName.includes(q) &&
          !code.includes(q) &&
          !mobile.includes(q) &&
          !email.includes(q) &&
          !head.includes(q)
        ) {
          return false;
        }
      }

      // Role Filter
      if (roleFilter !== 'all' && u.role !== roleFilter) {
        return false;
      }

      // Status Filter
      if (statusFilter === 'active' && !u.is_active) return false;
      if (statusFilter === 'inactive' && u.is_active) return false;

      // Tracking Filter
      if (trackingFilter === 'active' && !u.location_tracking) return false;
      if (trackingFilter === 'disabled' && u.location_tracking) return false;

      return true;
    });
  }, [users, searchQuery, roleFilter, statusFilter, trackingFilter]);

  // Reset to page 1 on filter changes
  useEffect(() => {
    setCurrentPage(1);
  }, [searchQuery, roleFilter, statusFilter, trackingFilter]);

  // Pagination slice
  const totalPages = Math.max(1, Math.ceil(filteredUsers.length / itemsPerPage));
  const paginatedUsers = useMemo(() => {
    const start = (currentPage - 1) * itemsPerPage;
    return filteredUsers.slice(start, start + itemsPerPage);
  }, [filteredUsers, currentPage, itemsPerPage]);

  const activeUsersCount = useMemo(() => users.filter((u) => u.is_active).length, [users]);
  const totalLicenseCount = Math.max(10, users.length + 5);

  const hasActiveFilters =
    searchQuery.trim() !== '' ||
    roleFilter !== 'all' ||
    statusFilter !== 'all' ||
    trackingFilter !== 'all';

  const resetAllFilters = () => {
    setSearchQuery('');
    setRoleFilter('all');
    setStatusFilter('all');
    setTrackingFilter('all');
  };

  // Download All Users to Excel
  const handleDownloadAllUsers = () => {
    if (filteredUsers.length === 0) {
      alert('No users available to export.');
      return;
    }

    const exportRows = filteredUsers.map((u) => ({
      'Staff Code': `#${u.user_code}`,
      'Full Name': `${u.first_name} ${u.last_name}`,
      'Mobile Number': u.mobile,
      'Email Address': u.email || 'N/A',
      'Role': u.role,
      'Reporting Head': u.reporting_head || '-',
      'GPS Location Tracking': u.location_tracking ? 'Active' : 'Disabled',
      'Account Status': u.is_active ? 'Active' : 'Inactive',
      'Last Login': u.last_login || 'N/A',
      'App / Device': u.device_info || 'Mobile App',
      'Leads Visibility': u.permissions?.leads_view === 'own' ? 'Own Assigned' : 'All Leads',
      'Customers Visibility': u.permissions?.customers_view === 'own' ? 'Own Assigned' : 'All Customers',
      'Sales Invoicing': u.permissions?.sales_invoice ? 'Allowed' : 'Restricted',
      'Member Since': u.created_at ? new Date(u.created_at).toLocaleDateString('en-GB') : 'N/A',
    }));

    const worksheet = XLSX.utils.json_to_sheet(exportRows);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Users');

    const dateStr = new Date().toISOString().split('T')[0];
    XLSX.writeFile(workbook, `UpTeams_Users_${dateStr}.xlsx`);
  };

  return (
    <div className="space-y-4">
      {/* Settings Sub-Tabs matching UpTeams */}
      <div className="bg-white p-2 rounded-xl border border-gray-200 shadow-2xs flex items-center space-x-1 overflow-x-auto">
        {[
          { id: 'company', label: 'Company Profile', icon: Building2 },
          { id: 'users', label: 'Users & Team Hierarchy', icon: Users },
          { id: 'sales_settings', label: 'Sales & Invoicing Rules', icon: SettingsIcon },
          { id: 'templates', label: 'Message Templates', icon: MessageSquare },
          { id: 'modules', label: 'Modules & Cards Visibility', icon: SlidersHorizontal },
        ].map((tab) => {
          const Icon = tab.icon;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as typeof activeTab)}
              className={`flex items-center space-x-2 px-4 py-2 rounded-lg text-xs font-bold transition-all cursor-pointer whitespace-nowrap ${
                activeTab === tab.id
                  ? 'bg-[#3949ab] text-white shadow-xs'
                  : 'text-gray-600 hover:bg-gray-100'
              }`}
            >
              <Icon className="w-4 h-4" />
              <span>{tab.label}</span>
            </button>
          );
        })}
      </div>

      {/* TAB 1: COMPANY PROFILE */}
      {activeTab === 'company' && (
        <form onSubmit={handleSaveCompany} className="bg-white p-6 rounded-xl border border-gray-200 shadow-2xs space-y-4 text-xs">
          <div className="flex items-center justify-between border-b border-gray-100 pb-3">
            <div>
              <h3 className="font-bold text-sm text-gray-900">Organization & Profile Configuration</h3>
              <p className="text-gray-500 text-[11px]">UpTeams Workspace branding and legal information</p>
            </div>
            {savedSuccess && (
              <span className="text-emerald-600 font-semibold flex items-center gap-1">
                <CheckCircle className="w-4 h-4" /> Saved Successfully!
              </span>
            )}
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block font-semibold text-gray-700 mb-1">Company Registered Name</label>
              <input
                type="text"
                value={company.company_name}
                onChange={(e) => setCompany({ ...company, company_name: e.target.value })}
                className="w-full border border-gray-300 rounded-lg p-2"
              />
            </div>
            <div>
              <label className="block font-semibold text-gray-700 mb-1">Brand Name</label>
              <input
                type="text"
                value={company.brand_name}
                onChange={(e) => setCompany({ ...company, brand_name: e.target.value })}
                className="w-full border border-gray-300 rounded-lg p-2"
              />
            </div>
            <div>
              <label className="block font-semibold text-gray-700 mb-1">GSTIN Number</label>
              <input
                type="text"
                value={company.gstin}
                onChange={(e) => setCompany({ ...company, gstin: e.target.value })}
                className="w-full border border-gray-300 rounded-lg p-2 font-mono uppercase"
              />
            </div>
            <div>
              <label className="block font-semibold text-gray-700 mb-1">Official Mobile / Support Phone</label>
              <input
                type="text"
                value={company.phone}
                onChange={(e) => setCompany({ ...company, phone: e.target.value })}
                className="w-full border border-gray-300 rounded-lg p-2"
              />
            </div>
            <div>
              <label className="block font-semibold text-gray-700 mb-1">Official Email Address</label>
              <input
                type="email"
                value={company.email}
                onChange={(e) => setCompany({ ...company, email: e.target.value })}
                className="w-full border border-gray-300 rounded-lg p-2"
              />
            </div>
            <div>
              <label className="block font-semibold text-gray-700 mb-1">Website URL</label>
              <input
                type="text"
                value={company.website}
                onChange={(e) => setCompany({ ...company, website: e.target.value })}
                className="w-full border border-gray-300 rounded-lg p-2"
              />
            </div>
            <div>
              <label className="block font-semibold text-gray-700 mb-1">Timezone</label>
              <select
                value={company.timezone}
                onChange={(e) => setCompany({ ...company, timezone: e.target.value })}
                className="w-full border border-gray-300 rounded-lg p-2"
              >
                <option value="GMT+5:30">GMT+5:30 (India Standard Time)</option>
                <option value="UTC">UTC</option>
              </select>
            </div>
            <div>
              <label className="block font-semibold text-gray-700 mb-1">Currency</label>
              <select
                value={company.currency}
                onChange={(e) => setCompany({ ...company, currency: e.target.value })}
                className="w-full border border-gray-300 rounded-lg p-2"
              >
                <option value="INR">INR (₹ Indian Rupee)</option>
                <option value="USD">USD ($)</option>
              </select>
            </div>
          </div>

          <div className="pt-2">
            <label className="flex items-center space-x-2 cursor-pointer">
              <input
                type="checkbox"
                checked={company.is_dsr_email}
                onChange={(e) => setCompany({ ...company, is_dsr_email: e.target.checked })}
                className="rounded-sm text-[#3949ab] focus:ring-[#3949ab]"
              />
              <span className="font-semibold text-gray-800">
                Send Daily Automated DSR (Daily Status Report) Email Digest to Administrators
              </span>
            </label>
          </div>

          <div className="pt-3 border-t border-gray-100 flex justify-end">
            <button
              type="submit"
              className="inline-flex items-center space-x-1.5 px-5 py-2 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-lg font-semibold shadow-xs cursor-pointer"
            >
              <Save className="w-4 h-4" />
              <span>Save Company Profile</span>
            </button>
          </div>
        </form>
      )}

      {/* TAB 2: USERS & TEAM HIERARCHY */}
      {activeTab === 'users' && (
        <div className="space-y-3">
          {/* A. LICENSE COUNTER ALERT BANNER (.user-max-license-alert) */}
          <div className="bg-gradient-to-r from-blue-50/90 via-indigo-50/70 to-blue-50/90 border border-blue-200/80 rounded-xl p-3.5 shadow-2xs flex flex-wrap items-center justify-between gap-3 text-xs">
            <div className="flex items-center space-x-3">
              <div className="w-9 h-9 rounded-lg bg-[#3949ab] text-white flex items-center justify-center shrink-0 shadow-xs">
                <ShieldCheck className="w-5 h-5 text-white" />
              </div>
              <div>
                <div className="flex items-center space-x-2">
                  <span className="font-bold text-gray-900 text-sm">Workspace License Allocation</span>
                  <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#3949ab] text-white">
                    UpTeams Enterprise
                  </span>
                </div>
                <p className="text-gray-600 text-[11px] mt-0.5">
                  Real-time GPS tracking, attendance geo-fencing, and granular role permissions enabled.
                </p>
              </div>
            </div>

            <div className="flex items-center space-x-3">
              <div className="text-right">
                <div className="text-xs font-bold text-gray-800">
                  Active Users: <span className="text-[#3949ab] font-extrabold">{activeUsersCount}</span> / {totalLicenseCount} Licenses
                </div>
                <div className="w-32 bg-gray-200 h-1.5 rounded-full overflow-hidden mt-1">
                  <div
                    className="bg-[#3949ab] h-full rounded-full transition-all duration-300"
                    style={{ width: `${Math.min(100, (activeUsersCount / totalLicenseCount) * 100)}%` }}
                  />
                </div>
              </div>
              <span className="px-2.5 py-1 bg-emerald-100 text-emerald-800 text-[11px] font-bold rounded-lg border border-emerald-200">
                {totalLicenseCount - activeUsersCount} Free Seats
              </span>
            </div>
          </div>

          {/* B. USERS FILTER BLOCK & ACTIONS (.users-filter-block) */}
          <div className="bg-white rounded-xl border border-gray-200 shadow-2xs p-3.5 space-y-3">
            <div className="flex flex-wrap items-center justify-between gap-2.5">
              {/* Left: Search & Filter inputs */}
              <div className="flex flex-wrap items-center gap-2 flex-1 min-w-[280px]">
                {/* Search Bar */}
                <div className="relative flex-1 min-w-[200px] max-w-sm">
                  <Search className="w-3.5 h-3.5 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                  <input
                    type="text"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder="Search by name, mobile, email, code..."
                    className="w-full pl-8 pr-7 py-1.5 text-xs border border-gray-200 rounded-lg bg-gray-50/50 focus:bg-white focus:outline-none focus:ring-1 focus:ring-[#3949ab] focus:border-[#3949ab] transition-colors"
                  />
                  {searchQuery && (
                    <button
                      onClick={() => setSearchQuery('')}
                      className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                    >
                      <X className="w-3.5 h-3.5" />
                    </button>
                  )}
                </div>

                {/* Role Filter */}
                <select
                  value={roleFilter}
                  onChange={(e) => setRoleFilter(e.target.value as typeof roleFilter)}
                  className="px-2.5 py-1.5 text-xs border border-gray-200 rounded-lg bg-white text-gray-700 focus:outline-none focus:ring-1 focus:ring-[#3949ab] cursor-pointer"
                >
                  <option value="all">All Roles</option>
                  <option value="Admin">Admin</option>
                  <option value="Manager">Manager</option>
                  <option value="Staff">Field Staff</option>
                </select>

                {/* Status Filter */}
                <select
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value as typeof statusFilter)}
                  className="px-2.5 py-1.5 text-xs border border-gray-200 rounded-lg bg-white text-gray-700 focus:outline-none focus:ring-1 focus:ring-[#3949ab] cursor-pointer"
                >
                  <option value="all">All Status</option>
                  <option value="active">Active</option>
                  <option value="inactive">Inactive</option>
                </select>

                {/* GPS Tracking Filter */}
                <select
                  value={trackingFilter}
                  onChange={(e) => setTrackingFilter(e.target.value as typeof trackingFilter)}
                  className="px-2.5 py-1.5 text-xs border border-gray-200 rounded-lg bg-white text-gray-700 focus:outline-none focus:ring-1 focus:ring-[#3949ab] cursor-pointer"
                >
                  <option value="all">All GPS Tracking</option>
                  <option value="active">GPS Enabled</option>
                  <option value="disabled">GPS Disabled</option>
                </select>

                {/* Reset Filters */}
                {hasActiveFilters && (
                  <button
                    onClick={resetAllFilters}
                    className="inline-flex items-center gap-1 text-[11px] font-semibold text-rose-600 hover:text-rose-700 px-2 py-1 rounded-md hover:bg-rose-50 transition-colors cursor-pointer"
                    title="Reset all filters"
                  >
                    <RotateCcw className="w-3 h-3" />
                    <span>Clear</span>
                  </button>
                )}
              </div>

              {/* Right: Column Selector Popover & Add User Button */}
              <div className="flex items-center gap-2">
                {/* Columns Visibility Popover (#settingColumns) */}
                <div className="relative" ref={columnsDropdownRef}>
                  <button
                    type="button"
                    onClick={() => setIsColumnsDropdownOpen((v) => !v)}
                    className="inline-flex items-center space-x-1.5 px-3 py-1.5 border border-gray-200 rounded-lg text-xs font-semibold text-gray-700 bg-white hover:bg-gray-50 transition-colors cursor-pointer shadow-2xs"
                    title="Customize visible columns"
                  >
                    <SlidersHorizontal className="w-3.5 h-3.5 text-[#3949ab]" />
                    <span>Columns</span>
                  </button>

                  {isColumnsDropdownOpen && (
                    <div className="absolute right-0 top-9 z-50 w-52 bg-white rounded-xl shadow-xl border border-gray-200 p-2 text-xs space-y-1 animate-in fade-in zoom-in-95">
                      <div className="px-2 py-1 text-[11px] font-bold text-gray-500 uppercase tracking-wider border-b border-gray-100 flex items-center justify-between">
                        <span>Show/Hide Columns</span>
                        <button
                          onClick={() => setIsColumnsDropdownOpen(false)}
                          className="text-gray-400 hover:text-gray-600"
                        >
                          <X className="w-3.5 h-3.5" />
                        </button>
                      </div>
                      <div className="max-h-60 overflow-y-auto space-y-0.5 pt-1">
                        {AVAILABLE_COLUMNS.map((col) => {
                          const isChecked = visibleColumns[col.key] ?? true;
                          return (
                            <label
                              key={col.key}
                              className={`flex items-center space-x-2 px-2 py-1.5 rounded-md hover:bg-gray-50 cursor-pointer ${
                                col.locked ? 'opacity-60 cursor-not-allowed' : ''
                              }`}
                            >
                              <input
                                type="checkbox"
                                disabled={col.locked}
                                checked={isChecked}
                                onChange={() => !col.locked && toggleColumnVisibility(col.key)}
                                className="rounded text-[#3949ab] focus:ring-[#3949ab]"
                              />
                              <span className="text-gray-700 text-xs font-medium">{col.label}</span>
                            </label>
                          );
                        })}
                      </div>
                    </div>
                  )}
                </div>

                {/* Primary Action: Add User */}
                <button
                  onClick={handleOpenAddUser}
                  className="inline-flex items-center space-x-1.5 px-3.5 py-1.5 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-lg text-xs font-semibold shadow-xs cursor-pointer transition-colors"
                >
                  <Plus className="w-4 h-4" />
                  <span>Add User</span>
                </button>
              </div>
            </div>
          </div>

          {/* C. USERS TABLE */}
          <div className="bg-white rounded-xl border border-gray-200 shadow-2xs overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs text-gray-700">
                <thead className="bg-gray-50 text-gray-500 font-semibold uppercase text-[11px] border-b border-gray-200">
                  <tr>
                    {visibleColumns.user_code && <th className="px-4 py-3">ID</th>}
                    {visibleColumns.name && <th className="px-4 py-3">Member Name</th>}
                    {visibleColumns.mobile && <th className="px-4 py-3">Mobile</th>}
                    {visibleColumns.email && <th className="px-4 py-3">Email</th>}
                    {visibleColumns.role && <th className="px-4 py-3">Role</th>}
                    {visibleColumns.reporting_head && <th className="px-4 py-3">Reporting Head</th>}
                    {visibleColumns.location_tracking && <th className="px-4 py-3 text-center">GPS Tracking & Live Map</th>}
                    {visibleColumns.last_login && <th className="px-4 py-3">Last Login / Device</th>}
                    {visibleColumns.status && <th className="px-4 py-3 text-center">Status</th>}
                    {visibleColumns.actions && <th className="px-4 py-3 text-right">Actions</th>}
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {paginatedUsers.map((u) => (
                    <tr key={u.id} className="hover:bg-gray-50/80 transition-colors">
                      {/* ID / Code */}
                      {visibleColumns.user_code && (
                        <td className="px-4 py-3 font-mono font-bold text-gray-900">
                          #{u.user_code}
                        </td>
                      )}

                      {/* Name & Avatar */}
                      {visibleColumns.name && (
                        <td className="px-4 py-3">
                          <div className="flex items-center space-x-2.5">
                            <div className="relative">
                              <div className="w-7 h-7 rounded-full bg-[#3949ab] text-white font-bold flex items-center justify-center text-[10px] shadow-2xs">
                                {u.first_name[0]}{u.last_name[0]}
                              </div>
                              <span
                                className={`absolute -bottom-0.5 -right-0.5 w-2.5 h-2.5 rounded-full border-2 border-white ${
                                  u.is_active ? 'bg-emerald-500' : 'bg-gray-300'
                                }`}
                                title={u.is_active ? 'Online / Active' : 'Inactive'}
                              />
                            </div>
                            <div>
                              <button
                                type="button"
                                onClick={() => handleOpenEditUser(u)}
                                className="font-bold text-gray-900 hover:text-[#3949ab] hover:underline text-left cursor-pointer flex items-center gap-1.5"
                                title="Click to edit member details"
                              >
                                <span>{u.first_name} {u.last_name}</span>
                              </button>
                              <div className="text-[10px] text-gray-400">
                                {u.role === 'Admin' ? 'System Administrator' : u.role === 'Manager' ? 'Branch / Team Manager' : 'Field Sales Executive'}
                              </div>
                            </div>
                          </div>
                        </td>
                      )}

                      {/* Mobile */}
                      {visibleColumns.mobile && (
                        <td className="px-4 py-3">
                          <a
                            href={`tel:${u.mobile}`}
                            className="inline-flex items-center gap-1 text-gray-800 hover:text-[#3949ab] font-medium"
                          >
                            <Phone className="w-3 h-3 text-gray-400" />
                            <span>{u.mobile}</span>
                          </a>
                        </td>
                      )}

                      {/* Email */}
                      {visibleColumns.email && (
                        <td className="px-4 py-3">
                          {u.email ? (
                            <a
                              href={`mailto:${u.email}`}
                              className="inline-flex items-center gap-1 text-gray-600 hover:text-[#3949ab]"
                            >
                              <Mail className="w-3 h-3 text-gray-400" />
                              <span className="truncate max-w-[150px]">{u.email}</span>
                            </a>
                          ) : (
                            <span className="text-gray-400">—</span>
                          )}
                        </td>
                      )}

                      {/* Role */}
                      {visibleColumns.role && (
                        <td className="px-4 py-3">
                          <span
                            className={`px-2 py-0.5 rounded-full text-[11px] font-semibold ${
                              u.role === 'Admin'
                                ? 'bg-purple-50 text-purple-700 border border-purple-200'
                                : u.role === 'Manager'
                                ? 'bg-blue-50 text-blue-700 border border-blue-200'
                                : 'bg-gray-100 text-gray-700 border border-gray-200'
                            }`}
                          >
                            {u.role}
                          </span>
                        </td>
                      )}

                      {/* Reporting Head */}
                      {visibleColumns.reporting_head && (
                        <td className="px-4 py-3 text-gray-600 font-medium">
                          {u.reporting_head || '—'}
                        </td>
                      )}

                      {/* GPS Location Tracking & Live Map View (#UserLocationMapView) */}
                      {visibleColumns.location_tracking && (
                        <td className="px-4 py-3 text-center">
                          <div className="inline-flex items-center gap-1.5 justify-center">
                            <button
                              onClick={() => onToggleTracking(u.id)}
                              className="cursor-pointer inline-flex items-center gap-1 font-semibold text-xs transition-colors"
                              title="Toggle GPS tracking"
                            >
                              {u.location_tracking ? (
                                <span className="text-emerald-600 flex items-center gap-1">
                                  <ToggleRight className="w-5 h-5 text-emerald-600" /> Active
                                </span>
                              ) : (
                                <span className="text-gray-400 flex items-center gap-1">
                                  <ToggleLeft className="w-5 h-5 text-gray-400" /> Disabled
                                </span>
                              )}
                            </button>

                            {/* Live Map Button */}
                            <button
                              type="button"
                              onClick={() => setSelectedLocationUser(u)}
                              className="p-1 rounded-md text-[#3949ab] hover:bg-[#3949ab]/10 hover:text-[#303f9f] transition-colors cursor-pointer"
                              title="View latest GPS coordinates & map location"
                            >
                              <MapPin className="w-4 h-4" />
                            </button>
                          </div>
                        </td>
                      )}

                      {/* Last Login & Device */}
                      {visibleColumns.last_login && (
                        <td className="px-4 py-3">
                          <div className="space-y-0.5">
                            <div className="flex items-center gap-1 text-gray-800 font-medium">
                              <Clock className="w-3 h-3 text-gray-400" />
                              <span>{u.last_login || 'Today, 10:45 AM'}</span>
                            </div>
                            <div className="flex items-center gap-1 text-[10px] text-gray-500">
                              <Smartphone className="w-2.5 h-2.5 text-gray-400" />
                              <span>{u.device_info || 'Android 14 (UpTeams v2.4)'}</span>
                            </div>
                          </div>
                        </td>
                      )}

                      {/* Status */}
                      {visibleColumns.status && (
                        <td className="px-4 py-3 text-center">
                          <button
                            onClick={() => onToggleActive(u.id)}
                            className={`px-2.5 py-0.5 rounded-full text-[11px] font-semibold cursor-pointer transition-colors ${
                              u.is_active
                                ? 'bg-emerald-50 text-emerald-700 border border-emerald-200 hover:bg-emerald-100'
                                : 'bg-rose-50 text-rose-700 border border-rose-200 hover:bg-rose-100'
                            }`}
                            title="Toggle active / inactive status"
                          >
                            {u.is_active ? 'Active' : 'Inactive'}
                          </button>
                        </td>
                      )}

                      {/* Actions */}
                      {visibleColumns.actions && (
                        <td className="px-4 py-3 text-right">
                          <div className="flex items-center justify-end space-x-1">
                            <button
                              type="button"
                              onClick={() => handleOpenEditUser(u)}
                              className="p-1.5 text-gray-500 hover:text-[#3949ab] hover:bg-[#3949ab]/10 rounded-lg transition-colors cursor-pointer"
                              title="Edit user details and permissions"
                            >
                              <Pencil className="w-4 h-4" />
                            </button>
                            {onDeleteUser && (
                              <button
                                type="button"
                                onClick={() => handleDeleteUser(u)}
                                className="p-1.5 text-gray-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors cursor-pointer"
                                title="Delete User"
                              >
                                <Trash2 className="w-4 h-4" />
                              </button>
                            )}
                          </div>
                        </td>
                      )}
                    </tr>
                  ))}

                  {paginatedUsers.length === 0 && (
                    <tr>
                      <td colSpan={10} className="text-center py-12 text-gray-400 text-xs">
                        No team members match your current search or filters.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>

            {/* D. BOTTOM BAR: DOWNLOAD ALL & PAGINATION (MATCHING LEADS, CUSTOMERS, SALES) */}
            <div className="w-full px-4 py-3 border-t border-gray-200 flex flex-wrap items-center justify-between gap-3 text-xs text-gray-500 bg-white">
              {/* Left: Download All Button */}
              <div>
                <button
                  onClick={handleDownloadAllUsers}
                  title="Download all users in Excel format"
                  className="inline-flex items-center gap-2 px-3.5 py-2 bg-[#3949ab] hover:bg-[#303f9f] text-white text-xs font-semibold rounded shadow-xs transition-colors cursor-pointer"
                >
                  <Download className="w-4 h-4" />
                  <span>Download All</span>
                </button>
              </div>

              {/* Right: Showing text, Page size dropdown, Page navigation */}
              <div className="flex flex-wrap items-center gap-3">
                <span className="text-gray-500 text-xs">
                  Showing {filteredUsers.length === 0 ? 0 : (currentPage - 1) * itemsPerPage + 1} -{' '}
                  {Math.min(currentPage * itemsPerPage, filteredUsers.length)} of{' '}
                  {filteredUsers.length.toLocaleString()}
                </span>

                {/* Page size dropdown */}
                <select
                  value={itemsPerPage}
                  onChange={(e) => {
                    setItemsPerPage(Number(e.target.value));
                    setCurrentPage(1);
                  }}
                  className="border border-gray-300 rounded px-2 py-1 text-xs text-gray-700 bg-white focus:outline-none focus:ring-1 focus:ring-[#3949ab] cursor-pointer"
                >
                  <option value={10}>10</option>
                  <option value={25}>25</option>
                  <option value={50}>50</option>
                  <option value={100}>100</option>
                </select>

                {/* Page navigation buttons */}
                <div className="flex items-center gap-1">
                  <button
                    disabled={currentPage === 1}
                    onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                    className="min-w-[28px] h-7 px-1.5 rounded flex items-center justify-center text-[#3949ab] hover:bg-gray-100 disabled:text-gray-300 disabled:hover:bg-transparent disabled:cursor-not-allowed cursor-pointer transition-colors"
                    title="Previous page"
                  >
                    <ChevronLeft className="w-4 h-4" />
                  </button>

                  {getPageNumbers(currentPage, totalPages).map((p, idx) => {
                    if (typeof p === 'string') {
                      return (
                        <span
                          key={`ellipsis-${idx}`}
                          className="px-1 text-gray-400 select-none flex items-center justify-center text-xs"
                        >
                          ...
                        </span>
                      );
                    }
                    const isActive = p === currentPage;
                    return (
                      <button
                        key={`page-${p}`}
                        onClick={() => setCurrentPage(p)}
                        className={`min-w-[28px] h-7 px-2 rounded flex items-center justify-center text-xs transition-colors cursor-pointer ${
                          isActive
                            ? 'bg-[#3949ab] text-white font-semibold shadow-xs'
                            : 'text-[#3949ab] hover:bg-gray-100 font-normal'
                        }`}
                      >
                        {p}
                      </button>
                    );
                  })}

                  <button
                    disabled={currentPage === totalPages || filteredUsers.length === 0}
                    onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                    className="min-w-[28px] h-7 px-1.5 rounded flex items-center justify-center text-[#3949ab] hover:bg-gray-100 disabled:text-gray-300 disabled:hover:bg-transparent disabled:cursor-not-allowed cursor-pointer transition-colors"
                    title="Next page"
                  >
                    <ChevronRight className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB 3: SALES & DOCUMENT SETTINGS */}
      {activeTab === 'sales_settings' && (
        <form onSubmit={handleSaveCompany} className="bg-white p-6 rounded-xl border border-gray-200 shadow-2xs space-y-4 text-xs">
          <h3 className="font-bold text-sm text-gray-900 border-b border-gray-100 pb-2">
            Invoicing Rules, Prefixes & Banking Configuration
          </h3>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block font-semibold text-gray-700 mb-1">Tax Invoice Prefix</label>
              <input
                type="text"
                value={company.invoice_prefix}
                onChange={(e) => setCompany({ ...company, invoice_prefix: e.target.value })}
                className="w-full border border-gray-300 rounded-lg p-2 font-mono uppercase"
              />
            </div>
            <div>
              <label className="block font-semibold text-gray-700 mb-1">Proforma Invoice Prefix</label>
              <input
                type="text"
                value={company.proforma_prefix}
                onChange={(e) => setCompany({ ...company, proforma_prefix: e.target.value })}
                className="w-full border border-gray-300 rounded-lg p-2 font-mono uppercase"
              />
            </div>
            <div>
              <label className="block font-semibold text-gray-700 mb-1">Order Prefix</label>
              <input
                type="text"
                value={company.order_prefix}
                onChange={(e) => setCompany({ ...company, order_prefix: e.target.value })}
                className="w-full border border-gray-300 rounded-lg p-2 font-mono uppercase"
              />
            </div>
          </div>

          <h4 className="font-bold text-gray-800 pt-2 text-xs uppercase tracking-wider">
            Bank Account Details (Printed on Invoices & Proforma)
          </h4>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block font-semibold text-gray-700 mb-1">Bank Name</label>
              <input
                type="text"
                value={company.bank_name}
                onChange={(e) => setCompany({ ...company, bank_name: e.target.value })}
                className="w-full border border-gray-300 rounded-lg p-2"
              />
            </div>
            <div>
              <label className="block font-semibold text-gray-700 mb-1">Account Number</label>
              <input
                type="text"
                value={company.bank_account_no}
                onChange={(e) => setCompany({ ...company, bank_account_no: e.target.value })}
                className="w-full border border-gray-300 rounded-lg p-2 font-mono"
              />
            </div>
            <div>
              <label className="block font-semibold text-gray-700 mb-1">IFSC Code</label>
              <input
                type="text"
                value={company.bank_ifsc}
                onChange={(e) => setCompany({ ...company, bank_ifsc: e.target.value })}
                className="w-full border border-gray-300 rounded-lg p-2 font-mono uppercase"
              />
            </div>
            <div>
              <label className="block font-semibold text-gray-700 mb-1">UPI ID (QR Payment)</label>
              <input
                type="text"
                value={company.upi_id}
                onChange={(e) => setCompany({ ...company, upi_id: e.target.value })}
                className="w-full border border-gray-300 rounded-lg p-2 font-mono"
              />
            </div>
          </div>

          <div>
            <label className="block font-semibold text-gray-700 mb-1">Default Terms & Conditions</label>
            <textarea
              rows={3}
              value={company.terms}
              onChange={(e) => setCompany({ ...company, terms: e.target.value })}
              className="w-full border border-gray-300 rounded-lg p-2"
            />
          </div>

          <div className="pt-3 border-t border-gray-100 flex justify-end">
            <button
              type="submit"
              className="inline-flex items-center space-x-1.5 px-5 py-2 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-lg font-semibold shadow-xs cursor-pointer"
            >
              <Save className="w-4 h-4" />
              <span>Save Invoicing Settings</span>
            </button>
          </div>
        </form>
      )}

      {/* TAB 4: TEMPLATES */}
      {activeTab === 'templates' && (
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-2xs space-y-4 text-xs">
          <div className="flex items-center justify-between border-b border-gray-100 pb-2">
            <div>
              <h3 className="font-bold text-sm text-gray-900">WhatsApp & Notification Templates</h3>
              <p className="text-gray-500 text-[11px]">Dynamic templates sent to leads and clients</p>
            </div>
          </div>

          <div className="space-y-3">
            {[
              {
                name: 'Proforma Invoice Share',
                module: 'Proforma Invoices',
                content: 'Dear {{customer_name}}, please find your Proforma Invoice {{id}} from {{brand_name}}. Total Amount: {{total}}.',
              },
              {
                name: 'First Follow-Up',
                module: 'Leads',
                content: 'Hello {{name}}, following up on our recent discussion regarding your requirements with {{companyName}}.',
              },
              {
                name: 'Invoice Payment Receipt',
                module: 'Invoices',
                content: 'Dear {{customer_name}}, we have received your payment of {{amount}} against Invoice {{id}}. Thank you for your business!',
              },
            ].map((tmpl) => (
              <div key={tmpl.name} className="p-4 bg-gray-50 rounded-lg border border-gray-100 space-y-1">
                <div className="flex items-center justify-between">
                  <span className="font-bold text-gray-900">{tmpl.name}</span>
                  <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-blue-50 text-blue-700">
                    {tmpl.module}
                  </span>
                </div>
                <p className="text-gray-600 font-mono text-[11px]">{tmpl.content}</p>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* TAB 5: MODULES & CARDS VISIBILITY */}
      {activeTab === 'modules' && (
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-2xs space-y-6 text-xs">
          <div className="flex items-center justify-between border-b border-gray-100 pb-3 flex-wrap gap-2">
            <div>
              <h3 className="font-bold text-sm text-gray-900 flex items-center gap-2">
                <span>Modules & Dashboard Cards Visibility Control</span>
                <span className="text-[10px] px-2 py-0.5 rounded-full bg-[#3949ab]/10 text-[#3949ab] font-bold">
                  UpTeams Customizer
                </span>
                {isSaving && (
                  <span className="inline-flex items-center gap-1.5 text-[11px] font-semibold text-[#3949ab] bg-[#3949ab]/10 px-2 py-0.5 rounded-full">
                    <Loader2 className="w-3.5 h-3.5 animate-spin" />
                    Saving to cloud...
                  </span>
                )}
              </h3>
              <p className="text-gray-500 text-[11px]">
                Enable or disable system modules and dashboard widgets for your workspace.
              </p>
            </div>
            {onResetDefaults && (
              <button
                type="button"
                onClick={() => !isSaving && onResetDefaults()}
                disabled={isSaving}
                className={`inline-flex items-center space-x-1.5 px-3 py-1.5 border border-gray-200 rounded-lg text-xs font-semibold transition-colors ${
                  isSaving
                    ? 'text-gray-400 bg-gray-50 cursor-not-allowed'
                    : 'text-gray-700 hover:bg-gray-50 cursor-pointer'
                }`}
              >
                <RotateCcw className="w-3.5 h-3.5" />
                <span>Reset All Defaults</span>
              </button>
            )}
          </div>

          {/* 1. Main Navigation Modules */}
          <div className="space-y-3">
            <h4 className="font-bold text-xs text-gray-800 uppercase tracking-wider flex items-center gap-2">
              <LayoutDashboard className="w-4 h-4 text-[#3949ab]" />
              <span>Main Navigation Modules</span>
            </h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {[
                { key: 'leads' as const, label: 'Leads Management', desc: 'Inquiries, stages, scoring, WhatsApp chat, and conversion to customer' },
                { key: 'customers' as const, label: 'Customers Directory', desc: 'Customer accounts, tiers (Gold/Silver), and purchase history' },
                { key: 'sales' as const, label: 'Sales & Invoices Suite', desc: 'Proforma Invoices, Tax Invoices, Orders, Payments, and Stock Inventory' },
                { key: 'expenses' as const, label: 'Field Expenses Claims', desc: 'Staff reimbursement claims, travel distance, receipt audit, and approvals' },
                { key: 'reports' as const, label: 'Reports & DSR Analytics', desc: 'Daily Status Reports, staff scorecards, and conversion funnel' },
                { key: 'settings' as const, label: 'Workspace Settings', desc: 'Company profile, team hierarchy, GPS tracking toggles, and templates' },
              ].map((m) => {
                const isVisible = moduleVisibility ? moduleVisibility[m.key] : true;
                return (
                  <div
                    key={m.key}
                    onClick={() => !isSaving && onToggleModule && onToggleModule(m.key)}
                    className={`p-3.5 rounded-xl border border-gray-200 transition-all flex items-center justify-between ${
                      isSaving
                        ? 'cursor-not-allowed opacity-70 bg-gray-50'
                        : 'cursor-pointer bg-gray-50/50 hover:bg-white hover:border-[#3949ab]/40'
                    }`}
                  >
                    <div className="min-w-0 pr-3">
                      <div className="flex items-center space-x-2">
                        <span className="font-bold text-gray-900">{m.label}</span>
                        <span className={`text-[10px] px-1.5 py-0.2 rounded-full font-semibold ${
                          isVisible ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' : 'bg-gray-200 text-gray-600'
                        }`}>
                          {isVisible ? 'Active' : 'Hidden'}
                        </span>
                      </div>
                      <p className="text-gray-500 text-[11px] mt-0.5">{m.desc}</p>
                    </div>
                    <div className="shrink-0">
                      {isSaving ? (
                        <Loader2 className="w-5 h-5 text-[#3949ab] animate-spin" />
                      ) : isVisible ? (
                        <ToggleRight className="w-6 h-6 text-[#3949ab]" />
                      ) : (
                        <ToggleLeft className="w-6 h-6 text-gray-300" />
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* 2. Dashboard Cards */}
          <div className="space-y-3 pt-3 border-t border-gray-100">
            <h4 className="font-bold text-xs text-gray-800 uppercase tracking-wider flex items-center gap-2">
              <Layers className="w-4 h-4 text-[#3949ab]" />
              <span>Dashboard Cards & Widgets</span>
            </h4>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
              {[
                { key: 'quickStats' as const, label: 'Metric KPI Counters' },
                { key: 'leadsChart' as const, label: 'Leads Pipeline Funnel' },
                { key: 'attendanceChart' as const, label: 'Attendance & Punch Status' },
                { key: 'visitsChart' as const, label: 'Field Client Visits' },
                { key: 'tasksChart' as const, label: 'Field Tasks Breakdown' },
                { key: 'callsSummary' as const, label: 'Calls Summary Log' },
                { key: 'visitsList' as const, label: 'Recent Leads Feed' },
                { key: 'ordersList' as const, label: 'Recent Invoices & Orders' },
                { key: 'customerReminders' as const, label: 'Customer Reminders' },
              ].map((c) => {
                const isVisible = dashboardCards ? dashboardCards[c.key] : true;
                return (
                  <div
                    key={c.key}
                    onClick={() => !isSaving && onToggleCard && onToggleCard(c.key)}
                    className={`p-3 rounded-lg border border-gray-200 transition-all flex items-center justify-between ${
                      isSaving
                        ? 'cursor-not-allowed opacity-70 bg-gray-50'
                        : 'cursor-pointer bg-gray-50/50 hover:bg-white hover:border-[#3949ab]/40'
                    }`}
                  >
                    <span className={`font-semibold ${isVisible ? 'text-gray-900' : 'text-gray-400'}`}>
                      {c.label}
                    </span>
                    <div className="shrink-0">
                      {isSaving ? (
                        <Loader2 className="w-4 h-4 text-[#3949ab] animate-spin" />
                      ) : isVisible ? (
                        <ToggleRight className="w-5 h-5 text-[#3949ab]" />
                      ) : (
                        <ToggleLeft className="w-5 h-5 text-gray-300" />
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* LIVE MAP & LOCATION MODAL (#UserLocationMapView) */}
      {selectedLocationUser && (
        <div className="fixed inset-0 z-50 overflow-y-auto bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden border border-gray-100 animate-in fade-in zoom-in-95">
            {/* Modal Header */}
            <div className="p-4 bg-gradient-to-r from-[#1a237e] to-[#3949ab] text-white flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center font-bold text-sm">
                  {selectedLocationUser.first_name[0]}{selectedLocationUser.last_name[0]}
                </div>
                <div>
                  <h3 className="font-bold text-sm leading-tight">
                    {selectedLocationUser.first_name} {selectedLocationUser.last_name}
                  </h3>
                  <div className="flex items-center space-x-2 text-[11px] text-white/80 mt-0.5">
                    <span>Staff #{selectedLocationUser.user_code}</span>
                    <span>•</span>
                    <span>{selectedLocationUser.role}</span>
                  </div>
                </div>
              </div>
              <button
                onClick={() => setSelectedLocationUser(null)}
                className="p-1 rounded-lg text-white/70 hover:text-white hover:bg-white/10 transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-5 space-y-4 text-xs">
              {/* Status Banner */}
              <div className="flex items-center justify-between p-3 rounded-xl bg-gray-50 border border-gray-200">
                <div className="flex items-center space-x-2">
                  <span className={`w-3 h-3 rounded-full ${selectedLocationUser.location_tracking ? 'bg-emerald-500 animate-pulse' : 'bg-gray-400'}`} />
                  <span className="font-bold text-gray-800">
                    {selectedLocationUser.location_tracking ? 'Real-time GPS Tracking Active' : 'GPS Tracking Disabled'}
                  </span>
                </div>
                <span className="text-[11px] font-semibold text-gray-500">
                  {selectedLocationUser.last_location?.updated_at || '15 mins ago'}
                </span>
              </div>

              {/* Map Visual Card */}
              <div className="relative h-48 w-full rounded-xl overflow-hidden border border-gray-200 bg-slate-100 flex items-center justify-center">
                {/* Styled Map Background Grid */}
                <div className="absolute inset-0 opacity-20 bg-[radial-gradient(#3949ab_1px,transparent_1px)] [background-size:16px_16px]" />
                
                {/* Radar pulse around pin */}
                <div className="absolute w-24 h-24 rounded-full bg-[#3949ab]/15 animate-ping" />
                <div className="absolute w-12 h-12 rounded-full bg-[#3949ab]/25 flex items-center justify-center">
                  <div className="w-7 h-7 rounded-full bg-[#3949ab] text-white flex items-center justify-center shadow-lg">
                    <MapPin className="w-4 h-4 text-white" />
                  </div>
                </div>

                {/* Badge Overlay */}
                <div className="absolute bottom-3 left-3 right-3 bg-white/95 backdrop-blur-xs p-2.5 rounded-lg border border-gray-200 shadow-sm flex items-center justify-between">
                  <div className="truncate pr-2">
                    <div className="font-bold text-gray-900 text-xs truncate">
                      {selectedLocationUser.last_location?.address || 'Kuvadva Road, Rajkot, Gujarat'}
                    </div>
                    <div className="text-[10px] text-gray-500 font-mono mt-0.5">
                      Lat: {selectedLocationUser.last_location?.lat || 22.3039}, Lng: {selectedLocationUser.last_location?.lng || 70.8022}
                    </div>
                  </div>
                  <a
                    href={`https://www.google.com/maps/search/?api=1&query=${selectedLocationUser.last_location?.lat || 22.3039},${selectedLocationUser.last_location?.lng || 70.8022}`}
                    target="_blank"
                    rel="noreferrer"
                    className="shrink-0 px-2.5 py-1.5 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-md text-[11px] font-bold inline-flex items-center gap-1 shadow-2xs transition-colors"
                  >
                    <span>Google Maps</span>
                    <ExternalLink className="w-3 h-3" />
                  </a>
                </div>
              </div>

              {/* Extra Info Grid */}
              <div className="grid grid-cols-2 gap-2.5 text-[11px]">
                <div className="p-2.5 bg-gray-50 rounded-lg border border-gray-100">
                  <span className="text-gray-400 block mb-0.5">Mobile Contact</span>
                  <span className="font-bold text-gray-800">{selectedLocationUser.mobile}</span>
                </div>
                <div className="p-2.5 bg-gray-50 rounded-lg border border-gray-100">
                  <span className="text-gray-400 block mb-0.5">Reports To</span>
                  <span className="font-bold text-gray-800">{selectedLocationUser.reporting_head || 'ADMIN ADMIN'}</span>
                </div>
                <div className="p-2.5 bg-gray-50 rounded-lg border border-gray-100">
                  <span className="text-gray-400 block mb-0.5">Last Logged Device</span>
                  <span className="font-bold text-gray-800 truncate block">
                    {selectedLocationUser.device_info || 'Android 14 (UpTeams v2.4)'}
                  </span>
                </div>
                <div className="p-2.5 bg-gray-50 rounded-lg border border-gray-100">
                  <span className="text-gray-400 block mb-0.5">Last Login Time</span>
                  <span className="font-bold text-gray-800">{selectedLocationUser.last_login || 'Today, 10:45 AM'}</span>
                </div>
              </div>
            </div>

            {/* Modal Footer */}
            <div className="p-4 bg-gray-50 border-t border-gray-100 flex justify-end">
              <button
                type="button"
                onClick={() => setSelectedLocationUser(null)}
                className="px-4 py-2 bg-white border border-gray-200 hover:bg-gray-100 text-gray-700 font-semibold rounded-lg text-xs transition-colors cursor-pointer"
              >
                Close Preview
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ADD / EDIT USER MODAL WITH GRANULAR PERMISSIONS (.permissions-module) */}
      {isUserModalOpen && (
        <div className="fixed inset-0 z-50 overflow-y-auto bg-black/50 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl border border-gray-100 overflow-hidden text-xs animate-in fade-in zoom-in-95">
            {/* Modal Header */}
            <div className="p-4 border-b border-gray-100 flex items-center justify-between bg-gray-50/70">
              <div>
                <h3 className="text-base font-bold text-gray-900">
                  {editingUser ? 'Edit Team Member Profile & Access' : 'Add New Field Team Member'}
                </h3>
                <p className="text-gray-500 text-[11px] mt-0.5">
                  {editingUser
                    ? `Updating staff member #${editingUser.user_code} (${editingUser.first_name} ${editingUser.last_name})`
                    : 'Assign reporting hierarchy and configure module data permissions'}
                </p>
              </div>
              <button
                type="button"
                onClick={() => {
                  setIsUserModalOpen(false);
                  setEditingUser(null);
                }}
                className="p-1.5 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Sub-Tabs: Profile vs Permissions */}
            <div className="flex border-b border-gray-200 bg-white px-4 pt-2">
              <button
                type="button"
                onClick={() => setUserModalTab('profile')}
                className={`px-4 py-2 text-xs font-bold border-b-2 transition-colors cursor-pointer ${
                  userModalTab === 'profile'
                    ? 'border-[#3949ab] text-[#3949ab]'
                    : 'border-transparent text-gray-500 hover:text-gray-700'
                }`}
              >
                1. Member Profile & Hierarchy
              </button>
              <button
                type="button"
                onClick={() => setUserModalTab('permissions')}
                className={`px-4 py-2 text-xs font-bold border-b-2 transition-colors cursor-pointer flex items-center gap-1.5 ${
                  userModalTab === 'permissions'
                    ? 'border-[#3949ab] text-[#3949ab]'
                    : 'border-transparent text-gray-500 hover:text-gray-700'
                }`}
              >
                <Lock className="w-3.5 h-3.5" />
                <span>2. Granular Module Permissions</span>
              </button>
            </div>

            {/* Form */}
            <form onSubmit={handleSaveUser}>
              <div className="p-6 space-y-4 max-h-[68vh] overflow-y-auto">
                {/* TAB A: PROFILE DETAILS */}
                {userModalTab === 'profile' && (
                  <div className="space-y-3.5">
                    <div className="grid grid-cols-2 gap-3">
                      <div>
                        <label className="block font-semibold text-gray-700 mb-1">First Name *</label>
                        <input
                          type="text"
                          required
                          value={newFirstName}
                          onChange={(e) => setNewFirstName(e.target.value)}
                          placeholder="e.g. Ramesh"
                          className="w-full border border-gray-300 rounded-lg p-2 focus:ring-[#3949ab] focus:border-[#3949ab]"
                        />
                      </div>
                      <div>
                        <label className="block font-semibold text-gray-700 mb-1">Last Name</label>
                        <input
                          type="text"
                          value={newLastName}
                          onChange={(e) => setNewLastName(e.target.value)}
                          placeholder="e.g. Patel"
                          className="w-full border border-gray-300 rounded-lg p-2 focus:ring-[#3949ab] focus:border-[#3949ab]"
                        />
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-3">
                      <div>
                        <label className="block font-semibold text-gray-700 mb-1">Mobile Number *</label>
                        <input
                          type="text"
                          required
                          value={newMobile}
                          onChange={(e) => setNewMobile(e.target.value)}
                          placeholder="10-digit mobile"
                          className="w-full border border-gray-300 rounded-lg p-2 focus:ring-[#3949ab] focus:border-[#3949ab]"
                        />
                      </div>
                      <div>
                        <label className="block font-semibold text-gray-700 mb-1">Email Address</label>
                        <input
                          type="email"
                          value={newEmail}
                          onChange={(e) => setNewEmail(e.target.value)}
                          placeholder="work email"
                          className="w-full border border-gray-300 rounded-lg p-2 focus:ring-[#3949ab] focus:border-[#3949ab]"
                        />
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-3">
                      <div>
                        <label className="block font-semibold text-gray-700 mb-1">Assigned Role</label>
                        <select
                          value={newRole}
                          onChange={(e) =>
                            handleRoleChangeInModal(e.target.value as 'Admin' | 'Manager' | 'Staff')
                          }
                          className="w-full border border-gray-300 rounded-lg p-2 bg-white font-medium"
                        >
                          <option value="Staff">Field Staff (Executive)</option>
                          <option value="Manager">Manager (Team Leader)</option>
                          <option value="Admin">Administrator (Full Access)</option>
                        </select>
                      </div>
                      <div>
                        <label className="block font-semibold text-gray-700 mb-1">Reporting Head</label>
                        <select
                          value={newReportingHead}
                          onChange={(e) => setNewReportingHead(e.target.value)}
                          className="w-full border border-gray-300 rounded-lg p-2 bg-white font-medium"
                        >
                          {reportingHeadOptions.map((head) => (
                            <option key={head} value={head}>
                              {head}
                            </option>
                          ))}
                        </select>
                      </div>
                    </div>

                    <div className="pt-3 border-t border-gray-100 space-y-2.5">
                      <label className="flex items-center space-x-2.5 cursor-pointer p-2 rounded-lg hover:bg-gray-50 border border-gray-100">
                        <input
                          type="checkbox"
                          checked={newLocationTracking}
                          onChange={(e) => setNewLocationTracking(e.target.checked)}
                          className="rounded text-[#3949ab] focus:ring-[#3949ab]"
                        />
                        <div>
                          <span className="font-bold text-gray-800 block">
                            Enable Real-time GPS Location Tracking
                          </span>
                          <span className="text-[11px] text-gray-500">
                            Logs route history, distance traveled, and client check-in coordinates.
                          </span>
                        </div>
                      </label>

                      <label className="flex items-center space-x-2.5 cursor-pointer p-2 rounded-lg hover:bg-gray-50 border border-gray-100">
                        <input
                          type="checkbox"
                          checked={newIsActive}
                          onChange={(e) => setNewIsActive(e.target.checked)}
                          className="rounded text-[#3949ab] focus:ring-[#3949ab]"
                        />
                        <div>
                          <span className="font-bold text-gray-800 block">
                            Active Account Status
                          </span>
                          <span className="text-[11px] text-gray-500">
                            Allow user to log in to the mobile app and submit daily reports.
                          </span>
                        </div>
                      </label>
                    </div>
                  </div>
                )}

                {/* TAB B: GRANULAR PERMISSIONS (.permissions-module) */}
                {userModalTab === 'permissions' && (
                  <div className="space-y-4">
                    <div className="p-3 bg-blue-50/80 border border-blue-200 rounded-xl flex items-center justify-between">
                      <div className="flex items-center space-x-2">
                        <Shield className="w-4 h-4 text-[#3949ab]" />
                        <span className="text-gray-800 font-semibold">
                          Permissions configured for <strong className="text-[#3949ab]">{newRole}</strong> role
                        </span>
                      </div>
                      <button
                        type="button"
                        onClick={() => setNewPermissions(getDefaultPermissions(newRole))}
                        className="text-[11px] font-bold text-[#3949ab] hover:underline cursor-pointer"
                      >
                        Reset Role Defaults
                      </button>
                    </div>

                    {/* 1. Leads Module Permissions */}
                    <div className="p-3.5 bg-gray-50 rounded-xl border border-gray-200 space-y-2.5">
                      <div className="flex items-center justify-between border-b border-gray-200 pb-2">
                        <span className="font-bold text-gray-900 text-xs">Leads Management Access</span>
                        <div className="flex items-center space-x-2">
                          <label className="inline-flex items-center space-x-1 cursor-pointer">
                            <input
                              type="radio"
                              name="leads_view"
                              checked={newPermissions.leads_view === 'all'}
                              onChange={() =>
                                setNewPermissions({ ...newPermissions, leads_view: 'all' })
                              }
                              className="text-[#3949ab] focus:ring-[#3949ab]"
                            />
                            <span className="text-[11px] font-medium text-gray-700">View All Leads</span>
                          </label>
                          <label className="inline-flex items-center space-x-1 cursor-pointer">
                            <input
                              type="radio"
                              name="leads_view"
                              checked={newPermissions.leads_view === 'own'}
                              onChange={() =>
                                setNewPermissions({ ...newPermissions, leads_view: 'own' })
                              }
                              className="text-[#3949ab] focus:ring-[#3949ab]"
                            />
                            <span className="text-[11px] font-medium text-gray-700">Own Only</span>
                          </label>
                        </div>
                      </div>
                      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 pt-1">
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.leads_create}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, leads_create: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Create Leads</span>
                        </label>
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.leads_edit}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, leads_edit: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Edit Leads</span>
                        </label>
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.leads_delete}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, leads_delete: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Delete Leads</span>
                        </label>
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.leads_export}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, leads_export: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Excel Export</span>
                        </label>
                      </div>
                    </div>

                    {/* 2. Customers Module Permissions */}
                    <div className="p-3.5 bg-gray-50 rounded-xl border border-gray-200 space-y-2.5">
                      <div className="flex items-center justify-between border-b border-gray-200 pb-2">
                        <span className="font-bold text-gray-900 text-xs">Customers Directory Access</span>
                        <div className="flex items-center space-x-2">
                          <label className="inline-flex items-center space-x-1 cursor-pointer">
                            <input
                              type="radio"
                              name="customers_view"
                              checked={newPermissions.customers_view === 'all'}
                              onChange={() =>
                                setNewPermissions({ ...newPermissions, customers_view: 'all' })
                              }
                              className="text-[#3949ab] focus:ring-[#3949ab]"
                            />
                            <span className="text-[11px] font-medium text-gray-700">View All Customers</span>
                          </label>
                          <label className="inline-flex items-center space-x-1 cursor-pointer">
                            <input
                              type="radio"
                              name="customers_view"
                              checked={newPermissions.customers_view === 'own'}
                              onChange={() =>
                                setNewPermissions({ ...newPermissions, customers_view: 'own' })
                              }
                              className="text-[#3949ab] focus:ring-[#3949ab]"
                            />
                            <span className="text-[11px] font-medium text-gray-700">Own Only</span>
                          </label>
                        </div>
                      </div>
                      <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 pt-1">
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.customers_create}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, customers_create: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Add Customers</span>
                        </label>
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.customers_edit}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, customers_edit: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Edit Customer Profile</span>
                        </label>
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.customers_export}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, customers_export: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Excel Export</span>
                        </label>
                      </div>
                    </div>

                    {/* 3. Sales & Invoicing Permissions */}
                    <div className="p-3.5 bg-gray-50 rounded-xl border border-gray-200 space-y-2.5">
                      <div className="font-bold text-gray-900 text-xs border-b border-gray-200 pb-2">
                        Sales, Invoices & Payments Collection
                      </div>
                      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 pt-1">
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.sales_pfi}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, sales_pfi: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Create Proforma (PFI)</span>
                        </label>
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.sales_invoice}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, sales_invoice: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Generate Tax Invoice</span>
                        </label>
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.sales_payment}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, sales_payment: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Record Payments</span>
                        </label>
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.sales_export}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, sales_export: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Export Sales Data</span>
                        </label>
                      </div>
                    </div>

                    {/* 4. Visits & Field Tracking */}
                    <div className="p-3.5 bg-gray-50 rounded-xl border border-gray-200 space-y-2.5">
                      <div className="font-bold text-gray-900 text-xs border-b border-gray-200 pb-2">
                        Visits & GPS Attendance Tracking
                      </div>
                      <div className="grid grid-cols-2 gap-2 pt-1">
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.visits_tracking}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, visits_tracking: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Live GPS Location Tracking</span>
                        </label>
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.visits_routes}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, visits_routes: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Route & Daily Trail History</span>
                        </label>
                      </div>
                    </div>
                  </div>
                )}
              </div>

              {/* Modal Footer */}
              <div className="p-4 bg-gray-50 border-t border-gray-100 flex items-center justify-between">
                <div>
                  {userModalTab === 'profile' ? (
                    <button
                      type="button"
                      onClick={() => setUserModalTab('permissions')}
                      className="px-3 py-1.5 text-xs font-bold text-[#3949ab] hover:bg-[#3949ab]/10 rounded-lg transition-colors cursor-pointer"
                    >
                      Next: Permissions →
                    </button>
                  ) : (
                    <button
                      type="button"
                      onClick={() => setUserModalTab('profile')}
                      className="px-3 py-1.5 text-xs font-bold text-gray-600 hover:bg-gray-200 rounded-lg transition-colors cursor-pointer"
                    >
                      ← Back to Profile
                    </button>
                  )}
                </div>

                <div className="flex items-center space-x-2">
                  <button
                    type="button"
                    onClick={() => {
                      setIsUserModalOpen(false);
                      setEditingUser(null);
                    }}
                    className="px-4 py-2 border border-gray-300 rounded-lg font-semibold text-gray-700 hover:bg-gray-100 cursor-pointer"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={isSubmittingUser}
                    className="px-5 py-2 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-lg font-semibold flex items-center space-x-1.5 cursor-pointer disabled:opacity-50 shadow-xs"
                  >
                    {isSubmittingUser && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                    <span>{editingUser ? 'Save Changes' : 'Create Member'}</span>
                  </button>
                </div>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
