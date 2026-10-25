import React, { useState, useEffect } from 'react';
import { Modal } from '../common/Modal';
import {
  Building,
  Phone,
  Mail,
  MapPin,
  Calendar,
  Send,
  Trash2,
  Edit2,
  Clock,
} from 'lucide-react';
import type { Lead, LeadNote } from '../../types/crm';
import { leadsService } from '../../services/leadsService';

interface LeadDetailModalProps {
  lead: Lead | null;
  isOpen: boolean;
  onClose: () => void;
  onEdit: (lead: Lead) => void;
  onDelete: (id: string) => void;
  onStageChange: (leadId: string, stage: Lead['stage']) => Promise<void>;
}

export const LeadDetailModal: React.FC<LeadDetailModalProps> = ({
  lead,
  isOpen,
  onClose,
  onEdit,
  onDelete,
  onStageChange,
}) => {
  const [notes, setNotes] = useState<LeadNote[]>([]);
  const [newNoteContent, setNewNoteContent] = useState('');
  const [isAddingNote, setIsAddingNote] = useState(false);
  const [isLoadingNotes, setIsLoadingNotes] = useState(false);

  useEffect(() => {
    if (lead?.id && isOpen) {
      loadNotes(lead.id);
    }
  }, [lead?.id, isOpen]);

  const loadNotes = async (leadId: string) => {
    setIsLoadingNotes(true);
    try {
      const data = await leadsService.fetchLeadNotes(leadId);
      setNotes(data);
    } catch (e) {
      console.error(e);
    } finally {
      setIsLoadingNotes(false);
    }
  };

  const handleAddNote = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!lead || !newNoteContent.trim()) return;

    setIsAddingNote(true);
    try {
      const created = await leadsService.addLeadNote(lead.id, newNoteContent.trim());
      setNotes([created, ...notes]);
      setNewNoteContent('');
    } catch (e) {
      console.error(e);
    } finally {
      setIsAddingNote(false);
    }
  };

  if (!lead) return null;

  const stages: { key: Lead['stage']; label: string }[] = [
    { key: 'newLead', label: 'New' },
    { key: 'contacted', label: 'Contacted' },
    { key: 'proposalSent', label: 'Proposal Sent' },
    { key: 'converted', label: 'Converted' },
    { key: 'disqualified', label: 'Disqualified' },
  ];

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={`Lead #${lead.lead_number} • ${lead.name}`}
      maxWidth="4xl"
    >
      <div className="space-y-6">
        {/* Header & Pipeline Stage Progression Bar */}
        <div className="bg-gray-50 p-4 rounded-xl border border-gray-200">
          <div className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">
            Pipeline Progression Stage:
          </div>
          <div className="flex flex-wrap gap-2">
            {stages.map((st) => {
              const isCurrent = lead.stage === st.key;
              return (
                <button
                  key={st.key}
                  onClick={() => onStageChange(lead.id, st.key)}
                  className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all cursor-pointer ${
                    isCurrent
                      ? 'bg-[#3949ab] text-white shadow-xs'
                      : 'bg-white border border-gray-200 text-gray-700 hover:border-gray-300'
                  }`}
                >
                  {st.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* Lead Details Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="bg-white p-4 rounded-xl border border-gray-200 space-y-3">
            <h4 className="text-xs font-bold text-gray-400 uppercase tracking-wider">
              Contact Information
            </h4>
            <div className="space-y-2 text-xs">
              <div className="flex items-center space-x-2 text-gray-800">
                <span className="font-semibold w-24 text-gray-500">Contact:</span>
                <span className="font-bold text-sm text-gray-900">{lead.name}</span>
              </div>
              {lead.company && (
                <div className="flex items-center space-x-2 text-gray-800">
                  <span className="font-semibold w-24 text-gray-500 flex items-center gap-1">
                    <Building className="w-3.5 h-3.5 text-gray-400" />
                    Company:
                  </span>
                  <span>{lead.company}</span>
                </div>
              )}
              <div className="flex items-center space-x-2 text-gray-800">
                <span className="font-semibold w-24 text-gray-500 flex items-center gap-1">
                  <Phone className="w-3.5 h-3.5 text-gray-400" />
                  Phone:
                </span>
                <a
                  href={`tel:${lead.phone}`}
                  className="text-[#3949ab] font-semibold hover:underline"
                >
                  {lead.phone}
                </a>
              </div>
              {lead.email && (
                <div className="flex items-center space-x-2 text-gray-800">
                  <span className="font-semibold w-24 text-gray-500 flex items-center gap-1">
                    <Mail className="w-3.5 h-3.5 text-gray-400" />
                    Email:
                  </span>
                  <span>{lead.email}</span>
                </div>
              )}
            </div>
          </div>

          <div className="bg-white p-4 rounded-xl border border-gray-200 space-y-3">
            <h4 className="text-xs font-bold text-gray-400 uppercase tracking-wider">
              Assignment & Geography
            </h4>
            <div className="space-y-2 text-xs">
              <div className="flex items-center space-x-2 text-gray-800">
                <span className="font-semibold w-24 text-gray-500">Staff Assigned:</span>
                <span className="font-semibold text-gray-900 bg-gray-100 px-2 py-0.5 rounded-sm">
                  {lead.staff_name || 'Unassigned'}
                </span>
              </div>
              <div className="flex items-center space-x-2 text-gray-800">
                <span className="font-semibold w-24 text-gray-500 flex items-center gap-1">
                  <MapPin className="w-3.5 h-3.5 text-gray-400" />
                  Territory:
                </span>
                <span>{lead.territory || 'Not Specified'}</span>
              </div>
              <div className="flex items-center space-x-2 text-gray-800">
                <span className="font-semibold w-24 text-gray-500">City / State:</span>
                <span>{[lead.city, lead.state].filter(Boolean).join(', ') || 'N/A'}</span>
              </div>
              <div className="flex items-center space-x-2 text-gray-800">
                <span className="font-semibold w-24 text-gray-500 flex items-center gap-1">
                  <Calendar className="w-3.5 h-3.5 text-gray-400" />
                  Created:
                </span>
                <span>
                  {new Date(lead.created_at).toLocaleDateString('en-GB', {
                    day: 'numeric',
                    month: 'short',
                    year: 'numeric',
                  })}
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Lead Notes Stream (MyTeams Style Feed) */}
        <div className="bg-white p-5 rounded-xl border border-gray-200 space-y-4">
          <h4 className="text-xs font-bold text-gray-500 uppercase tracking-wider">
            Discussion & Activity Notes ({notes.length})
          </h4>

          {/* Add note input */}
          <form onSubmit={handleAddNote} className="flex gap-2">
            <input
              type="text"
              placeholder="Post a quick discussion note..."
              value={newNoteContent}
              onChange={(e) => setNewNoteContent(e.target.value)}
              className="flex-1 text-xs border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-[#3949ab]"
            />
            <button
              type="submit"
              disabled={isAddingNote || !newNoteContent.trim()}
              className="px-4 py-2 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-lg text-xs font-semibold flex items-center space-x-1.5 disabled:opacity-50 cursor-pointer"
            >
              <Send className="w-3.5 h-3.5" />
              <span>{isAddingNote ? 'Posting...' : 'Post Note'}</span>
            </button>
          </form>

          {/* Notes list */}
          <div className="space-y-2.5 max-h-56 overflow-y-auto pt-2">
            {isLoadingNotes ? (
              <div className="text-center py-4 text-xs text-gray-400">Loading notes...</div>
            ) : notes.length === 0 ? (
              <div className="text-center py-4 text-xs text-gray-400">
                No notes posted for this lead yet.
              </div>
            ) : (
              notes.map((n) => (
                <div
                  key={n.id}
                  className="p-3 bg-gray-50 rounded-lg border border-gray-100 text-xs"
                >
                  <p className="text-gray-800">{n.content}</p>
                  <div className="flex items-center space-x-1 text-[10px] text-gray-400 mt-1">
                    <Clock className="w-3 h-3" />
                    <span>{new Date(n.created_at).toLocaleString()}</span>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Footer Actions (Edit & Delete) */}
        <div className="pt-4 border-t border-gray-100 flex items-center justify-between">
          <button
            type="button"
            onClick={() => {
              if (window.confirm(`Are you sure you want to delete lead #${lead.lead_number}?`)) {
                onDelete(lead.id);
                onClose();
              }
            }}
            className="px-3.5 py-2 text-rose-600 hover:bg-rose-50 rounded-lg text-xs font-semibold flex items-center space-x-1.5 cursor-pointer"
          >
            <Trash2 className="w-4 h-4" />
            <span>Delete Lead</span>
          </button>

          <div className="flex items-center space-x-2">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 border border-gray-300 rounded-lg text-xs font-semibold text-gray-700 hover:bg-gray-50 cursor-pointer"
            >
              Close
            </button>
            <button
              type="button"
              onClick={() => {
                onClose();
                onEdit(lead);
              }}
              className="px-4 py-2 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-lg text-xs font-semibold flex items-center space-x-1.5 cursor-pointer"
            >
              <Edit2 className="w-3.5 h-3.5" />
              <span>Edit Lead Details</span>
            </button>
          </div>
        </div>
      </div>
    </Modal>
  );
};
