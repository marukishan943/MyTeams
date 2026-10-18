import React from 'react';
import { Modal } from '../common/Modal';
import { CornerUpRight, Building, Phone, MapPin, User, Loader2 } from 'lucide-react';
import type { Lead } from '../../types/crm';

interface ConvertLeadModalProps {
  lead: Lead | null;
  isOpen: boolean;
  onClose: () => void;
  onConfirm: (lead: Lead) => Promise<void>;
  isConverting?: boolean;
}

export const ConvertLeadModal: React.FC<ConvertLeadModalProps> = ({
  lead,
  isOpen,
  onClose,
  onConfirm,
  isConverting = false,
}) => {
  if (!lead) return null;

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title=""
      maxWidth="md"
    >
      <div className="space-y-5 text-gray-800">
        {/* Header Icon + Title */}
        <div className="flex items-start gap-4">
          <div className="w-11 h-11 rounded-full bg-blue-50 border border-blue-200 flex items-center justify-center shrink-0">
            <CornerUpRight className="w-6 h-6 text-[#1976d2]" />
          </div>
          <div>
            <h3 className="text-base font-bold text-gray-900">
              Convert Lead to Customer
            </h3>
            <p className="text-xs text-gray-500 mt-0.5">
              Are you sure you want to convert this lead into an active customer account?
            </p>
          </div>
        </div>

        {/* Lead Summary Box */}
        <div className="bg-gray-50 rounded-xl p-4 border border-gray-200 space-y-2.5 text-xs">
          <div className="flex items-center justify-between pb-2 border-b border-gray-200">
            <span className="font-bold text-gray-900 text-sm">{lead.name}</span>
            <span className="font-mono font-bold text-[#1976d2] bg-blue-50 px-2 py-0.5 rounded border border-blue-200">
              Lead #{lead.lead_number}
            </span>
          </div>

          <div className="grid grid-cols-2 gap-2 pt-1 text-gray-600">
            {lead.company && (
              <div className="flex items-center gap-1.5 truncate">
                <Building className="w-3.5 h-3.5 text-gray-400 shrink-0" />
                <span className="truncate">{lead.company}</span>
              </div>
            )}
            <div className="flex items-center gap-1.5">
              <Phone className="w-3.5 h-3.5 text-gray-400 shrink-0" />
              <span>{lead.phone}</span>
            </div>
            {(lead.city || lead.state) && (
              <div className="flex items-center gap-1.5 truncate">
                <MapPin className="w-3.5 h-3.5 text-gray-400 shrink-0" />
                <span className="truncate">
                  {[lead.city, lead.state].filter(Boolean).join(', ')}
                </span>
              </div>
            )}
            {lead.staff_name && (
              <div className="flex items-center gap-1.5">
                <User className="w-3.5 h-3.5 text-gray-400 shrink-0" />
                <span>Assigned: {lead.staff_name}</span>
              </div>
            )}
          </div>
        </div>

        {/* What happens info */}
        <div className="rounded-lg bg-blue-50/60 border border-blue-100 p-3 text-xs text-blue-900 space-y-1">
          <p className="font-semibold text-blue-950">What will happen:</p>
          <ul className="list-disc list-inside space-y-0.5 text-blue-800 text-[11px]">
            <li>A new Customer profile will be created in your Customer Directory.</li>
            <li>This lead's pipeline stage will be updated to <strong className="text-emerald-700">Converted</strong>.</li>
            <li>All contact, company, phone, and territory details will be linked.</li>
          </ul>
        </div>

        {/* Actions */}
        <div className="flex items-center justify-end gap-2.5 pt-2 border-t border-gray-100">
          <button
            type="button"
            onClick={onClose}
            disabled={isConverting}
            className="px-4 py-2 border border-gray-300 rounded-lg text-xs font-semibold text-gray-700 hover:bg-gray-50 transition-colors disabled:opacity-50 cursor-pointer"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={async () => {
              await onConfirm(lead);
              onClose();
            }}
            disabled={isConverting}
            className="px-4 py-2 bg-[#1976d2] hover:bg-[#1565c0] text-white rounded-lg text-xs font-semibold shadow-xs flex items-center gap-1.5 disabled:opacity-50 transition-colors cursor-pointer"
          >
            {isConverting ? (
              <>
                <Loader2 className="w-3.5 h-3.5 animate-spin" />
                <span>Converting...</span>
              </>
            ) : (
              <>
                <CornerUpRight className="w-3.5 h-3.5" />
                <span>Yes, Convert to Customer</span>
              </>
            )}
          </button>
        </div>
      </div>
    </Modal>
  );
};
