import React, { useState } from 'react';
import { Modal } from '../common/Modal';
import type { Expense } from '../../types/crm';

interface ExpenseFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (expenseData: Partial<Expense>) => Promise<void>;
  staffList: string[];
}

export const ExpenseFormModal: React.FC<ExpenseFormModalProps> = ({
  isOpen,
  onClose,
  onSubmit,
  staffList,
}) => {
  const [staffName, setStaffName] = useState(staffList[0] || 'Mehul Ajagya');
  const [category, setCategory] = useState<Expense['category']>('Travel');
  const [units, setUnits] = useState(0);
  const [amount, setAmount] = useState(0);
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);
  const [note, setNote] = useState('');
  const [receiptUrl, setReceiptUrl] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (amount <= 0) {
      setError('Please enter a valid expense amount.');
      return;
    }

    setIsSubmitting(true);
    setError('');
    try {
      await onSubmit({
        staff_name: staffName,
        category,
        units,
        amount,
        date,
        note,
        receipt_url: receiptUrl,
      });
      onClose();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to submit expense.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Submit Field Expense Claim" maxWidth="lg">
      <form onSubmit={handleSubmit} className="space-y-4">
        {error && (
          <div className="p-3 bg-rose-50 border border-rose-200 text-rose-700 text-xs rounded-lg">
            {error}
          </div>
        )}

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Field Staff
            </label>
            <select
              value={staffName}
              onChange={(e) => setStaffName(e.target.value)}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
            >
              {staffList.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Expense Category
            </label>
            <select
              value={category}
              onChange={(e) => setCategory(e.target.value as Expense['category'])}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
            >
              <option value="Travel">Travel (Fuel / Km)</option>
              <option value="Food">Food / Meals</option>
              <option value="Hotel">Hotel Stay</option>
              <option value="Advance">Advance Request</option>
              <option value="Other">Other Expenses</option>
            </select>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          {category === 'Travel' && (
            <div>
              <label className="block text-xs font-semibold text-gray-700 mb-1">
                Distance (Km)
              </label>
              <input
                type="number"
                step="any"
                value={units}
                onChange={(e) => setUnits(parseFloat(e.target.value) || 0)}
                className="w-full text-xs border border-gray-300 rounded-lg p-2"
                placeholder="e.g. 24"
              />
            </div>
          )}
          <div className={category === 'Travel' ? 'sm:col-span-1' : 'sm:col-span-2'}>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Claim Amount (₹) <span className="text-rose-500">*</span>
            </label>
            <input
              type="number"
              required
              step="any"
              value={amount}
              onChange={(e) => setAmount(parseFloat(e.target.value) || 0)}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 font-bold"
              placeholder="e.g. 450"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Date
            </label>
            <input
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              className="w-full text-xs border border-gray-300 rounded-lg p-2"
            />
          </div>
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Bill Receipt Image URL (Optional)
          </label>
          <input
            type="text"
            value={receiptUrl}
            onChange={(e) => setReceiptUrl(e.target.value)}
            className="w-full text-xs border border-gray-300 rounded-lg p-2"
            placeholder="Paste bill receipt photo link or upload URL..."
          />
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Description / Trip Purpose
          </label>
          <textarea
            rows={2}
            value={note}
            onChange={(e) => setNote(e.target.value)}
            className="w-full text-xs border border-gray-300 rounded-lg p-2"
            placeholder="e.g. Visited Rajkot Industrial estate for client demonstration"
          />
        </div>

        <div className="pt-4 border-t border-gray-100 flex items-center justify-end space-x-2">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 border border-gray-300 rounded-lg text-xs font-semibold text-gray-700 hover:bg-gray-50 cursor-pointer"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={isSubmitting}
            className="px-5 py-2 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-lg text-xs font-semibold shadow-xs disabled:opacity-50 cursor-pointer"
          >
            {isSubmitting ? 'Submitting...' : 'Submit Claim'}
          </button>
        </div>
      </form>
    </Modal>
  );
};
