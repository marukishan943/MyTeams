import React from 'react';
import { Modal } from '../common/Modal';
import {
  Printer,
  Trash2,
  Edit2,
  Building,
  Calendar,
  User,
} from 'lucide-react';
import type { SalesOrder } from '../../types/crm';

interface OrderDetailModalProps {
  order: SalesOrder | null;
  isOpen: boolean;
  onClose: () => void;
  onEdit: (order: SalesOrder) => void;
  onDelete: (id: string) => void;
  onUpdateStatus: (id: string, newStatus: SalesOrder['status']) => Promise<void>;
}

export const OrderDetailModal: React.FC<OrderDetailModalProps> = ({
  order,
  isOpen,
  onClose,
  onEdit,
  onDelete,
  onUpdateStatus,
}) => {
  if (!order) return null;

  const formatCurrency = (val: number) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
    }).format(val);
  };

  const handlePrint = () => {
    window.print();
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={`${order.type.replace('_', ' ').toUpperCase()} #${order.order_number}`}
      maxWidth="4xl"
    >
      <div className="space-y-6">
        {/* Action Header & Status Switcher */}
        <div className="bg-gray-50 p-4 rounded-xl border border-gray-200 flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center space-x-2">
            <span className="text-xs font-semibold text-gray-500 uppercase tracking-wider">
              Status:
            </span>
            {(['open', 'pending', 'delivered', 'converted'] as SalesOrder['status'][]).map(
              (st) => (
                <button
                  key={st}
                  onClick={() => onUpdateStatus(order.id, st)}
                  className={`px-3 py-1 rounded-lg text-xs font-semibold capitalize transition-all cursor-pointer ${
                    order.status === st
                      ? 'bg-[#3949ab] text-white shadow-xs'
                      : 'bg-white border border-gray-200 text-gray-700 hover:border-gray-300'
                  }`}
                >
                  {st === 'converted' ? 'Converted / Paid' : st}
                </button>
              )
            )}
          </div>

          <button
            onClick={handlePrint}
            className="inline-flex items-center space-x-1.5 px-3 py-1.5 bg-white border border-gray-300 hover:bg-gray-100 rounded-lg text-xs font-semibold text-gray-700 shadow-2xs transition-colors cursor-pointer"
          >
            <Printer className="w-4 h-4 text-gray-600" />
            <span>Print / Save PDF</span>
          </button>
        </div>

        {/* Printable Invoice Card */}
        <div className="p-6 bg-white border border-gray-200 rounded-xl space-y-6 shadow-xs">
          {/* Company & Document Header */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between border-b border-gray-200 pb-5 gap-4">
            <div>
              <div className="flex items-center space-x-2">
                <div className="w-8 h-8 rounded-lg bg-[#3949ab] text-white font-bold flex items-center justify-center text-sm">
                  MT
                </div>
                <h3 className="text-lg font-black text-gray-900 tracking-tight">
                  IV SQUARE STRUCTURE INDIA PVT LTD
                </h3>
              </div>
              <p className="text-xs text-gray-500 mt-1">
                Corporate Office • Rajkot, Gujarat, India
              </p>
            </div>
            <div className="text-left sm:text-right">
              <span className="inline-block px-3 py-1 rounded-md text-xs font-bold uppercase tracking-wider bg-indigo-50 text-[#3949ab] border border-indigo-200">
                {order.type.replace('_', ' ')}
              </span>
              <div className="text-lg font-mono font-bold text-gray-900 mt-1">
                #{order.order_number}
              </div>
            </div>
          </div>

          {/* Bill To & Invoice Info */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
            <div className="space-y-1.5">
              <span className="font-bold text-gray-400 uppercase tracking-wider block">
                Billed To:
              </span>
              <p className="text-sm font-bold text-gray-900">
                {order.reference_name || 'Client Account'}
              </p>
              <div className="text-gray-500 flex items-center gap-1">
                <Building className="w-3.5 h-3.5 text-gray-400" />
                <span>Verified Client Record</span>
              </div>
            </div>

            <div className="space-y-1.5 sm:text-right">
              <span className="font-bold text-gray-400 uppercase tracking-wider block">
                Document Details:
              </span>
              <div className="text-gray-700 flex sm:justify-end items-center gap-1.5">
                <Calendar className="w-3.5 h-3.5 text-gray-400" />
                <span>Date: <b>{order.date}</b></span>
              </div>
              {order.due_date && (
                <div className="text-gray-700 flex sm:justify-end items-center gap-1.5">
                  <Calendar className="w-3.5 h-3.5 text-rose-400" />
                  <span>Due Date: <b>{order.due_date}</b></span>
                </div>
              )}
              <div className="text-gray-700 flex sm:justify-end items-center gap-1.5">
                <User className="w-3.5 h-3.5 text-gray-400" />
                <span>Sales Staff: <b>{order.staff_name || 'Office'}</b></span>
              </div>
            </div>
          </div>

          {/* Line Items Table */}
          <div className="border border-gray-200 rounded-lg overflow-hidden">
            <table className="w-full text-left text-xs">
              <thead className="bg-gray-50 text-gray-600 font-semibold border-b border-gray-200">
                <tr>
                  <th className="px-4 py-2.5">#</th>
                  <th className="px-4 py-2.5">Item & Description</th>
                  <th className="px-4 py-2.5 text-center">Qty</th>
                  <th className="px-4 py-2.5 text-right">Rate</th>
                  <th className="px-4 py-2.5 text-center">GST %</th>
                  <th className="px-4 py-2.5 text-right">Total</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {order.items.map((item, idx) => {
                  const lineTotal =
                    item.quantity * item.rate * (1 + (item.tax_percent || 0) / 100);
                  return (
                    <tr key={idx} className="hover:bg-gray-50/50">
                      <td className="px-4 py-2.5 text-gray-400">{idx + 1}</td>
                      <td className="px-4 py-2.5 font-medium text-gray-900">
                        {item.product}
                      </td>
                      <td className="px-4 py-2.5 text-center">{item.quantity}</td>
                      <td className="px-4 py-2.5 text-right">
                        {formatCurrency(item.rate)}
                      </td>
                      <td className="px-4 py-2.5 text-center">
                        {item.tax_percent || 0}%
                      </td>
                      <td className="px-4 py-2.5 text-right font-bold text-gray-900">
                        {formatCurrency(lineTotal)}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          {/* Totals Breakdown */}
          <div className="flex flex-col sm:flex-row justify-between items-start pt-2 gap-4">
            <div className="text-xs text-gray-500 max-w-sm">
              {order.notes && (
                <div className="p-3 bg-gray-50 rounded-lg border border-gray-100">
                  <span className="font-bold text-gray-700 block mb-0.5">Notes:</span>
                  <p>{order.notes}</p>
                </div>
              )}
            </div>

            <div className="w-full sm:w-64 space-y-2 text-xs">
              <div className="flex justify-between text-gray-600">
                <span>Taxable Amount:</span>
                <span className="font-semibold">{formatCurrency(order.taxable_amount)}</span>
              </div>
              <div className="flex justify-between text-gray-600">
                <span>GST Tax:</span>
                <span className="font-semibold">
                  {formatCurrency(Math.max(0, order.total_amount - order.taxable_amount))}
                </span>
              </div>
              <div className="flex justify-between text-base font-bold text-gray-900 pt-2 border-t border-gray-200">
                <span>Total Amount:</span>
                <span className="text-[#3949ab]">{formatCurrency(order.total_amount)}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Footer Actions */}
        <div className="pt-4 border-t border-gray-100 flex items-center justify-between">
          <button
            type="button"
            onClick={() => {
              if (
                window.confirm(
                  `Are you sure you want to delete ${order.type.replace('_', ' ')} #${order.order_number}?`
                )
              ) {
                onDelete(order.id);
                onClose();
              }
            }}
            className="px-3.5 py-2 text-rose-600 hover:bg-rose-50 rounded-lg text-xs font-semibold flex items-center space-x-1.5 cursor-pointer"
          >
            <Trash2 className="w-4 h-4" />
            <span>Delete Document</span>
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
                onEdit(order);
              }}
              className="px-4 py-2 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-lg text-xs font-semibold flex items-center space-x-1.5 cursor-pointer"
            >
              <Edit2 className="w-3.5 h-3.5" />
              <span>Edit Document</span>
            </button>
          </div>
        </div>
      </div>
    </Modal>
  );
};
