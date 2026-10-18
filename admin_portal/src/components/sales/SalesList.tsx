import React, { useState, useRef, useEffect } from 'react';
import {
  Search,
  Plus,
  Send,
  MoreHorizontal,
  Edit2,
  Trash2,
  RefreshCw,
  Eye,
  Filter,
  Calendar,
  User as UserIcon,
  FileText,
  Receipt,
  CreditCard,
  Package,
  Info,
  ArrowLeftRight,
  User,
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
  staffList?: string[];
}

function getInitials(name?: string): string {
  if (!name) return '??';
  const parts = name.trim().split(/\s+/);
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

function formatSalesDate(dateStr?: string): string {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  const now = new Date();
  const diff = now.setHours(0, 0, 0, 0) - d.setHours(0, 0, 0, 0);
  const daysDiff = Math.round(diff / 86400000);
  if (daysDiff === 0) return 'TODAY';
  if (daysDiff === 1) return 'YESTERDAY';
  return new Date(dateStr).toLocaleDateString('en-GB', {
    day: 'numeric',
    month: 'short',
  });
}

function formatCurrencyINR(val?: number): string {
  if (val === undefined || val === null) return '0';
  return Number(val).toLocaleString('en-IN');
}

// Dropdown menu for each order's "..." button
function OrderRowActions({
  order,
  onOpenEdit,
  onOpenDetail,
  onDeleteOrder,
}: {
  order: SalesOrder;
  onOpenEdit: (order: SalesOrder) => void;
  onOpenDetail: (order: SalesOrder) => void;
  onDeleteOrder: (id: string) => void;
}) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };
    if (open) document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [open]);

  return (
    <div className="relative" ref={ref}>
      <button
        onClick={(e) => {
          e.stopPropagation();
          setOpen((v) => !v);
        }}
        className="p-1.5 rounded hover:bg-gray-100 text-[#1a237e] transition-colors cursor-pointer"
        title="More actions"
      >
        <MoreHorizontal className="w-4 h-4 text-[#1a237e]" />
      </button>

      {open && (
        <div className="absolute right-0 top-8 z-50 w-36 bg-white rounded-md shadow-xl border border-gray-200 py-1.5 text-xs">
          <button
            onClick={(e) => {
              e.stopPropagation();
              setOpen(false);
              onOpenDetail(order);
            }}
            className="w-full flex items-center gap-2.5 px-3.5 py-2 text-gray-700 hover:bg-gray-50 cursor-pointer"
          >
            <Info className="w-4 h-4 text-[#1a237e]" />
            <span>View Details</span>
          </button>
          <button
            onClick={(e) => {
              e.stopPropagation();
              setOpen(false);
              onOpenEdit(order);
            }}
            className="w-full flex items-center gap-2.5 px-3.5 py-2 text-gray-700 hover:bg-gray-50 cursor-pointer"
          >
            <Edit2 className="w-4 h-4 text-[#1a237e]" />
            <span>Edit</span>
          </button>
          <button
            onClick={(e) => {
              e.stopPropagation();
              setOpen(false);
              if (
                window.confirm(
                  `Delete ${order.type.replace('_', ' ')} #${order.order_number}?`
                )
              ) {
                onDeleteOrder(order.id);
              }
            }}
            className="w-full flex items-center gap-2.5 px-3.5 py-2 text-rose-600 hover:bg-rose-50 cursor-pointer"
          >
            <Trash2 className="w-4 h-4 text-rose-500" />
            <span>Delete</span>
          </button>
        </div>
      )}
    </div>
  );
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
  staffList = [],
}) => {
  // Inner Sub-navigation (Proforma Invoices, Invoices, Payments, Inventory)
  const [subTab, setSubTab] = useState<
    'proforma_invoice' | 'invoice' | 'payments' | 'inventory'
  >('proforma_invoice');

  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [staffFilter, setStaffFilter] = useState<string>('all');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 20;

  // Filter orders by subTab ('proforma_invoice' or 'invoice')
  const isOrderView = subTab === 'proforma_invoice' || subTab === 'invoice';
  const currentOrders = orders.filter((o) => o.type === subTab);

  // Status Tab Counts for Orders
  const orderStatusCounts = {
    all: currentOrders.length,
    open: currentOrders.filter((o) => o.status === 'open' || o.status === 'pending').length,
    converted: currentOrders.filter((o) => o.status === 'converted' || o.status === 'delivered').length,
    cancelled: currentOrders.filter((o) => o.status === 'delivered' ? false : o.status === 'cancelled' as unknown as string).length,
  };

  const filteredOrders = currentOrders.filter((o) => {
    const matchesSearch =
      o.order_number.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (o.reference_name &&
        o.reference_name.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (o.staff_name &&
        o.staff_name.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (o.notes && o.notes.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchesStatus =
      statusFilter === 'all' ||
      (statusFilter === 'open'
        ? o.status === 'open' || o.status === 'pending'
        : statusFilter === 'converted'
        ? o.status === 'converted' || o.status === 'delivered'
        : o.status === statusFilter);

    const matchesStaff =
      staffFilter === 'all' || o.staff_name === staffFilter;

    return matchesSearch && matchesStatus && matchesStaff;
  });

  // Payments filtering
  const filteredPayments = payments.filter((p) => {
    const matchesSearch =
      p.contact_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      p.sales_id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      p.mode.toLowerCase().includes(searchTerm.toLowerCase()) ||
      p.staff_name.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStaff =
      staffFilter === 'all' || p.staff_name === staffFilter;

    return matchesSearch && matchesStaff;
  });

  // Inventory filtering
  const filteredInventory = inventory.filter((i) => {
    return (
      i.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      i.sku.toLowerCase().includes(searchTerm.toLowerCase()) ||
      i.category.toLowerCase().includes(searchTerm.toLowerCase())
    );
  });

  // Calculate live summary totals for bottom summary bar
  const totalAmount = filteredOrders.reduce(
    (sum, o) => sum + (o.total_amount || 0),
    0
  );
  const convertedAmount = filteredOrders
    .filter((o) => o.status === 'converted' || o.status === 'delivered')
    .reduce((sum, o) => sum + (o.total_amount || 0), 0);
  const openAmount = filteredOrders
    .filter((o) => o.status === 'open' || o.status === 'pending')
    .reduce((sum, o) => sum + (o.total_amount || 0), 0);

  // Pagination
  const totalItems = isOrderView
    ? filteredOrders.length
    : subTab === 'payments'
    ? filteredPayments.length
    : filteredInventory.length;

  const totalPages = Math.ceil(totalItems / itemsPerPage) || 1;

  const paginatedOrders = filteredOrders.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const getOrderStatusPill = (status: SalesOrder['status']) => {
    if (status === 'converted' || status === 'delivered') {
      return (
        <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-[#d1fae5] text-[#059669] border border-[#a7f3d0]">
          <span className="w-2 h-2 rounded-full bg-[#10b981] shrink-0" />
          <span>Converted</span>
          <ArrowLeftRight className="w-3 h-3 text-[#059669]" />
        </span>
      );
    }
    if (status === 'pending' || status === 'open') {
      return (
        <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-[#dbeafe] text-[#2563eb] border border-[#bfdbfe]">
          <span className="w-2 h-2 rounded-full bg-[#3b82f6] shrink-0" />
          <span>Open</span>
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-[#fee2e2] text-[#ef4444] border border-[#fecaca]">
        <span className="w-2 h-2 rounded-full bg-[#ef4444] shrink-0" />
        <span>Cancelled</span>
      </span>
    );
  };

  const getSubTabTitle = () => {
    switch (subTab) {
      case 'proforma_invoice':
        return 'Proforma Invoices';
      case 'invoice':
        return 'Invoices';
      case 'payments':
        return 'Payments';
      case 'inventory':
        return 'Inventory';
    }
  };

  return (
    <div className="w-full bg-white flex min-h-screen text-gray-800">
      {/* ── INNER SECONDARY SIDEBAR (Sales sub-navigation) ── */}
      <div className="w-48 sm:w-52 border-r border-gray-200 bg-white flex flex-col shrink-0 select-none">
        {/* Sales Title */}
        <div className="px-5 py-3.5 border-b border-gray-200">
          <h2 className="text-base font-bold text-gray-900 tracking-tight">Sales</h2>
        </div>

        {/* Sub-navigation Menu Links */}
        <nav className="p-2 space-y-1 text-xs font-semibold">
          <button
            onClick={() => {
              setSubTab('proforma_invoice');
              setCurrentPage(1);
              setStatusFilter('all');
            }}
            className={`w-full flex items-center gap-2.5 px-3 py-2.5 rounded-lg transition-colors cursor-pointer ${
              subTab === 'proforma_invoice'
                ? 'bg-blue-50/70 text-[#1a237e] font-bold'
                : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
            }`}
          >
            <FileText
              className={`w-4 h-4 ${
                subTab === 'proforma_invoice' ? 'text-[#1a237e]' : 'text-gray-400'
              }`}
            />
            <span>Proforma Invoices</span>
          </button>

          <button
            onClick={() => {
              setSubTab('invoice');
              setCurrentPage(1);
              setStatusFilter('all');
            }}
            className={`w-full flex items-center gap-2.5 px-3 py-2.5 rounded-lg transition-colors cursor-pointer ${
              subTab === 'invoice'
                ? 'bg-blue-50/70 text-[#1a237e] font-bold'
                : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
            }`}
          >
            <Receipt
              className={`w-4 h-4 ${
                subTab === 'invoice' ? 'text-[#1a237e]' : 'text-gray-400'
              }`}
            />
            <span>Invoices</span>
          </button>

          <button
            onClick={() => {
              setSubTab('payments');
              setCurrentPage(1);
            }}
            className={`w-full flex items-center gap-2.5 px-3 py-2.5 rounded-lg transition-colors cursor-pointer ${
              subTab === 'payments'
                ? 'bg-blue-50/70 text-[#1a237e] font-bold'
                : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
            }`}
          >
            <CreditCard
              className={`w-4 h-4 ${
                subTab === 'payments' ? 'text-[#1a237e]' : 'text-gray-400'
              }`}
            />
            <span>Payments</span>
          </button>

          <button
            onClick={() => {
              setSubTab('inventory');
              setCurrentPage(1);
            }}
            className={`w-full flex items-center gap-2.5 px-3 py-2.5 rounded-lg transition-colors cursor-pointer ${
              subTab === 'inventory'
                ? 'bg-blue-50/70 text-[#1a237e] font-bold'
                : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
            }`}
          >
            <Package
              className={`w-4 h-4 ${
                subTab === 'inventory' ? 'text-[#1a237e]' : 'text-gray-400'
              }`}
            />
            <span>Inventory</span>
          </button>
        </nav>
      </div>

      {/* ── MAIN CONTENT AREA ── */}
      <div className="flex-1 flex flex-col min-w-0 bg-white">
        {/* ── TOP HEADER BAR ── */}
        <div className="w-full bg-white px-4 py-2.5 border-b border-gray-200 flex flex-wrap items-center gap-2.5 shadow-2xs">
          {/* Header Title with Document Icon */}
          <div className="flex items-center gap-2 mr-1">
            <FileText className="w-5 h-5 text-[#1a237e]" />
            <span className="text-base font-bold text-gray-900 tracking-tight">
              {getSubTabTitle()}
            </span>
          </div>

          {/* Search Box */}
          <div className="relative min-w-44 flex-1 sm:max-w-xs">
            <input
              type="text"
              placeholder="Search..."
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                setCurrentPage(1);
              }}
              className="w-full text-xs pl-3 pr-8 py-1.5 border border-gray-300 rounded focus:ring-1 focus:ring-[#1a237e] focus:border-[#1a237e] outline-none bg-white"
            />
            <Search className="w-3.5 h-3.5 text-gray-400 absolute right-2.5 top-2.5" />
          </div>

          {/* Filter: Date */}
          <div className="flex items-center border border-gray-300 rounded px-2.5 py-1.5 bg-white text-xs text-gray-700">
            <span className="pr-2 text-xs">All</span>
            <Calendar className="w-3.5 h-3.5 text-gray-400 shrink-0" />
          </div>

          {/* Filter: Staff */}
          <div className="flex items-center border border-gray-300 rounded px-2.5 py-1.5 bg-white text-xs text-gray-700">
            <select
              className="bg-transparent outline-none text-xs text-gray-700 cursor-pointer pr-1"
              value={staffFilter}
              onChange={(e) => {
                setStaffFilter(e.target.value);
                setCurrentPage(1);
              }}
            >
              <option value="all">Staff</option>
              {staffList.map((st) => (
                <option key={st} value={st}>
                  {st}
                </option>
              ))}
            </select>
            <UserIcon className="w-3.5 h-3.5 text-gray-400 shrink-0" />
          </div>

          {/* Action Icon Buttons */}
          <div className="flex items-center gap-1.5 ml-auto">
            <button
              title="Filter"
              className="p-1.5 rounded bg-[#1a237e] hover:bg-[#151c65] text-white transition-colors cursor-pointer shadow-2xs"
            >
              <Filter className="w-3.5 h-3.5" />
            </button>
            <button
              title="Refresh"
              onClick={() => window.location.reload()}
              className="p-1.5 rounded bg-[#1a237e] hover:bg-[#151c65] text-white transition-colors cursor-pointer shadow-2xs"
            >
              <RefreshCw className="w-3.5 h-3.5" />
            </button>
            <button
              title="Column Visibility"
              className="p-1.5 rounded bg-[#1a237e] hover:bg-[#151c65] text-white transition-colors cursor-pointer shadow-2xs"
            >
              <Eye className="w-3.5 h-3.5" />
            </button>

            {/* Main Action Button */}
            {subTab === 'proforma_invoice' && (
              <button
                onClick={() => onOpenAdd('proforma_invoice')}
                className="flex items-center gap-1.5 px-3.5 py-1.5 bg-[#1a237e] hover:bg-[#151c65] text-white rounded text-xs font-semibold shadow-2xs transition-colors cursor-pointer"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>+ Add Proforma Invoice</span>
              </button>
            )}

            {subTab === 'invoice' && (
              <button
                onClick={() => onOpenAdd('invoice')}
                className="flex items-center gap-1.5 px-3.5 py-1.5 bg-[#1a237e] hover:bg-[#151c65] text-white rounded text-xs font-semibold shadow-2xs transition-colors cursor-pointer"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>+ Add Invoice</span>
              </button>
            )}

            {subTab === 'payments' && (
              <button
                onClick={onOpenRecordPayment}
                className="flex items-center gap-1.5 px-3.5 py-1.5 bg-[#1a237e] hover:bg-[#151c65] text-white rounded text-xs font-semibold shadow-2xs transition-colors cursor-pointer"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>+ Record Payment</span>
              </button>
            )}

            {subTab === 'inventory' && (
              <button
                onClick={onOpenAddInventory}
                className="flex items-center gap-1.5 px-3.5 py-1.5 bg-[#1a237e] hover:bg-[#151c65] text-white rounded text-xs font-semibold shadow-2xs transition-colors cursor-pointer"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>+ Add Product</span>
              </button>
            )}
          </div>
        </div>

        {/* ── STATUS TABS BAR (When in Proforma or Invoice view) ── */}
        {isOrderView && (
          <div className="w-full bg-white px-4 py-2 border-b border-gray-200 flex items-center gap-2 overflow-x-auto">
            <button
              onClick={() => {
                setStatusFilter('all');
                setCurrentPage(1);
              }}
              className={`px-3 py-0.5 rounded text-xs font-bold whitespace-nowrap transition-all cursor-pointer border ${
                statusFilter === 'all'
                  ? 'bg-[#1a237e] text-white border-transparent shadow-2xs'
                  : 'bg-white text-blue-600 border-blue-500 hover:opacity-85'
              }`}
            >
              <span>All</span>
              <span className="ml-1.5">{orderStatusCounts.all}</span>
            </button>

            <button
              onClick={() => {
                setStatusFilter('open');
                setCurrentPage(1);
              }}
              className={`px-3 py-0.5 rounded text-xs font-bold whitespace-nowrap transition-all cursor-pointer border ${
                statusFilter === 'open'
                  ? 'bg-[#2196f3] text-white border-transparent shadow-2xs'
                  : 'bg-white text-[#2196f3] border-[#2196f3] hover:opacity-85'
              }`}
            >
              <span>Open</span>
              <span className="ml-1.5">{orderStatusCounts.open}</span>
            </button>

            <button
              onClick={() => {
                setStatusFilter('converted');
                setCurrentPage(1);
              }}
              className={`px-3 py-0.5 rounded text-xs font-bold whitespace-nowrap transition-all cursor-pointer border ${
                statusFilter === 'converted'
                  ? 'bg-[#4caf50] text-white border-transparent shadow-2xs'
                  : 'bg-white text-[#4caf50] border-[#4caf50] hover:opacity-85'
              }`}
            >
              <span>Converted</span>
              <span className="ml-1.5">{orderStatusCounts.converted}</span>
            </button>

            <button
              onClick={() => {
                setStatusFilter('cancelled');
                setCurrentPage(1);
              }}
              className={`px-3 py-0.5 rounded text-xs font-bold whitespace-nowrap transition-all cursor-pointer border ${
                statusFilter === 'cancelled'
                  ? 'bg-[#f44336] text-white border-transparent shadow-2xs'
                  : 'bg-white text-[#f44336] border-[#f44336] hover:opacity-85'
              }`}
            >
              <span>Cancelled</span>
              <span className="ml-1.5">{orderStatusCounts.cancelled}</span>
            </button>
          </div>
        )}

        {/* ── INVOICES / PROFORMA TABLE ── */}
        {isOrderView && (
          <div className="w-full flex-1 overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead className="bg-[#f8fafc] border-b border-gray-200 text-gray-600 font-semibold text-xs">
                <tr>
                  <th className="px-3.5 py-3.5 whitespace-nowrap">
                    <div className="flex items-center gap-1.5 text-gray-700">
                      <span>Date</span>
                      <span className="text-gray-400 text-xs">⇅</span>
                    </div>
                  </th>
                  <th className="px-3.5 py-3.5 whitespace-nowrap">
                    <div className="flex items-center gap-1.5 text-gray-700">
                      <span>ID</span>
                      <span className="text-gray-400 text-xs">⇅</span>
                    </div>
                  </th>
                  <th className="px-3.5 py-3.5 whitespace-nowrap">
                    <div className="flex items-center gap-1.5 text-gray-700">
                      <span>Contact</span>
                      <span className="text-gray-400 text-xs">⇅</span>
                    </div>
                  </th>
                  <th className="px-3.5 py-3.5 whitespace-nowrap">
                    <div className="flex items-center gap-1.5 text-gray-700">
                      <span>Items</span>
                    </div>
                  </th>
                  <th className="px-3.5 py-3.5 whitespace-nowrap">
                    <div className="flex items-center gap-1.5 text-gray-700">
                      <span>REFERANCE</span>
                      <span className="text-gray-400 text-xs">⇅</span>
                    </div>
                  </th>
                  <th className="px-3.5 py-3.5 whitespace-nowrap">
                    <div className="flex items-center gap-1.5 text-gray-700">
                      <span>NOTE</span>
                      <span className="text-gray-400 text-xs">⇅</span>
                    </div>
                  </th>
                  <th className="px-3.5 py-3.5 whitespace-nowrap text-right">
                    <div className="flex items-center justify-end gap-1.5 text-gray-700">
                      <span>Amount (₹)</span>
                      <span className="text-gray-400 text-xs">⇅</span>
                    </div>
                  </th>
                  <th className="px-3.5 py-3.5 whitespace-nowrap">
                    <div className="flex items-center gap-1.5 text-gray-700">
                      <span>Status</span>
                    </div>
                  </th>
                  <th className="px-3.5 py-3.5 whitespace-nowrap">
                    <div className="flex items-center gap-1.5 text-gray-700">
                      <span>Staff</span>
                      <span className="text-gray-400 text-xs">⇅</span>
                    </div>
                  </th>
                  <th className="px-3.5 py-3.5 text-right whitespace-nowrap"></th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 bg-white">
                {paginatedOrders.map((order) => {
                  const prefix =
                    order.type === 'proforma_invoice' ? 'PFI-' : 'INV-';
                  const formattedId = order.order_number.startsWith('PFI-') || order.order_number.startsWith('INV-')
                    ? order.order_number
                    : `${prefix}${order.order_number}`;

                  return (
                    <tr
                      key={order.id}
                      className="hover:bg-blue-50/20 transition-colors cursor-pointer"
                      onClick={() => onOpenDetail(order)}
                    >
                      {/* Date */}
                      <td className="px-3.5 py-3.5 whitespace-nowrap text-gray-700 font-medium text-xs uppercase">
                        {formatSalesDate(order.date)}
                      </td>

                      {/* ID */}
                      <td className="px-3.5 py-3.5 whitespace-nowrap">
                        <span className="text-[#1a237e] font-bold font-mono text-xs">
                          {formattedId}
                        </span>
                      </td>

                      {/* Contact (2 Lines: Name on top with user icon, Company below) */}
                      <td className="px-3.5 py-3.5">
                        <div className="flex items-start gap-1.5">
                          <User className="w-3.5 h-3.5 text-gray-400 shrink-0 mt-0.5" />
                          <div>
                            <div className="font-semibold text-gray-800 text-xs tracking-tight uppercase max-w-52 truncate">
                              {order.reference_name || 'Customer'}
                            </div>
                            <div className="text-gray-500 text-[11px] max-w-52 truncate mt-0.5">
                              {order.reference_name || '—'}
                            </div>
                          </div>
                        </div>
                      </td>

                      {/* Items */}
                      <td className="px-3.5 py-3.5 whitespace-nowrap">
                        <span className="text-[#1a237e] font-bold text-xs">
                          {order.items?.length || 1}
                        </span>
                      </td>

                      {/* REFERANCE */}
                      <td className="px-3.5 py-3.5 whitespace-nowrap">
                        <span className="border border-gray-400 text-gray-700 px-2 py-0.5 rounded text-[11px] font-semibold tracking-wide uppercase inline-block">
                          {order.staff_name || 'ISHA VORA'}
                        </span>
                      </td>

                      {/* NOTE */}
                      <td className="px-3.5 py-3.5 text-gray-600 text-xs max-w-36">
                        <span className="truncate block max-w-36">
                          {order.notes || ''}
                        </span>
                      </td>

                      {/* Amount (₹) */}
                      <td className="px-3.5 py-3.5 whitespace-nowrap text-right font-semibold text-gray-800 text-xs">
                        {formatCurrencyINR(order.total_amount)}
                      </td>

                      {/* Status */}
                      <td className="px-3.5 py-3.5 whitespace-nowrap">
                        {getOrderStatusPill(order.status)}
                      </td>

                      {/* Staff Avatar (Soft Lavender / Blue background, dark blue letters) */}
                      <td className="px-3.5 py-3.5 whitespace-nowrap">
                        <div
                          title={order.staff_name || 'Unassigned'}
                          className="w-8 h-8 rounded-full bg-[#e8eaf6] text-[#3949ab] text-xs font-bold flex items-center justify-center uppercase shrink-0"
                        >
                          {getInitials(order.staff_name)}
                        </div>
                      </td>

                      {/* Actions */}
                      <td
                        className="px-3.5 py-3.5 whitespace-nowrap text-right"
                        onClick={(e) => e.stopPropagation()}
                      >
                        <div className="flex items-center justify-end gap-1.5">
                          {/* Info Icon */}
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              onOpenDetail(order);
                            }}
                            title="View Details"
                            className="p-1 rounded hover:bg-blue-50 text-[#1a237e] transition-colors cursor-pointer"
                          >
                            <Info className="w-4 h-4 text-[#1a237e]" />
                          </button>
                          {/* Quick send icon (paper-plane) in blue */}
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              onOpenDetail(order);
                            }}
                            title="Send Document"
                            className="p-1 rounded hover:bg-blue-50 text-[#1a237e] transition-colors cursor-pointer"
                          >
                            <Send className="w-4 h-4 text-[#1a237e]" />
                          </button>
                          {/* Three dots dropdown menu */}
                          <OrderRowActions
                            order={order}
                            onOpenEdit={onOpenEdit}
                            onOpenDetail={onOpenDetail}
                            onDeleteOrder={onDeleteOrder}
                          />
                        </div>
                      </td>
                    </tr>
                  );
                })}

                {paginatedOrders.length === 0 && (
                  <tr>
                    <td
                      colSpan={10}
                      className="text-center py-16 text-gray-400 text-xs"
                    >
                      No {getSubTabTitle().toLowerCase()} match your current search or filters.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* ── PAYMENTS TABLE ── */}
        {subTab === 'payments' && (
          <div className="w-full flex-1 overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead className="bg-[#f8fafc] border-b border-gray-200 text-gray-600 font-semibold text-xs">
                <tr>
                  <th className="px-3.5 py-3.5">Payment #</th>
                  <th className="px-3.5 py-3.5">Invoice / Sales #</th>
                  <th className="px-3.5 py-3.5">Contact Name</th>
                  <th className="px-3.5 py-3.5">Mode</th>
                  <th className="px-3.5 py-3.5 text-right">Amount (₹)</th>
                  <th className="px-3.5 py-3.5">Date</th>
                  <th className="px-3.5 py-3.5">Staff</th>
                  <th className="px-3.5 py-3.5 text-right"></th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 bg-white">
                {filteredPayments.map((p) => (
                  <tr key={p.id} className="hover:bg-blue-50/20 transition-colors">
                    <td className="px-3.5 py-3.5 font-mono font-bold text-[#1a237e]">
                      {p.payment_number}
                    </td>
                    <td className="px-3.5 py-3.5 font-semibold text-gray-700">
                      {p.sales_id}
                    </td>
                    <td className="px-3.5 py-3.5 text-gray-800 font-medium">
                      {p.contact_name}
                    </td>
                    <td className="px-3.5 py-3.5">
                      <span className="px-2 py-0.5 rounded text-[11px] font-semibold bg-gray-100 text-gray-700">
                        {p.mode}
                      </span>
                    </td>
                    <td className="px-3.5 py-3.5 text-right font-bold text-gray-900">
                      ₹{formatCurrencyINR(p.amount)}
                    </td>
                    <td className="px-3.5 py-3.5 text-gray-600">
                      {formatSalesDate(p.date)}
                    </td>
                    <td className="px-3.5 py-3.5 whitespace-nowrap">
                      <div
                        title={p.staff_name || 'Staff'}
                        className="w-8 h-8 rounded-full bg-[#e8eaf6] text-[#3949ab] text-xs font-bold flex items-center justify-center uppercase shrink-0"
                      >
                        {getInitials(p.staff_name)}
                      </div>
                    </td>
                    <td className="px-3.5 py-3.5 text-right">
                      <button
                        onClick={() => {
                          if (window.confirm(`Delete payment #${p.payment_number}?`)) {
                            onDeletePayment(p.id);
                          }
                        }}
                        className="p-1 rounded text-gray-400 hover:text-rose-600 transition-colors"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))}
                {filteredPayments.length === 0 && (
                  <tr>
                    <td colSpan={8} className="text-center py-16 text-gray-400 text-xs">
                      No payment records found.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* ── INVENTORY TABLE ── */}
        {subTab === 'inventory' && (
          <div className="w-full flex-1 overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead className="bg-[#f8fafc] border-b border-gray-200 text-gray-600 font-semibold text-xs">
                <tr>
                  <th className="px-3.5 py-3.5">Item Name</th>
                  <th className="px-3.5 py-3.5">SKU</th>
                  <th className="px-3.5 py-3.5">Category</th>
                  <th className="px-3.5 py-3.5 text-center">In Stock</th>
                  <th className="px-3.5 py-3.5 text-right">Rate (₹)</th>
                  <th className="px-3.5 py-3.5">Status</th>
                  <th className="px-3.5 py-3.5 text-right">Stock Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 bg-white">
                {filteredInventory.map((item) => (
                  <tr key={item.id} className="hover:bg-blue-50/20 transition-colors">
                    <td className="px-3.5 py-3.5 font-bold text-gray-900">
                      {item.name}
                    </td>
                    <td className="px-3.5 py-3.5 font-mono text-gray-600">
                      {item.sku}
                    </td>
                    <td className="px-3.5 py-3.5 text-gray-600">
                      {item.category}
                    </td>
                    <td className="px-3.5 py-3.5 text-center font-bold text-sm text-[#1a237e]">
                      {item.quantity} {item.unit}
                    </td>
                    <td className="px-3.5 py-3.5 text-right font-semibold text-gray-800">
                      ₹{formatCurrencyINR(item.rate)}
                    </td>
                    <td className="px-3.5 py-3.5">
                      <span
                        className={`px-2 py-0.5 rounded-full text-[11px] font-semibold ${
                          item.quantity > item.min_stock
                            ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                            : 'bg-rose-50 text-rose-700 border border-rose-200'
                        }`}
                      >
                        {item.status}
                      </span>
                    </td>
                    <td className="px-3.5 py-3.5 text-right whitespace-nowrap">
                      <div className="flex items-center justify-end gap-1">
                        <button
                          onClick={() => onAdjustStock(item.id, -1)}
                          title="Reduce stock"
                          className="p-1 text-gray-500 hover:text-rose-600 cursor-pointer"
                        >
                          <MinusCircle className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => onAdjustStock(item.id, 1)}
                          title="Add stock"
                          className="p-1 text-gray-500 hover:text-emerald-600 cursor-pointer"
                        >
                          <PlusCircle className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => {
                            if (window.confirm(`Delete product ${item.name}?`)) {
                              onDeleteInventory(item.id);
                            }
                          }}
                          className="p-1 text-gray-400 hover:text-rose-600 cursor-pointer ml-1"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {filteredInventory.length === 0 && (
                  <tr>
                    <td colSpan={7} className="text-center py-16 text-gray-400 text-xs">
                      No inventory items found.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* ── BOTTOM TOTAL SUMMARY BAR (Exact UpTeams styling from screenshot) ── */}
        {isOrderView && (
          <div className="w-full px-4 py-2.5 bg-white border-t border-gray-200 flex flex-wrap items-center justify-between gap-3 text-xs">
            {/* 3 Summary Pills */}
            <div className="flex items-center gap-2 flex-wrap">
              <div className="px-3 py-1 rounded bg-blue-50 text-[#1a237e] border border-blue-200 font-bold text-xs">
                <span>Total </span>
                <span className="font-mono">₹{formatCurrencyINR(totalAmount)}</span>
              </div>
              <div className="px-3 py-1 rounded bg-emerald-50 text-[#059669] border border-emerald-200 font-bold text-xs">
                <span>Converted </span>
                <span className="font-mono">₹{formatCurrencyINR(convertedAmount)}</span>
              </div>
              <div className="px-3 py-1 rounded bg-amber-50 text-[#d97706] border border-amber-200 font-bold text-xs">
                <span>Open </span>
                <span className="font-mono">₹{formatCurrencyINR(openAmount)}</span>
              </div>
            </div>

            {/* Pagination Controls */}
            {totalPages > 1 && (
              <div className="flex items-center space-x-1 ml-auto text-gray-500 text-xs">
                <button
                  disabled={currentPage === 1}
                  onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                  className="px-2.5 py-1 border border-gray-200 rounded disabled:opacity-40 hover:bg-gray-50 cursor-pointer"
                >
                  Previous
                </button>
                <span className="px-2 font-medium">
                  {currentPage} / {totalPages}
                </span>
                <button
                  disabled={currentPage === totalPages}
                  onClick={() =>
                    setCurrentPage((p) => Math.min(totalPages, p + 1))
                  }
                  className="px-2.5 py-1 border border-gray-200 rounded disabled:opacity-40 hover:bg-gray-50 cursor-pointer"
                >
                  Next
                </button>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};
