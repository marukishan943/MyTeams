import React, { useState, useRef, useEffect } from 'react';
import {
  Search,
  Plus,
  Send,
  MoreHorizontal,
  Edit2,
  Check,
  XCircle,
  RefreshCw,
  Eye,
  Filter,
  Calendar,
  Tag,
  User as UserIcon,
  Download,
  Contact,
} from 'lucide-react';
import type { Customer } from '../../types/crm';

interface CustomersListProps {
  customers: Customer[];
  onOpenAdd: () => void;
  onOpenEdit: (customer: Customer) => void;
  onOpenDetail: (customer: Customer) => void;
  onDelete: (id: string) => void;
  onToggleStatus?: (customerId: string, currentStatus: 'Active' | 'Inactive') => void;
  staffList?: string[];
}

interface CategoryTabConfig {
  id: string;
  label: string;
  borderInactive: string;
  textInactive: string;
  bgActive: string;
}

const CUSTOMER_TABS: CategoryTabConfig[] = [
  {
    id: 'all',
    label: 'All',
    borderInactive: 'border-blue-500',
    textInactive: 'text-blue-600',
    bgActive: 'bg-[#1a237e] text-white',
  },
  {
    id: 'New',
    label: 'New',
    borderInactive: 'border-blue-400',
    textInactive: 'text-blue-500',
    bgActive: 'bg-[#2196f3] text-white',
  },
  {
    id: 'Bronze',
    label: 'Bronze',
    borderInactive: 'border-[#00bcd4]',
    textInactive: 'text-[#00bcd4]',
    bgActive: 'bg-[#00bcd4] text-white',
  },
  {
    id: 'Silver',
    label: 'Silver',
    borderInactive: 'border-gray-400',
    textInactive: 'text-gray-500',
    bgActive: 'bg-gray-500 text-white',
  },
  {
    id: 'Gold',
    label: 'Gold',
    borderInactive: 'border-[#ffb300]',
    textInactive: 'text-[#ffb300]',
    bgActive: 'bg-[#ffb300] text-white',
  },
  {
    id: 'Platinum',
    label: 'Platinum',
    borderInactive: 'border-[#4caf50]',
    textInactive: 'text-[#4caf50]',
    bgActive: 'bg-[#4caf50] text-white',
  },
];

function getInitials(name?: string): string {
  if (!name) return '??';
  const parts = name.trim().split(/\s+/);
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

function formatCustomerNumber(num?: string): string {
  if (!num) return '000';
  const clean = num.replace(/^#/, '');
  return clean.padStart(3, '0');
}

// Row Actions Dropdown Menu
function CustomerRowActions({
  customer,
  onOpenEdit,
  onToggleStatus,
}: {
  customer: Customer;
  onOpenEdit: (customer: Customer) => void;
  onToggleStatus?: (customerId: string, currentStatus: 'Active' | 'Inactive') => void;
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
              onOpenEdit(customer);
            }}
            className="w-full flex items-center gap-2.5 px-3.5 py-2 text-gray-700 hover:bg-gray-50 cursor-pointer"
          >
            <Edit2 className="w-4 h-4 text-[#1a237e]" />
            <span>Edit</span>
          </button>
          {onToggleStatus && (
            <button
              onClick={(e) => {
                e.stopPropagation();
                setOpen(false);
                onToggleStatus(customer.id, customer.status);
              }}
              className="w-full flex items-center gap-2.5 px-3.5 py-2 text-gray-700 hover:bg-gray-50 cursor-pointer"
            >
              {customer.status === 'Active' ? (
                <>
                  <XCircle className="w-4 h-4 text-[#1a237e]" />
                  <span>Inactive</span>
                </>
              ) : (
                <>
                  <Check className="w-4 h-4 text-emerald-600" />
                  <span>Active</span>
                </>
              )}
            </button>
          )}
        </div>
      )}
    </div>
  );
}

export const CustomersList: React.FC<CustomersListProps> = ({
  customers,
  onOpenAdd,
  onOpenEdit,
  onOpenDetail,
  onToggleStatus,
  staffList = [],
}) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [staffFilter, setStaffFilter] = useState<string>('all');
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 20;

  // Tab counts
  const tabCounts = CUSTOMER_TABS.reduce<Record<string, number>>((acc, tab) => {
    if (tab.id === 'all') {
      acc['all'] = customers.length;
    } else if (tab.id === 'New') {
      // In UpTeams, newly converted or retail customers are "New"
      acc['New'] = customers.filter(
        (c) => c.category === 'Retailer' || c.category === 'Other' || !c.category
      ).length;
    } else {
      acc[tab.id] = customers.filter((c) => c.category === tab.id).length;
    }
    return acc;
  }, {});

  // Filter customers
  const filteredCustomers = customers.filter((cust) => {
    const matchesSearch =
      cust.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (cust.company && cust.company.toLowerCase().includes(searchTerm.toLowerCase())) ||
      cust.phone.includes(searchTerm) ||
      cust.customer_number.includes(searchTerm) ||
      (cust.address && cust.address.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (cust.city && cust.city.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchesCategory =
      categoryFilter === 'all' ||
      (categoryFilter === 'New'
        ? cust.category === 'Retailer' || cust.category === 'Other' || !cust.category
        : cust.category === categoryFilter);

    const matchesStatus =
      statusFilter === 'all' || cust.status === statusFilter;

    const matchesStaff =
      staffFilter === 'all' || cust.staff_name === staffFilter;

    return matchesSearch && matchesCategory && matchesStatus && matchesStaff;
  });

  const totalPages = Math.ceil(filteredCustomers.length / itemsPerPage) || 1;
  const paginatedCustomers = filteredCustomers.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const isAllSelected =
    paginatedCustomers.length > 0 &&
    paginatedCustomers.every((c) => selectedIds.includes(c.id));

  const toggleSelectAll = () => {
    if (isAllSelected) {
      setSelectedIds([]);
    } else {
      setSelectedIds(paginatedCustomers.map((c) => c.id));
    }
  };

  const toggleSelectRow = (id: string) => {
    setSelectedIds((prev) =>
      prev.includes(id) ? prev.filter((i) => i !== id) : [...prev, id]
    );
  };

  return (
    <div className="w-full bg-white flex flex-col min-h-screen text-gray-800">
      {/* ── TOP HEADER BAR (Flush edge-to-edge, exact UpTeams styling) ── */}
      <div className="w-full bg-white px-4 py-2.5 border-b border-gray-200 flex flex-wrap items-center gap-2.5 shadow-2xs">
        {/* Title & Contact Icon */}
        <div className="flex items-center gap-2 mr-1">
          <div className="w-7 h-7 rounded-md bg-[#1a237e] text-white flex items-center justify-center font-bold text-xs shadow-2xs">
            <Contact className="w-4 h-4 fill-white" />
          </div>
          <span className="text-base font-bold text-gray-900 tracking-tight">Customers</span>
        </div>

        {/* Search */}
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

        {/* Filter: Status */}
        <div className="flex items-center border border-gray-300 rounded px-2.5 py-1.5 bg-white text-xs text-gray-700">
          <select
            className="bg-transparent outline-none text-xs text-gray-700 cursor-pointer pr-1"
            value={statusFilter}
            onChange={(e) => {
              setStatusFilter(e.target.value);
              setCurrentPage(1);
            }}
          >
            <option value="all">Status</option>
            <option value="all">All Status</option>
            <option value="Active">Active</option>
            <option value="Inactive">Inactive</option>
          </select>
          <Tag className="w-3.5 h-3.5 text-gray-400 shrink-0" />
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
            <option value="all">All</option>
            {staffList.map((st) => (
              <option key={st} value={st}>
                {st}
              </option>
            ))}
          </select>
          <UserIcon className="w-3.5 h-3.5 text-gray-400 shrink-0" />
        </div>

        {/* Action Icon Buttons (All in Add Lead/Customer color #1a237e) */}
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

          {/* Import Button */}
          <button
            className="flex items-center gap-1.5 px-3 py-1.5 bg-[#1a237e] hover:bg-[#151c65] text-white rounded text-xs font-semibold shadow-2xs transition-colors cursor-pointer"
          >
            <Download className="w-3.5 h-3.5" />
            <span>Import</span>
          </button>

          {/* + Add Customer Button */}
          <button
            onClick={onOpenAdd}
            className="flex items-center gap-1.5 px-3.5 py-1.5 bg-[#1a237e] hover:bg-[#151c65] text-white rounded text-xs font-semibold shadow-2xs transition-colors cursor-pointer"
          >
            <Plus className="w-3.5 h-3.5" />
            <span>+ Add Customer</span>
          </button>
        </div>
      </div>

      {/* ── CATEGORY TABS BAR (All, New, Bronze, Silver, Gold, Platinum) ── */}
      <div className="w-full bg-white px-4 py-2.5 border-b border-gray-200 flex items-center gap-2 overflow-x-auto">
        {CUSTOMER_TABS.map((tab) => {
          const isActive = categoryFilter === tab.id;
          const count = tabCounts[tab.id] ?? 0;
          return (
            <button
              key={tab.id}
              onClick={() => {
                setCategoryFilter(tab.id);
                setCurrentPage(1);
              }}
              className={`px-3 py-1 rounded text-xs font-bold whitespace-nowrap transition-all cursor-pointer border ${
                isActive
                  ? `${tab.bgActive} border-transparent shadow-2xs`
                  : `bg-white ${tab.textInactive} ${tab.borderInactive} hover:opacity-85`
              }`}
            >
              <span>{tab.label}</span>
              <span className="ml-1.5">{count}</span>
            </button>
          );
        })}
      </div>

      {/* ── CUSTOMERS TABLE (Full-width edge-to-edge) ── */}
      <div className="w-full flex-1 overflow-x-auto">
        <table className="w-full text-left text-xs border-collapse">
          <thead className="bg-[#f8fafc] border-b border-gray-200 text-gray-600 font-semibold text-xs">
            <tr>
              {/* Checkbox */}
              <th className="px-3.5 py-3.5 w-10 text-center">
                <input
                  type="checkbox"
                  checked={isAllSelected}
                  onChange={toggleSelectAll}
                  className="rounded border-gray-300 text-[#1a237e] focus:ring-[#1a237e] cursor-pointer"
                />
              </th>
              <th className="px-3.5 py-3.5 whitespace-nowrap">
                <div className="flex items-center gap-1.5 text-gray-700">
                  <span>ID</span>
                  <span className="text-gray-400 text-xs">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3.5 whitespace-nowrap">
                <div className="flex items-center gap-1.5 text-gray-700">
                  <span>Name</span>
                  <span className="text-gray-400 text-xs">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3.5 whitespace-nowrap">
                <div className="flex items-center gap-1.5 text-gray-700">
                  <span>Location Area</span>
                  <span className="text-gray-400 text-xs">⇅</span>
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
                  <span>Category</span>
                  <span className="text-gray-400 text-xs">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3.5 whitespace-nowrap text-center">
                <div className="flex items-center justify-center gap-1.5 text-gray-700">
                  <span>Active</span>
                  <span className="text-gray-400 text-xs">⇅</span>
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
            {paginatedCustomers.map((cust) => {
              const isSelected = selectedIds.includes(cust.id);
              const locationText =
                [cust.address, cust.city, cust.state, cust.pincode]
                  .filter(Boolean)
                  .join(', ') || '—';

              return (
                <tr
                  key={cust.id}
                  className={`hover:bg-blue-50/20 transition-colors cursor-pointer ${
                    isSelected ? 'bg-blue-50/30' : ''
                  }`}
                  onClick={() => onOpenDetail(cust)}
                >
                  {/* Checkbox */}
                  <td
                    className="px-3.5 py-3.5 w-10 text-center"
                    onClick={(e) => e.stopPropagation()}
                  >
                    <input
                      type="checkbox"
                      checked={isSelected}
                      onChange={() => toggleSelectRow(cust.id)}
                      className="rounded border-gray-300 text-[#1a237e] focus:ring-[#1a237e] cursor-pointer"
                    />
                  </td>

                  {/* ID */}
                  <td className="px-3.5 py-3.5 whitespace-nowrap">
                    <span className="text-[#1a237e] font-bold font-mono text-sm">
                      {formatCustomerNumber(cust.customer_number)}
                    </span>
                  </td>

                  {/* Name (2 Lines: Name on top, Company below) */}
                  <td className="px-3.5 py-3.5">
                    <div>
                      <div className="font-semibold text-gray-800 text-xs tracking-tight uppercase max-w-56 truncate">
                        {cust.name}
                      </div>
                      {cust.company && (
                        <div className="text-gray-500 text-[11px] max-w-56 truncate mt-0.5">
                          {cust.company}
                        </div>
                      )}
                    </div>
                  </td>

                  {/* Location Area */}
                  <td className="px-3.5 py-3.5 text-gray-700 text-xs max-w-md">
                    <span className="line-clamp-2 leading-relaxed">
                      {locationText}
                    </span>
                  </td>

                  {/* REFERANCE */}
                  <td className="px-3.5 py-3.5 whitespace-nowrap">
                    <span className="border border-gray-400 text-gray-700 px-2.5 py-0.5 rounded text-[11px] font-semibold tracking-wide uppercase inline-block">
                      {cust.created_by || cust.staff_name || 'ISHA VORA'}
                    </span>
                  </td>

                  {/* Category Pill (e.g. ● New) */}
                  <td className="px-3.5 py-3.5 whitespace-nowrap">
                    <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-50 text-blue-600 border border-blue-200">
                      <span className="w-2 h-2 rounded-full bg-blue-500 shrink-0" />
                      <span>{cust.category || 'New'}</span>
                    </span>
                  </td>

                  {/* Active (Checkmark icon if Active) */}
                  <td className="px-3.5 py-3.5 whitespace-nowrap text-center">
                    {cust.status === 'Active' ? (
                      <Check className="w-4 h-4 text-[#1a237e] mx-auto stroke-[2.5]" />
                    ) : (
                      <span className="text-gray-300 text-xs">—</span>
                    )}
                  </td>

                  {/* Staff Avatar (Soft Lavender / Blue background, dark blue letters) */}
                  <td className="px-3.5 py-3.5 whitespace-nowrap">
                    <div
                      title={cust.staff_name || 'Unassigned'}
                      className="w-8 h-8 rounded-full bg-[#e8eaf6] text-[#3949ab] text-xs font-bold flex items-center justify-center uppercase shrink-0"
                    >
                      {getInitials(cust.staff_name || cust.created_by)}
                    </div>
                  </td>

                  {/* Actions */}
                  <td
                    className="px-3.5 py-3.5 whitespace-nowrap text-right"
                    onClick={(e) => e.stopPropagation()}
                  >
                    <div className="flex items-center justify-end gap-1.5">
                      {/* Quick send icon (paper-plane) in blue */}
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          onOpenDetail(cust);
                        }}
                        title="View Details"
                        className="p-1 rounded hover:bg-blue-50 text-[#1a237e] transition-colors cursor-pointer"
                      >
                        <Send className="w-4 h-4 text-[#1a237e]" />
                      </button>
                      {/* Three dots dropdown menu (Edit / Inactive) */}
                      <CustomerRowActions
                        customer={cust}
                        onOpenEdit={onOpenEdit}
                        onToggleStatus={onToggleStatus}
                      />
                    </div>
                  </td>
                </tr>
              );
            })}

            {paginatedCustomers.length === 0 && (
              <tr>
                <td
                  colSpan={9}
                  className="text-center py-16 text-gray-400 text-xs"
                >
                  No customers match your current search or filters.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* ── PAGINATION BAR ── */}
      {totalPages > 1 && (
        <div className="w-full px-4 py-2.5 border-t border-gray-200 flex items-center justify-between text-xs text-gray-500 bg-white">
          <div>
            Showing {(currentPage - 1) * itemsPerPage + 1}–
            {Math.min(currentPage * itemsPerPage, filteredCustomers.length)} of{' '}
            {filteredCustomers.length} customers
          </div>
          <div className="flex items-center space-x-1">
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
        </div>
      )}
    </div>
  );
};
