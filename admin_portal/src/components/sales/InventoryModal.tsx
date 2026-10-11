import React, { useState } from 'react';
import { Modal } from '../common/Modal';
import type { InventoryItem } from '../../types/crm';

interface InventoryModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (item: Partial<InventoryItem>) => Promise<void>;
}

export const InventoryModal: React.FC<InventoryModalProps> = ({
  isOpen,
  onClose,
  onSubmit,
}) => {
  const [name, setName] = useState('');
  const [sku, setSku] = useState('');
  const [category, setCategory] = useState('ZINC SPRAY');
  const [unit, setUnit] = useState('Bottles');
  const [quantity, setQuantity] = useState(100);
  const [minStock, setMinStock] = useState(20);
  const [rate, setRate] = useState(250);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setError('Product Name is required.');
      return;
    }

    setIsSubmitting(true);
    setError('');
    try {
      await onSubmit({
        name,
        sku: sku || `SKU-${Math.floor(100 + Math.random() * 900)}`,
        category,
        unit,
        quantity,
        min_stock: minStock,
        rate,
      });
      onClose();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to add product.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Add New Product to Inventory" maxWidth="md">
      <form onSubmit={handleSubmit} className="space-y-4 text-xs">
        {error && (
          <div className="p-3 bg-rose-50 border border-rose-200 text-rose-700 rounded-lg">
            {error}
          </div>
        )}

        <div>
          <label className="block font-semibold text-gray-700 mb-1">
            Product Name <span className="text-rose-500">*</span>
          </label>
          <input
            type="text"
            required
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="e.g. ZINC SPRAY 500ML"
            className="w-full border border-gray-300 rounded-lg p-2"
          />
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block font-semibold text-gray-700 mb-1">
              SKU / Code
            </label>
            <input
              type="text"
              value={sku}
              onChange={(e) => setSku(e.target.value)}
              placeholder="e.g. ZS-500"
              className="w-full border border-gray-300 rounded-lg p-2 font-mono uppercase"
            />
          </div>
          <div>
            <label className="block font-semibold text-gray-700 mb-1">
              Category
            </label>
            <input
              type="text"
              value={category}
              onChange={(e) => setCategory(e.target.value)}
              placeholder="e.g. ZINC SPRAY"
              className="w-full border border-gray-300 rounded-lg p-2"
            />
          </div>
        </div>

        <div className="grid grid-cols-3 gap-3">
          <div>
            <label className="block font-semibold text-gray-700 mb-1">
              Initial Qty
            </label>
            <input
              type="number"
              value={quantity}
              onChange={(e) => setQuantity(parseFloat(e.target.value) || 0)}
              className="w-full border border-gray-300 rounded-lg p-2"
            />
          </div>
          <div>
            <label className="block font-semibold text-gray-700 mb-1">
              Low Stock Alert
            </label>
            <input
              type="number"
              value={minStock}
              onChange={(e) => setMinStock(parseFloat(e.target.value) || 0)}
              className="w-full border border-gray-300 rounded-lg p-2"
            />
          </div>
          <div>
            <label className="block font-semibold text-gray-700 mb-1">
              Unit Rate (₹)
            </label>
            <input
              type="number"
              step="any"
              value={rate}
              onChange={(e) => setRate(parseFloat(e.target.value) || 0)}
              className="w-full border border-gray-300 rounded-lg p-2 font-bold"
            />
          </div>
        </div>

        <div>
          <label className="block font-semibold text-gray-700 mb-1">
            Measuring Unit
          </label>
          <select
            value={unit}
            onChange={(e) => setUnit(e.target.value)}
            className="w-full border border-gray-300 rounded-lg p-2"
          >
            <option value="Bottles">Bottles</option>
            <option value="Pcs">Pcs</option>
            <option value="Boxes">Boxes</option>
            <option value="Litres">Litres</option>
            <option value="Kg">Kg</option>
            <option value="Trips">Trips</option>
          </select>
        </div>

        <div className="pt-4 border-t border-gray-100 flex items-center justify-end space-x-2">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 border border-gray-300 rounded-lg font-semibold text-gray-700 hover:bg-gray-50 cursor-pointer"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={isSubmitting}
            className="px-5 py-2 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-lg font-semibold shadow-xs disabled:opacity-50 cursor-pointer"
          >
            {isSubmitting ? 'Adding...' : 'Add to Catalog'}
          </button>
        </div>
      </form>
    </Modal>
  );
};
