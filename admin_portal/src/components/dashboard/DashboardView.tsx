import React from 'react';
import {
  Target,
  Users,
  FileText,
  TrendingUp,
  Plus,
  ArrowRight,
  CheckCircle,
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
  onSelectLead?: (lead: Lead) => void;
  onSelectOrder?: (order: SalesOrder) => void;
  cardsConfig?: DashboardCardsConfig;
  onToggleCard?: (key: keyof DashboardCardsConfig) => void;
  onResetCards?: () => void;
  onSetAllCards?: (visible: boolean) => void;
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
  moduleVisibility = {
    leads: true,
    customers: true,
    sales: true,
    expenses: true,
    reports: true,
    settings: true,
  },
}) => {
  // Statistics Calculations
  const totalLeads = leads.length;
  const convertedLeads = leads.filter((l) => l.stage === 'converted').length;
  const newLeads = leads.filter((l) => l.stage === 'newLead').length;
  const contactedLeads = leads.filter((l) => l.stage === 'contacted').length;
  const proposalLeads = leads.filter((l) => l.stage === 'proposalSent').length;

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

  const showLeadsMetric = moduleVisibility.leads !== false;
  const showCustomersMetric = moduleVisibility.customers !== false;
  const showInvoicesMetric = moduleVisibility.sales !== false;
  const showOrdersMetric = moduleVisibility.sales !== false;
  const visibleKpiCount =
    (showLeadsMetric ? 1 : 0) +
    (showCustomersMetric ? 1 : 0) +
    (showInvoicesMetric ? 1 : 0) +
    (showOrdersMetric ? 1 : 0);

  return (
    <div className="space-y-6">
      {/* Quick Action Bar */}
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

      {/* 4 Metric KPI Cards */}
      {visibleKpiCount > 0 && (
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
      )}
    </div>
  );
};
