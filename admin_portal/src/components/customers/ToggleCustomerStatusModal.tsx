import React, { useEffect } from 'react';
import {
  HelpCircle,
  Building,
  Phone,
  MapPin,
  User,
  Loader2,
  AlertTriangle,
} from 'lucide-react';
import type { Customer } from '../../types/crm';

interface ToggleCustomerStatusModalProps {
  customer: Customer | null;
  isOpen: boolean;
  onClose: () => void;
  onConfirm: (customerId: string, newStatus: 'Active' | 'Inactive') => Promise<void>;
  isUpdating?: boolean;
}

export const ToggleCustomerStatusModal: React.FC<ToggleCustomerStatusModalProps> = ({
  customer,
  isOpen,
  onClose,
  onConfirm,
  isUpdating = false,
}) => {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && !isUpdating) onClose();
    };
    if (isOpen) {
      document.body.style.overflow = 'hidden';
      window.addEventListener('keydown', handleKeyDown);
    }
    return () => {
      document.body.style.overflow = 'unset';
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [isOpen, onClose, isUpdating]);

  if (!isOpen || !customer) return null;

  const willBeInactive = customer.status === 'Active';
  const targetStatus: 'Active' | 'Inactive' = willBeInactive ? 'Inactive' : 'Active';

  return (
    <div className="fixed inset-0 z-[9999] bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
      <div
        className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-6 text-center border border-gray-100 transform transition-all animate-in fade-in zoom-in-95 duration-200"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Animated Circular Icon */}
        <div
          className={`w-18 h-18 rounded-full flex items-center justify-center mx-auto mb-4 border-4 shadow-sm ${
            willBeInactive
              ? 'bg-rose-50 border-rose-200 text-rose-500'
              : 'bg-emerald-50 border-emerald-200 text-emerald-600'
          }`}
        >
          {willBeInactive ? (
            <AlertTriangle className="w-10 h-10" />
          ) : (
            <HelpCircle className="w-10 h-10" />
          )}
        </div>

        {/* Big Alert Headline */}
        <h3 className="text-xl font-bold text-gray-900 tracking-tight">
          {willBeInactive ? 'Mark as Inactive?' : 'Activate Customer?'}
        </h3>

        {/* Description */}
        <p className="text-xs text-gray-500 mt-1.5 leading-relaxed">
          {willBeInactive
            ? 'Are you sure you want to mark this customer as inactive?'
            : 'Are you sure you want to reactivate this customer?'}
        </p>

        {/* Customer Summary Box */}
        <div className="mt-4 bg-gray-50 rounded-xl p-3.5 border border-gray-200 text-left text-xs space-y-2">
          <div className="flex items-center justify-between pb-2 border-b border-gray-200">
            <span className="font-bold text-gray-900 text-sm truncate max-w-[240px]">
              {customer.name}
            </span>
            <span className="font-mono font-bold text-[#1a237e] bg-blue-50 px-2 py-0.5 rounded border border-blue-200 shrink-0">
              #{customer.customer_number}
            </span>
          </div>

          <div className="grid grid-cols-2 gap-2 text-gray-600 pt-0.5">
            {customer.company && (
              <div className="flex items-center gap-1.5 truncate">
                <Building className="w-3.5 h-3.5 text-gray-400 shrink-0" />
                <span className="truncate">{customer.company}</span>
              </div>
            )}
            <div className="flex items-center gap-1.5">
              <Phone className="w-3.5 h-3.5 text-gray-400 shrink-0" />
              <span>{customer.phone}</span>
            </div>
            {(customer.city || customer.address) && (
              <div className="flex items-center gap-1.5 truncate col-span-2">
                <MapPin className="w-3.5 h-3.5 text-gray-400 shrink-0" />
                <span className="truncate">
                  {[customer.address, customer.city].filter(Boolean).join(', ')}
                </span>
              </div>
            )}
            {customer.staff_name && (
              <div className="flex items-center gap-1.5 truncate">
                <User className="w-3.5 h-3.5 text-gray-400 shrink-0" />
                <span className="truncate">{customer.staff_name}</span>
              </div>
            )}
          </div>
        </div>

        {/* Notice */}
        <div
          className={`mt-3.5 p-2.5 rounded-lg text-left text-[11px] border ${
            willBeInactive
              ? 'bg-rose-50/70 border-rose-100 text-rose-900'
              : 'bg-emerald-50/70 border-emerald-100 text-emerald-900'
          }`}
        >
          {willBeInactive
            ? 'Inactive customers will no longer be marked active in directory lists, but can be reactivated anytime from the Status filter.'
            : 'Reactivating will restore this customer to Active status across the directory and CRM modules.'}
        </div>

        {/* Action Buttons */}
        <div className="mt-6 flex items-center justify-center gap-3">
          <button
            type="button"
            onClick={onClose}
            disabled={isUpdating}
            className="w-1/2 py-2.5 px-4 border border-gray-300 rounded-lg text-xs font-semibold text-gray-700 hover:bg-gray-100 transition-colors disabled:opacity-50 cursor-pointer"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={async () => {
              await onConfirm(customer.id, targetStatus);
              onClose();
            }}
            disabled={isUpdating}
            className={`w-1/2 py-2.5 px-4 text-white rounded-lg text-xs font-semibold shadow-md flex items-center justify-center gap-1.5 disabled:opacity-50 transition-colors cursor-pointer ${
              willBeInactive
                ? 'bg-rose-600 hover:bg-rose-700'
                : 'bg-[#1a237e] hover:bg-[#151c65]'
            }`}
          >
            {isUpdating ? (
              <>
                <Loader2 className="w-3.5 h-3.5 animate-spin" />
                <span>Updating...</span>
              </>
            ) : (
              <span>{willBeInactive ? 'Yes, Mark Inactive' : 'Yes, Activate'}</span>
            )}
          </button>
        </div>
      </div>
    </div>
  );
};
