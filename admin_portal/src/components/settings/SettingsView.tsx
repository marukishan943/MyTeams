import React, { useState } from 'react';
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
} from 'lucide-react';
import type { TeamUser, CompanyConfig, ModuleVisibilityConfig, DashboardCardsConfig } from '../../types/crm';

interface SettingsViewProps {
  users: TeamUser[];
  onAddUser: (user: Partial<TeamUser>) => Promise<void>;
  onToggleTracking: (id: string) => void;
  onToggleActive: (id: string) => void;
  moduleVisibility?: ModuleVisibilityConfig;
  onToggleModule?: (key: keyof ModuleVisibilityConfig) => void;
  dashboardCards?: DashboardCardsConfig;
  onToggleCard?: (key: keyof DashboardCardsConfig) => void;
  onResetDefaults?: () => void;
}

export const SettingsView: React.FC<SettingsViewProps> = ({
  users,
  onAddUser,
  onToggleTracking,
  onToggleActive,
  moduleVisibility,
  onToggleModule,
  dashboardCards,
  onToggleCard,
  onResetDefaults,
}) => {
  const [activeTab, setActiveTab] = useState<
    'company' | 'users' | 'sales_settings' | 'templates' | 'modules'
  >('company');

  // Company Profile state
  const [company, setCompany] = useState<CompanyConfig>({
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
  });

  const [savedSuccess, setSavedSuccess] = useState(false);

  // New User Modal state
  const [isUserModalOpen, setIsUserModalOpen] = useState(false);
  const [newFirstName, setNewFirstName] = useState('');
  const [newLastName, setNewLastName] = useState('');
  const [newMobile, setNewMobile] = useState('');
  const [newEmail, setNewEmail] = useState('');
  const [newRole, setNewRole] = useState<'Admin' | 'Manager' | 'Staff'>('Staff');
  const [newReportingHead, setNewReportingHead] = useState('ADMIN ADMIN');

  const handleSaveCompany = (e: React.FormEvent) => {
    e.preventDefault();
    localStorage.setItem('myteams_company_config', JSON.stringify(company));
    setSavedSuccess(true);
    setTimeout(() => setSavedSuccess(false), 3000);
  };

  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newFirstName.trim() || !newMobile.trim()) return;

    await onAddUser({
      first_name: newFirstName,
      last_name: newLastName,
      mobile: newMobile,
      email: newEmail,
      role: newRole,
      reporting_head: newReportingHead,
      location_tracking: true,
      is_active: true,
    });

    setIsUserModalOpen(false);
    setNewFirstName('');
    setNewLastName('');
    setNewMobile('');
    setNewEmail('');
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
        <div className="bg-white rounded-xl border border-gray-200 shadow-2xs overflow-hidden">
          <div className="p-4 border-b border-gray-100 flex items-center justify-between">
            <div>
              <h3 className="font-bold text-sm text-gray-900">Field Team & User Hierarchy</h3>
              <p className="text-gray-500 text-[11px]">Configured team members, reporting structure, and GPS location tracking</p>
            </div>
            <button
              onClick={() => setIsUserModalOpen(true)}
              className="inline-flex items-center space-x-1.5 px-3.5 py-2 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-lg text-xs font-semibold shadow-xs cursor-pointer"
            >
              <Plus className="w-4 h-4" />
              <span>Add User</span>
            </button>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs text-gray-700">
              <thead className="bg-gray-50 text-gray-500 font-semibold uppercase text-[11px]">
                <tr>
                  <th className="px-4 py-3">ID</th>
                  <th className="px-4 py-3">Member Name</th>
                  <th className="px-4 py-3">Mobile</th>
                  <th className="px-4 py-3">Email</th>
                  <th className="px-4 py-3">Role</th>
                  <th className="px-4 py-3">Reporting Head</th>
                  <th className="px-4 py-3 text-center">GPS Tracking</th>
                  <th className="px-4 py-3 text-center">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {users.map((u) => (
                  <tr key={u.id} className="hover:bg-gray-50/70">
                    <td className="px-4 py-3 font-mono font-bold text-gray-900">#{u.user_code}</td>
                    <td className="px-4 py-3">
                      <div className="flex items-center space-x-2">
                        <div className="w-7 h-7 rounded-full bg-[#3949ab] text-white font-bold flex items-center justify-center text-[10px]">
                          {u.first_name[0]}{u.last_name[0]}
                        </div>
                        <span className="font-bold text-gray-900">{u.first_name} {u.last_name}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-gray-800">{u.mobile}</td>
                    <td className="px-4 py-3 text-gray-600">{u.email}</td>
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
                    <td className="px-4 py-3 text-gray-600">{u.reporting_head}</td>
                    <td className="px-4 py-3 text-center">
                      <button
                        onClick={() => onToggleTracking(u.id)}
                        className="cursor-pointer inline-flex items-center gap-1 font-semibold text-xs"
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
                    </td>
                    <td className="px-4 py-3 text-center">
                      <button
                        onClick={() => onToggleActive(u.id)}
                        className={`px-2.5 py-0.5 rounded-full text-[11px] font-semibold cursor-pointer ${
                          u.is_active
                            ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                            : 'bg-rose-50 text-rose-700 border border-rose-200'
                        }`}
                      >
                        {u.is_active ? 'Active' : 'Inactive'}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
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
              </h3>
              <p className="text-gray-500 text-[11px]">
                Enable or disable system modules and dashboard widgets for your workspace.
              </p>
            </div>
            {onResetDefaults && (
              <button
                type="button"
                onClick={onResetDefaults}
                className="inline-flex items-center space-x-1.5 px-3 py-1.5 border border-gray-200 text-gray-700 hover:bg-gray-50 rounded-lg text-xs font-semibold transition-colors cursor-pointer"
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
                    onClick={() => onToggleModule && onToggleModule(m.key)}
                    className="p-3.5 rounded-xl border border-gray-200 bg-gray-50/50 hover:bg-white hover:border-[#3949ab]/40 transition-all flex items-center justify-between cursor-pointer"
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
                      {isVisible ? (
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
                    onClick={() => onToggleCard && onToggleCard(c.key)}
                    className="p-3 rounded-lg border border-gray-200 bg-gray-50/50 hover:bg-white hover:border-[#3949ab]/40 transition-all flex items-center justify-between cursor-pointer"
                  >
                    <span className={`font-semibold ${isVisible ? 'text-gray-900' : 'text-gray-400'}`}>
                      {c.label}
                    </span>
                    <div className="shrink-0">
                      {isVisible ? (
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

      {/* ADD USER MODAL */}
      {isUserModalOpen && (
        <div className="fixed inset-0 z-50 overflow-y-auto bg-black/50 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-2xl w-full max-w-md p-6 border border-gray-100 space-y-4 text-xs animate-in fade-in zoom-in-95">
            <h3 className="text-base font-bold text-gray-900">Add Field Staff / User</h3>
            <form onSubmit={handleCreateUser} className="space-y-3">
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block font-semibold text-gray-700 mb-1">First Name *</label>
                  <input
                    type="text"
                    required
                    value={newFirstName}
                    onChange={(e) => setNewFirstName(e.target.value)}
                    className="w-full border border-gray-300 rounded-lg p-2"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-gray-700 mb-1">Last Name</label>
                  <input
                    type="text"
                    value={newLastName}
                    onChange={(e) => setNewLastName(e.target.value)}
                    className="w-full border border-gray-300 rounded-lg p-2"
                  />
                </div>
              </div>
              <div>
                <label className="block font-semibold text-gray-700 mb-1">Mobile Number *</label>
                <input
                  type="text"
                  required
                  value={newMobile}
                  onChange={(e) => setNewMobile(e.target.value)}
                  className="w-full border border-gray-300 rounded-lg p-2"
                />
              </div>
              <div>
                <label className="block font-semibold text-gray-700 mb-1">Email Address</label>
                <input
                  type="email"
                  value={newEmail}
                  onChange={(e) => setNewEmail(e.target.value)}
                  className="w-full border border-gray-300 rounded-lg p-2"
                />
              </div>
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block font-semibold text-gray-700 mb-1">Role</label>
                  <select
                    value={newRole}
                    onChange={(e) => setNewRole(e.target.value as 'Admin' | 'Manager' | 'Staff')}
                    className="w-full border border-gray-300 rounded-lg p-2"
                  >
                    <option value="Staff">Staff</option>
                    <option value="Manager">Manager</option>
                    <option value="Admin">Admin</option>
                  </select>
                </div>
                <div>
                  <label className="block font-semibold text-gray-700 mb-1">Reporting Head</label>
                  <select
                    value={newReportingHead}
                    onChange={(e) => setNewReportingHead(e.target.value)}
                    className="w-full border border-gray-300 rounded-lg p-2"
                  >
                    <option value="ADMIN ADMIN">ADMIN ADMIN</option>
                    <option value="JITESHBHAI VASANIYA">JITESHBHAI VASANIYA</option>
                  </select>
                </div>
              </div>
              <div className="pt-3 flex justify-end space-x-2">
                <button
                  type="button"
                  onClick={() => setIsUserModalOpen(false)}
                  className="px-4 py-2 border border-gray-300 rounded-lg font-semibold text-gray-700"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-[#3949ab] text-white rounded-lg font-semibold"
                >
                  Create Member
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
