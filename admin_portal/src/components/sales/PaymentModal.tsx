import React, { useState } from 'react';
import { Modal } from '../common/Modal';
import type { PaymentRecord } from '../../types/crm';

interface PaymentModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (payment: Partial<PaymentRecord>) => Promise<void>;
  staffList: string[];
}

export const PaymentModal: React.FC<PaymentModalProps> = ({
  isOpen,
  onClose,
  onSubmit,
  staffList,
}) => {
  const [salesId, setSalesId] = useState('');
  const [contactName, setContactName] = useState('');
  const [companyName, setCompanyName] = useState('');
  const [mode, setMode] = useState<PaymentRecord['mode']>('Cash');
  const [amount, setAmount] = useState(0);
  const [staffName, setStaffName] = useState(staffList[0] || 'Kishan Maru');
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!contactName.trim() || amount <= 0) {
      setError('Contact Name and valid Amount are required.');
      return;
    }

    setIsSubmitting(true);
    setError('');
    try {
      await onSubmit({
        sales_id: salesId.trim() || `INV-${Math.floor(10 + Math.random() * 90)}`,
        contact_name: contactName,
        company_name: companyName,
        mode,
        amount,
        staff_name: staffName,
        date,
      });
      onClose();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to record payment.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Record Client Payment Collection" maxWidth="md">
      <form onSubmit={handleSubmit} className="space-y-4 text-xs">
        {error && (
          <div className="p-3 bg-rose-50 border border-rose-200 text-rose-700 rounded-lg">
            {error}
          </div>
        )}

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block font-semibold text-gray-700 mb-1">
              Sales / Invoice ID
            </label>
            <input
              type="text"
              value={salesId}
              onChange={(e) => setSalesId(e.target.value)}
              placeholder="e.g. INV-045"
              className="w-full border border-gray-300 rounded-lg p-2 font-mono uppercase"
            />
          </div>
          <div>
            <label className="block font-semibold text-gray-700 mb-1">
              Collection Mode
            </label>
            <select
              value={mode}
              onChange={(e) => setMode(e.target.value as PaymentRecord['mode'])}
              className="w-full border border-gray-300 rounded-lg p-2"
            >
              <option value="Cash">Cash</option>
              <option value="UPI">UPI / QR Code</option>
              <option value="Cheque">Cheque</option>
              <option value="Bank Transfer">Bank Transfer (NEFT/RTGS)</option>
            </select>
          </div>
        </div>

        <div>
          <label className="block font-semibold text-gray-700 mb-1">
            Client Contact Name <span className="text-rose-500">*</span>
          </label>
          <input
            type="text"
            required
            value={contactName}
            onChange={(e) => setContactName(e.target.value)}
            placeholder="e.g. Jignesh Mehta"
            className="w-full border border-gray-300 rounded-lg p-2"
          />
        </div>

        <div>
          <label className="block font-semibold text-gray-700 mb-1">
            Company Name
          </label>
          <input
            type="text"
            value={companyName}
            onChange={(e) => setCompanyName(e.target.value)}
            placeholder="e.g. Express Modify Pvt Ltd"
            className="w-full border border-gray-300 rounded-lg p-2"
          />
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block font-semibold text-gray-700 mb-1">
              Amount Received (₹) <span className="text-rose-500">*</span>
            </label>
            <input
              type="number"
              required
              step="any"
              value={amount}
              onChange={(e) => setAmount(parseFloat(e.target.value) || 0)}
              placeholder="e.g. 2500"
              className="w-full border border-gray-300 rounded-lg p-2 font-bold text-sm"
            />
          </div>
          <div>
            <label className="block font-semibold text-gray-700 mb-1">
              Payment Date
            </label>
            <input
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              className="w-full border border-gray-300 rounded-lg p-2"
            />
          </div>
        </div>

        <div>
          <label className="block font-semibold text-gray-700 mb-1">
            Collecting Staff
          </label>
          <select
            value={staffName}
            onChange={(e) => setStaffName(e.target.value)}
            className="w-full border border-gray-300 rounded-lg p-2"
          >
            {staffList.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
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
            className="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-semibold shadow-xs disabled:opacity-50 cursor-pointer"
          >
            {isSubmitting ? 'Recording...' : 'Record Payment'}
          </button>
        </div>
      </form>
    </Modal>
  );
};
