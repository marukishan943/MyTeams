import React, { useState } from 'react';
import {
  Search,
  Plus,
  Eye,
  Edit2,
  Trash2,
  Calendar,
  User,
} from 'lucide-react';
import type { SalesOrder } from '../../types/crm';

interface SalesListProps {
  orders: SalesOrder[];
  onOpenAdd: (type: SalesOrder['type']) => void;
  onOpenEdit: (order: SalesOrder) => void;
  onOpenDetail: (order: SalesOrder) => void;
  onDelete: (id: string) => void;
}

export const SalesList: React.FC<SalesListProps> = ({
  orders,
  onOpenAdd,
  onOpenEdit,
  onOpenDetail,
  onDelete,
}) => {
  const [activeTab, setActiveTab] = useState<'invoice' | 'proforma_invoice' | 'order'>(
    'invoice'
  );
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 12;

  // Filter orders by active tab, search, and status
  const currentTabOrders = orders.filter((o) => o.type === activeTab);

  const filteredOrders = currentTabOrders.filter((o) => {
    const matchesSearch =
      o.order_number.includes(searchTerm) ||
      (o.reference_name && o.reference_name.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (o.staff_name && o.staff_name.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchesStatus = statusFilter === 'all' || o.status === statusFilter;

    return matchesSearch && matchesStatus;
  });

  const totalPages = Math.ceil(filteredOrders.length / itemsPerPage) || 1;
  const paginatedOrders = filteredOrders.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const formatCurrency = (val: number) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      maximumFractionDigits: 0,
    }).format(val);
  };

  const totalValue = currentTabOrders.reduce((sum, o) => sum + (o.total_amount || 0), 0);
  const convertedValue = currentTabOrders
    .filter((o) => o.status === 'converted')
    .reduce((sum, o) => sum + (o.total_amount || 0), 0);

  const getStatusBadge = (status: SalesOrder['status']) => {
    switch (status) {
      case 'converted':
        return (
          <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
            Converted / Paid
          </span>
        );
      case 'delivered':
        return (
          <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-blue-50 text-blue-700 border border-blue-200">
            Delivered
          </span>
        );
      case 'pending':
        return (
          <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-purple-50 text-purple-700 border border-purple-200">
            Pending
          </span>
        );
      default:
        return (
          <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-200">
            Open
          </span>
        );
    }
  };

  return (
    <div className="space-y-4">
      {/* 3 Tabs Bar (Matching UpTeams & MyTeams Mobile) */}
      <div className="bg-white p-2 rounded-xl border border-gray-200 shadow-2xs flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center space-x-1">
          {[
            { id: 'invoice', label: 'Tax Invoices' },
            { id: 'proforma_invoice', label: 'Proforma Invoices' },
            { id: 'order', label: 'Orders' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => {
                setActiveTab(tab.id as SalesOrder['type']);
                setCurrentPage(1);
              }}
              className={`px-4 py-2 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                activeTab === tab.id
                  ? 'bg-[#3949ab] text-white shadow-xs'
                  : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
              }`}
            >
              {tab.label} (
              {orders.filter((o) => o.type === tab.id).length})
            </button>
          ))}
        </div>

        <button
          onClick={() => onOpenAdd(activeTab)}
          className="inline-flex items-center space-x-1.5 px-3.5 py-2 bg-slate-800 hover:bg-slate-900 text-white rounded-lg text-xs font-semibold shadow-xs transition-colors cursor-pointer"
        >
          <Plus className="w-4 h-4" />
          <span>
            Create {activeTab === 'proforma_invoice' ? 'Proforma' : activeTab === 'invoice' ? 'Invoice' : 'Order'}
          </span>
        </button>
      </div>

      {/* Summary Stat Pill */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <div className="bg-white p-3.5 rounded-xl border border-gray-200 shadow-2xs">
          <span className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider block">
            Total {activeTab.replace('_', ' ')}s
          </span>
          <span className="text-xl font-bold text-gray-900 mt-1 block">
            {currentTabOrders.length}
          </span>
        </div>
        <div className="bg-white p-3.5 rounded-xl border border-gray-200 shadow-2xs">
          <span className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider block">
            Total Value
          </span>
          <span className="text-xl font-bold text-[#3949ab] mt-1 block">
            {formatCurrency(totalValue)}
          </span>
        </div>
        <div className="bg-white p-3.5 rounded-xl border border-gray-200 shadow-2xs">
          <span className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider block">
            Realized / Converted
          </span>
          <span className="text-xl font-bold text-emerald-600 mt-1 block">
            {formatCurrency(convertedValue)}
          </span>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-2xs flex flex-wrap items-center justify-between gap-3">
        <div className="relative min-w-56 flex-1 sm:flex-initial">
          <Search className="w-4 h-4 text-gray-400 absolute left-3 top-2.5" />
          <input
            type="text"
            placeholder="Search by doc #, customer, staff..."
            value={searchTerm}
            onChange={(e) => {
              setSearchTerm(e.target.value);
              setCurrentPage(1);
            }}
            className="w-full text-xs pl-9 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#3949ab] focus:outline-hidden"
          />
        </div>

        <div className="flex items-center gap-1.5 text-xs">
          <span className="text-[11px] font-semibold text-gray-400 mr-1">Status:</span>
          {['all', 'open', 'pending', 'delivered', 'converted'].map((st) => (
            <button
              key={st}
              onClick={() => {
                setStatusFilter(st);
                setCurrentPage(1);
              }}
              className={`px-3 py-1 rounded-md font-medium capitalize transition-colors cursor-pointer ${
                statusFilter === st
                  ? 'bg-gray-800 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              {st}
            </button>
          ))}
        </div>
      </div>

      {/* Documents Table */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-2xs overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-gray-700">
            <thead className="bg-gray-50/75 border-b border-gray-200 text-gray-500 uppercase tracking-wider font-semibold text-[11px]">
              <tr>
                <th className="px-4 py-3">Doc #</th>
                <th className="px-4 py-3">Client / Reference</th>
                <th className="px-4 py-3">Date</th>
                <th className="px-4 py-3">Staff</th>
                <th className="px-4 py-3 text-right">Amount</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {paginatedOrders.map((order) => (
                <tr
                  key={order.id}
                  className="hover:bg-gray-50/80 transition-colors group cursor-pointer"
                  onClick={() => onOpenDetail(order)}
                >
                  <td className="px-4 py-3 font-mono font-bold text-gray-900">
                    #{order.order_number}
                  </td>
                  <td className="px-4 py-3 font-semibold text-gray-800">
                    {order.reference_name || 'Client Order'}
                  </td>
                  <td className="px-4 py-3 text-gray-600">
                    <div className="flex items-center gap-1">
                      <Calendar className="w-3.5 h-3.5 text-gray-400" />
                      <span>{order.date}</span>
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-1 text-gray-700">
                      <User className="w-3.5 h-3.5 text-gray-400" />
                      <span>{order.staff_name || 'Office'}</span>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-right font-bold text-gray-900">
                    {formatCurrency(order.total_amount)}
                  </td>
                  <td className="px-4 py-3">{getStatusBadge(order.status)}</td>
                  <td
                    className="px-4 py-3 text-right space-x-1 whitespace-nowrap"
                    onClick={(e) => e.stopPropagation()}
                  >
                    <button
                      onClick={() => onOpenDetail(order)}
                      title="View Document"
                      className="p-1.5 rounded-md hover:bg-gray-100 text-gray-500 hover:text-[#3949ab] transition-colors"
                    >
                      <Eye className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => onOpenEdit(order)}
                      title="Edit Document"
                      className="p-1.5 rounded-md hover:bg-gray-100 text-gray-500 hover:text-emerald-600 transition-colors"
                    >
                      <Edit2 className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => {
                        if (
                          window.confirm(
                            `Delete document #${order.order_number}?`
                          )
                        ) {
                          onDelete(order.id);
                        }
                      }}
                      title="Delete Document"
                      className="p-1.5 rounded-md hover:bg-rose-50 text-gray-400 hover:text-rose-600 transition-colors"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </td>
                </tr>
              ))}
              {paginatedOrders.length === 0 && (
                <tr>
                  <td colSpan={7} className="text-center py-8 text-gray-400">
                    No documents found for this selection.
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
              {Math.min(currentPage * itemsPerPage, filteredOrders.length)} of{' '}
              {filteredOrders.length} documents
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
