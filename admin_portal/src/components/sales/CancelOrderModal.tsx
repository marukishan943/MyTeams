import React, { useEffect } from 'react';
import {
  AlertTriangle,
  FileText,
  User,
  Loader2,
  Calendar,
} from 'lucide-react';
import type { SalesOrder } from '../../types/crm';

interface CancelOrderModalProps {
  order: SalesOrder | null;
  isOpen: boolean;
  onClose: () => void;
  onConfirm: (orderId: string) => Promise<void>;
  isCancelling?: boolean;
}

export const CancelOrderModal: React.FC<CancelOrderModalProps> = ({
  order,
  isOpen,
  onClose,
  onConfirm,
  isCancelling = false,
}) => {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && !isCancelling) onClose();
    };
    if (isOpen) {
      document.body.style.overflow = 'hidden';
      window.addEventListener('keydown', handleKeyDown);
    }
    return () => {
      document.body.style.overflow = 'unset';
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [isOpen, onClose, isCancelling]);

  if (!isOpen || !order) return null;

  const isPFI = order.type === 'proforma_invoice';
  const docTypeLabel = isPFI ? 'Proforma Invoice' : 'Invoice';
  const prefix = isPFI ? 'PFI-' : 'INV-';
  const formattedId =
    order.order_number.startsWith('PFI-') || order.order_number.startsWith('INV-')
      ? order.order_number
      : `${prefix}${order.order_number}`;

  return (
    <div className="fixed inset-0 z-[9999] bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
      <div
        className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-6 text-center border border-gray-100 transform transition-all animate-in fade-in zoom-in-95 duration-200"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Animated Circular Warning Icon */}
        <div className="w-16 h-16 rounded-full bg-rose-50 border-4 border-rose-100 text-rose-500 flex items-center justify-center mx-auto mb-4 shadow-sm">
          <AlertTriangle className="w-8 h-8" />
        </div>

        {/* Big Alert Headline */}
        <h3 className="text-xl font-bold text-gray-900 tracking-tight">
          Cancel {docTypeLabel}?
        </h3>

        {/* Description */}
        <p className="text-xs text-gray-500 mt-1.5 leading-relaxed">
          Are you sure you want to cancel this {docTypeLabel.toLowerCase()}? Its status will be updated to <span className="font-semibold text-rose-600">Cancelled</span>.
        </p>

        {/* Document Summary Box */}
        <div className="mt-4 bg-gray-50 rounded-xl p-3.5 border border-gray-200 text-left text-xs space-y-2">
          <div className="flex items-center justify-between pb-2 border-b border-gray-200">
            <div className="flex items-center gap-2">
              <FileText className="w-4 h-4 text-[#1a237e]" />
              <span className="font-mono font-bold text-[#1a237e] text-sm">
                {formattedId}
              </span>
            </div>
            <span className="px-2 py-0.5 rounded text-[11px] font-bold uppercase bg-amber-50 text-amber-700 border border-amber-200">
              {order.status}
            </span>
          </div>

          <div className="grid grid-cols-2 gap-2 text-gray-600 pt-0.5">
            <div className="flex items-center gap-1.5 truncate">
              <User className="w-3.5 h-3.5 text-gray-400 shrink-0" />
              <span className="truncate font-medium text-gray-800">
                {order.reference_name || 'Customer'}
              </span>
            </div>
            <div className="flex items-center gap-1.5">
              <Calendar className="w-3.5 h-3.5 text-gray-400 shrink-0" />
              <span>{new Date(order.date).toLocaleDateString('en-GB')}</span>
            </div>
          </div>

          <div className="pt-2 border-t border-gray-200 flex items-center justify-between font-semibold">
            <span className="text-gray-500">Total Amount:</span>
            <span className="text-gray-900 font-bold text-sm">
              ₹{Number(order.total_amount || 0).toLocaleString('en-IN')}
            </span>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="mt-6 flex items-center justify-center gap-3">
          <button
            type="button"
            onClick={onClose}
            disabled={isCancelling}
            className="flex-1 px-4 py-2.5 rounded-xl border border-gray-300 text-gray-700 text-xs font-semibold hover:bg-gray-50 transition-colors disabled:opacity-50 cursor-pointer"
          >
            No, Keep Open
          </button>
          <button
            type="button"
            disabled={isCancelling}
            onClick={async () => {
              await onConfirm(order.id);
              onClose();
            }}
            className="flex-1 px-4 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-bold transition-all shadow-md shadow-rose-600/20 disabled:opacity-50 flex items-center justify-center gap-1.5 cursor-pointer"
          >
            {isCancelling ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                <span>Cancelling...</span>
              </>
            ) : (
              <span>Yes, Cancel</span>
            )}
          </button>
        </div>
      </div>
    </div>
  );
};
