import React, { useState, useEffect } from 'react';
import { Modal } from '../common/Modal';
import { CheckCircle, XCircle, ExternalLink } from 'lucide-react';
import type { Expense } from '../../types/crm';

interface ExpenseApproveModalProps {
  expense: Expense | null;
  isOpen: boolean;
  onClose: () => void;
  onDecide: (
    id: string,
    status: 'Approved' | 'Rejected',
    approvedAmount: number,
    comments?: string
  ) => Promise<void>;
}

export const ExpenseApproveModal: React.FC<ExpenseApproveModalProps> = ({
  expense,
  isOpen,
  onClose,
  onDecide,
}) => {
  const [approvedAmount, setApprovedAmount] = useState<number>(0);
  const [comments, setComments] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (expense) {
      setApprovedAmount(expense.approved_amount ?? expense.amount);
      setComments(expense.decision_comments || '');
    }
  }, [expense]);

  if (!expense) return null;

  const handleAction = async (status: 'Approved' | 'Rejected') => {
    setIsSubmitting(true);
    try {
      await onDecide(
        expense.id,
        status,
        status === 'Approved' ? approvedAmount : 0,
        comments
      );
      onClose();
    } catch (e) {
      console.error(e);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={`Review Expense Claim #${expense.expense_number} • ${expense.staff_name}`}
      maxWidth="lg"
    >
      <div className="space-y-4 text-xs">
        {/* Claim Summary Card */}
        <div className="bg-gray-50 p-4 rounded-xl border border-gray-200 grid grid-cols-2 gap-3">
          <div>
            <span className="text-gray-400 font-semibold block uppercase tracking-wider text-[10px]">
              Staff Member:
            </span>
            <span className="font-bold text-gray-900 text-sm">{expense.staff_name}</span>
          </div>
          <div>
            <span className="text-gray-400 font-semibold block uppercase tracking-wider text-[10px]">
              Expense Category:
            </span>
            <span className="font-semibold text-gray-800 bg-white px-2 py-0.5 rounded-sm border border-gray-200">
              {expense.category} {expense.units ? `(${expense.units} km)` : ''}
            </span>
          </div>
          <div>
            <span className="text-gray-400 font-semibold block uppercase tracking-wider text-[10px]">
              Claim Date:
            </span>
            <span className="text-gray-800 font-medium">{expense.date}</span>
          </div>
          <div>
            <span className="text-gray-400 font-semibold block uppercase tracking-wider text-[10px]">
              Claimed Amount:
            </span>
            <span className="text-sm font-bold text-gray-900">₹{expense.amount}</span>
          </div>
        </div>

        {/* Note / Purpose */}
        {expense.note && (
          <div className="p-3 bg-white border border-gray-200 rounded-lg">
            <span className="text-gray-400 font-semibold block mb-0.5 text-[10px] uppercase">
              Staff Note:
            </span>
            <p className="text-gray-700">{expense.note}</p>
          </div>
        )}

        {/* Bill Image Preview (if present) */}
        {expense.receipt_url && (
          <div className="p-3 bg-white border border-gray-200 rounded-lg">
            <span className="text-gray-400 font-semibold block mb-1.5 text-[10px] uppercase flex items-center justify-between">
              <span>Attached Bill Receipt:</span>
              <a
                href={expense.receipt_url}
                target="_blank"
                rel="noreferrer"
                className="text-[#3949ab] font-bold flex items-center gap-1 hover:underline"
              >
                Open Full Image <ExternalLink className="w-3 h-3" />
              </a>
            </span>
            <img
              src={expense.receipt_url}
              alt="Receipt"
              className="max-h-48 rounded-md object-contain border border-gray-100 bg-gray-50 w-full"
            />
          </div>
        )}

        {/* Admin Audit Adjustment */}
        <div className="space-y-3 pt-2">
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Sanctioned / Approved Amount (₹)
            </label>
            <input
              type="number"
              value={approvedAmount}
              onChange={(e) => setApprovedAmount(parseFloat(e.target.value) || 0)}
              className="w-full text-sm font-bold border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-emerald-500"
            />
            <p className="text-[10px] text-gray-500 mt-0.5">
              Allows partial reimbursements if bill receipts don't cover full claim.
            </p>
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Admin Decision Comments / Audit Notes
            </label>
            <textarea
              rows={2}
              value={comments}
              onChange={(e) => setComments(e.target.value)}
              placeholder="e.g. Approved as per field travel allowance policy."
              className="w-full text-xs border border-gray-300 rounded-lg p-2"
            />
          </div>
        </div>

        {/* Action Buttons */}
        <div className="pt-4 border-t border-gray-100 flex items-center justify-between">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 border border-gray-300 rounded-lg text-xs font-semibold text-gray-700 hover:bg-gray-50 cursor-pointer"
          >
            Cancel
          </button>

          <div className="flex items-center space-x-2">
            <button
              type="button"
              disabled={isSubmitting}
              onClick={() => handleAction('Rejected')}
              className="px-4 py-2 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 rounded-lg text-xs font-semibold flex items-center space-x-1.5 cursor-pointer disabled:opacity-50"
            >
              <XCircle className="w-4 h-4 text-rose-600" />
              <span>Reject Claim</span>
            </button>
            <button
              type="button"
              disabled={isSubmitting}
              onClick={() => handleAction('Approved')}
              className="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-semibold flex items-center space-x-1.5 cursor-pointer shadow-xs disabled:opacity-50"
            >
              <CheckCircle className="w-4 h-4 text-white" />
              <span>Approve (₹{approvedAmount})</span>
            </button>
          </div>
        </div>
      </div>
    </Modal>
  );
};
