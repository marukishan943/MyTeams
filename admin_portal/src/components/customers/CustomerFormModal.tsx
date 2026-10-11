import React, { useState, useEffect } from 'react';
import { Modal } from '../common/Modal';
import type { Customer } from '../../types/crm';

interface CustomerFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: Partial<Customer>) => Promise<void>;
  initialData?: Customer | null;
  staffList: string[];
}

export const CustomerFormModal: React.FC<CustomerFormModalProps> = ({
  isOpen,
  onClose,
  onSubmit,
  initialData,
  staffList,
}) => {
  const [formData, setFormData] = useState<Partial<Customer>>({
    customer_number: '',
    name: '',
    company: '',
    phone: '',
    email: '',
    category: 'Retailer',
    status: 'Active',
    gst: '',
    territory: '',
    city: '',
    address: '',
    staff_name: '',
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (initialData) {
      setFormData(initialData);
    } else {
      setFormData({
        customer_number: Math.floor(1000 + Math.random() * 9000).toString(),
        name: '',
        company: '',
        phone: '',
        email: '',
        category: 'Retailer',
        status: 'Active',
        gst: '',
        territory: 'RAJKOT',
        city: 'RAJKOT',
        address: '',
        staff_name: staffList[0] || 'Kishan Maru',
      });
    }
    setError('');
  }, [initialData, isOpen, staffList]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.name?.trim() || !formData.phone?.trim()) {
      setError('Customer Name and Phone number are required.');
      return;
    }

    setIsSubmitting(true);
    setError('');
    try {
      await onSubmit(formData);
      onClose();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to save customer.';
      setError(msg);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={initialData ? `Edit Customer #${initialData.customer_number}` : 'Add New Customer'}
      maxWidth="2xl"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        {error && (
          <div className="p-3 bg-rose-50 border border-rose-200 text-rose-700 text-xs rounded-lg">
            {error}
          </div>
        )}

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Customer #
            </label>
            <input
              type="text"
              value={formData.customer_number || ''}
              onChange={(e) =>
                setFormData({ ...formData, customer_number: e.target.value })
              }
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
              placeholder="e.g. 1128"
            />
          </div>
          <div className="sm:col-span-2">
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Customer / Contact Name <span className="text-rose-500">*</span>
            </label>
            <input
              type="text"
              required
              value={formData.name || ''}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
              placeholder="e.g. Ramesh Bhai"
            />
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Company / Business Name
            </label>
            <input
              type="text"
              value={formData.company || ''}
              onChange={(e) => setFormData({ ...formData, company: e.target.value })}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
              placeholder="e.g. Shree Ram Enterprises"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Phone Number <span className="text-rose-500">*</span>
            </label>
            <input
              type="text"
              required
              value={formData.phone || ''}
              onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
              placeholder="+91 98765 43210"
            />
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Category
            </label>
            <select
              value={formData.category || 'Retailer'}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  category: e.target.value as Customer['category'],
                })
              }
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
            >
              <option value="Retailer">Retailer</option>
              <option value="Distributor">Distributor</option>
              <option value="Other">Other</option>
            </select>
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Status
            </label>
            <select
              value={formData.status || 'Active'}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  status: e.target.value as Customer['status'],
                })
              }
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
            >
              <option value="Active">Active</option>
              <option value="Inactive">Inactive</option>
            </select>
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Assigned Staff
            </label>
            <select
              value={formData.staff_name || ''}
              onChange={(e) => setFormData({ ...formData, staff_name: e.target.value })}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
            >
              <option value="">Unassigned</option>
              {staffList.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Email Address
            </label>
            <input
              type="email"
              value={formData.email || ''}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
              placeholder="customer@example.com"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              GST Number
            </label>
            <input
              type="text"
              value={formData.gst || ''}
              onChange={(e) => setFormData({ ...formData, gst: e.target.value })}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
              placeholder="24AAAAA0000A1Z5"
            />
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Territory
            </label>
            <input
              type="text"
              value={formData.territory || ''}
              onChange={(e) => setFormData({ ...formData, territory: e.target.value })}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
              placeholder="e.g. RAJKOT"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              City
            </label>
            <input
              type="text"
              value={formData.city || ''}
              onChange={(e) => setFormData({ ...formData, city: e.target.value })}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
              placeholder="e.g. Rajkot"
            />
          </div>
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Address
          </label>
          <textarea
            rows={2}
            value={formData.address || ''}
            onChange={(e) => setFormData({ ...formData, address: e.target.value })}
            className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
            placeholder="Shop / Office address..."
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
            className="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-semibold shadow-xs disabled:opacity-50 cursor-pointer"
          >
            {isSubmitting ? 'Saving...' : initialData ? 'Update Customer' : 'Add Customer'}
          </button>
        </div>
      </form>
    </Modal>
  );
};
