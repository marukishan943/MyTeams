import React, { useState, useRef, useEffect } from 'react';
import {
  Target,
  Users,
  FileText,
  TrendingUp,
  Plus,
  ArrowRight,
  Phone,
  Building,
  CheckCircle,
  Clock,
  Calendar,
  ListTodo,
  ChevronDown,
  SlidersHorizontal,
  RotateCcw,
  Bell,
  Loader2,
} from 'lucide-react';
import type { Lead, Customer, SalesOrder, DashboardCardsConfig, ModuleVisibilityConfig } from '../../types/crm';

interface DashboardViewProps {
  leads: Lead[];
  customers: Customer[];
  orders: SalesOrder[];
  onNavigateTab: (tab: string) => void;
  onOpenAddLead: () => void;
  onOpenAddCustomer: () => void;
  onOpenAddOrder: () => void;
  onSelectLead: (lead: Lead) => void;
  onSelectOrder: (order: SalesOrder) => void;
  cardsConfig: DashboardCardsConfig;
  onToggleCard: (key: keyof DashboardCardsConfig) => void;
  onResetCards: () => void;
  onSetAllCards: (visible: boolean) => void;
  moduleVisibility?: ModuleVisibilityConfig;
  isSaving?: boolean;
}

export const DashboardView: React.FC<DashboardViewProps> = ({
  leads,
  customers,
  orders,
  onNavigateTab,
  onOpenAddLead,
  onOpenAddCustomer,
  onOpenAddOrder,
  onSelectLead,
  onSelectOrder,
  cardsConfig,
  onToggleCard,
  onResetCards,
  onSetAllCards,
  isSaving = false,
  moduleVisibility = {
    leads: true,
    customers: true,
    sales: true,
    expenses: true,
    reports: true,
    settings: true,
  },
}) => {
  const [showCardsDropdown, setShowCardsDropdown] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Close dropdown on click outside
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setShowCardsDropdown(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Statistics Calculations
  const totalLeads = leads.length;
  const convertedLeads = leads.filter((l) => l.stage === 'converted').length;
  const newLeads = leads.filter((l) => l.stage === 'newLead').length;
  const contactedLeads = leads.filter((l) => l.stage === 'contacted').length;
  const proposalLeads = leads.filter((l) => l.stage === 'proposalSent').length;
  const sampleLeads = leads.filter((l) => l.stage === 'sampleSent').length;
  const disqualifiedLeads = leads.filter((l) => l.stage === 'disqualified').length;

  const totalCustomers = customers.length;
  const activeCustomers = customers.filter((c) => c.status === 'Active').length;

  const invoices = orders.filter((o) => o.type === 'invoice');
  const proformaInvoices = orders.filter((o) => o.type === 'proforma_invoice');
  const regularOrders = orders.filter((o) => o.type === 'order');

  const totalInvoiceRevenue = invoices.reduce((sum, o) => sum + (o.total_amount || 0), 0);
  const totalOrdersValue = regularOrders.reduce((sum, o) => sum + (o.total_amount || 0), 0);

  const formatCurrency = (val: number) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      maximumFractionDigits: 0,
    }).format(val);
  };

  const getStageBadge = (stage: Lead['stage']) => {
    switch (stage) {
      case 'newLead':
        return <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-blue-50 text-blue-700 border border-blue-200">New Lead</span>;
      case 'contacted':
        return <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-200">Contacted</span>;
      case 'proposalSent':
        return <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-purple-50 text-purple-700 border border-purple-200">Proposal Sent</span>;
      case 'sampleSent':
        return <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-indigo-50 text-indigo-700 border border-indigo-200">Sample Sent</span>;
      case 'converted':
        return <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">Converted</span>;
      case 'disqualified':
        return <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-gray-100 text-gray-700 border border-gray-200">Disqualified</span>;
      default:
        return null;
    }
  };

  const cardDefinitions: {
    key: keyof DashboardCardsConfig;
    label: string;
    icon: React.ElementType;
    moduleKey?: keyof ModuleVisibilityConfig;
  }[] = [
    { key: 'quickStats', label: 'Metric KPI Cards', icon: TrendingUp },
    { key: 'leadsChart', label: 'Leads Stage Funnel', icon: Target, moduleKey: 'leads' },
    { key: 'attendanceChart', label: 'Attendance & Punch Status', icon: Clock },
    { key: 'visitsChart', label: 'Field Client Visits', icon: Calendar },
    { key: 'tasksChart', label: 'Field Tasks Breakdown', icon: ListTodo },
    { key: 'callsSummary', label: 'Calls & Communications', icon: Phone },
    { key: 'visitsList', label: 'Recent Leads Feed', icon: Target, moduleKey: 'leads' },
    { key: 'ordersList', label: 'Recent Invoices & Orders', icon: FileText, moduleKey: 'sales' },
    { key: 'customerReminders', label: 'Customer Reminders', icon: Bell, moduleKey: 'customers' },
  ];

  const availableCardDefinitions = cardDefinitions.filter(
    (card) => !card.moduleKey || moduleVisibility[card.moduleKey] !== false
  );

  const visibleCardsCount = availableCardDefinitions.filter((card) => cardsConfig[card.key]).length;
  const totalCardsCount = availableCardDefinitions.length;

  return (
    <div className="space-y-6">
      {/* MyTeams Quick Action & Widget Control Bar */}
      <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-2xs flex flex-wrap items-center justify-between gap-3">
        <div>
          <h2 className="text-base font-bold text-gray-900 flex items-center gap-2">
            <span>Field Force & CRM Command Center</span>
          </h2>
          <p className="text-xs text-gray-500">
            Real-time pipeline overview, customer accounts, and revenue orders.
          </p>
        </div>

        <div className="flex items-center gap-2 flex-wrap">
          {/* EXACT #showCardsDropdown */}
          <div className="relative" ref={dropdownRef}>
            <button
              id="showCardsDropdown"
              onClick={() => setShowCardsDropdown(!showCardsDropdown)}
              className="inline-flex items-center space-x-1.5 px-3 py-2 bg-gray-50 hover:bg-gray-100 border border-gray-300 text-gray-700 rounded-lg text-xs font-semibold transition-colors cursor-pointer"
            >
              <SlidersHorizontal className="w-3.5 h-3.5 text-[#3949ab]" />
              <span>Show / Hide Cards</span>
              <span className="text-[10px] px-1.5 py-0.2 rounded-full bg-[#3949ab]/10 text-[#3949ab] font-bold">
                {visibleCardsCount}/{totalCardsCount}
              </span>
              <ChevronDown className="w-3.5 h-3.5 text-gray-400" />
            </button>

            {/* Dropdown Checklist Menu */}
            {showCardsDropdown && (
              <div className="absolute right-0 mt-2 w-72 bg-white rounded-xl shadow-xl border border-gray-200 z-50 p-3 space-y-2 animate-in fade-in zoom-in-95 duration-150">
                <div className="flex items-center justify-between pb-2 border-b border-gray-100">
                  <span className="text-xs font-bold text-gray-800 flex items-center gap-1.5">
                    <span>Dashboard Widgets</span>
                    {isSaving && <Loader2 className="w-3 h-3 text-[#3949ab] animate-spin" />}
                  </span>
                  <div className="flex items-center space-x-2 text-[11px]">
                    <button
                      onClick={() => !isSaving && onSetAllCards(true)}
                      disabled={isSaving}
                      className={isSaving ? 'text-gray-300 cursor-not-allowed' : 'text-[#3949ab] hover:underline font-semibold cursor-pointer'}
                    >
                      Show All
                    </button>
                    <span className="text-gray-300">•</span>
                    <button
                      onClick={() => !isSaving && onResetCards()}
                      disabled={isSaving}
                      className={isSaving ? 'text-gray-300 cursor-not-allowed flex items-center gap-0.5' : 'text-gray-500 hover:text-gray-700 flex items-center gap-0.5 cursor-pointer'}
                    >
                      <RotateCcw className="w-3 h-3" />
                      Reset
                    </button>
                  </div>
                </div>

                <div className="space-y-1 max-h-64 overflow-y-auto pr-1">
                  {availableCardDefinitions.map((card) => {
                    const isVisible = cardsConfig[card.key];
                    const Icon = card.icon;
                    return (
                      <label
                        key={card.key}
                        onClick={() => !isSaving && onToggleCard(card.key)}
                        className={`flex items-center justify-between p-2 rounded-lg text-xs transition-colors ${
                          isSaving ? 'opacity-60 cursor-not-allowed' : 'hover:bg-gray-50 cursor-pointer'
                        }`}
                      >
                        <div className="flex items-center space-x-2 text-gray-700">
                          <Icon className="w-3.5 h-3.5 text-gray-400" />
                          <span className={isVisible ? 'font-medium text-gray-900' : 'text-gray-400'}>
                            {card.label}
                          </span>
                        </div>
                        <input
                          type="checkbox"
                          checked={isVisible}
                          disabled={isSaving}
                          onChange={() => {}}
                          className={`w-4 h-4 text-[#3949ab] rounded-sm border-gray-300 focus:ring-[#3949ab] ${
                            isSaving ? 'cursor-not-allowed' : 'cursor-pointer'
                          }`}
                        />
                      </label>
                    );
                  })}
                </div>

                <div className="pt-2 border-t border-gray-100 text-[10px] text-gray-400 text-center">
                  Check or uncheck cards to customize your dashboard
                </div>
              </div>
            )}
          </div>

          {moduleVisibility.leads !== false && (
            <button
              onClick={onOpenAddLead}
              className="inline-flex items-center space-x-1.5 px-3.5 py-2 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-lg text-xs font-semibold shadow-xs transition-colors cursor-pointer"
            >
              <Plus className="w-4 h-4" />
              <span>Add Lead</span>
            </button>
          )}
          {moduleVisibility.customers !== false && (
            <button
              onClick={onOpenAddCustomer}
              className="inline-flex items-center space-x-1.5 px-3.5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-semibold shadow-xs transition-colors cursor-pointer"
            >
              <Plus className="w-4 h-4" />
              <span>Add Customer</span>
            </button>
          )}
          {moduleVisibility.sales !== false && (
            <button
              onClick={onOpenAddOrder}
              className="inline-flex items-center space-x-1.5 px-3.5 py-2 bg-slate-800 hover:bg-slate-900 text-white rounded-lg text-xs font-semibold shadow-xs transition-colors cursor-pointer"
            >
              <Plus className="w-4 h-4" />
              <span>Create Invoice</span>
            </button>
          )}
        </div>
      </div>

      {/* 1. MyTeams-Style Metric KPI Cards (quickStats) */}
      {(() => {
        const showLeadsMetric = moduleVisibility.leads !== false;
        const showCustomersMetric = moduleVisibility.customers !== false;
        const showInvoicesMetric = moduleVisibility.sales !== false;
        const showOrdersMetric = moduleVisibility.sales !== false;
        const visibleKpiCount =
          (showLeadsMetric ? 1 : 0) +
          (showCustomersMetric ? 1 : 0) +
          (showInvoicesMetric ? 1 : 0) +
          (showOrdersMetric ? 1 : 0);

        if (!cardsConfig.quickStats || visibleKpiCount === 0) return null;

        return (
          <div
            className={`grid grid-cols-1 ${
              visibleKpiCount >= 2 ? 'sm:grid-cols-2' : ''
            } ${
              visibleKpiCount >= 4
                ? 'lg:grid-cols-4'
                : visibleKpiCount === 3
                ? 'lg:grid-cols-3'
                : ''
            } gap-4`}
          >
            {/* Metric 1: Leads */}
            {showLeadsMetric && (
              <div
                onClick={() => onNavigateTab('leads')}
                className="bg-white p-5 rounded-xl border border-gray-200 shadow-2xs hover:border-[#3949ab]/40 transition-all cursor-pointer group"
              >
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold text-gray-500 uppercase tracking-wider">
                    Total Leads
                  </span>
                  <div className="w-9 h-9 rounded-lg bg-blue-50 text-[#3949ab] flex items-center justify-center group-hover:bg-[#3949ab] group-hover:text-white transition-colors">
                    <Target className="w-5 h-5" />
                  </div>
                </div>
                <div className="mt-3 flex items-baseline justify-between">
                  <span className="text-2xl font-bold text-gray-900">{totalLeads}</span>
                  <span className="text-xs font-semibold text-emerald-600 flex items-center gap-0.5">
                    <CheckCircle className="w-3.5 h-3.5" />
                    {convertedLeads} Converted
                  </span>
                </div>
                <div className="mt-4 pt-3 border-t border-gray-100 flex items-center justify-between text-[11px] text-gray-500">
                  <span>New: <b>{newLeads}</b></span>
                  <span>Contacted: <b>{contactedLeads}</b></span>
                  <span>Proposal: <b>{proposalLeads}</b></span>
                </div>
              </div>
            )}

            {/* Metric 2: Customers */}
            {showCustomersMetric && (
              <div
                onClick={() => onNavigateTab('customers')}
                className="bg-white p-5 rounded-xl border border-gray-200 shadow-2xs hover:border-emerald-500/40 transition-all cursor-pointer group"
              >
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold text-gray-500 uppercase tracking-wider">
                    Customers
                  </span>
                  <div className="w-9 h-9 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center group-hover:bg-emerald-600 group-hover:text-white transition-colors">
                    <Users className="w-5 h-5" />
                  </div>
                </div>
                <div className="mt-3 flex items-baseline justify-between">
                  <span className="text-2xl font-bold text-gray-900">{totalCustomers}</span>
                  <span className="text-xs font-medium text-gray-500">
                    {activeCustomers} Active Accounts
                  </span>
                </div>
                <div className="mt-4 pt-3 border-t border-gray-100 flex items-center justify-between text-[11px] text-gray-500">
                  <span>Retailers & Distributors</span>
                  <span className="text-emerald-600 font-semibold flex items-center">
                    View List <ArrowRight className="w-3 h-3 ml-0.5" />
                  </span>
                </div>
              </div>
            )}

            {/* Metric 3: Invoices Revenue */}
            {showInvoicesMetric && (
              <div
                onClick={() => onNavigateTab('sales')}
                className="bg-white p-5 rounded-xl border border-gray-200 shadow-2xs hover:border-purple-500/40 transition-all cursor-pointer group"
              >
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold text-gray-500 uppercase tracking-wider">
                    Total Invoiced
                  </span>
                  <div className="w-9 h-9 rounded-lg bg-purple-50 text-purple-600 flex items-center justify-center group-hover:bg-purple-600 group-hover:text-white transition-colors">
                    <TrendingUp className="w-5 h-5" />
                  </div>
                </div>
                <div className="mt-3 flex items-baseline justify-between">
                  <span className="text-2xl font-bold text-gray-900">
                    {formatCurrency(totalInvoiceRevenue)}
                  </span>
                  <span className="text-xs text-gray-500">
                    {invoices.length} Invoices
                  </span>
                </div>
                <div className="mt-4 pt-3 border-t border-gray-100 flex items-center justify-between text-[11px] text-gray-500">
                  <span>Proforma: <b>{proformaInvoices.length}</b></span>
                  <span>Orders: <b>{regularOrders.length}</b></span>
                </div>
              </div>
            )}

            {/* Metric 4: Orders Value */}
            {showOrdersMetric && (
              <div
                onClick={() => onNavigateTab('sales')}
                className="bg-white p-5 rounded-xl border border-gray-200 shadow-2xs hover:border-amber-500/40 transition-all cursor-pointer group"
              >
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold text-gray-500 uppercase tracking-wider">
                    Orders Pipeline
                  </span>
                  <div className="w-9 h-9 rounded-lg bg-amber-50 text-amber-600 flex items-center justify-center group-hover:bg-amber-600 group-hover:text-white transition-colors">
                    <FileText className="w-5 h-5" />
                  </div>
                </div>
                <div className="mt-3 flex items-baseline justify-between">
                  <span className="text-2xl font-bold text-gray-900">
                    {formatCurrency(totalOrdersValue)}
                  </span>
                  <span className="text-xs font-semibold text-amber-600">
                    Active Orders
                  </span>
                </div>
                <div className="mt-4 pt-3 border-t border-gray-100 flex items-center justify-between text-[11px] text-gray-500">
                  <span>Live Field Bookings</span>
                  <span className="text-amber-600 font-semibold flex items-center">
                    Inspect <ArrowRight className="w-3 h-3 ml-0.5" />
                  </span>
                </div>
              </div>
            )}
          </div>
        );
      })()}

      {/* 2. MyTeams Funnel & Operations Blocks (leadsChart, attendanceChart, visitsChart, tasksChart, callsSummary) */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {/* Leads Pipeline Funnel */}
        {cardsConfig.leadsChart && moduleVisibility.leads !== false && (
          <div className="bg-white p-5 rounded-xl border border-gray-200 shadow-2xs space-y-4">
            <div className="flex items-center justify-between border-b border-gray-100 pb-3">
              <div className="flex items-center space-x-2">
                <Target className="w-4 h-4 text-[#3949ab]" />
                <h3 className="font-bold text-sm text-gray-900">Leads Pipeline Funnel</h3>
              </div>
              <span className="text-[11px] text-emerald-600 font-bold bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200">
                {totalLeads > 0 ? ((convertedLeads / totalLeads) * 100).toFixed(0) : 0}% Won
              </span>
            </div>
            <div className="space-y-2.5 text-xs">
              {[
                { label: 'New Inquiries', count: newLeads, color: 'bg-blue-500' },
                { label: 'Contacted', count: contactedLeads, color: 'bg-amber-500' },
                { label: 'Proposal Sent', count: proposalLeads, color: 'bg-purple-500' },
                { label: 'Sample Sent', count: sampleLeads, color: 'bg-indigo-500' },
                { label: 'Converted Customers', count: convertedLeads, color: 'bg-emerald-500' },
                { label: 'Disqualified', count: disqualifiedLeads, color: 'bg-gray-400' },
              ].map((item) => {
                const pct = totalLeads > 0 ? (item.count / totalLeads) * 100 : 0;
                return (
                  <div key={item.label} className="space-y-1">
                    <div className="flex justify-between font-semibold text-gray-700">
                      <span>{item.label}</span>
                      <span>{item.count} ({pct.toFixed(0)}%)</span>
                    </div>
                    <div className="w-full bg-gray-100 rounded-full h-1.5">
                      <div className={`${item.color} h-1.5 rounded-full`} style={{ width: `${pct}%` }} />
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* Field Attendance Status */}
        {cardsConfig.attendanceChart && (
          <div className="bg-white p-5 rounded-xl border border-gray-200 shadow-2xs space-y-4">
            <div className="flex items-center justify-between border-b border-gray-100 pb-3">
              <div className="flex items-center space-x-2">
                <Clock className="w-4 h-4 text-emerald-600" />
                <h3 className="font-bold text-sm text-gray-900">Attendance Status</h3>
              </div>
              <span className="text-[11px] text-gray-500">Geo Punch-in</span>
            </div>
            <div className="grid grid-cols-3 gap-2 text-center pt-2">
              <div className="p-3 bg-emerald-50 rounded-xl border border-emerald-100">
                <span className="text-[10px] font-bold text-emerald-700 uppercase">Present</span>
                <div className="text-xl font-black text-emerald-800 mt-1">3</div>
                <span className="text-[10px] text-emerald-600 mt-0.5 block">On Duty</span>
              </div>
              <div className="p-3 bg-amber-50 rounded-xl border border-amber-100">
                <span className="text-[10px] font-bold text-amber-700 uppercase">On Leave</span>
                <div className="text-xl font-black text-amber-800 mt-1">1</div>
                <span className="text-[10px] text-amber-600 mt-0.5 block">Approved</span>
              </div>
              <div className="p-3 bg-gray-50 rounded-xl border border-gray-200">
                <span className="text-[10px] font-bold text-gray-600 uppercase">Absent</span>
                <div className="text-xl font-black text-gray-700 mt-1">0</div>
                <span className="text-[10px] text-gray-500 mt-0.5 block">No Punch</span>
              </div>
            </div>
            <div className="p-3 bg-blue-50/60 rounded-lg text-xs text-blue-800 flex items-center justify-between">
              <span>Avg Punch-in Time: <b>09:12 AM</b></span>
              <span className="font-semibold text-[#3949ab]">Live GPS Active</span>
            </div>
          </div>
        )}

        {/* Field Client Visits */}
        {cardsConfig.visitsChart && (
          <div className="bg-white p-5 rounded-xl border border-gray-200 shadow-2xs space-y-4">
            <div className="flex items-center justify-between border-b border-gray-100 pb-3">
              <div className="flex items-center space-x-2">
                <Calendar className="w-4 h-4 text-[#3949ab]" />
                <h3 className="font-bold text-sm text-gray-900">Client Field Visits</h3>
              </div>
              <span className="text-[11px] text-gray-500">Today</span>
            </div>
            <div className="space-y-3 pt-1 text-xs">
              <div className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
                <span className="font-medium text-gray-700">Completed Client Check-ins</span>
                <span className="font-bold text-base text-gray-900">18 Visits</span>
              </div>
              <div className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
                <span className="font-medium text-gray-700">Total Distance Logged</span>
                <span className="font-bold text-base text-emerald-600">108.7 Km</span>
              </div>
              <div className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
                <span className="font-medium text-gray-700">Pending Scheduled Stops</span>
                <span className="font-bold text-base text-amber-600">4 Stops</span>
              </div>
            </div>
          </div>
        )}

        {/* Field Tasks Breakdown */}
        {cardsConfig.tasksChart && (
          <div className="bg-white p-5 rounded-xl border border-gray-200 shadow-2xs space-y-4">
            <div className="flex items-center justify-between border-b border-gray-100 pb-3">
              <div className="flex items-center space-x-2">
                <ListTodo className="w-4 h-4 text-indigo-600" />
                <h3 className="font-bold text-sm text-gray-900">Field Tasks</h3>
              </div>
              <span className="text-[11px] text-indigo-600 font-bold bg-indigo-50 px-2 py-0.5 rounded-full">
                85% Done
              </span>
            </div>
            <div className="space-y-2.5 text-xs pt-1">
              <div className="flex items-center justify-between p-2.5 bg-gray-50 rounded-lg">
                <span className="text-gray-700 font-medium">Follow-up with Architect</span>
                <span className="px-2 py-0.5 text-[10px] font-bold bg-emerald-100 text-emerald-800 rounded-sm">Done</span>
              </div>
              <div className="flex items-center justify-between p-2.5 bg-gray-50 rounded-lg">
                <span className="text-gray-700 font-medium">Deliver Structural Catalog</span>
                <span className="px-2 py-0.5 text-[10px] font-bold bg-emerald-100 text-emerald-800 rounded-sm">Done</span>
              </div>
              <div className="flex items-center justify-between p-2.5 bg-gray-50 rounded-lg">
                <span className="text-gray-700 font-medium">Site Measurement & Verification</span>
                <span className="px-2 py-0.5 text-[10px] font-bold bg-amber-100 text-amber-800 rounded-sm">Pending</span>
              </div>
            </div>
          </div>
        )}

        {/* Calls & Communications */}
        {cardsConfig.callsSummary && (
          <div className="bg-white p-5 rounded-xl border border-gray-200 shadow-2xs space-y-4">
            <div className="flex items-center justify-between border-b border-gray-100 pb-3">
              <div className="flex items-center space-x-2">
                <Phone className="w-4 h-4 text-emerald-600" />
                <h3 className="font-bold text-sm text-gray-900">Calls Summary</h3>
              </div>
              <span className="text-[11px] text-gray-500">Telephony Log</span>
            </div>
            <div className="grid grid-cols-2 gap-3 text-center pt-1">
              <div className="p-3 bg-gray-50 rounded-lg border border-gray-100">
                <span className="text-[10px] uppercase font-bold text-gray-400">Total Outbound</span>
                <div className="text-2xl font-bold text-gray-900 mt-1">42</div>
                <span className="text-[10px] text-gray-500">Calls Logged</span>
              </div>
              <div className="p-3 bg-emerald-50 rounded-lg border border-emerald-100">
                <span className="text-[10px] uppercase font-bold text-emerald-700">Connected</span>
                <div className="text-2xl font-bold text-emerald-800 mt-1">31</div>
                <span className="text-[10px] text-emerald-600">74% Connect Rate</span>
              </div>
            </div>
            <div className="text-xs text-gray-500 p-2.5 bg-gray-50 rounded-lg flex justify-between">
              <span>Avg Talk Duration:</span>
              <b className="text-gray-800">3m 45s</b>
            </div>
          </div>
        )}

        {/* Customer Reminders */}
        {cardsConfig.customerReminders && (
          <div className="bg-white p-5 rounded-xl border border-gray-200 shadow-2xs space-y-4">
            <div className="flex items-center justify-between border-b border-gray-100 pb-3">
              <div className="flex items-center space-x-2">
                <Bell className="w-4 h-4 text-amber-600" />
                <h3 className="font-bold text-sm text-gray-900">Customer Reminders</h3>
              </div>
              <span className="text-[11px] text-amber-700 font-bold bg-amber-50 px-2 py-0.5 rounded-full border border-amber-200">
                3 Pending
              </span>
            </div>
            <div className="space-y-2 text-xs pt-1">
              <div className="p-2.5 bg-amber-50/60 rounded-lg border border-amber-100 space-y-0.5">
                <div className="font-bold text-gray-800">Payment Reminder: INV-2026-001</div>
                <div className="text-gray-500 text-[11px]">Due Today • Apex Infrastructure (₹45,000)</div>
              </div>
              <div className="p-2.5 bg-blue-50/60 rounded-lg border border-blue-100 space-y-0.5">
                <div className="font-bold text-gray-800">Quotation Follow-up: PFI-2026-004</div>
                <div className="text-gray-500 text-[11px]">Due Tomorrow • Sun Real Estate</div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* 3. Two Column Section: Recent Leads & Recent Sales (visitsList & ordersList) */}
      {((cardsConfig.visitsList && moduleVisibility.leads !== false) ||
        (cardsConfig.ordersList && moduleVisibility.sales !== false)) && (
        <div
          className={`grid grid-cols-1 ${
            cardsConfig.visitsList &&
            moduleVisibility.leads !== false &&
            cardsConfig.ordersList &&
            moduleVisibility.sales !== false
              ? 'lg:grid-cols-2'
              : ''
          } gap-6`}
        >
          {/* Recent Leads Widget (visitsList) */}
          {cardsConfig.visitsList && moduleVisibility.leads !== false && (
            <div className="bg-white rounded-xl border border-gray-200 shadow-2xs overflow-hidden">
              <div className="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <Target className="w-4 h-4 text-[#3949ab]" />
                  <h3 className="font-bold text-sm text-gray-900">Recent Leads</h3>
                </div>
                <button
                  onClick={() => onNavigateTab('leads')}
                  className="text-xs font-semibold text-[#3949ab] hover:underline flex items-center cursor-pointer"
                >
                  View All ({leads.length}) <ArrowRight className="w-3 h-3 ml-1" />
                </button>
              </div>
              <div className="divide-y divide-gray-100 max-h-96 overflow-y-auto">
                {leads.slice(0, 6).map((lead) => (
                  <div
                    key={lead.id}
                    onClick={() => onSelectLead(lead)}
                    className="p-4 hover:bg-gray-50/80 transition-colors cursor-pointer flex items-center justify-between"
                  >
                    <div className="min-w-0 pr-3">
                      <div className="flex items-center space-x-2">
                        <span className="text-xs font-bold text-gray-900 truncate">
                          {lead.name}
                        </span>
                        <span className="text-[10px] bg-gray-100 text-gray-600 px-1.5 py-0.5 rounded-sm font-mono">
                          #{lead.lead_number}
                        </span>
                      </div>
                      <div className="flex items-center gap-3 mt-1 text-xs text-gray-500">
                        {lead.company && (
                          <span className="flex items-center gap-1 truncate">
                            <Building className="w-3 h-3 text-gray-400 shrink-0" />
                            {lead.company}
                          </span>
                        )}
                        <span className="flex items-center gap-1">
                          <Phone className="w-3 h-3 text-gray-400 shrink-0" />
                          {lead.phone}
                        </span>
                      </div>
                    </div>
                    <div className="text-right shrink-0">
                      {getStageBadge(lead.stage)}
                      <div className="text-[10px] text-gray-400 mt-1">
                        {lead.staff_name || 'Unassigned'}
                      </div>
                    </div>
                  </div>
                ))}
                {leads.length === 0 && (
                  <div className="p-8 text-center text-sm text-gray-400">
                    No leads recorded yet.
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Recent Invoices & Orders Widget (ordersList) */}
          {cardsConfig.ordersList && moduleVisibility.sales !== false && (
            <div className="bg-white rounded-xl border border-gray-200 shadow-2xs overflow-hidden">
              <div className="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <FileText className="w-4 h-4 text-purple-600" />
                  <h3 className="font-bold text-sm text-gray-900">
                    Recent Invoices & Orders
                  </h3>
                </div>
                <button
                  onClick={() => onNavigateTab('sales')}
                  className="text-xs font-semibold text-purple-600 hover:underline flex items-center cursor-pointer"
                >
                  View All ({orders.length}) <ArrowRight className="w-3 h-3 ml-1" />
                </button>
              </div>
              <div className="divide-y divide-gray-100 max-h-96 overflow-y-auto">
                {orders.slice(0, 6).map((order) => (
                  <div
                    key={order.id}
                    onClick={() => onSelectOrder(order)}
                    className="p-4 hover:bg-gray-50/80 transition-colors cursor-pointer flex items-center justify-between"
                  >
                    <div className="min-w-0 pr-3">
                      <div className="flex items-center space-x-2">
                        <span className="text-xs font-bold text-gray-900 truncate">
                          {order.reference_name || `Doc #${order.order_number}`}
                        </span>
                        <span className="text-[10px] uppercase font-mono px-1.5 py-0.5 rounded-sm bg-purple-50 text-purple-700 font-semibold">
                          {order.type.replace('_', ' ')}
                        </span>
                      </div>
                      <div className="flex items-center gap-3 mt-1 text-xs text-gray-500">
                        <span>Date: {order.date}</span>
                        <span>Staff: {order.staff_name || 'Office'}</span>
                      </div>
                    </div>
                    <div className="text-right shrink-0">
                      <div className="text-sm font-bold text-gray-900">
                        {formatCurrency(order.total_amount)}
                      </div>
                      <span
                        className={`inline-block text-[10px] font-semibold px-2 py-0.5 rounded-full capitalize mt-1 ${
                          order.status === 'converted'
                            ? 'bg-emerald-50 text-emerald-700'
                            : 'bg-amber-50 text-amber-700'
                        }`}
                      >
                        {order.status}
                      </span>
                    </div>
                  </div>
                ))}
                {orders.length === 0 && (
                  <div className="p-8 text-center text-sm text-gray-400">
                    No orders or invoices recorded yet.
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};
