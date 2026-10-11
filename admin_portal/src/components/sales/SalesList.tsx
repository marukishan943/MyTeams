import React, { useState } from 'react';
import {
  Search,
  Plus,
  Eye,
  Edit2,
  Trash2,
  Calendar,
  User,
  Package,
  CreditCard,
  PlusCircle,
  MinusCircle,
} from 'lucide-react';
import type { SalesOrder, PaymentRecord, InventoryItem } from '../../types/crm';

interface SalesListProps {
  orders: SalesOrder[];
  payments: PaymentRecord[];
  inventory: InventoryItem[];
  onOpenAdd: (type: SalesOrder['type']) => void;
  onOpenEdit: (order: SalesOrder) => void;
  onOpenDetail: (order: SalesOrder) => void;
  onDeleteOrder: (id: string) => void;
  onOpenRecordPayment: () => void;
  onDeletePayment: (id: string) => void;
  onOpenAddInventory: () => void;
  onAdjustStock: (id: string, delta: number) => void;
  onDeleteInventory: (id: string) => void;
}

export const SalesList: React.FC<SalesListProps> = ({
  orders,
  payments,
  inventory,
  onOpenAdd,
  onOpenEdit,
  onOpenDetail,
  onDeleteOrder,
  onOpenRecordPayment,
  onDeletePayment,
  onOpenAddInventory,
  onAdjustStock,
  onDeleteInventory,
}) => {
  const [activeTab, setActiveTab] = useState<
    'invoice' | 'proforma_invoice' | 'order' | 'payments' | 'inventory'
  >('invoice');
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;

  const formatCurrency = (val: number) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      maximumFractionDigits: 0,
    }).format(val);
  };

  // 1. Invoices / Orders Filtering
  const isOrderType =
    activeTab === 'invoice' || activeTab === 'proforma_invoice' || activeTab === 'order';
  const currentTabOrders = orders.filter((o) => o.type === activeTab);

  const filteredOrders = currentTabOrders.filter((o) => {
    const matchesSearch =
      o.order_number.includes(searchTerm) ||
      (o.reference_name && o.reference_name.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (o.staff_name && o.staff_name.toLowerCase().includes(searchTerm.toLowerCase()));
    const matchesStatus = statusFilter === 'all' || o.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  // 2. Payments Filtering
  const filteredPayments = payments.filter((p) => {
    return (
      p.contact_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      p.sales_id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      p.mode.toLowerCase().includes(searchTerm.toLowerCase()) ||
      p.staff_name.toLowerCase().includes(searchTerm.toLowerCase())
    );
  });

  // 3. Inventory Filtering
  const filteredInventory = inventory.filter((i) => {
    return (
      i.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      i.sku.toLowerCase().includes(searchTerm.toLowerCase()) ||
      i.category.toLowerCase().includes(searchTerm.toLowerCase())
    );
  });

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
      {/* 5 Main Tabs (Matching Complete UpTeams Sales Suite) */}
      <div className="bg-white p-2 rounded-xl border border-gray-200 shadow-2xs flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center space-x-1 flex-wrap">
          {[
            { id: 'invoice', label: 'Invoices', count: orders.filter((o) => o.type === 'invoice').length },
            { id: 'proforma_invoice', label: 'Proforma', count: orders.filter((o) => o.type === 'proforma_invoice').length },
            { id: 'order', label: 'Orders', count: orders.filter((o) => o.type === 'order').length },
            { id: 'payments', label: 'Payments', count: payments.length },
            { id: 'inventory', label: 'Inventory', count: inventory.length },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => {
                setActiveTab(tab.id as typeof activeTab);
                setCurrentPage(1);
                setSearchTerm('');
              }}
              className={`px-3.5 py-2 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                activeTab === tab.id
                  ? 'bg-[#3949ab] text-white shadow-xs'
                  : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
              }`}
            >
              {tab.label} ({tab.count})
            </button>
          ))}
        </div>

        {/* Dynamic Action Button according to active tab */}
        {activeTab === 'payments' ? (
          <button
            onClick={onOpenRecordPayment}
            className="inline-flex items-center space-x-1.5 px-3.5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-semibold shadow-xs transition-colors cursor-pointer"
          >
            <CreditCard className="w-4 h-4" />
            <span>Record Payment</span>
          </button>
        ) : activeTab === 'inventory' ? (
          <button
            onClick={onOpenAddInventory}
            className="inline-flex items-center space-x-1.5 px-3.5 py-2 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-lg text-xs font-semibold shadow-xs transition-colors cursor-pointer"
          >
            <Package className="w-4 h-4" />
            <span>Add Product</span>
          </button>
        ) : (
          <button
            onClick={() => onOpenAdd(activeTab)}
            className="inline-flex items-center space-x-1.5 px-3.5 py-2 bg-slate-800 hover:bg-slate-900 text-white rounded-lg text-xs font-semibold shadow-xs transition-colors cursor-pointer"
          >
            <Plus className="w-4 h-4" />
            <span>
              Create {activeTab === 'proforma_invoice' ? 'Proforma' : activeTab === 'invoice' ? 'Invoice' : 'Order'}
            </span>
          </button>
        )}
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-2xs flex flex-wrap items-center justify-between gap-3">
        <div className="relative min-w-56 flex-1 sm:flex-initial">
          <Search className="w-4 h-4 text-gray-400 absolute left-3 top-2.5" />
          <input
            type="text"
            placeholder={
              activeTab === 'payments'
                ? 'Search payments by client, mode, ID...'
                : activeTab === 'inventory'
                ? 'Search products by name, SKU...'
                : 'Search by doc #, customer, staff...'
            }
            value={searchTerm}
            onChange={(e) => {
              setSearchTerm(e.target.value);
              setCurrentPage(1);
            }}
            className="w-full text-xs pl-9 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#3949ab] focus:outline-hidden"
          />
        </div>

        {isOrderType && (
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
        )}
      </div>

      {/* TAB CONTENT 1: Orders / Invoices / Proforma */}
      {isOrderType && (
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
                {filteredOrders.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage).map((order) => (
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
                        className="p-1.5 rounded-md hover:bg-gray-100 text-gray-500 hover:text-[#3949ab]"
                      >
                        <Eye className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => onOpenEdit(order)}
                        title="Edit Document"
                        className="p-1.5 rounded-md hover:bg-gray-100 text-gray-500 hover:text-emerald-600"
                      >
                        <Edit2 className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => {
                          if (window.confirm(`Delete document #${order.order_number}?`)) {
                            onDeleteOrder(order.id);
                          }
                        }}
                        title="Delete Document"
                        className="p-1.5 rounded-md hover:bg-rose-50 text-gray-400 hover:text-rose-600"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))}
                {filteredOrders.length === 0 && (
                  <tr>
                    <td colSpan={7} className="text-center py-8 text-gray-400">
                      No documents found for this selection.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* TAB CONTENT 2: Payments / Collections */}
      {activeTab === 'payments' && (
        <div className="bg-white rounded-xl border border-gray-200 shadow-2xs overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs text-gray-700">
              <thead className="bg-gray-50/75 border-b border-gray-200 text-gray-500 uppercase tracking-wider font-semibold text-[11px]">
                <tr>
                  <th className="px-4 py-3">Receipt #</th>
                  <th className="px-4 py-3">Date</th>
                  <th className="px-4 py-3">Sales / Invoice ID</th>
                  <th className="px-4 py-3">Contact / Company</th>
                  <th className="px-4 py-3">Payment Mode</th>
                  <th className="px-4 py-3 text-right">Amount (₹)</th>
                  <th className="px-4 py-3">Staff</th>
                  <th className="px-4 py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {filteredPayments.map((p) => (
                  <tr key={p.id} className="hover:bg-gray-50/80 transition-colors">
                    <td className="px-4 py-3 font-mono font-bold text-gray-900">{p.payment_number}</td>
                    <td className="px-4 py-3 text-gray-600">{p.date}</td>
                    <td className="px-4 py-3 font-mono text-[#3949ab] font-bold">{p.sales_id}</td>
                    <td className="px-4 py-3">
                      <div className="font-bold text-gray-900">{p.contact_name}</div>
                      {p.company_name && <div className="text-[11px] text-gray-500">{p.company_name}</div>}
                    </td>
                    <td className="px-4 py-3">
                      <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-gray-100 text-gray-800 border border-gray-200">
                        {p.mode}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right font-bold text-emerald-600 text-sm">
                      {formatCurrency(p.amount)}
                    </td>
                    <td className="px-4 py-3 text-gray-700">{p.staff_name}</td>
                    <td className="px-4 py-3 text-right">
                      <button
                        onClick={() => {
                          if (window.confirm(`Delete payment record ${p.payment_number}?`)) {
                            onDeletePayment(p.id);
                          }
                        }}
                        className="p-1 text-gray-400 hover:text-rose-600"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))}
                {filteredPayments.length === 0 && (
                  <tr>
                    <td colSpan={8} className="text-center py-8 text-gray-400">
                      No payment records recorded yet.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* TAB CONTENT 3: Inventory / Products Stock */}
      {activeTab === 'inventory' && (
        <div className="bg-white rounded-xl border border-gray-200 shadow-2xs overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs text-gray-700">
              <thead className="bg-gray-50/75 border-b border-gray-200 text-gray-500 uppercase tracking-wider font-semibold text-[11px]">
                <tr>
                  <th className="px-4 py-3">Product Name</th>
                  <th className="px-4 py-3">SKU</th>
                  <th className="px-4 py-3">Category</th>
                  <th className="px-4 py-3 text-right">Unit Rate (₹)</th>
                  <th className="px-4 py-3 text-center">In Stock Qty</th>
                  <th className="px-4 py-3">Stock Status</th>
                  <th className="px-4 py-3 text-center">Adjust Stock</th>
                  <th className="px-4 py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {filteredInventory.map((item) => (
                  <tr key={item.id} className="hover:bg-gray-50/80 transition-colors">
                    <td className="px-4 py-3 font-bold text-gray-900">{item.name}</td>
                    <td className="px-4 py-3 font-mono text-gray-600">{item.sku}</td>
                    <td className="px-4 py-3 text-gray-600">{item.category}</td>
                    <td className="px-4 py-3 text-right font-semibold text-gray-900">
                      {formatCurrency(item.rate)}
                    </td>
                    <td className="px-4 py-3 text-center font-bold text-sm text-gray-900">
                      {item.quantity} <span className="text-xs font-normal text-gray-400">{item.unit}</span>
                    </td>
                    <td className="px-4 py-3">
                      <span
                        className={`px-2 py-0.5 rounded-full text-[11px] font-semibold ${
                          item.status === 'In Stock'
                            ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                            : item.status === 'Low Stock'
                            ? 'bg-amber-50 text-amber-700 border border-amber-200'
                            : 'bg-rose-50 text-rose-700 border border-rose-200'
                        }`}
                      >
                        {item.status}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-center">
                      <div className="inline-flex items-center gap-1.5">
                        <button
                          onClick={() => onAdjustStock(item.id, -10)}
                          title="Deduct 10 units"
                          className="text-gray-400 hover:text-rose-600 p-0.5"
                        >
                          <MinusCircle className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => onAdjustStock(item.id, 10)}
                          title="Add 10 units"
                          className="text-gray-400 hover:text-emerald-600 p-0.5"
                        >
                          <PlusCircle className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-right">
                      <button
                        onClick={() => {
                          if (window.confirm(`Delete product ${item.name}?`)) {
                            onDeleteInventory(item.id);
                          }
                        }}
                        className="p-1 text-gray-400 hover:text-rose-600"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))}
                {filteredInventory.length === 0 && (
                  <tr>
                    <td colSpan={8} className="text-center py-8 text-gray-400">
                      No products found in inventory.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};
