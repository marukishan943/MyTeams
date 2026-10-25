import React, { useState, useRef, useEffect } from 'react';
import {
  Search,
  Plus,
  Send,
  MoreHorizontal,
  Edit2,
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
  Download,
  Ban,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react';
import * as XLSX from 'xlsx';
import type { SalesOrder, PaymentRecord, InventoryItem } from '../../types/crm';
import { CancelOrderModal } from './CancelOrderModal';
import { InventoryDetailModal } from './InventoryDetailModal';

interface SalesListProps {
  orders: SalesOrder[];
  payments: PaymentRecord[];
  inventory: InventoryItem[];
  onOpenAdd: (type: SalesOrder['type']) => void;
  onOpenEdit: (order: SalesOrder) => void;
  onOpenDetail: (order: SalesOrder) => void;
  onDeleteOrder: (id: string) => void;
  onOpenRecordPayment: () => void;
  onDeletePayment?: (id: string) => void;
  onOpenAddInventory: () => void;
  onAdjustStock?: (id: string, delta: number) => void;
  onDeleteInventory?: (id: string) => void;
  onUpdateStatus?: (id: string, newStatus: SalesOrder['status']) => Promise<void>;
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

// Download printable formatted document helper
function downloadOrderDocument(order: SalesOrder) {
  const isPFI = order.type === 'proforma_invoice';
  const prefix = isPFI ? 'PFI-' : 'INV-';
  const formattedId =
    order.order_number.startsWith('PFI-') || order.order_number.startsWith('INV-')
      ? order.order_number
      : `${prefix}${order.order_number}`;

  const docTitle = isPFI ? 'PROFORMA INVOICE' : 'TAX INVOICE';
  const printWindow = window.open('', '_blank');
  if (!printWindow) {
    window.print();
    return;
  }

  const itemsHtml =
    order.items && order.items.length > 0
      ? order.items
          .map(
            (it, idx) => `
        <tr>
          <td style="padding: 10px; border-bottom: 1px solid #e2e8f0; text-align: center;">${idx + 1}</td>
          <td style="padding: 10px; border-bottom: 1px solid #e2e8f0;">
            <strong>${it.product}</strong>
            ${it.description ? `<div style="font-size: 11px; color: #64748b;">${it.description}</div>` : ''}
          </td>
          <td style="padding: 10px; border-bottom: 1px solid #e2e8f0; text-align: center;">${it.quantity}</td>
          <td style="padding: 10px; border-bottom: 1px solid #e2e8f0; text-align: right;">₹${Number(it.rate || 0).toLocaleString('en-IN')}</td>
          <td style="padding: 10px; border-bottom: 1px solid #e2e8f0; text-align: right; font-weight: 600;">₹${(Number(it.quantity || 0) * Number(it.rate || 0)).toLocaleString('en-IN')}</td>
        </tr>
      `
          )
          .join('')
      : `<tr><td colspan="5" style="padding: 20px; text-align: center; color: #94a3b8;">General Sales Document Items</td></tr>`;

  printWindow.document.write(`
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>${docTitle} - ${formattedId}</title>
        <style>
          @page { size: A4; margin: 15mm; }
          body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            color: #1e293b;
            padding: 25px;
            margin: 0;
            background: #fff;
          }
          .header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            border-bottom: 2px solid #1a237e;
            padding-bottom: 18px;
            margin-bottom: 24px;
          }
          .company-name {
            font-size: 20px;
            font-weight: 800;
            color: #1a237e;
            letter-spacing: -0.5px;
          }
          .company-sub {
            font-size: 12px;
            color: #64748b;
            margin-top: 4px;
          }
          .doc-badge {
            text-align: right;
          }
          .doc-type {
            font-size: 22px;
            font-weight: 800;
            color: #1a237e;
            letter-spacing: 0.5px;
          }
          .doc-number {
            font-size: 15px;
            font-weight: 700;
            color: #475569;
            margin-top: 2px;
          }
          .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 24px;
            margin-bottom: 28px;
            font-size: 13px;
          }
          .info-box {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 12px 16px;
          }
          .info-title {
            font-size: 11px;
            text-transform: uppercase;
            font-weight: 700;
            color: #64748b;
            margin-bottom: 6px;
          }
          table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 24px;
            font-size: 13px;
          }
          thead th {
            background: #f1f5f9;
            color: #334155;
            font-weight: 700;
            padding: 10px;
            border-bottom: 2px solid #cbd5e1;
            text-align: left;
          }
          .totals-box {
            display: flex;
            justify-content: flex-end;
            margin-top: 20px;
          }
          .totals-table {
            width: 280px;
            font-size: 13px;
          }
          .totals-row {
            display: flex;
            justify-content: space-between;
            padding: 6px 0;
            border-bottom: 1px solid #e2e8f0;
          }
          .totals-row.grand {
            font-size: 16px;
            font-weight: 800;
            color: #1a237e;
            border-bottom: 2px solid #1a237e;
            padding-top: 10px;
          }
          .footer-note {
            margin-top: 40px;
            padding-top: 15px;
            border-top: 1px solid #e2e8f0;
            font-size: 11px;
            color: #94a3b8;
            text-align: center;
          }
        </style>
      </head>
      <body>
        <div class="header">
          <div>
            <div class="company-name">IV SQUARE STRUCTURE INDIA PVT LTD</div>
            <div class="company-sub">Corporate Office • Rajkot, Gujarat, India</div>
          </div>
          <div class="doc-badge">
            <div class="doc-type">${docTitle}</div>
            <div class="doc-number">${formattedId}</div>
          </div>
        </div>

        <div class="info-grid">
          <div class="info-box">
            <div class="info-title">Bill To / Customer</div>
            <div style="font-size: 15px; font-weight: 700; color: #0f172a;">${order.reference_name || 'Customer'}</div>
            ${order.notes ? `<div style="margin-top: 6px; color: #475569;">${order.notes}</div>` : ''}
          </div>
          <div class="info-box">
            <div class="info-title">Document Details</div>
            <div><strong>Date:</strong> ${new Date(order.date).toLocaleDateString('en-GB')}</div>
            ${order.due_date ? `<div><strong>Due Date:</strong> ${new Date(order.due_date).toLocaleDateString('en-GB')}</div>` : ''}
            <div><strong>Staff:</strong> ${order.staff_name || '—'}</div>
            <div><strong>Status:</strong> ${order.status.toUpperCase()}</div>
          </div>
        </div>

        <table>
          <thead>
            <tr>
              <th style="width: 40px; text-align: center;">#</th>
              <th>Item & Description</th>
              <th style="width: 70px; text-align: center;">Qty</th>
              <th style="width: 110px; text-align: right;">Rate (₹)</th>
              <th style="width: 120px; text-align: right;">Amount (₹)</th>
            </tr>
          </thead>
          <tbody>
            ${itemsHtml}
          </tbody>
        </table>

        <div class="totals-box">
          <div class="totals-table">
            <div class="totals-row">
              <span style="color: #64748b;">Taxable Amount:</span>
              <span>₹${Number(order.taxable_amount || order.total_amount || 0).toLocaleString('en-IN')}</span>
            </div>
            ${
              order.total_discount
                ? `
              <div class="totals-row">
                <span style="color: #64748b;">Discount:</span>
                <span style="color: #10b981;">-₹${Number(order.total_discount).toLocaleString('en-IN')}</span>
              </div>
            `
                : ''
            }
            <div class="totals-row grand">
              <span>Total Amount:</span>
              <span>₹${Number(order.total_amount || 0).toLocaleString('en-IN')}</span>
            </div>
          </div>
        </div>

        <div class="footer-note">
          This is a computer generated document. Generated from MY TEAMS CRM.
        </div>

        <script>
          window.onload = function() {
            setTimeout(function() {
              window.print();
            }, 300);
          };
        <\/script>
      </body>
    </html>
  `);
  printWindow.document.close();
}

// Dropdown menu for each order's "..." button
// Proforma Invoices: View, Download, Cancel
// Invoices: View, Download, Edit
function OrderRowActions({
  order,
  onOpenView,
  onDownload,
  onOpenEdit,
  onRequestCancel,
}: {
  order: SalesOrder;
  onOpenView: (order: SalesOrder) => void;
  onDownload: (order: SalesOrder) => void;
  onOpenEdit: (order: SalesOrder) => void;
  onRequestCancel: (order: SalesOrder) => void;
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

  const isProforma = order.type === 'proforma_invoice';

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
          {/* Option 1: View */}
          <button
            onClick={(e) => {
              e.stopPropagation();
              setOpen(false);
              onOpenView(order);
            }}
            className="w-full flex items-center gap-2.5 px-3.5 py-2 text-gray-700 hover:bg-gray-50 cursor-pointer"
          >
            <Eye className="w-4 h-4 text-[#1a237e]" />
            <span>View</span>
          </button>

          {/* Option 2: Download */}
          <button
            onClick={(e) => {
              e.stopPropagation();
              setOpen(false);
              onDownload(order);
            }}
            className="w-full flex items-center gap-2.5 px-3.5 py-2 text-gray-700 hover:bg-gray-50 cursor-pointer"
          >
            <Download className="w-4 h-4 text-[#1a237e]" />
            <span>Download</span>
          </button>

          {/* Option 3: Proforma -> Cancel | Invoice -> Edit */}
          {isProforma ? (
            <button
              onClick={(e) => {
                e.stopPropagation();
                setOpen(false);
                onRequestCancel(order);
              }}
              className="w-full flex items-center gap-2.5 px-3.5 py-2 text-rose-600 hover:bg-rose-50 cursor-pointer"
            >
              <Ban className="w-4 h-4 text-rose-500" />
              <span>Cancel</span>
            </button>
          ) : (
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
          )}
        </div>
      )}
    </div>
  );
}

function getPageNumbers(current: number, total: number): (number | string)[] {
  if (total <= 7) {
    return Array.from({ length: total }, (_, i) => i + 1);
  }
  if (current <= 4) {
    return [1, 2, 3, 4, 5, '...', total];
  }
  if (current >= total - 3) {
    return [1, '...', total - 4, total - 3, total - 2, total - 1, total];
  }
  return [1, '...', current - 1, current, current + 1, '...', total];
}

export const SalesList: React.FC<SalesListProps> = ({
  orders,
  payments,
  inventory,
  onOpenAdd,
  onOpenEdit,
  onOpenDetail,
  onDeleteOrder: _onDeleteOrder,
  onOpenRecordPayment,
  onDeletePayment: _onDeletePayment,
  onOpenAddInventory,
  onAdjustStock: _onAdjustStock,
  onDeleteInventory: _onDeleteInventory,
  onUpdateStatus,
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
  const [itemsPerPage, setItemsPerPage] = useState(10);

  // Confirmation alert dialogue state for Cancel Proforma Invoice
  const [cancelModalOrder, setCancelModalOrder] = useState<SalesOrder | null>(null);
  const [isCancellingOrder, setIsCancellingOrder] = useState(false);

  // Detail modal state for Inventory item info
  const [detailInventoryItem, setDetailInventoryItem] = useState<InventoryItem | null>(null);

  const handleConfirmCancelOrder = async (orderId: string) => {
    if (!onUpdateStatus) return;
    setIsCancellingOrder(true);
    try {
      await onUpdateStatus(orderId, 'cancelled');
    } finally {
      setIsCancellingOrder(false);
      setCancelModalOrder(null);
    }
  };

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

  const paginatedPayments = filteredPayments.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const paginatedInventory = filteredInventory.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const handleDownloadAll = () => {
    if (subTab === 'proforma_invoice' || subTab === 'invoice') {
      if (filteredOrders.length === 0) {
        alert('No records available to download.');
        return;
      }

      const isPFI = subTab === 'proforma_invoice';
      const exportRows = filteredOrders.map((o) => ({
        'Order No': o.order_number || '',
        'Type': isPFI ? 'Proforma Invoice' : 'Tax Invoice',
        'Date': o.date ? new Date(o.date).toLocaleDateString('en-GB') : '',
        'Customer': o.reference_name || '',
        'Total Amount (₹)': o.total_amount || 0,
        'Status': o.status?.toUpperCase() || '',
        'Staff': o.staff_name || '',
        'Due Date': o.due_date ? new Date(o.due_date).toLocaleDateString('en-GB') : '',
        'Notes': o.notes || '',
      }));

      const worksheet = XLSX.utils.json_to_sheet(exportRows);
      const columnKeys = Object.keys(exportRows[0] || {});
      worksheet['!cols'] = columnKeys.map((key) => {
        let maxLen = key.length;
        for (const row of exportRows) {
          const val = String((row as Record<string, unknown>)[key] || '');
          if (val.length > maxLen) maxLen = Math.min(val.length, 60);
        }
        return { wch: Math.max(maxLen + 3, 10) };
      });

      const workbook = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(
        workbook,
        worksheet,
        isPFI ? 'Proforma Invoices' : 'Invoices'
      );
      XLSX.writeFile(
        workbook,
        isPFI ? 'Sales_Orders.xlsx' : 'Invoices.xlsx'
      );
    } else if (subTab === 'payments') {
      if (filteredPayments.length === 0) {
        alert('No payments available to download.');
        return;
      }

      const exportRows = filteredPayments.map((p) => ({
        'Payment No': p.payment_number || p.id || '',
        'Sales ID': p.sales_id || '',
        'Customer': p.contact_name || '',
        'Company': p.company_name || '',
        'Amount (₹)': p.amount || 0,
        'Mode': p.mode?.toUpperCase() || '',
        'Date': p.date ? new Date(p.date).toLocaleDateString('en-GB') : '',
        'Staff': p.staff_name || '',
      }));

      const worksheet = XLSX.utils.json_to_sheet(exportRows);
      const workbook = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(workbook, worksheet, 'Payments');
      XLSX.writeFile(workbook, 'Payments.xlsx');
    } else if (subTab === 'inventory') {
      if (filteredInventory.length === 0) {
        alert('No inventory items available to download.');
        return;
      }

      const exportRows = filteredInventory.map((i) => ({
        'Item Name': i.name || '',
        'SKU': i.sku || '',
        'Category': i.category || '',
        'Quantity': i.quantity || 0,
        'Unit': i.unit || '',
        'Rate (₹)': i.rate || 0,
        'Min Stock': i.min_stock || 0,
        'Status': i.status || '',
      }));

      const worksheet = XLSX.utils.json_to_sheet(exportRows);
      const workbook = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(workbook, worksheet, 'Inventory');
      XLSX.writeFile(workbook, 'Inventory.xlsx');
    }
  };

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
                            onOpenView={onOpenDetail}
                            onDownload={downloadOrderDocument}
                            onOpenEdit={onOpenEdit}
                            onRequestCancel={(ord) => setCancelModalOrder(ord)}
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
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 bg-white">
                {paginatedPayments.map((p) => (
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
                  </tr>
                ))}
                {filteredPayments.length === 0 && (
                  <tr>
                    <td colSpan={7} className="text-center py-16 text-gray-400 text-xs">
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
                  <th className="px-3.5 py-3.5 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 bg-white">
                {paginatedInventory.map((item) => (
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
                      <button
                        onClick={() => setDetailInventoryItem(item)}
                        title="View Product Details"
                        className="p-1.5 rounded hover:bg-blue-50 text-[#1a237e] transition-colors cursor-pointer"
                      >
                        <Info className="w-4 h-4 text-[#1a237e]" />
                      </button>
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

        {/* ── BOTTOM SUMMARY BAR & PAGINATION ── */}
        <div className="w-full px-4 py-3 bg-white border-t border-gray-200 flex flex-wrap items-center justify-between gap-3 text-xs text-gray-500">
          {/* Left: Download All Button & Order Summary Pills */}
          <div className="flex items-center gap-3 flex-wrap">
            <button
              onClick={handleDownloadAll}
              title={`Download all ${getSubTabTitle()} in Excel format`}
              className="inline-flex items-center gap-2 px-3.5 py-2 bg-[#1a237e] hover:bg-[#283593] text-white text-xs font-semibold rounded shadow-sm transition-colors cursor-pointer"
            >
              <Download className="w-4 h-4" />
              <span>Download All</span>
            </button>

            {isOrderView && (
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
            )}
          </div>

          {/* Right: Showing text, Page size dropdown, Page navigation */}
          <div className="flex flex-wrap items-center gap-3">
            <span className="text-gray-500 text-xs">
              Showing {totalItems === 0 ? 0 : (currentPage - 1) * itemsPerPage + 1} -{' '}
              {Math.min(currentPage * itemsPerPage, totalItems)} of{' '}
              {totalItems.toLocaleString()}
            </span>

            {/* Page size dropdown */}
            <select
              value={itemsPerPage}
              onChange={(e) => {
                setItemsPerPage(Number(e.target.value));
                setCurrentPage(1);
              }}
              className="border border-gray-300 rounded px-2 py-1 text-xs text-gray-700 bg-white focus:outline-none focus:ring-1 focus:ring-[#1a237e] cursor-pointer"
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
                className="min-w-[28px] h-7 px-1.5 rounded flex items-center justify-center text-blue-600 hover:bg-gray-100 disabled:text-gray-300 disabled:hover:bg-transparent disabled:cursor-not-allowed cursor-pointer transition-colors"
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
                        ? 'bg-[#1a237e] text-white font-semibold shadow-xs'
                        : 'text-blue-600 hover:bg-gray-100 font-normal'
                    }`}
                  >
                    {p}
                  </button>
                );
              })}

              <button
                disabled={currentPage === totalPages || totalItems === 0}
                onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                className="min-w-[28px] h-7 px-1.5 rounded flex items-center justify-center text-blue-600 hover:bg-gray-100 disabled:text-gray-300 disabled:hover:bg-transparent disabled:cursor-not-allowed cursor-pointer transition-colors"
                title="Next page"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* ── CONFIRMATION ALERT DIALOGUE FOR CANCEL PROFORMA INVOICE ── */}
      <CancelOrderModal
        order={cancelModalOrder}
        isOpen={!!cancelModalOrder}
        onClose={() => setCancelModalOrder(null)}
        onConfirm={handleConfirmCancelOrder}
        isCancelling={isCancellingOrder}
      />

      {/* ── INVENTORY PRODUCT DETAILS MODAL ── */}
      <InventoryDetailModal
        item={detailInventoryItem}
        isOpen={!!detailInventoryItem}
        onClose={() => setDetailInventoryItem(null)}
      />
    </div>
  );
};
