import React, { useState } from 'react';
import {
  Plus,
  Search,
  Calendar,
  Image as ImageIcon,
  CheckCircle,
  XCircle,
  Clock,
  Trash2,
} from 'lucide-react';
import type { Expense } from '../../types/crm';

interface ExpensesListProps {
  expenses: Expense[];
  onOpenAdd: () => void;
  onReview: (expense: Expense) => void;
  onDelete: (id: string) => void;
}

export const ExpensesList: React.FC<ExpensesListProps> = ({
  expenses,
  onOpenAdd,
  onReview,
  onDelete,
}) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'All' | 'Pending' | 'Approved' | 'Rejected'>('All');
  const [categoryFilter, setCategoryFilter] = useState('All');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;

  // Counts
  const countAll = expenses.length;
  const countPending = expenses.filter((e) => e.status === 'Pending').length;
  const countApproved = expenses.filter((e) => e.status === 'Approved').length;
  const countRejected = expenses.filter((e) => e.status === 'Rejected').length;

  const totalClaimed = expenses.reduce((s, e) => s + e.amount, 0);
  const totalApproved = expenses
    .filter((e) => e.status === 'Approved')
    .reduce((s, e) => s + (e.approved_amount || e.amount), 0);

  const filteredExpenses = expenses.filter((e) => {
    const matchesSearch =
      e.staff_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      e.expense_number.includes(searchTerm) ||
      (e.note && e.note.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchesStatus = statusFilter === 'All' || e.status === statusFilter;
    const matchesCategory = categoryFilter === 'All' || e.category === categoryFilter;

    return matchesSearch && matchesStatus && matchesCategory;
  });

  const totalPages = Math.ceil(filteredExpenses.length / itemsPerPage) || 1;
  const paginatedExpenses = filteredExpenses.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  return (
    <div className="space-y-4">
      {/* Top Header matching MyTeams */}
      <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-2xs flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center space-x-2">
          <h2 className="text-base font-bold text-gray-900">Expenses Claims</h2>
          <span className="px-2 py-0.5 bg-gray-100 text-gray-700 text-xs font-semibold rounded-full">
            {countAll} Total
          </span>
        </div>

        <div className="flex items-center gap-2 flex-wrap">
          <div className="relative min-w-56 flex-1 sm:flex-initial">
            <Search className="w-4 h-4 text-gray-400 absolute left-3 top-2.5" />
            <input
              type="text"
              placeholder="Search staff, expense ID, notes..."
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                setCurrentPage(1);
              }}
              className="w-full text-xs pl-9 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#3949ab] focus:outline-hidden"
            />
          </div>

          <select
            value={categoryFilter}
            onChange={(e) => {
              setCategoryFilter(e.target.value);
              setCurrentPage(1);
            }}
            className="text-xs px-3 py-2 border border-gray-300 rounded-lg bg-white text-gray-700 focus:ring-2 focus:ring-[#3949ab] focus:outline-hidden cursor-pointer"
          >
            <option value="All">All Categories</option>
            <option value="Travel">Travel</option>
            <option value="Food">Food</option>
            <option value="Hotel">Hotel</option>
            <option value="Advance">Advance</option>
            <option value="Other">Other</option>
          </select>

          <button
            onClick={onOpenAdd}
            className="inline-flex items-center space-x-1.5 px-3.5 py-2 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-lg text-xs font-semibold shadow-xs transition-colors cursor-pointer"
          >
            <Plus className="w-4 h-4" />
            <span>+ Add Expense</span>
          </button>
        </div>
      </div>

      {/* MyTeams Status Pills Row */}
      <div className="flex items-center justify-between gap-3 flex-wrap">
        <div className="flex items-center gap-2 overflow-x-auto pb-1 text-xs">
          {[
            { id: 'All', label: 'All', count: countAll },
            { id: 'Pending', label: 'Pending', count: countPending },
            { id: 'Approved', label: 'Approved', count: countApproved },
            { id: 'Rejected', label: 'Rejected', count: countRejected },
          ].map((pill) => (
            <button
              key={pill.id}
              onClick={() => {
                setStatusFilter(pill.id as 'All' | 'Pending' | 'Approved' | 'Rejected');
                setCurrentPage(1);
              }}
              className={`px-3 py-1.5 rounded-lg font-semibold flex items-center space-x-1.5 transition-colors cursor-pointer ${
                statusFilter === pill.id
                  ? 'bg-gray-800 text-white shadow-xs'
                  : 'bg-white border border-gray-200 text-gray-700 hover:bg-gray-50'
              }`}
            >
              <span>{pill.label}</span>
              <span
                className={`text-[10px] px-1.5 py-0.2 rounded-full font-bold ${
                  statusFilter === pill.id
                    ? 'bg-white/20 text-white'
                    : 'bg-gray-100 text-gray-700'
                }`}
              >
                {pill.count}
              </span>
            </button>
          ))}
        </div>

        {/* Claimed vs Approved stats */}
        <div className="text-xs flex items-center gap-4 text-gray-600 bg-white px-3 py-1.5 rounded-lg border border-gray-200">
          <span>
            Total Claimed: <b className="text-gray-900">₹{totalClaimed.toLocaleString()}</b>
          </span>
          <span className="border-l border-gray-200 pl-4 text-emerald-600">
            Total Approved: <b>₹{totalApproved.toLocaleString()}</b>
          </span>
        </div>
      </div>

      {/* Expenses Table */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-2xs overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-gray-700">
            <thead className="bg-gray-50/75 border-b border-gray-200 text-gray-500 uppercase tracking-wider font-semibold text-[11px]">
              <tr>
                <th className="px-4 py-3">Date</th>
                <th className="px-4 py-3">Expense #</th>
                <th className="px-4 py-3">Staff</th>
                <th className="px-4 py-3">Category</th>
                <th className="px-4 py-3">Note / Purpose</th>
                <th className="px-4 py-3 text-center">Receipt</th>
                <th className="px-4 py-3 text-right">Claimed (₹)</th>
                <th className="px-4 py-3 text-right">Approved (₹)</th>
                <th className="px-4 py-3 text-center">Status</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {paginatedExpenses.map((exp) => (
                <tr
                  key={exp.id}
                  className="hover:bg-gray-50/80 transition-colors group cursor-pointer"
                  onClick={() => onReview(exp)}
                >
                  <td className="px-4 py-3 text-gray-600 whitespace-nowrap">
                    <div className="flex items-center gap-1.5">
                      <Calendar className="w-3.5 h-3.5 text-gray-400" />
                      <span>{exp.date}</span>
                    </div>
                  </td>
                  <td className="px-4 py-3 font-mono font-bold text-gray-900">
                    #{exp.expense_number}
                  </td>
                  <td className="px-4 py-3 font-semibold text-gray-800">
                    <div className="flex items-center gap-1.5">
                      <div className="w-6 h-6 rounded-full bg-indigo-50 text-[#3949ab] flex items-center justify-center font-bold text-[10px]">
                        {exp.staff_name.slice(0, 2).toUpperCase()}
                      </div>
                      <span>{exp.staff_name}</span>
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-gray-100 text-gray-700 border border-gray-200">
                      {exp.category} {exp.units ? `(${exp.units} km)` : ''}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-gray-600 max-w-xs truncate">
                    {exp.note || 'No notes added'}
                  </td>
                  <td className="px-4 py-3 text-center">
                    {exp.receipt_url ? (
                      <a
                        href={exp.receipt_url}
                        target="_blank"
                        rel="noreferrer"
                        onClick={(e) => e.stopPropagation()}
                        className="inline-flex items-center justify-center p-1 rounded-md bg-blue-50 text-blue-600 hover:bg-blue-100"
                      >
                        <ImageIcon className="w-3.5 h-3.5" />
                      </a>
                    ) : (
                      <span className="text-gray-300">-</span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-right font-bold text-gray-900">
                    ₹{exp.amount.toLocaleString()}
                  </td>
                  <td className="px-4 py-3 text-right font-bold text-emerald-600">
                    ₹{(exp.approved_amount ?? 0).toLocaleString()}
                  </td>
                  <td className="px-4 py-3 text-center">
                    {exp.status === 'Approved' ? (
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
                        <CheckCircle className="w-3 h-3" />
                        Approved
                      </span>
                    ) : exp.status === 'Rejected' ? (
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-rose-50 text-rose-700 border border-rose-200">
                        <XCircle className="w-3 h-3" />
                        Rejected
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-200">
                        <Clock className="w-3 h-3" />
                        Pending
                      </span>
                    )}
                  </td>
                  <td
                    className="px-4 py-3 text-right space-x-1 whitespace-nowrap"
                    onClick={(e) => e.stopPropagation()}
                  >
                    <button
                      onClick={() => onReview(exp)}
                      className="px-2.5 py-1 text-xs font-semibold bg-indigo-50 hover:bg-indigo-100 text-[#3949ab] rounded-md transition-colors"
                    >
                      Audit
                    </button>
                    <button
                      onClick={() => {
                        if (window.confirm(`Delete expense #${exp.expense_number}?`)) {
                          onDelete(exp.id);
                        }
                      }}
                      className="p-1 text-gray-400 hover:text-rose-600 rounded-md transition-colors"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </td>
                </tr>
              ))}
              {paginatedExpenses.length === 0 && (
                <tr>
                  <td colSpan={10} className="text-center py-8 text-gray-400">
                    No expense claims found for this selection.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="px-4 py-3 border-t border-gray-100 flex items-center justify-between text-xs text-gray-500">
            <div>
              Showing {(currentPage - 1) * itemsPerPage + 1} to{' '}
              {Math.min(currentPage * itemsPerPage, filteredExpenses.length)} of{' '}
              {filteredExpenses.length} claims
            </div>
            <div className="flex items-center space-x-1">
              <button
                disabled={currentPage === 1}
                onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                className="px-2.5 py-1 border border-gray-200 rounded-md disabled:opacity-40 hover:bg-gray-50 cursor-pointer"
              >
                Previous
              </button>
              <span className="px-2 font-medium">
                {currentPage} / {totalPages}
              </span>
              <button
                disabled={currentPage === totalPages}
                onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                className="px-2.5 py-1 border border-gray-200 rounded-md disabled:opacity-40 hover:bg-gray-50 cursor-pointer"
              >
                Next
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
