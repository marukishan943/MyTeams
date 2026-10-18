import React, { useEffect } from 'react';
import {
  HelpCircle,
  Building,
  Phone,
  MapPin,
  User,
  Loader2,
  CheckCircle2,
} from 'lucide-react';
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
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && !isConverting) onClose();
    };
    if (isOpen) {
      document.body.style.overflow = 'hidden';
      window.addEventListener('keydown', handleKeyDown);
    }
    return () => {
      document.body.style.overflow = 'unset';
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [isOpen, onClose, isConverting]);

  if (!isOpen || !lead) return null;

  return (
    <div className="fixed inset-0 z-[9999] bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
      <div
        className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-6 text-center border border-gray-100 transform transition-all animate-in fade-in zoom-in-95 duration-200"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Animated SweetAlert-Style Circular Icon */}
        <div className="w-18 h-18 rounded-full bg-amber-50 border-4 border-amber-200 flex items-center justify-center mx-auto mb-4 text-amber-500 shadow-sm">
          <HelpCircle className="w-10 h-10" />
        </div>

        {/* Big Alert Headline */}
        <h3 className="text-xl font-bold text-gray-900 tracking-tight">
          Convert to Customer?
        </h3>

        {/* Description */}
        <p className="text-xs text-gray-500 mt-1.5 leading-relaxed">
          Are you sure you want to convert this lead into an active customer account?
        </p>

        {/* Lead Summary Info Card */}
        <div className="mt-4 bg-gray-50 rounded-xl p-3.5 border border-gray-200 text-left text-xs space-y-2">
          <div className="flex items-center justify-between pb-2 border-b border-gray-200">
            <span className="font-bold text-gray-900 text-sm truncate max-w-[240px]">
              {lead.name}
            </span>
            <span className="font-mono font-bold text-[#1976d2] bg-blue-50 px-2 py-0.5 rounded border border-blue-200 shrink-0">
              #{lead.lead_number}
            </span>
          </div>

          <div className="grid grid-cols-2 gap-2 text-gray-600 pt-0.5">
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
              <div className="flex items-center gap-1.5 truncate">
                <User className="w-3.5 h-3.5 text-gray-400 shrink-0" />
                <span className="truncate">{lead.staff_name}</span>
              </div>
            )}
          </div>
        </div>

        {/* Outcome Notice */}
        <div className="mt-3.5 flex items-start gap-2 bg-blue-50/70 border border-blue-100 rounded-lg p-2.5 text-left text-[11px] text-blue-900">
          <CheckCircle2 className="w-4 h-4 text-blue-600 shrink-0 mt-0.5" />
          <span>
            This lead will be saved as an active Customer, and the lead status will be updated to <strong className="text-emerald-700 font-semibold">Converted</strong>.
          </span>
        </div>

        {/* Action Buttons (Centered, prominent) */}
        <div className="mt-6 flex items-center justify-center gap-3">
          <button
            type="button"
            onClick={onClose}
            disabled={isConverting}
            className="w-1/2 py-2.5 px-4 border border-gray-300 rounded-lg text-xs font-semibold text-gray-700 hover:bg-gray-100 transition-colors disabled:opacity-50 cursor-pointer"
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
            className="w-1/2 py-2.5 px-4 bg-[#1976d2] hover:bg-[#1565c0] text-white rounded-lg text-xs font-semibold shadow-md flex items-center justify-center gap-1.5 disabled:opacity-50 transition-colors cursor-pointer"
          >
            {isConverting ? (
              <>
                <Loader2 className="w-3.5 h-3.5 animate-spin" />
                <span>Converting...</span>
              </>
            ) : (
              <span>Yes, Convert it!</span>
            )}
          </button>
        </div>
      </div>
    </div>
  );
};
