import React, { useState, useRef, useEffect } from 'react';
import {
  Search,
  Plus,
  Send,
  MoreHorizontal,
  Edit2,
  Trash2,
  CornerUpRight,
  RefreshCw,
  Eye,
  Filter,
  Calendar,
  Tag,
  User as UserIcon,
  Download,
  ShieldAlert,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react';
import * as XLSX from 'xlsx';
import type { Lead } from '../../types/crm';
import { ConvertLeadModal } from './ConvertLeadModal';

interface LeadsListProps {
  leads: Lead[];
  onOpenAdd: () => void;
  onOpenEdit: (lead: Lead) => void;
  onOpenDetail: (lead: Lead) => void;
  onDelete: (id: string) => void;
  onConvertToCustomer?: (lead: Lead) => Promise<void> | void;
  staffList: string[];
}

interface StageTabConfig {
  id: string;
  label: string;
  borderInactive: string;
  textInactive: string;
  bgActive: string;
}

const STAGE_TABS: StageTabConfig[] = [
  {
    id: 'all',
    label: 'All',
    borderInactive: 'border-blue-500',
    textInactive: 'text-blue-600',
    bgActive: 'bg-[#2979ff] text-white',
  },
  {
    id: 'newLead',
    label: 'New',
    borderInactive: 'border-[#2196f3]',
    textInactive: 'text-[#2196f3]',
    bgActive: 'bg-[#2196f3] text-white',
  },
  {
    id: 'contacted',
    label: 'Contacted',
    borderInactive: 'border-[#ff9800]',
    textInactive: 'text-[#ff9800]',
    bgActive: 'bg-[#1a237e] text-white',
  },
  {
    id: 'proposalSent',
    label: 'Proposal Sent',
    borderInactive: 'border-[#00bcd4]',
    textInactive: 'text-[#00bcd4]',
    bgActive: 'bg-[#00bcd4] text-white',
  },
  {
    id: 'sampleSent',
    label: 'SAMPLE SENT',
    borderInactive: 'border-[#4caf50]',
    textInactive: 'text-[#4caf50]',
    bgActive: 'bg-[#4caf50] text-white',
  },
  {
    id: 'disqualified',
    label: 'Disqualified',
    borderInactive: 'border-[#f44336]',
    textInactive: 'text-[#f44336]',
    bgActive: 'bg-[#f44336] text-white',
  },
  {
    id: 'converted',
    label: 'Converted',
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

function formatDate(dateStr?: string): string {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  const now = new Date();
  const diff = now.setHours(0, 0, 0, 0) - d.setHours(0, 0, 0, 0);
  const daysDiff = Math.round(diff / 86400000);
  if (daysDiff === 0) return 'TODAY';
  if (daysDiff === 1) return 'YESTERDAY';
  if (daysDiff < 7) return `${daysDiff} DAYS AGO`;
  return new Date(dateStr)
    .toLocaleDateString('en-GB', {
      day: 'numeric',
      month: 'short',
    })
    .toUpperCase();
}

// Dropdown menu for each row's "..." button
function RowActionsMenu({
  lead,
  onOpenEdit,
  onDelete,
  onStartConvert,
}: {
  lead: Lead;
  onOpenEdit: (lead: Lead) => void;
  onDelete: (id: string) => void;
  onStartConvert: (lead: Lead) => void;
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
        <div className="absolute right-0 top-8 z-50 w-48 bg-white rounded-md shadow-xl border border-gray-200 py-1.5 text-xs">
          <button
            onClick={(e) => {
              e.stopPropagation();
              setOpen(false);
              onOpenEdit(lead);
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
              onStartConvert(lead);
            }}
            className="w-full flex items-center gap-2.5 px-3.5 py-2 text-gray-700 hover:bg-gray-50 cursor-pointer"
          >
            <CornerUpRight className="w-4 h-4 text-[#1a237e]" />
            <span>Convert to Customer</span>
          </button>
          <button
            onClick={(e) => {
              e.stopPropagation();
              setOpen(false);
              if (
                window.confirm(
                  `Delete lead #${lead.lead_number} (${lead.name})?`
                )
              ) {
                onDelete(lead.id);
              }
            }}
            className="w-full flex items-center gap-2.5 px-3.5 py-2 text-gray-700 hover:bg-rose-50 hover:text-rose-600 cursor-pointer"
          >
            <Trash2 className="w-4 h-4 text-[#1a237e]" />
            <span>Delete</span>
          </button>
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

export const LeadsList: React.FC<LeadsListProps> = ({
  leads,
  onOpenAdd,
  onOpenEdit,
  onOpenDetail,
  onDelete,
  onConvertToCustomer,
  staffList,
}) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [stageFilter, setStageFilter] = useState<string>('all');
  const [sourceFilter, setSourceFilter] = useState<string>('all');
  const [staffFilter, setStaffFilter] = useState<string>('all');
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);

  // State for Convert to Customer confirmation dialogue
  const [leadToConvert, setLeadToConvert] = useState<Lead | null>(null);
  const [isConverting, setIsConverting] = useState(false);

  // Stage counts
  const stageCounts = STAGE_TABS.reduce<Record<string, number>>((acc, tab) => {
    if (tab.id === 'all') {
      acc['all'] = leads.length;
    } else {
      acc[tab.id] = leads.filter((l) => l.stage === tab.id).length;
    }
    return acc;
  }, {});

  // Filter leads
  const filteredLeads = leads.filter((lead) => {
    const matchesSearch =
      lead.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (lead.company &&
        lead.company.toLowerCase().includes(searchTerm.toLowerCase())) ||
      lead.phone.includes(searchTerm) ||
      lead.lead_number.includes(searchTerm) ||
      (lead.email &&
        lead.email.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (lead.title &&
        lead.title.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchesStage = stageFilter === 'all' || lead.stage === stageFilter;
    const matchesSource =
      sourceFilter === 'all' || lead.source === sourceFilter;
    const matchesStaff =
      staffFilter === 'all' || lead.staff_name === staffFilter;

    return matchesSearch && matchesStage && matchesSource && matchesStaff;
  });

  const totalPages = Math.ceil(filteredLeads.length / itemsPerPage) || 1;
  const paginatedLeads = filteredLeads.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const handleDownloadAll = () => {
    if (filteredLeads.length === 0) {
      alert('No leads available to download.');
      return;
    }

    const exportRows = filteredLeads.map((lead) => ({
      ID: lead.lead_number || '',
      Name: lead.name || '',
      Location: [lead.city, lead.state].filter(Boolean).join(', ') || ' ',
      Area: lead.address || lead.territory || '',
      REFERANCE: (lead.source || '').toUpperCase(),
      Category:
        STAGE_TABS.find((t) => t.id === lead.stage)?.label || lead.stage || '',
      Active: !lead.is_closed ? 'Yes' : 'No',
      Staff: lead.staff_name || '',
      Phone: lead.phone || '',
      Email: lead.email || '',
      Company: lead.company || '',
    }));

    const worksheet = XLSX.utils.json_to_sheet(exportRows);

    // Auto-fit column widths
    const columnKeys = Object.keys(exportRows[0] || {});
    worksheet['!cols'] = columnKeys.map((key) => {
      let maxLen = key.length;
      for (const row of exportRows) {
        const val = String((row as Record<string, unknown>)[key] || '');
        if (val.length > maxLen) {
          maxLen = Math.min(val.length, 60);
        }
      }
      return { wch: Math.max(maxLen + 3, 10) };
    });

    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Leads');

    XLSX.writeFile(workbook, 'Leads.xlsx');
  };

  const handleConfirmConvert = async (lead: Lead) => {
    if (!onConvertToCustomer) return;
    setIsConverting(true);
    try {
      await onConvertToCustomer(lead);
    } finally {
      setIsConverting(false);
      setLeadToConvert(null);
    }
  };

  const getStagePill = (stage: Lead['stage']) => {
    switch (stage) {
      case 'disqualified':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-rose-50 text-rose-600 border border-rose-200">
            <span className="w-2 h-2 rounded-full bg-rose-500 shrink-0" />
            <span>Disqualified</span>
          </span>
        );
      case 'contacted':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-50 text-amber-600 border border-amber-200">
            <span className="w-2 h-2 rounded-full bg-amber-500 shrink-0" />
            <span>Contacted</span>
          </span>
        );
      case 'converted':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-600 border border-emerald-200">
            <span className="w-2 h-2 rounded-full bg-emerald-500 shrink-0" />
            <span>Converted</span>
          </span>
        );
      case 'proposalSent':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-cyan-50 text-cyan-600 border border-cyan-200">
            <span className="w-2 h-2 rounded-full bg-cyan-500 shrink-0" />
            <span>Proposal Sent</span>
          </span>
        );
      case 'sampleSent':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-teal-50 text-teal-600 border border-teal-200">
            <span className="w-2 h-2 rounded-full bg-teal-500 shrink-0" />
            <span>Sample Sent</span>
          </span>
        );
      case 'newLead':
      default:
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-50 text-blue-600 border border-blue-200">
            <span className="w-2 h-2 rounded-full bg-blue-500 shrink-0" />
            <span>New Lead</span>
          </span>
        );
    }
  };

  return (
    <div className="w-full bg-white flex flex-col min-h-screen text-gray-800">
      {/* ── TOP HEADER BAR (Flush edge-to-edge, MyTeams design) ── */}
      <div className="w-full bg-white px-4 py-2.5 border-b border-gray-200 flex flex-wrap items-center gap-2.5 shadow-2xs">
        {/* Title & Icon */}
        <div className="flex items-center gap-2 mr-1">
          <div className="w-7 h-7 rounded-md bg-[#1a237e] text-white flex items-center justify-center font-bold text-xs shadow-2xs">
            <ShieldAlert className="w-4 h-4 fill-white" />
          </div>
          <span className="text-base font-bold text-gray-900 tracking-tight">Leads</span>
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

        {/* Filter: Status */}
        <div className="flex items-center border border-gray-300 rounded px-2.5 py-1.5 bg-white text-xs text-gray-700">
          <select
            className="bg-transparent outline-none text-xs text-gray-700 cursor-pointer pr-1"
            value={stageFilter}
            onChange={(e) => {
              setStageFilter(e.target.value);
              setCurrentPage(1);
            }}
          >
            <option value="all">Status</option>
            <option value="all">All</option>
            <option value="newLead">New</option>
            <option value="contacted">Contacted</option>
            <option value="proposalSent">Proposal Sent</option>
            <option value="sampleSent">Sample Sent</option>
            <option value="disqualified">Disqualified</option>
            <option value="converted">Converted</option>
          </select>
          <Tag className="w-3.5 h-3.5 text-gray-400 shrink-0" />
        </div>

        {/* Filter: Date */}
        <div className="flex items-center border border-gray-300 rounded px-2.5 py-1.5 bg-white text-xs text-gray-700">
          <span className="pr-2 text-xs">All</span>
          <Calendar className="w-3.5 h-3.5 text-gray-400 shrink-0" />
        </div>

        {/* Filter: Source */}
        <div className="flex items-center border border-gray-300 rounded px-2.5 py-1.5 bg-white text-xs text-gray-700">
          <select
            className="bg-transparent outline-none text-xs text-gray-700 cursor-pointer pr-1"
            value={sourceFilter}
            onChange={(e) => {
              setSourceFilter(e.target.value);
              setCurrentPage(1);
            }}
          >
            <option value="all">Source</option>
            <option value="all">All Sources</option>
            <option value="call">Call</option>
            <option value="email">Email</option>
            <option value="website">Website</option>
            <option value="others">Others</option>
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

        {/* Action Icon Buttons (All in Add Lead button color #1a237e) */}
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

          {/* Import Button (Now in Add Lead button color #1a237e) */}
          <button
            className="flex items-center gap-1.5 px-3 py-1.5 bg-[#1a237e] hover:bg-[#151c65] text-white rounded text-xs font-semibold shadow-2xs transition-colors cursor-pointer"
          >
            <Download className="w-3.5 h-3.5" />
            <span>Import</span>
          </button>

          {/* + Add Lead Button (Dark Blue/Indigo) */}
          <button
            onClick={onOpenAdd}
            className="flex items-center gap-1.5 px-3.5 py-1.5 bg-[#1a237e] hover:bg-[#151c65] text-white rounded text-xs font-semibold shadow-2xs transition-colors cursor-pointer"
          >
            <Plus className="w-3.5 h-3.5" />
            <span>+ Add Lead</span>
          </button>
        </div>
      </div>

      {/* ── STAGE TABS BAR (Full-width, exact MyTeams styling) ── */}
      <div className="w-full bg-white px-4 py-2.5 border-b border-gray-200 flex items-center gap-2 overflow-x-auto">
        {STAGE_TABS.map((tab) => {
          const isActive = stageFilter === tab.id;
          const count = stageCounts[tab.id] ?? 0;
          return (
            <button
              key={tab.id}
              onClick={() => {
                setStageFilter(tab.id);
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

      {/* ── LEADS TABLE (Full-width edge-to-edge) ── */}
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
                  <span>Name</span>
                  <span className="text-gray-400 text-xs">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3.5 whitespace-nowrap">
                <div className="flex items-center gap-1.5 text-gray-700">
                  <span>Company</span>
                  <span className="text-gray-400 text-xs">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3.5 whitespace-nowrap">
                <div className="flex items-center gap-1.5 text-gray-700">
                  <span>Phone</span>
                  <span className="text-gray-400 text-xs">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3.5 whitespace-nowrap">
                <div className="flex items-center gap-1.5 text-gray-700">
                  <span>Email</span>
                  <span className="text-gray-400 text-xs">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3.5 whitespace-nowrap">
                <div className="flex items-center gap-1.5 text-gray-700">
                  <span>Title</span>
                  <span className="text-gray-400 text-xs">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3.5 whitespace-nowrap">
                <div className="flex items-center gap-1.5 text-gray-700">
                  <span>Note</span>
                  <span className="text-gray-400 text-xs">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3.5 whitespace-nowrap">
                <div className="flex items-center gap-1.5 text-gray-700">
                  <span>City</span>
                  <span className="text-gray-400 text-xs">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3.5 whitespace-nowrap">
                <div className="flex items-center gap-1.5 text-gray-700">
                  <span>Stage</span>
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
            {paginatedLeads.map((lead) => (
              <tr
                key={lead.id}
                className="hover:bg-blue-50/20 transition-colors cursor-pointer"
                onClick={() => onOpenDetail(lead)}
              >
                {/* Date */}
                <td className="px-3.5 py-3.5 whitespace-nowrap text-gray-700 font-medium text-xs uppercase">
                  {formatDate(lead.created_at)}
                </td>

                {/* ID */}
                <td className="px-3.5 py-3.5 whitespace-nowrap">
                  <span className="text-[#1a237e] font-bold font-mono text-sm">
                    {lead.lead_number}
                  </span>
                </td>

                {/* Name */}
                <td className="px-3.5 py-3.5">
                  <span className="font-semibold text-gray-800 text-xs uppercase tracking-tight block max-w-48 truncate">
                    {lead.name}
                  </span>
                </td>

                {/* Company */}
                <td className="px-3.5 py-3.5">
                  <span className="text-gray-700 text-xs block max-w-48 truncate">
                    {lead.company || lead.name || '—'}
                  </span>
                </td>

                {/* Phone */}
                <td className="px-3.5 py-3.5 whitespace-nowrap text-gray-700 text-xs font-medium">
                  {lead.phone}
                </td>

                {/* Email */}
                <td className="px-3.5 py-3.5 text-gray-500 text-xs max-w-36">
                  <span className="truncate block max-w-36">
                    {lead.email || ''}
                  </span>
                </td>

                {/* Title */}
                <td className="px-3.5 py-3.5 text-gray-700 text-xs">
                  <span className="truncate block max-w-40 font-normal uppercase">
                    {lead.title || ''}
                  </span>
                </td>

                {/* Note */}
                <td className="px-3.5 py-3.5 text-gray-600 text-xs">
                  <span className="truncate block max-w-40">
                    {lead.note || ''}
                  </span>
                </td>

                {/* City (2 lines: City top, State bottom) */}
                <td className="px-3.5 py-3.5 text-xs">
                  {lead.city ? (
                    <div>
                      <div className="font-semibold text-gray-800 uppercase text-xs">
                        {lead.city}
                      </div>
                      <div className="text-gray-400 uppercase text-[11px] tracking-wide mt-0.5">
                        {lead.state || 'INDIA'}
                      </div>
                    </div>
                  ) : (
                    <span className="text-gray-300">—</span>
                  )}
                </td>

                {/* Stage */}
                <td className="px-3.5 py-3.5 whitespace-nowrap">
                  {getStagePill(lead.stage)}
                </td>

                {/* Staff Avatar (Soft Lavender / Blue background, dark blue letters) */}
                <td className="px-3.5 py-3.5 whitespace-nowrap">
                  <div
                    title={lead.staff_name || 'Unassigned'}
                    className="w-8 h-8 rounded-full bg-[#e8eaf6] text-[#3949ab] text-xs font-bold flex items-center justify-center uppercase shrink-0"
                  >
                    {getInitials(lead.staff_name)}
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
                        onOpenDetail(lead);
                      }}
                      title="View Details"
                      className="p-1 rounded hover:bg-blue-50 text-[#1a237e] transition-colors cursor-pointer"
                    >
                      <Send className="w-4 h-4 text-[#1a237e]" />
                    </button>
                    {/* Three dots dropdown menu */}
                    <RowActionsMenu
                      lead={lead}
                      onOpenEdit={onOpenEdit}
                      onDelete={onDelete}
                      onStartConvert={(l) => setLeadToConvert(l)}
                    />
                  </div>
                </td>
              </tr>
            ))}

            {paginatedLeads.length === 0 && (
              <tr>
                <td
                  colSpan={12}
                  className="text-center py-16 text-gray-400 text-xs"
                >
                  No leads match your current search or filters.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* ── BOTTOM BAR: DOWNLOAD ALL & PAGINATION ── */}
      <div className="w-full px-4 py-3 border-t border-gray-200 flex flex-wrap items-center justify-between gap-3 text-xs text-gray-500 bg-white">
        {/* Left: Download All Button */}
        <div>
          <button
            onClick={handleDownloadAll}
            title="Download all leads in Excel format"
            className="inline-flex items-center gap-2 px-3.5 py-2 bg-[#1a237e] hover:bg-[#283593] text-white text-xs font-semibold rounded shadow-sm transition-colors cursor-pointer"
          >
            <Download className="w-4 h-4" />
            <span>Download All</span>
          </button>
        </div>

        {/* Right: Showing text, Page size dropdown, Page navigation */}
        <div className="flex flex-wrap items-center gap-3">
          <span className="text-gray-500 text-xs">
            Showing {filteredLeads.length === 0 ? 0 : (currentPage - 1) * itemsPerPage + 1} -{' '}
            {Math.min(currentPage * itemsPerPage, filteredLeads.length)} of{' '}
            {filteredLeads.length.toLocaleString()}
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
              disabled={currentPage === totalPages || filteredLeads.length === 0}
              onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
              className="min-w-[28px] h-7 px-1.5 rounded flex items-center justify-center text-blue-600 hover:bg-gray-100 disabled:text-gray-300 disabled:hover:bg-transparent disabled:cursor-not-allowed cursor-pointer transition-colors"
              title="Next page"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* ── PROPER ALERT / CONFIRMATION DIALOGUE FOR CONVERT TO CUSTOMER ── */}
      <ConvertLeadModal
        lead={leadToConvert}
        isOpen={!!leadToConvert}
        onClose={() => setLeadToConvert(null)}
        onConfirm={handleConfirmConvert}
        isConverting={isConverting}
      />
    </div>
  );
};
