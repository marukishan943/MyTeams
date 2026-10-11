import React, { useState } from 'react';
import { ArrowUpRight, Users, Briefcase } from 'lucide-react';
import type { Lead, Customer, SalesOrder, Expense, DSRRecord } from '../../types/crm';

interface ReportsViewProps {
  leads: Lead[];
  customers: Customer[];
  orders: SalesOrder[];
  expenses: Expense[];
  staffList: string[];
}

export const ReportsView: React.FC<ReportsViewProps> = ({
  leads,
  customers,
  orders,
  expenses,
  staffList,
}) => {
  const [reportTab, setReportTab] = useState<'dsr' | 'leads' | 'sales' | 'attendance' | 'expenses'>('dsr');
  const [timeFilter, setTimeFilter] = useState<'Daily' | 'Weekly' | 'Monthly'>('Weekly');
  const [selectedStaff, setSelectedStaff] = useState('All');

  const formatCurrency = (val: number) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      maximumFractionDigits: 0,
    }).format(val);
  };

  // Sample DSR data based on team members
  const dsrRecords: DSRRecord[] = [
    {
      id: 'dsr-1',
      staff_name: 'Mehul Ajagya',
      date: '10 Oct 2026',
      attendance_status: 'Present',
      punch_in_time: '09:15 AM',
      distance_km: 38.5,
      visits_count: 6,
      leads_count: 3,
      orders_value: 12500,
    },
    {
      id: 'dsr-2',
      staff_name: 'Kishan Maru',
      date: '10 Oct 2026',
      attendance_status: 'Present',
      punch_in_time: '09:02 AM',
      distance_km: 52.0,
      visits_count: 8,
      leads_count: 5,
      orders_value: 28400,
    },
    {
      id: 'dsr-3',
      staff_name: 'Sachin Chauhan',
      date: '10 Oct 2026',
      attendance_status: 'Present',
      punch_in_time: '09:30 AM',
      distance_km: 18.2,
      visits_count: 4,
      leads_count: 1,
      orders_value: 4500,
    },
    {
      id: 'dsr-4',
      staff_name: 'Isha Vora',
      date: '10 Oct 2026',
      attendance_status: 'On Leave',
      punch_in_time: '-',
      distance_km: 0,
      visits_count: 0,
      leads_count: 0,
      orders_value: 0,
    },
  ];

  const filteredDSR = dsrRecords.filter(
    (d) => selectedStaff === 'All' || d.staff_name === selectedStaff
  );

  // Conversion calculations
  const totalLeads = leads.length;
  const convertedLeads = leads.filter((l) => l.stage === 'converted').length;
  const conversionRate = totalLeads > 0 ? ((convertedLeads / totalLeads) * 100).toFixed(1) : '0';

  // Sales totals
  const totalInvoiced = orders
    .filter((o) => o.type === 'invoice')
    .reduce((sum, o) => sum + (o.total_amount || 0), 0);

  // Expense categories
  const travelExp = expenses
    .filter((e) => e.category === 'Travel')
    .reduce((sum, e) => sum + e.amount, 0);
  const foodExp = expenses
    .filter((e) => e.category === 'Food')
    .reduce((sum, e) => sum + e.amount, 0);
  const hotelExp = expenses
    .filter((e) => e.category === 'Hotel')
    .reduce((sum, e) => sum + e.amount, 0);
  const otherExp = expenses
    .filter((e) => e.category === 'Other' || e.category === 'Advance')
    .reduce((sum, e) => sum + e.amount, 0);

  return (
    <div className="space-y-4">
      {/* Top Report Selector Tabs matching UpTeams */}
      <div className="bg-white p-2 rounded-xl border border-gray-200 shadow-2xs flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center space-x-1 flex-wrap">
          {[
            { id: 'dsr', label: 'DSR (Daily Status)' },
            { id: 'leads', label: 'Leads Conversion' },
            { id: 'sales', label: 'Sales & Invoices' },
            { id: 'attendance', label: 'Attendance' },
            { id: 'expenses', label: 'Expense Analytics' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setReportTab(tab.id as typeof reportTab)}
              className={`px-3.5 py-2 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                reportTab === tab.id
                  ? 'bg-[#3949ab] text-white shadow-xs'
                  : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        <div className="flex items-center space-x-2 text-xs flex-wrap">
          <select
            value={selectedStaff}
            onChange={(e) => setSelectedStaff(e.target.value)}
            className="px-2.5 py-1 border border-gray-300 rounded-md bg-white text-gray-700 text-xs focus:ring-2 focus:ring-[#3949ab] focus:outline-hidden cursor-pointer"
          >
            <option value="All">All Staff</option>
            {staffList.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </select>

          <div className="flex items-center space-x-1">
            {['Daily', 'Weekly', 'Monthly'].map((period) => (
              <button
                key={period}
                onClick={() => setTimeFilter(period as typeof timeFilter)}
                className={`px-3 py-1 rounded-md font-semibold transition-colors cursor-pointer ${
                  timeFilter === period
                    ? 'bg-gray-800 text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {period}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* DSR REPORT VIEW */}
      {reportTab === 'dsr' && (
        <div className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-4 gap-3">
            <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-2xs">
              <span className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider block">
                Total Distance Traveled
              </span>
              <span className="text-xl font-bold text-gray-900 mt-1 block">
                {filteredDSR.reduce((s, d) => s + d.distance_km, 0).toFixed(1)} km
              </span>
            </div>
            <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-2xs">
              <span className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider block">
                Field Client Visits
              </span>
              <span className="text-xl font-bold text-[#3949ab] mt-1 block">
                {filteredDSR.reduce((s, d) => s + d.visits_count, 0)} Visits
              </span>
            </div>
            <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-2xs">
              <span className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider block">
                New Leads Generated
              </span>
              <span className="text-xl font-bold text-amber-600 mt-1 block">
                {filteredDSR.reduce((s, d) => s + d.leads_count, 0)} Leads
              </span>
            </div>
            <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-2xs">
              <span className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider block">
                Sales Booked in Field
              </span>
              <span className="text-xl font-bold text-emerald-600 mt-1 block">
                {formatCurrency(filteredDSR.reduce((s, d) => s + d.orders_value, 0))}
              </span>
            </div>
          </div>

          <div className="bg-white rounded-xl border border-gray-200 shadow-2xs overflow-hidden">
            <div className="px-5 py-3.5 border-b border-gray-200 font-bold text-xs text-gray-800 uppercase tracking-wider flex items-center space-x-2">
              <Briefcase className="w-4 h-4 text-[#3949ab]" />
              <span>Daily Staff Activity Scorecard</span>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs text-gray-700">
                <thead className="bg-gray-50 text-gray-500 font-semibold uppercase text-[11px]">
                  <tr>
                    <th className="px-4 py-3">Staff Member</th>
                    <th className="px-4 py-3">Attendance</th>
                    <th className="px-4 py-3">Punch-in Time</th>
                    <th className="px-4 py-3 text-center">Distance (Km)</th>
                    <th className="px-4 py-3 text-center">Visits</th>
                    <th className="px-4 py-3 text-center">Leads Created</th>
                    <th className="px-4 py-3 text-right">Revenue Booked</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {filteredDSR.map((d) => (
                    <tr key={d.id} className="hover:bg-gray-50/70">
                      <td className="px-4 py-3 font-bold text-gray-900">{d.staff_name}</td>
                      <td className="px-4 py-3">
                        <span
                          className={`px-2 py-0.5 rounded-full text-[11px] font-semibold ${
                            d.attendance_status === 'Present'
                              ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                              : 'bg-rose-50 text-rose-700 border border-rose-200'
                          }`}
                        >
                          {d.attendance_status}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-gray-600">{d.punch_in_time}</td>
                      <td className="px-4 py-3 text-center font-semibold text-gray-900">
                        {d.distance_km} km
                      </td>
                      <td className="px-4 py-3 text-center font-bold text-[#3949ab]">
                        {d.visits_count}
                      </td>
                      <td className="px-4 py-3 text-center font-bold text-amber-600">
                        {d.leads_count}
                      </td>
                      <td className="px-4 py-3 text-right font-bold text-emerald-600 text-sm">
                        {formatCurrency(d.orders_value)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* LEADS REPORT VIEW */}
      {reportTab === 'leads' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="bg-white p-5 rounded-xl border border-gray-200 shadow-2xs space-y-4">
            <h3 className="font-bold text-sm text-gray-900 flex items-center justify-between">
              <span>Pipeline Stage Funnel</span>
              <span className="text-emerald-600 font-semibold text-xs flex items-center">
                {conversionRate}% Conversion <ArrowUpRight className="w-3.5 h-3.5 ml-0.5" />
              </span>
            </h3>
            <div className="space-y-3 text-xs">
              {[
                { stage: 'New Leads', count: leads.filter((l) => l.stage === 'newLead').length, color: 'bg-blue-500' },
                { stage: 'Contacted', count: leads.filter((l) => l.stage === 'contacted').length, color: 'bg-amber-500' },
                { stage: 'Proposal Sent', count: leads.filter((l) => l.stage === 'proposalSent').length, color: 'bg-purple-500' },
                { stage: 'Converted', count: leads.filter((l) => l.stage === 'converted').length, color: 'bg-emerald-500' },
                { stage: 'Disqualified', count: leads.filter((l) => l.stage === 'disqualified').length, color: 'bg-gray-400' },
              ].map((item) => {
                const pct = totalLeads > 0 ? (item.count / totalLeads) * 100 : 0;
                return (
                  <div key={item.stage} className="space-y-1">
                    <div className="flex justify-between font-semibold text-gray-700">
                      <span>{item.stage}</span>
                      <span>{item.count} leads ({pct.toFixed(0)}%)</span>
                    </div>
                    <div className="w-full bg-gray-100 rounded-full h-2">
                      <div className={`${item.color} h-2 rounded-full`} style={{ width: `${pct}%` }} />
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="bg-white p-5 rounded-xl border border-gray-200 shadow-2xs space-y-4">
            <h3 className="font-bold text-sm text-gray-900">Lead Sources Breakdown</h3>
            <div className="space-y-3 text-xs">
              {[
                { source: 'Phone Calls', count: leads.filter((l) => l.source === 'call').length },
                { source: 'Website Inquiries', count: leads.filter((l) => l.source === 'website').length },
                { source: 'Emails', count: leads.filter((l) => l.source === 'email').length },
                { source: 'Field Referrals & Others', count: leads.filter((l) => l.source === 'others').length },
              ].map((s) => (
                <div key={s.source} className="flex justify-between items-center p-3 bg-gray-50 rounded-lg border border-gray-100">
                  <span className="font-semibold text-gray-800">{s.source}</span>
                  <span className="font-bold text-sm text-gray-900">{s.count}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* SALES & INVOICES REPORT */}
      {reportTab === 'sales' && (
        <div className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-4 gap-3">
            <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-2xs">
              <span className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider block">
                Total Tax Invoiced
              </span>
              <span className="text-2xl font-bold text-gray-900 mt-1 block">
                {formatCurrency(totalInvoiced)}
              </span>
            </div>
            <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-2xs">
              <span className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider block">
                Paid / Realized Collections
              </span>
              <span className="text-2xl font-bold text-emerald-600 mt-1 block">
                {formatCurrency(
                  orders
                    .filter((o) => o.status === 'converted')
                    .reduce((sum, o) => sum + (o.total_amount || 0), 0)
                )}
              </span>
            </div>
            <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-2xs">
              <span className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider block">
                Pending Receivables
              </span>
              <span className="text-2xl font-bold text-amber-600 mt-1 block">
                {formatCurrency(
                  orders
                    .filter((o) => o.status !== 'converted')
                    .reduce((sum, o) => sum + (o.total_amount || 0), 0)
                )}
              </span>
            </div>
            <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-2xs">
              <span className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider flex items-center justify-between">
                <span>Active B2B Customers</span>
                <Users className="w-3.5 h-3.5 text-[#3949ab]" />
              </span>
              <span className="text-2xl font-bold text-[#3949ab] mt-1 block">
                {customers.length} Accounts
              </span>
            </div>
          </div>
        </div>
      )}

      {/* ATTENDANCE REPORT */}
      {reportTab === 'attendance' && (
        <div className="bg-white p-5 rounded-xl border border-gray-200 shadow-2xs space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="font-bold text-sm text-gray-900">Attendance Status Summary</h3>
            <span className="text-xs text-gray-500">Live Geo-punch records</span>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-center">
            <div className="p-4 bg-emerald-50 rounded-xl border border-emerald-100">
              <span className="text-xs font-bold text-emerald-700 uppercase">Present</span>
              <div className="text-2xl font-black text-emerald-800 mt-1">3 Staff</div>
            </div>
            <div className="p-4 bg-amber-50 rounded-xl border border-amber-100">
              <span className="text-xs font-bold text-amber-700 uppercase">On Leave</span>
              <div className="text-2xl font-black text-amber-800 mt-1">1 Staff</div>
            </div>
            <div className="p-4 bg-gray-50 rounded-xl border border-gray-200">
              <span className="text-xs font-bold text-gray-600 uppercase">Not Punched In</span>
              <div className="text-2xl font-black text-gray-800 mt-1">0 Staff</div>
            </div>
          </div>
        </div>
      )}

      {/* EXPENSES REPORT */}
      {reportTab === 'expenses' && (
        <div className="bg-white p-5 rounded-xl border border-gray-200 shadow-2xs space-y-4">
          <h3 className="font-bold text-sm text-gray-900">Team Expense Heads Distribution</h3>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            <div className="p-3 bg-gray-50 rounded-lg border border-gray-100 text-xs">
              <span className="text-gray-400 font-semibold block text-[10px] uppercase">Travel / Fuel</span>
              <span className="text-base font-bold text-gray-900 mt-1 block">₹{travelExp.toLocaleString()}</span>
            </div>
            <div className="p-3 bg-gray-50 rounded-lg border border-gray-100 text-xs">
              <span className="text-gray-400 font-semibold block text-[10px] uppercase">Food & Meals</span>
              <span className="text-base font-bold text-gray-900 mt-1 block">₹{foodExp.toLocaleString()}</span>
            </div>
            <div className="p-3 bg-gray-50 rounded-lg border border-gray-100 text-xs">
              <span className="text-gray-400 font-semibold block text-[10px] uppercase">Hotel Stay</span>
              <span className="text-base font-bold text-gray-900 mt-1 block">₹{hotelExp.toLocaleString()}</span>
            </div>
            <div className="p-3 bg-gray-50 rounded-lg border border-gray-100 text-xs">
              <span className="text-gray-400 font-semibold block text-[10px] uppercase">Advance & Other</span>
              <span className="text-base font-bold text-gray-900 mt-1 block">₹{otherExp.toLocaleString()}</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
