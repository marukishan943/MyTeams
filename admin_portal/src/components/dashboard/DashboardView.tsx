import React from 'react';
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
} from 'lucide-react';
import type { Lead, Customer, SalesOrder } from '../../types/crm';

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

  const getStageBadge = (stage: Lead['stage']) => {
    switch (stage) {
      case 'newLead':
        return <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-blue-50 text-blue-700 border border-blue-200">New Lead</span>;
      case 'contacted':
        return <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-200">Contacted</span>;
      case 'proposalSent':
        return <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-purple-50 text-purple-700 border border-purple-200">Proposal Sent</span>;
      case 'converted':
        return <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">Converted</span>;
      case 'disqualified':
        return <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-gray-100 text-gray-700 border border-gray-200">Disqualified</span>;
      default:
        return null;
    }
  };

  return (
    <div className="space-y-6">
      {/* Quick Action Buttons Row (UpTeams Quick Bar) */}
      <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-2xs flex flex-wrap items-center justify-between gap-3">
        <div>
          <h2 className="text-base font-bold text-gray-900">
            Field Force & CRM Command Center
          </h2>
          <p className="text-xs text-gray-500">
            Real-time pipeline overview, customer accounts, and revenue orders.
          </p>
        </div>
        <div className="flex items-center gap-2 flex-wrap">
          <button
            onClick={onOpenAddLead}
            className="inline-flex items-center space-x-1.5 px-3.5 py-2 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-lg text-xs font-semibold shadow-xs transition-colors cursor-pointer"
          >
            <Plus className="w-4 h-4" />
            <span>Add Lead</span>
          </button>
          <button
            onClick={onOpenAddCustomer}
            className="inline-flex items-center space-x-1.5 px-3.5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-semibold shadow-xs transition-colors cursor-pointer"
          >
            <Plus className="w-4 h-4" />
            <span>Add Customer</span>
          </button>
          <button
            onClick={onOpenAddOrder}
            className="inline-flex items-center space-x-1.5 px-3.5 py-2 bg-slate-800 hover:bg-slate-900 text-white rounded-lg text-xs font-semibold shadow-xs transition-colors cursor-pointer"
          >
            <Plus className="w-4 h-4" />
            <span>Create Invoice</span>
          </button>
        </div>
      </div>

      {/* UpTeams-Style Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Metric 1: Leads */}
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
          {/* Mini Stage Progress Bar */}
          <div className="mt-4 pt-3 border-t border-gray-100 flex items-center justify-between text-[11px] text-gray-500">
            <span>New: <b>{newLeads}</b></span>
            <span>Contacted: <b>{contactedLeads}</b></span>
            <span>Proposal: <b>{proposalLeads}</b></span>
          </div>
        </div>

        {/* Metric 2: Customers */}
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

        {/* Metric 3: Invoices Revenue */}
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

        {/* Metric 4: Orders Value */}
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
      </div>

      {/* Two Column Section: Recent Leads & Recent Sales */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Leads Widget */}
        <div className="bg-white rounded-xl border border-gray-200 shadow-2xs overflow-hidden">
          <div className="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <Target className="w-4 h-4 text-[#3949ab]" />
              <h3 className="font-bold text-sm text-gray-900">Recent Leads</h3>
            </div>
            <button
              onClick={() => onNavigateTab('leads')}
              className="text-xs font-semibold text-[#3949ab] hover:underline flex items-center"
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

        {/* Recent Invoices & Orders Widget */}
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
              className="text-xs font-semibold text-purple-600 hover:underline flex items-center"
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
      </div>
    </div>
  );
};
