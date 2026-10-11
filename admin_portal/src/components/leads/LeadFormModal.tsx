import React, { useState, useEffect } from 'react';
import { Modal } from '../common/Modal';
import type { Lead } from '../../types/crm';

interface LeadFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (leadData: Partial<Lead>) => Promise<void>;
  initialData?: Lead | null;
  staffList: string[];
}

export const LeadFormModal: React.FC<LeadFormModalProps> = ({
  isOpen,
  onClose,
  onSubmit,
  initialData,
  staffList,
}) => {
  const [formData, setFormData] = useState<Partial<Lead>>({
    lead_number: '',
    name: '',
    company: '',
    phone: '',
    email: '',
    territory: '',
    city: '',
    staff_name: '',
    source: 'call',
    stage: 'newLead',
    value: 0,
    note: '',
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (initialData) {
      setFormData(initialData);
    } else {
      setFormData({
        lead_number: Math.floor(100 + Math.random() * 900).toString(),
        name: '',
        company: '',
        phone: '',
        email: '',
        territory: 'RAJKOT',
        city: 'RAJKOT',
        staff_name: staffList[0] || 'Kishan Maru',
        source: 'call',
        stage: 'newLead',
        value: 0,
        note: '',
      });
    }
    setError('');
  }, [initialData, isOpen, staffList]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.name?.trim() || !formData.phone?.trim()) {
      setError('Contact Name and Phone number are required.');
      return;
    }

    setIsSubmitting(true);
    setError('');
    try {
      await onSubmit(formData);
      onClose();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to save lead.';
      setError(msg);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={initialData ? `Edit Lead #${initialData.lead_number}` : 'Add New Lead'}
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
              Lead #
            </label>
            <input
              type="text"
              value={formData.lead_number || ''}
              onChange={(e) => setFormData({ ...formData, lead_number: e.target.value })}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
              placeholder="e.g. 085"
            />
          </div>
          <div className="sm:col-span-2">
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Contact Name <span className="text-rose-500">*</span>
            </label>
            <input
              type="text"
              required
              value={formData.name || ''}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
              placeholder="e.g. Rajesh Patel"
            />
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Company Name
            </label>
            <input
              type="text"
              value={formData.company || ''}
              onChange={(e) => setFormData({ ...formData, company: e.target.value })}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
              placeholder="e.g. Patel Trading Co."
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
              placeholder="rajesh@example.com"
            />
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

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Lead Source
            </label>
            <select
              value={formData.source || 'call'}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  source: e.target.value as Lead['source'],
                })
              }
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
            >
              <option value="call">Phone Call</option>
              <option value="email">Email</option>
              <option value="website">Website</option>
              <option value="others">Others</option>
            </select>
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Pipeline Stage
            </label>
            <select
              value={formData.stage || 'newLead'}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  stage: e.target.value as Lead['stage'],
                })
              }
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
            >
              <option value="newLead">New Lead</option>
              <option value="contacted">Contacted</option>
              <option value="proposalSent">Proposal Sent</option>
              <option value="converted">Converted</option>
              <option value="disqualified">Disqualified</option>
            </select>
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Estimated Value (₹)
            </label>
            <input
              type="number"
              value={formData.value || 0}
              onChange={(e) =>
                setFormData({ ...formData, value: parseFloat(e.target.value) || 0 })
              }
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
            />
          </div>
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Notes / Requirement
          </label>
          <textarea
            rows={2}
            value={formData.note || ''}
            onChange={(e) => setFormData({ ...formData, note: e.target.value })}
            className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
            placeholder="Add specific client requirements or discussion points..."
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
            {isSubmitting ? 'Saving...' : initialData ? 'Update Lead' : 'Create Lead'}
          </button>
        </div>
      </form>
    </Modal>
  );
};
