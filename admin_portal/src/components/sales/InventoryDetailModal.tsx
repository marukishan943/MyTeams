import React, { useEffect } from 'react';
import { Package, X, Tag, CheckCircle2, AlertCircle } from 'lucide-react';
import type { InventoryItem } from '../../types/crm';

interface InventoryDetailModalProps {
  item: InventoryItem | null;
  isOpen: boolean;
  onClose: () => void;
}

export const InventoryDetailModal: React.FC<InventoryDetailModalProps> = ({
  item,
  isOpen,
  onClose,
}) => {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    if (isOpen) {
      document.body.style.overflow = 'hidden';
      window.addEventListener('keydown', handleKeyDown);
    }
    return () => {
      document.body.style.overflow = 'unset';
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [isOpen, onClose]);

  if (!isOpen || !item) return null;

  const isLowStock = item.quantity <= item.min_stock;

  return (
    <div className="fixed inset-0 z-[9999] bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
      <div
        className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-6 text-left border border-gray-100 transform transition-all animate-in fade-in zoom-in-95 duration-200"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between pb-3 border-b border-gray-200">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-blue-50 text-[#1a237e] flex items-center justify-center font-bold">
              <Package className="w-4 h-4 text-[#1a237e]" />
            </div>
            <div>
              <h3 className="text-base font-bold text-gray-900 tracking-tight">
                {item.name}
              </h3>
              <p className="text-xs font-mono text-gray-500">SKU: {item.sku}</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-colors cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Details Grid */}
        <div className="mt-4 space-y-3 text-xs">
          <div className="grid grid-cols-2 gap-3 bg-gray-50 p-3.5 rounded-xl border border-gray-200">
            <div>
              <span className="text-gray-500 block mb-0.5">Category</span>
              <span className="font-semibold text-gray-800 flex items-center gap-1">
                <Tag className="w-3 h-3 text-gray-400" />
                {item.category || 'General'}
              </span>
            </div>
            <div>
              <span className="text-gray-500 block mb-0.5">Rate / Price</span>
              <span className="font-bold text-gray-900 text-sm">
                ₹{Number(item.rate || 0).toLocaleString('en-IN')}
              </span>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3 bg-gray-50 p-3.5 rounded-xl border border-gray-200">
            <div>
              <span className="text-gray-500 block mb-0.5">Current Stock</span>
              <span className="font-bold text-[#1a237e] text-base">
                {item.quantity} <span className="text-xs font-normal text-gray-500">{item.unit}</span>
              </span>
            </div>
            <div>
              <span className="text-gray-500 block mb-0.5">Minimum Stock Alert</span>
              <span className="font-semibold text-gray-700">
                {item.min_stock} {item.unit}
              </span>
            </div>
          </div>

          <div className="flex items-center justify-between px-3.5 py-2.5 rounded-xl border border-gray-200 bg-white">
            <span className="text-gray-600 font-medium">Status</span>
            <span
              className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full font-semibold text-[11px] ${
                !isLowStock
                  ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                  : 'bg-rose-50 text-rose-700 border border-rose-200'
              }`}
            >
              {!isLowStock ? (
                <>
                  <CheckCircle2 className="w-3 h-3 text-emerald-600" />
                  <span>In Stock</span>
                </>
              ) : (
                <>
                  <AlertCircle className="w-3 h-3 text-rose-600" />
                  <span>Low Stock</span>
                </>
              )}
            </span>
          </div>

          {item.updated_at && (
            <div className="bg-gray-50 px-3.5 py-2.5 rounded-xl border border-gray-200 flex items-center justify-between text-gray-500">
              <span>Last Updated</span>
              <span className="font-medium text-gray-700">
                {new Date(item.updated_at).toLocaleDateString('en-GB')}
              </span>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="mt-5 flex justify-end">
          <button
            onClick={onClose}
            className="px-4 py-2 bg-[#1a237e] hover:bg-[#151c65] text-white rounded-xl text-xs font-semibold shadow-xs cursor-pointer"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
};
