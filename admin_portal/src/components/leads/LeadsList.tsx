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
  User,
  Download,
} from 'lucide-react';
import type { Lead } from '../../types/crm';

interface LeadsListProps {
  leads: Lead[];
  onOpenAdd: () => void;
  onOpenEdit: (lead: Lead) => void;
  onOpenDetail: (lead: Lead) => void;
  onDelete: (id: string) => void;
  onConvertToCustomer?: (lead: Lead) => void;
  staffList: string[];
}

interface StageMeta {
  id: string;
  label: string;
  dotColor: string;
  pillBg: string;
  pillText: string;
  pillBorder: string;
  countBg: string;
  countText: string;
}

const STAGE_META: Record<string, StageMeta> = {
  all: {
    id: 'all',
    label: 'All',
    dotColor: '',
    pillBg: 'bg-gray-100',
    pillText: 'text-gray-700',
    pillBorder: 'border-gray-300',
    countBg: 'bg-gray-200',
    countText: 'text-gray-700',
  },
  newLead: {
    id: 'newLead',
    label: 'New',
    dotColor: 'bg-blue-500',
    pillBg: 'bg-blue-50',
    pillText: 'text-blue-700',
    pillBorder: 'border-blue-400',
    countBg: 'bg-blue-500',
    countText: 'text-white',
  },
  contacted: {
    id: 'contacted',
    label: 'Contacted',
    dotColor: 'bg-amber-500',
    pillBg: 'bg-amber-50',
    pillText: 'text-amber-700',
    pillBorder: 'border-amber-400',
    countBg: 'bg-amber-500',
    countText: 'text-white',
  },
  proposalSent: {
    id: 'proposalSent',
    label: 'Proposal Sent',
    dotColor: 'bg-purple-500',
    pillBg: 'bg-purple-50',
    pillText: 'text-purple-700',
    pillBorder: 'border-purple-400',
    countBg: 'bg-purple-500',
    countText: 'text-white',
  },
  sampleSent: {
    id: 'sampleSent',
    label: 'Sample Sent',
    dotColor: 'bg-teal-500',
    pillBg: 'bg-teal-50',
    pillText: 'text-teal-700',
    pillBorder: 'border-teal-400',
    countBg: 'bg-teal-500',
    countText: 'text-white',
  },
  disqualified: {
    id: 'disqualified',
    label: 'Disqualified',
    dotColor: 'bg-rose-500',
    pillBg: 'bg-rose-50',
    pillText: 'text-rose-700',
    pillBorder: 'border-rose-400',
    countBg: 'bg-rose-500',
    countText: 'text-white',
  },
  converted: {
    id: 'converted',
    label: 'Converted',
    dotColor: 'bg-emerald-500',
    pillBg: 'bg-emerald-50',
    pillText: 'text-emerald-700',
    pillBorder: 'border-emerald-400',
    countBg: 'bg-emerald-500',
    countText: 'text-white',
  },
};

const STAGE_ORDER = [
  'all',
  'newLead',
  'contacted',
  'proposalSent',
  'sampleSent',
  'disqualified',
  'converted',
];

function getInitials(name?: string): string {
  if (!name) return '??';
  const parts = name.trim().split(/\s+/);
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

function getAvatarColor(name?: string): string {
  const colors = [
    'bg-indigo-500',
    'bg-blue-500',
    'bg-emerald-500',
    'bg-amber-500',
    'bg-purple-500',
    'bg-rose-500',
    'bg-teal-500',
    'bg-cyan-500',
    'bg-orange-500',
  ];
  if (!name) return colors[0];
  const idx =
    name.split('').reduce((acc, ch) => acc + ch.charCodeAt(0), 0) %
    colors.length;
  return colors[idx];
}

function formatDate(dateStr?: string): string {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  const now = new Date();
  const diff = now.setHours(0, 0, 0, 0) - d.setHours(0, 0, 0, 0);
  const daysDiff = Math.round(diff / 86400000);
  if (daysDiff === 0) return 'Today';
  if (daysDiff === 1) return 'Yesterday';
  if (daysDiff < 7) return `${daysDiff} days ago`;
  return new Date(dateStr).toLocaleDateString('en-GB', {
    day: 'numeric',
    month: 'short',
  });
}

// Dropdown menu for each row's "..." button
function RowActionsMenu({
  lead,
  onOpenEdit,
  onOpenDetail,
  onDelete,
  onConvertToCustomer,
}: {
  lead: Lead;
  onOpenEdit: (lead: Lead) => void;
  onOpenDetail: (lead: Lead) => void;
  onDelete: (id: string) => void;
  onConvertToCustomer?: (lead: Lead) => void;
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
        className="p-1.5 rounded-md hover:bg-gray-100 text-gray-400 hover:text-gray-700 transition-colors cursor-pointer"
        title="More actions"
      >
        <MoreHorizontal className="w-4 h-4" />
      </button>
      {open && (
        <div className="absolute right-0 top-8 z-50 w-48 bg-white rounded-lg shadow-xl border border-gray-200 py-1.5 text-xs">
          <button
            onClick={(e) => {
              e.stopPropagation();
              setOpen(false);
              onOpenEdit(lead);
            }}
            className="w-full flex items-center gap-2.5 px-3.5 py-2 text-gray-700 hover:bg-gray-50 cursor-pointer"
          >
            <Edit2 className="w-4 h-4 text-[#3949ab]" />
            <span>Edit</span>
          </button>
          <button
            onClick={(e) => {
              e.stopPropagation();
              setOpen(false);
              if (onConvertToCustomer) {
                onConvertToCustomer(lead);
              }
            }}
            className="w-full flex items-center gap-2.5 px-3.5 py-2 text-gray-700 hover:bg-gray-50 cursor-pointer"
          >
            <CornerUpRight className="w-4 h-4 text-[#3949ab]" />
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
            className="w-full flex items-center gap-2.5 px-3.5 py-2 text-gray-700 hover:bg-gray-50 cursor-pointer"
          >
            <Trash2 className="w-4 h-4 text-[#3949ab]" />
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
}) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [stageFilter, setStageFilter] = useState<string>('all');
  const [sourceFilter, setSourceFilter] = useState<string>('all');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 15;

  // Stage counts
  const stageCounts = STAGE_ORDER.reduce<Record<string, number>>((acc, key) => {
    if (key === 'all') {
      acc['all'] = leads.length;
    } else {
      acc[key] = leads.filter((l) => l.stage === key).length;
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
        lead.email.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchesStage = stageFilter === 'all' || lead.stage === stageFilter;
    const matchesSource =
      sourceFilter === 'all' || lead.source === sourceFilter;

    return matchesSearch && matchesStage && matchesSource;
  });

  const totalPages = Math.ceil(filteredLeads.length / itemsPerPage) || 1;
  const paginatedLeads = filteredLeads.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const getStageDot = (stage: Lead['stage']) => {
    const meta = STAGE_META[stage];
    if (!meta) return null;
    return (
      <span className="flex items-center gap-1.5 whitespace-nowrap">
        <span
          className={`w-1.5 h-1.5 rounded-full shrink-0 ${meta.dotColor}`}
        />
        <span
          className={`text-[11px] font-semibold ${meta.pillText}`}
        >
          {meta.label}
        </span>
      </span>
    );
  };

  return (
    <div className="flex flex-col h-full space-y-0">
      {/* ── Top Toolbar ── */}
      <div className="bg-white px-4 py-3 border-b border-gray-200 flex flex-wrap items-center gap-2">
        {/* Search */}
        <div className="relative flex-1 min-w-48">
          <Search className="w-3.5 h-3.5 text-gray-400 absolute left-2.5 top-2.5" />
          <input
            type="text"
            placeholder="Search..."
            value={searchTerm}
            onChange={(e) => {
              setSearchTerm(e.target.value);
              setCurrentPage(1);
            }}
            className="w-full text-xs pl-8 pr-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-[#3949ab] focus:outline-none bg-gray-50"
          />
        </div>

        {/* Status filter */}
        <div className="flex items-center gap-1.5 border border-gray-200 rounded-lg px-2.5 py-2 bg-gray-50 text-xs text-gray-500">
          <Tag className="w-3.5 h-3.5 text-gray-400" />
          <span className="font-medium">Status</span>
          <select
            className="bg-transparent focus:outline-none text-xs text-gray-700 cursor-pointer"
            value={stageFilter}
            onChange={(e) => {
              setStageFilter(e.target.value);
              setCurrentPage(1);
            }}
          >
            <option value="all">All</option>
            <option value="newLead">New</option>
            <option value="contacted">Contacted</option>
            <option value="proposalSent">Proposal Sent</option>
            <option value="sampleSent">Sample Sent</option>
            <option value="disqualified">Disqualified</option>
            <option value="converted">Converted</option>
          </select>
        </div>

        {/* Date pill */}
        <div className="flex items-center gap-1.5 border border-gray-200 rounded-lg px-2.5 py-2 bg-gray-50 text-xs text-gray-500">
          <Calendar className="w-3.5 h-3.5 text-gray-400" />
          <span>All</span>
        </div>

        {/* Source filter */}
        <div className="flex items-center gap-1.5 border border-gray-200 rounded-lg px-2.5 py-2 bg-gray-50 text-xs text-gray-500">
          <Tag className="w-3.5 h-3.5 text-gray-400" />
          <span className="font-medium">Source</span>
          <select
            className="bg-transparent focus:outline-none text-xs text-gray-700 cursor-pointer"
            value={sourceFilter}
            onChange={(e) => {
              setSourceFilter(e.target.value);
              setCurrentPage(1);
            }}
          >
            <option value="all">All</option>
            <option value="call">Call</option>
            <option value="email">Email</option>
            <option value="website">Website</option>
            <option value="others">Others</option>
          </select>
        </div>

        {/* Staff */}
        <div className="flex items-center gap-1.5 border border-gray-200 rounded-lg px-2.5 py-2 bg-gray-50 text-xs text-gray-500">
          <User className="w-3.5 h-3.5 text-gray-400" />
          <span>All</span>
        </div>

        {/* Icon buttons */}
        <div className="flex items-center gap-1 ml-auto">
          <button
            title="Filter"
            className="p-2 rounded-lg hover:bg-gray-100 text-gray-500 transition-colors cursor-pointer"
          >
            <Filter className="w-4 h-4" />
          </button>
          <button
            title="Refresh"
            className="p-2 rounded-lg hover:bg-gray-100 text-gray-500 transition-colors cursor-pointer"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
          <button
            title="Column visibility"
            className="p-2 rounded-lg hover:bg-gray-100 text-gray-500 transition-colors cursor-pointer"
          >
            <Eye className="w-4 h-4" />
          </button>
        </div>

        {/* Import button */}
        <button className="flex items-center gap-1.5 px-3 py-2 border border-gray-300 rounded-lg text-xs font-semibold text-gray-700 hover:bg-gray-50 transition-colors cursor-pointer">
          <Download className="w-3.5 h-3.5" />
          Import
        </button>

        {/* Add Lead */}
        <button
          onClick={onOpenAdd}
          className="flex items-center gap-1.5 px-3 py-2 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-lg text-xs font-semibold shadow-sm transition-colors cursor-pointer"
        >
          <Plus className="w-3.5 h-3.5" />
          Add Lead
        </button>
      </div>

      {/* ── Stage Tab Pills with counts ── */}
      <div className="bg-white px-4 py-2.5 border-b border-gray-200 flex items-center gap-2 flex-wrap">
        {STAGE_ORDER.map((key) => {
          const meta = STAGE_META[key];
          const count = stageCounts[key] ?? 0;
          const isActive = stageFilter === key;
          return (
            <button
              key={key}
              onClick={() => {
                setStageFilter(key);
                setCurrentPage(1);
              }}
              className={`flex items-center gap-1.5 px-2.5 py-1 rounded-full border text-[11px] font-semibold transition-all cursor-pointer whitespace-nowrap ${
                isActive
                  ? `${meta.pillBg} ${meta.pillText} ${meta.pillBorder} border`
                  : 'bg-white text-gray-500 border-gray-200 hover:border-gray-300 hover:bg-gray-50'
              }`}
            >
              {key !== 'all' && (
                <span
                  className={`w-1.5 h-1.5 rounded-full shrink-0 ${
                    isActive ? meta.dotColor : 'bg-gray-300'
                  }`}
                />
              )}
              <span className="uppercase tracking-wide">{meta.label}</span>
              <span
                className={`ml-0.5 px-1.5 py-0.5 rounded-full text-[10px] font-bold ${
                  isActive ? `${meta.countBg} ${meta.countText}` : 'bg-gray-100 text-gray-500'
                }`}
              >
                {count}
              </span>
            </button>
          );
        })}
      </div>

      {/* ── Leads Table ── */}
      <div className="flex-1 bg-white overflow-hidden">
        <div className="overflow-x-auto h-full">
          <table className="w-full text-left text-xs text-gray-700 border-collapse">
            <thead className="bg-gray-50 border-b border-gray-200 text-gray-500 uppercase tracking-wider font-semibold text-[10px] sticky top-0 z-10">
              <tr>
                <th className="px-3 py-3 whitespace-nowrap">
                  <div className="flex items-center gap-1">
                    Date <span className="text-gray-300">▼</span>
                  </div>
                </th>
                <th className="px-3 py-3 whitespace-nowrap">ID</th>
                <th className="px-3 py-3 whitespace-nowrap">Name</th>
                <th className="px-3 py-3 whitespace-nowrap">Company</th>
                <th className="px-3 py-3 whitespace-nowrap">Phone</th>
                <th className="px-3 py-3 whitespace-nowrap">Email</th>
                <th className="px-3 py-3 whitespace-nowrap">Title</th>
                <th className="px-3 py-3 whitespace-nowrap">Note</th>
                <th className="px-3 py-3 whitespace-nowrap">City</th>
                <th className="px-3 py-3 whitespace-nowrap">Stage</th>
                <th className="px-3 py-3 whitespace-nowrap">Staff</th>
                <th className="px-3 py-3 text-right whitespace-nowrap"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {paginatedLeads.map((lead) => (
                <tr
                  key={lead.id}
                  className="hover:bg-blue-50/30 transition-colors cursor-pointer"
                  onClick={() => onOpenDetail(lead)}
                >
                  {/* Date */}
                  <td className="px-3 py-3 text-gray-500 whitespace-nowrap text-[11px] uppercase font-medium tracking-wide">
                    {formatDate(lead.created_at)}
                  </td>

                  {/* ID */}
                  <td className="px-3 py-3 whitespace-nowrap">
                    <span className="text-[#3949ab] font-semibold font-mono">
                      {lead.lead_number}
                    </span>
                  </td>

                  {/* Name */}
                  <td className="px-3 py-3">
                    <span className="font-semibold text-gray-500 text-[11px] uppercase tracking-wide max-w-36 truncate block">
                      {lead.name}
                    </span>
                  </td>

                  {/* Company */}
                  <td className="px-3 py-3">
                    <span className="text-gray-700 text-[11px] max-w-40 truncate block">
                      {lead.company || '—'}
                    </span>
                  </td>

                  {/* Phone */}
                  <td className="px-3 py-3 whitespace-nowrap text-gray-700 text-[11px]">
                    {lead.phone}
                  </td>

                  {/* Email */}
                  <td className="px-3 py-3 text-gray-500 text-[11px] max-w-32">
                    <span className="truncate block max-w-32">
                      {lead.email || ''}
                    </span>
                  </td>

                  {/* Title */}
                  <td className="px-3 py-3 text-gray-500 text-[11px]">
                    <span className="truncate block max-w-28">
                      {lead.title || ''}
                    </span>
                  </td>

                  {/* Note */}
                  <td className="px-3 py-3 text-gray-500 text-[11px]">
                    <span className="truncate block max-w-32">
                      {lead.note || ''}
                    </span>
                  </td>

                  {/* City */}
                  <td className="px-3 py-3 text-[11px]">
                    {lead.city ? (
                      <div>
                        <div className="font-semibold text-gray-700 uppercase">
                          {lead.city}
                        </div>
                        {lead.state && (
                          <div className="text-gray-400 uppercase text-[10px]">
                            {lead.state}
                          </div>
                        )}
                      </div>
                    ) : (
                      <span className="text-gray-300">—</span>
                    )}
                  </td>

                  {/* Stage */}
                  <td className="px-3 py-3 whitespace-nowrap">
                    {getStageDot(lead.stage)}
                  </td>

                  {/* Staff Avatar */}
                  <td className="px-3 py-3 whitespace-nowrap">
                    {lead.staff_name ? (
                      <div
                        title={lead.staff_name}
                        className={`w-7 h-7 rounded-full ${getAvatarColor(lead.staff_name)} text-white text-[10px] font-bold flex items-center justify-center uppercase`}
                      >
                        {getInitials(lead.staff_name)}
                      </div>
                    ) : (
                      <div className="w-7 h-7 rounded-full bg-gray-200 text-gray-400 text-[10px] font-bold flex items-center justify-center">
                        —
                      </div>
                    )}
                  </td>

                  {/* Actions */}
                  <td
                    className="px-3 py-3 whitespace-nowrap"
                    onClick={(e) => e.stopPropagation()}
                  >
                    <div className="flex items-center gap-1">
                      {/* Quick send/detail icon */}
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          onOpenDetail(lead);
                        }}
                        title="View Details"
                        className="p-1.5 rounded-md hover:bg-[#3949ab]/10 text-[#3949ab] transition-colors cursor-pointer"
                      >
                        <Send className="w-3.5 h-3.5" />
                      </button>
                      <RowActionsMenu
                        lead={lead}
                        onOpenEdit={onOpenEdit}
                        onOpenDetail={onOpenDetail}
                        onDelete={onDelete}
                        onConvertToCustomer={onConvertToCustomer}
                      />
                    </div>
                  </td>
                </tr>
              ))}

              {paginatedLeads.length === 0 && (
                <tr>
                  <td
                    colSpan={12}
                    className="text-center py-12 text-gray-400 text-xs"
                  >
                    No leads match your current search or filters.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="px-4 py-3 border-t border-gray-100 flex items-center justify-between text-xs text-gray-500 bg-white">
            <div>
              Showing {(currentPage - 1) * itemsPerPage + 1}–
              {Math.min(currentPage * itemsPerPage, filteredLeads.length)} of{' '}
              {filteredLeads.length} leads
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
                onClick={() =>
                  setCurrentPage((p) => Math.min(totalPages, p + 1))
                }
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
