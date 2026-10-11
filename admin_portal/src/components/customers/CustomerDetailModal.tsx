import React from 'react';
import { Modal } from '../common/Modal';
import {
  Building,
  Phone,
  Mail,
  MapPin,
  Calendar,
  Trash2,
  Edit2,
  FileBadge,
} from 'lucide-react';
import type { Customer } from '../../types/crm';

interface CustomerDetailModalProps {
  customer: Customer | null;
  isOpen: boolean;
  onClose: () => void;
  onEdit: (customer: Customer) => void;
  onDelete: (id: string) => void;
  onToggleStatus: (customerId: string, newStatus: 'Active' | 'Inactive') => Promise<void>;
}

export const CustomerDetailModal: React.FC<CustomerDetailModalProps> = ({
  customer,
  isOpen,
  onClose,
  onEdit,
  onDelete,
  onToggleStatus,
}) => {
  if (!customer) return null;

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={`Customer #${customer.customer_number} • ${customer.name}`}
      maxWidth="2xl"
    >
      <div className="space-y-6">
        {/* Header Status Bar */}
        <div className="bg-gray-50 p-4 rounded-xl border border-gray-200 flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center space-x-3">
            <span
              className={`px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider ${
                customer.status === 'Active'
                  ? 'bg-emerald-100 text-emerald-800'
                  : 'bg-rose-100 text-rose-800'
              }`}
            >
              {customer.status} Account
            </span>
            <span className="px-2.5 py-1 rounded-md text-xs font-semibold bg-blue-50 text-blue-700 border border-blue-200">
              {customer.category}
            </span>
          </div>

          <button
            onClick={() =>
              onToggleStatus(
                customer.id,
                customer.status === 'Active' ? 'Inactive' : 'Active'
              )
            }
            className="px-3 py-1.5 border border-gray-300 hover:bg-gray-100 rounded-lg text-xs font-medium text-gray-700 transition-colors cursor-pointer"
          >
            Mark as {customer.status === 'Active' ? 'Inactive' : 'Active'}
          </button>
        </div>

        {/* Customer Information Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="bg-white p-4 rounded-xl border border-gray-200 space-y-3">
            <h4 className="text-xs font-bold text-gray-400 uppercase tracking-wider">
              Profile & Contact
            </h4>
            <div className="space-y-2 text-xs">
              <div className="flex items-center space-x-2 text-gray-800">
                <span className="font-semibold w-24 text-gray-500">Contact:</span>
                <span className="font-bold text-sm text-gray-900">{customer.name}</span>
              </div>
              {customer.company && (
                <div className="flex items-center space-x-2 text-gray-800">
                  <span className="font-semibold w-24 text-gray-500 flex items-center gap-1">
                    <Building className="w-3.5 h-3.5 text-gray-400" />
                    Company:
                  </span>
                  <span>{customer.company}</span>
                </div>
              )}
              <div className="flex items-center space-x-2 text-gray-800">
                <span className="font-semibold w-24 text-gray-500 flex items-center gap-1">
                  <Phone className="w-3.5 h-3.5 text-gray-400" />
                  Phone:
                </span>
                <a
                  href={`tel:${customer.phone}`}
                  className="text-emerald-600 font-semibold hover:underline"
                >
                  {customer.phone}
                </a>
              </div>
              {customer.email && (
                <div className="flex items-center space-x-2 text-gray-800">
                  <span className="font-semibold w-24 text-gray-500 flex items-center gap-1">
                    <Mail className="w-3.5 h-3.5 text-gray-400" />
                    Email:
                  </span>
                  <span>{customer.email}</span>
                </div>
              )}
              {customer.gst && (
                <div className="flex items-center space-x-2 text-gray-800">
                  <span className="font-semibold w-24 text-gray-500 flex items-center gap-1">
                    <FileBadge className="w-3.5 h-3.5 text-gray-400" />
                    GST:
                  </span>
                  <span className="font-mono bg-gray-50 px-1.5 py-0.5 rounded-sm">
                    {customer.gst}
                  </span>
                </div>
              )}
            </div>
          </div>

          <div className="bg-white p-4 rounded-xl border border-gray-200 space-y-3">
            <h4 className="text-xs font-bold text-gray-400 uppercase tracking-wider">
              Assignment & Location
            </h4>
            <div className="space-y-2 text-xs">
              <div className="flex items-center space-x-2 text-gray-800">
                <span className="font-semibold w-24 text-gray-500">Staff Assigned:</span>
                <span className="font-semibold text-gray-900 bg-gray-100 px-2 py-0.5 rounded-sm">
                  {customer.staff_name || 'Unassigned'}
                </span>
              </div>
              <div className="flex items-center space-x-2 text-gray-800">
                <span className="font-semibold w-24 text-gray-500 flex items-center gap-1">
                  <MapPin className="w-3.5 h-3.5 text-gray-400" />
                  Territory:
                </span>
                <span>{customer.territory || 'RAJKOT'}</span>
              </div>
              <div className="flex items-center space-x-2 text-gray-800">
                <span className="font-semibold w-24 text-gray-500">City / State:</span>
                <span>{[customer.city, customer.state].filter(Boolean).join(', ') || 'N/A'}</span>
              </div>
              {customer.address && (
                <div className="flex items-start space-x-2 text-gray-800">
                  <span className="font-semibold w-24 text-gray-500">Address:</span>
                  <span className="flex-1">{customer.address}</span>
                </div>
              )}
              <div className="flex items-center space-x-2 text-gray-800">
                <span className="font-semibold w-24 text-gray-500 flex items-center gap-1">
                  <Calendar className="w-3.5 h-3.5 text-gray-400" />
                  Joined:
                </span>
                <span>
                  {new Date(customer.created_at).toLocaleDateString('en-GB', {
                    day: 'numeric',
                    month: 'short',
                    year: 'numeric',
                  })}
                </span>
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
                  `Are you sure you want to delete customer #${customer.customer_number}?`
                )
              ) {
                onDelete(customer.id);
                onClose();
              }
            }}
            className="px-3.5 py-2 text-rose-600 hover:bg-rose-50 rounded-lg text-xs font-semibold flex items-center space-x-1.5 cursor-pointer"
          >
            <Trash2 className="w-4 h-4" />
            <span>Delete Customer</span>
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
                onEdit(customer);
              }}
              className="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-semibold flex items-center space-x-1.5 cursor-pointer"
            >
              <Edit2 className="w-3.5 h-3.5" />
              <span>Edit Customer</span>
            </button>
          </div>
        </div>
      </div>
    </Modal>
  );
};
