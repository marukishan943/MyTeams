import React, { useState } from 'react';
import {
  Search,
  Plus,
  Phone,
  Eye,
  Edit2,
  Trash2,
  Building,
} from 'lucide-react';
import type { Lead } from '../../types/crm';

interface LeadsListProps {
  leads: Lead[];
  onOpenAdd: () => void;
  onOpenEdit: (lead: Lead) => void;
  onOpenDetail: (lead: Lead) => void;
  onDelete: (id: string) => void;
  staffList: string[];
}

export const LeadsList: React.FC<LeadsListProps> = ({
  leads,
  onOpenAdd,
  onOpenEdit,
  onOpenDetail,
  onDelete,
}) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [stageFilter, setStageFilter] = useState<string>('all');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 12;

  // Filter leads
  const filteredLeads = leads.filter((lead) => {
    const matchesSearch =
      lead.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (lead.company && lead.company.toLowerCase().includes(searchTerm.toLowerCase())) ||
      lead.phone.includes(searchTerm) ||
      lead.lead_number.includes(searchTerm);

    const matchesStage = stageFilter === 'all' || lead.stage === stageFilter;

    return matchesSearch && matchesStage;
  });

  const totalPages = Math.ceil(filteredLeads.length / itemsPerPage) || 1;
  const paginatedLeads = filteredLeads.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const getStageBadge = (stage: Lead['stage']) => {
    switch (stage) {
      case 'newLead':
        return (
          <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-blue-50 text-blue-700 border border-blue-200">
            New Lead
          </span>
        );
      case 'contacted':
        return (
          <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-200">
            Contacted
          </span>
        );
      case 'proposalSent':
        return (
          <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-purple-50 text-purple-700 border border-purple-200">
            Proposal Sent
          </span>
        );
      case 'converted':
        return (
          <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
            Converted
          </span>
        );
      case 'disqualified':
        return (
          <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-gray-100 text-gray-700 border border-gray-200">
            Disqualified
          </span>
        );
      default:
        return null;
    }
  };

  return (
    <div className="space-y-4">
      {/* Top Header & Search Bar (UpTeams Style) */}
      <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-2xs space-y-3">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <div className="flex items-center space-x-2">
            <h2 className="text-base font-bold text-gray-900">Leads Pipeline</h2>
            <span className="px-2 py-0.5 bg-gray-100 text-gray-700 text-xs font-semibold rounded-full">
              {filteredLeads.length} Total
            </span>
          </div>

          <div className="flex items-center gap-2 flex-wrap">
            <div className="relative min-w-56 flex-1 sm:flex-initial">
              <Search className="w-4 h-4 text-gray-400 absolute left-3 top-2.5" />
              <input
                type="text"
                placeholder="Search by name, company, phone..."
                value={searchTerm}
                onChange={(e) => {
                  setSearchTerm(e.target.value);
                  setCurrentPage(1);
                }}
                className="w-full text-xs pl-9 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#3949ab] focus:outline-hidden"
              />
            </div>
            <button
              onClick={onOpenAdd}
              className="inline-flex items-center space-x-1.5 px-3.5 py-2 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-lg text-xs font-semibold shadow-xs transition-colors cursor-pointer"
            >
              <Plus className="w-4 h-4" />
              <span>Add Lead</span>
            </button>
          </div>
        </div>

        {/* Stage Filter Buttons */}
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 text-xs">
          {[
            { id: 'all', label: 'All Leads' },
            { id: 'newLead', label: 'New' },
            { id: 'contacted', label: 'Contacted' },
            { id: 'proposalSent', label: 'Proposal Sent' },
            { id: 'converted', label: 'Converted' },
            { id: 'disqualified', label: 'Disqualified' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => {
                setStageFilter(tab.id);
                setCurrentPage(1);
              }}
              className={`px-3 py-1.5 rounded-lg font-medium whitespace-nowrap transition-colors cursor-pointer ${
                stageFilter === tab.id
                  ? 'bg-[#3949ab] text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      {/* Leads Table */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-2xs overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-gray-700">
            <thead className="bg-gray-50/75 border-b border-gray-200 text-gray-500 uppercase tracking-wider font-semibold text-[11px]">
              <tr>
                <th className="px-4 py-3">Lead #</th>
                <th className="px-4 py-3">Contact / Company</th>
                <th className="px-4 py-3">Phone</th>
                <th className="px-4 py-3">Territory</th>
                <th className="px-4 py-3">Assigned Staff</th>
                <th className="px-4 py-3">Stage</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {paginatedLeads.map((lead) => (
                <tr
                  key={lead.id}
                  className="hover:bg-gray-50/80 transition-colors group cursor-pointer"
                  onClick={() => onOpenDetail(lead)}
                >
                  <td className="px-4 py-3 font-mono font-bold text-gray-800">
                    #{lead.lead_number}
                  </td>
                  <td className="px-4 py-3">
                    <div className="font-bold text-gray-900">{lead.name}</div>
                    {lead.company && (
                      <div className="text-[11px] text-gray-500 flex items-center gap-1 mt-0.5">
                        <Building className="w-3 h-3 text-gray-400 shrink-0" />
                        <span className="truncate max-w-48">{lead.company}</span>
                      </div>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center space-x-1.5 text-gray-800">
                      <Phone className="w-3.5 h-3.5 text-gray-400" />
                      <span>{lead.phone}</span>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-gray-600">
                    {lead.territory || 'RAJKOT'}
                  </td>
                  <td className="px-4 py-3">
                    <span className="bg-gray-100 text-gray-700 px-2 py-0.5 rounded-sm font-medium text-[11px]">
                      {lead.staff_name || 'Unassigned'}
                    </span>
                  </td>
                  <td className="px-4 py-3">{getStageBadge(lead.stage)}</td>
                  <td
                    className="px-4 py-3 text-right space-x-1 whitespace-nowrap"
                    onClick={(e) => e.stopPropagation()}
                  >
                    <button
                      onClick={() => onOpenDetail(lead)}
                      title="View Details"
                      className="p-1.5 rounded-md hover:bg-gray-100 text-gray-500 hover:text-[#3949ab] transition-colors"
                    >
                      <Eye className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => onOpenEdit(lead)}
                      title="Edit Lead"
                      className="p-1.5 rounded-md hover:bg-gray-100 text-gray-500 hover:text-emerald-600 transition-colors"
                    >
                      <Edit2 className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => {
                        if (
                          window.confirm(
                            `Delete lead #${lead.lead_number} (${lead.name})?`
                          )
                        ) {
                          onDelete(lead.id);
                        }
                      }}
                      title="Delete Lead"
                      className="p-1.5 rounded-md hover:bg-rose-50 text-gray-400 hover:text-rose-600 transition-colors"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </td>
                </tr>
              ))}
              {paginatedLeads.length === 0 && (
                <tr>
                  <td colSpan={7} className="text-center py-8 text-gray-400">
                    No leads match your current search or filters.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Bar */}
        {totalPages > 1 && (
          <div className="px-4 py-3 border-t border-gray-100 flex items-center justify-between text-xs text-gray-500">
            <div>
              Showing {(currentPage - 1) * itemsPerPage + 1} to{' '}
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
