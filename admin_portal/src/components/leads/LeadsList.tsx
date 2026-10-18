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
} from 'lucide-react';
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
        className="p-1.5 rounded hover:bg-gray-100 text-[#1976d2] transition-colors cursor-pointer"
        title="More actions"
      >
        <MoreHorizontal className="w-4 h-4 text-[#1976d2]" />
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
            <Edit2 className="w-4 h-4 text-[#1976d2]" />
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
            <CornerUpRight className="w-4 h-4 text-[#1976d2]" />
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
            <Trash2 className="w-4 h-4 text-[#1976d2]" />
            <span>Delete</span>
          </button>
        </div>
      )}
    </div>
  );
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
  const itemsPerPage = 20;

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
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-rose-50 text-rose-600 border border-rose-200">
            <span className="w-1.5 h-1.5 rounded-full bg-rose-500 shrink-0" />
            <span>Disqualified</span>
          </span>
        );
      case 'contacted':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-600 border border-amber-200">
            <span className="w-1.5 h-1.5 rounded-full bg-amber-500 shrink-0" />
            <span>Contacted</span>
          </span>
        );
      case 'converted':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-600 border border-emerald-200">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 shrink-0" />
            <span>Converted</span>
          </span>
        );
      case 'proposalSent':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-cyan-50 text-cyan-600 border border-cyan-200">
            <span className="w-1.5 h-1.5 rounded-full bg-cyan-500 shrink-0" />
            <span>Proposal Sent</span>
          </span>
        );
      case 'sampleSent':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-teal-50 text-teal-600 border border-teal-200">
            <span className="w-1.5 h-1.5 rounded-full bg-teal-500 shrink-0" />
            <span>Sample Sent</span>
          </span>
        );
      case 'newLead':
      default:
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-blue-50 text-blue-600 border border-blue-200">
            <span className="w-1.5 h-1.5 rounded-full bg-blue-500 shrink-0" />
            <span>New Lead</span>
          </span>
        );
    }
  };

  return (
    <div className="w-full bg-white flex flex-col min-h-screen text-gray-800">
      {/* ── TOP HEADER BAR (Flush edge-to-edge, UpTeams design) ── */}
      <div className="w-full bg-white px-4 py-2.5 border-b border-gray-200 flex flex-wrap items-center gap-2.5 shadow-2xs">
        {/* Title & Icon */}
        <div className="flex items-center gap-2 mr-1">
          <div className="w-7 h-7 rounded-md bg-[#1976d2] text-white flex items-center justify-center font-bold text-xs shadow-2xs">
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
            className="w-full text-xs pl-3 pr-8 py-1.5 border border-gray-300 rounded focus:ring-1 focus:ring-[#1976d2] focus:border-[#1976d2] outline-none bg-white"
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

        {/* Action Icon Buttons (Blue solid) */}
        <div className="flex items-center gap-1.5 ml-auto">
          <button
            title="Filter"
            className="p-1.5 rounded bg-[#1976d2] hover:bg-[#1565c0] text-white transition-colors cursor-pointer shadow-2xs"
          >
            <Filter className="w-3.5 h-3.5" />
          </button>
          <button
            title="Refresh"
            onClick={() => window.location.reload()}
            className="p-1.5 rounded bg-[#1976d2] hover:bg-[#1565c0] text-white transition-colors cursor-pointer shadow-2xs"
          >
            <RefreshCw className="w-3.5 h-3.5" />
          </button>
          <button
            title="Column Visibility"
            className="p-1.5 rounded bg-[#1976d2] hover:bg-[#1565c0] text-white transition-colors cursor-pointer shadow-2xs"
          >
            <Eye className="w-3.5 h-3.5" />
          </button>

          {/* Import Button (Blue) */}
          <button
            className="flex items-center gap-1.5 px-3 py-1.5 bg-[#1976d2] hover:bg-[#1565c0] text-white rounded text-xs font-semibold shadow-2xs transition-colors cursor-pointer"
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

      {/* ── STAGE TABS BAR (Full-width, exact UpTeams styling) ── */}
      <div className="w-full bg-white px-4 py-2 border-b border-gray-200 flex items-center gap-1.5 overflow-x-auto">
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
              className={`px-2.5 py-0.5 rounded text-[11px] font-bold whitespace-nowrap transition-all cursor-pointer border ${
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
          <thead className="bg-[#f8fafc] border-b border-gray-200 text-gray-500 font-semibold text-[11px]">
            <tr>
              <th className="px-3.5 py-3 whitespace-nowrap">
                <div className="flex items-center gap-1 text-gray-600">
                  <span>Date</span>
                  <span className="text-gray-400 text-[10px]">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3 whitespace-nowrap">
                <div className="flex items-center gap-1 text-gray-600">
                  <span>ID</span>
                  <span className="text-gray-400 text-[10px]">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3 whitespace-nowrap">
                <div className="flex items-center gap-1 text-gray-600">
                  <span>Name</span>
                  <span className="text-gray-400 text-[10px]">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3 whitespace-nowrap">
                <div className="flex items-center gap-1 text-gray-600">
                  <span>Company</span>
                  <span className="text-gray-400 text-[10px]">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3 whitespace-nowrap">
                <div className="flex items-center gap-1 text-gray-600">
                  <span>Phone</span>
                  <span className="text-gray-400 text-[10px]">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3 whitespace-nowrap">
                <div className="flex items-center gap-1 text-gray-600">
                  <span>Email</span>
                  <span className="text-gray-400 text-[10px]">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3 whitespace-nowrap">
                <div className="flex items-center gap-1 text-gray-600">
                  <span>Title</span>
                  <span className="text-gray-400 text-[10px]">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3 whitespace-nowrap">
                <div className="flex items-center gap-1 text-gray-600">
                  <span>Note</span>
                  <span className="text-gray-400 text-[10px]">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3 whitespace-nowrap">
                <div className="flex items-center gap-1 text-gray-600">
                  <span>City</span>
                  <span className="text-gray-400 text-[10px]">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3 whitespace-nowrap">
                <div className="flex items-center gap-1 text-gray-600">
                  <span>Stage</span>
                  <span className="text-gray-400 text-[10px]">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3 whitespace-nowrap">
                <div className="flex items-center gap-1 text-gray-600">
                  <span>Staff</span>
                  <span className="text-gray-400 text-[10px]">⇅</span>
                </div>
              </th>
              <th className="px-3.5 py-3 text-right whitespace-nowrap"></th>
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
                <td className="px-3.5 py-3 whitespace-nowrap text-gray-600 font-medium text-[11px] uppercase">
                  {formatDate(lead.created_at)}
                </td>

                {/* ID */}
                <td className="px-3.5 py-3 whitespace-nowrap">
                  <span className="text-[#1976d2] font-bold font-mono text-[12px]">
                    {lead.lead_number}
                  </span>
                </td>

                {/* Name */}
                <td className="px-3.5 py-3">
                  <span className="font-semibold text-gray-800 text-[11px] uppercase tracking-tight block max-w-44 truncate">
                    {lead.name}
                  </span>
                </td>

                {/* Company */}
                <td className="px-3.5 py-3">
                  <span className="text-gray-700 text-[11px] block max-w-44 truncate">
                    {lead.company || lead.name || '—'}
                  </span>
                </td>

                {/* Phone */}
                <td className="px-3.5 py-3 whitespace-nowrap text-gray-700 text-[11px]">
                  {lead.phone}
                </td>

                {/* Email */}
                <td className="px-3.5 py-3 text-gray-500 text-[11px] max-w-32">
                  <span className="truncate block max-w-32">
                    {lead.email || ''}
                  </span>
                </td>

                {/* Title */}
                <td className="px-3.5 py-3 text-gray-700 text-[11px]">
                  <span className="truncate block max-w-36 font-normal uppercase">
                    {lead.title || ''}
                  </span>
                </td>

                {/* Note */}
                <td className="px-3.5 py-3 text-gray-600 text-[11px]">
                  <span className="truncate block max-w-36">
                    {lead.note || ''}
                  </span>
                </td>

                {/* City (2 lines: City top, State bottom) */}
                <td className="px-3.5 py-3 text-[11px]">
                  {lead.city ? (
                    <div>
                      <div className="font-semibold text-gray-800 uppercase text-[11px]">
                        {lead.city}
                      </div>
                      <div className="text-gray-400 uppercase text-[10px] tracking-wide">
                        {lead.state || 'INDIA'}
                      </div>
                    </div>
                  ) : (
                    <span className="text-gray-300">—</span>
                  )}
                </td>

                {/* Stage */}
                <td className="px-3.5 py-3 whitespace-nowrap">
                  {getStagePill(lead.stage)}
                </td>

                {/* Staff Avatar (Soft Lavender / Blue background, dark blue letters) */}
                <td className="px-3.5 py-3 whitespace-nowrap">
                  <div
                    title={lead.staff_name || 'Unassigned'}
                    className="w-7 h-7 rounded-full bg-[#e8eaf6] text-[#3949ab] text-[11px] font-bold flex items-center justify-center uppercase shrink-0"
                  >
                    {getInitials(lead.staff_name)}
                  </div>
                </td>

                {/* Actions */}
                <td
                  className="px-3.5 py-3 whitespace-nowrap text-right"
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
                      className="p-1 rounded hover:bg-blue-50 text-[#1976d2] transition-colors cursor-pointer"
                    >
                      <Send className="w-3.5 h-3.5 text-[#1976d2]" />
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

      {/* ── PAGINATION BAR ── */}
      {totalPages > 1 && (
        <div className="w-full px-4 py-2.5 border-t border-gray-200 flex items-center justify-between text-xs text-gray-500 bg-white">
          <div>
            Showing {(currentPage - 1) * itemsPerPage + 1}–
            {Math.min(currentPage * itemsPerPage, filteredLeads.length)} of{' '}
            {filteredLeads.length} leads
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
