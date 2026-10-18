import React, { useState, useEffect } from 'react';
import { Modal } from '../common/Modal';
import { Plus, Trash2 } from 'lucide-react';
import type { SalesOrder, OrderItem, Customer, Lead } from '../../types/crm';

interface OrderFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (orderData: Partial<SalesOrder>) => Promise<void>;
  initialData?: SalesOrder | null;
  defaultType?: 'order' | 'invoice' | 'proforma_invoice';
  customers: Customer[];
  leads: Lead[];
  staffList: string[];
}

export const OrderFormModal: React.FC<OrderFormModalProps> = ({
  isOpen,
  onClose,
  onSubmit,
  initialData,
  defaultType = 'invoice',
  customers,
  leads,
  staffList,
}) => {
  const [type, setType] = useState<'order' | 'invoice' | 'proforma_invoice'>(
    defaultType
  );
  const [orderNumber, setOrderNumber] = useState('');
  const [referenceName, setReferenceName] = useState('');
  const [customerId, setCustomerId] = useState('');
  const [leadId, setLeadId] = useState('');
  const [staffName, setStaffName] = useState('');
  const [date, setDate] = useState('');
  const [dueDate, setDueDate] = useState('');
  const [status, setStatus] = useState<SalesOrder['status']>('open');
  const [items, setItems] = useState<OrderItem[]>([]);
  const [notes, setNotes] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (initialData) {
      setType(initialData.type);
      setOrderNumber(initialData.order_number);
      setReferenceName(initialData.reference_name || '');
      setCustomerId(initialData.customer_id || '');
      setLeadId(initialData.lead_id || '');
      setStaffName(initialData.staff_name || '');
      setDate(initialData.date);
      setDueDate(initialData.due_date || '');
      setStatus(initialData.status);
      setItems(initialData.items && initialData.items.length > 0 ? initialData.items : [
        { id: Date.now().toString(), product: 'Product Item', quantity: 1, rate: 500, tax_percent: 18, discount: 0 }
      ]);
      setNotes(initialData.notes || '');
    } else {
      setType(defaultType);
      setOrderNumber(Math.floor(1000 + Math.random() * 9000).toString());
      setReferenceName('');
      setCustomerId('');
      setLeadId('');
      setStaffName(staffList[0] || 'Kishan Maru');
      setDate(new Date().toISOString().split('T')[0]);
      setDueDate(new Date(Date.now() + 7 * 86400000).toISOString().split('T')[0]);
      setStatus('open');
      setItems([
        { id: Date.now().toString(), product: 'Consulting / Product Item', quantity: 1, rate: 1000, tax_percent: 18, discount: 0 }
      ]);
      setNotes('Payment terms: Net 15 days. Standard warranty applies.');
    }
    setError('');
  }, [initialData, defaultType, isOpen, staffList]);

  // Handle client selection
  const handleClientSelection = (clientId: string, clientType: 'customer' | 'lead') => {
    if (clientType === 'customer') {
      setCustomerId(clientId);
      setLeadId('');
      const c = customers.find((x) => x.id === clientId);
      if (c) setReferenceName(c.name + (c.company ? ` (${c.company})` : ''));
    } else {
      setLeadId(clientId);
      setCustomerId('');
      const l = leads.find((x) => x.id === clientId);
      if (l) setReferenceName(l.name + (l.company ? ` (${l.company})` : ''));
    }
  };

  // Line item manipulation
  const addItem = () => {
    setItems([
      ...items,
      {
        id: Date.now().toString(),
        product: '',
        quantity: 1,
        rate: 0,
        tax_percent: 18,
        discount: 0,
      },
    ]);
  };

  const updateItem = (index: number, field: keyof OrderItem, val: string | number) => {
    const next = [...items];
    next[index] = { ...next[index], [field]: val };
    setItems(next);
  };

  const removeItem = (index: number) => {
    if (items.length <= 1) return;
    setItems(items.filter((_, i) => i !== index));
  };

  // Calculate totals
  const subtotal = items.reduce((sum, item) => sum + item.quantity * item.rate, 0);
  const taxTotal = items.reduce(
    (sum, item) => sum + (item.quantity * item.rate * (item.tax_percent || 0)) / 100,
    0
  );
  const totalAmount = subtotal + taxTotal;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!referenceName.trim()) {
      setError('Please select or specify a Customer or Lead.');
      return;
    }
    if (items.some((i) => !i.product.trim())) {
      setError('Please fill in product names for all items.');
      return;
    }

    setIsSubmitting(true);
    setError('');

    try {
      await onSubmit({
        type,
        order_number: orderNumber,
        reference_name: referenceName,
        customer_id: customerId || null,
        lead_id: leadId || null,
        staff_name: staffName,
        date,
        due_date: dueDate || null,
        status,
        taxable_amount: subtotal,
        total_amount: totalAmount,
        items,
        notes,
      });
      onClose();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to save sales order.';
      setError(msg);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={initialData ? `Edit ${type.replace('_', ' ')} #${orderNumber}` : `New ${type.replace('_', ' ')}`}
      maxWidth="4xl"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        {error && (
          <div className="p-3 bg-rose-50 border border-rose-200 text-rose-700 text-xs rounded-lg">
            {error}
          </div>
        )}

        {/* Top type & number row */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 bg-gray-50 p-3 rounded-xl border border-gray-200">
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Document Type
            </label>
            <select
              value={type}
              onChange={(e) => setType(e.target.value as SalesOrder['type'])}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 bg-white focus:ring-2 focus:ring-[#3949ab]"
            >
              <option value="invoice">Tax Invoice</option>
              <option value="proforma_invoice">Proforma Invoice</option>
              <option value="order">Sales Order</option>
            </select>
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Document #
            </label>
            <input
              type="text"
              value={orderNumber}
              onChange={(e) => setOrderNumber(e.target.value)}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 bg-white focus:ring-2 focus:ring-[#3949ab]"
              placeholder="e.g. 7154"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Status
            </label>
            <select
              value={status}
              onChange={(e) => setStatus(e.target.value as SalesOrder['status'])}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 bg-white focus:ring-2 focus:ring-[#3949ab]"
            >
              <option value="open">Open</option>
              <option value="pending">Pending</option>
              <option value="delivered">Delivered</option>
              <option value="converted">Converted / Paid</option>
              <option value="cancelled">Cancelled</option>
            </select>
          </div>
        </div>

        {/* Customer / Lead Reference Picker */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Select Customer / Lead
            </label>
            <select
              value={customerId ? `cust_${customerId}` : leadId ? `lead_${leadId}` : ''}
              onChange={(e) => {
                const val = e.target.value;
                if (val.startsWith('cust_')) {
                  handleClientSelection(val.replace('cust_', ''), 'customer');
                } else if (val.startsWith('lead_')) {
                  handleClientSelection(val.replace('lead_', ''), 'lead');
                }
              }}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
            >
              <option value="">-- Choose Account --</option>
              <optgroup label="Customers">
                {customers.map((c) => (
                  <option key={c.id} value={`cust_${c.id}`}>
                    [Customer] {c.name} {c.company ? `(${c.company})` : ''}
                  </option>
                ))}
              </optgroup>
              <optgroup label="Leads">
                {leads.map((l) => (
                  <option key={l.id} value={`lead_${l.id}`}>
                    [Lead #{l.lead_number}] {l.name} {l.company ? `(${l.company})` : ''}
                  </option>
                ))}
              </optgroup>
            </select>
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Bill To / Reference Name <span className="text-rose-500">*</span>
            </label>
            <input
              type="text"
              required
              value={referenceName}
              onChange={(e) => setReferenceName(e.target.value)}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
              placeholder="e.g. Ramesh Patel (Shree Ram Traders)"
            />
          </div>
        </div>

        {/* Dates and Staff */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Date
            </label>
            <input
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Due Date
            </label>
            <input
              type="date"
              value={dueDate}
              onChange={(e) => setDueDate(e.target.value)}
              className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-gray-700 mb-1">
              Sales Staff
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
        </div>

        {/* Line Items Table */}
        <div className="border border-gray-200 rounded-xl overflow-hidden">
          <div className="bg-gray-50 px-4 py-2.5 border-b border-gray-200 flex items-center justify-between">
            <span className="text-xs font-bold text-gray-700 uppercase tracking-wider">
              Product & Service Line Items
            </span>
            <button
              type="button"
              onClick={addItem}
              className="inline-flex items-center space-x-1 text-xs font-semibold text-[#3949ab] hover:underline cursor-pointer"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>Add Item</span>
            </button>
          </div>

          <div className="p-3 space-y-2 overflow-x-auto">
            {items.map((item, index) => {
              const lineTotal =
                item.quantity * item.rate * (1 + (item.tax_percent || 0) / 100);
              return (
                <div
                  key={item.id}
                  className="flex items-center gap-2 text-xs bg-gray-50/50 p-2 rounded-lg border border-gray-100"
                >
                  <div className="flex-1 min-w-40">
                    <input
                      type="text"
                      placeholder="Product or service name..."
                      value={item.product}
                      onChange={(e) => updateItem(index, 'product', e.target.value)}
                      className="w-full text-xs border border-gray-300 rounded-md p-1.5 bg-white"
                    />
                  </div>
                  <div className="w-20">
                    <input
                      type="number"
                      min="1"
                      step="any"
                      placeholder="Qty"
                      value={item.quantity}
                      onChange={(e) =>
                        updateItem(index, 'quantity', parseFloat(e.target.value) || 0)
                      }
                      className="w-full text-xs border border-gray-300 rounded-md p-1.5 bg-white text-center"
                    />
                  </div>
                  <div className="w-28">
                    <input
                      type="number"
                      min="0"
                      step="any"
                      placeholder="Rate ₹"
                      value={item.rate}
                      onChange={(e) =>
                        updateItem(index, 'rate', parseFloat(e.target.value) || 0)
                      }
                      className="w-full text-xs border border-gray-300 rounded-md p-1.5 bg-white text-right"
                    />
                  </div>
                  <div className="w-20">
                    <select
                      value={item.tax_percent}
                      onChange={(e) =>
                        updateItem(index, 'tax_percent', parseFloat(e.target.value) || 0)
                      }
                      className="w-full text-xs border border-gray-300 rounded-md p-1.5 bg-white"
                    >
                      <option value="0">0%</option>
                      <option value="5">5%</option>
                      <option value="12">12%</option>
                      <option value="18">18%</option>
                      <option value="28">28%</option>
                    </select>
                  </div>
                  <div className="w-24 text-right font-bold text-gray-800 pr-1">
                    ₹{lineTotal.toFixed(2)}
                  </div>
                  <button
                    type="button"
                    onClick={() => removeItem(index)}
                    disabled={items.length <= 1}
                    className="p-1 text-gray-400 hover:text-rose-600 disabled:opacity-20 cursor-pointer"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              );
            })}
          </div>

          {/* Totals Summary */}
          <div className="bg-gray-50/75 p-3 border-t border-gray-200 flex justify-end">
            <div className="w-64 space-y-1.5 text-xs">
              <div className="flex justify-between text-gray-600">
                <span>Taxable Amount:</span>
                <span className="font-semibold">₹{subtotal.toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-gray-600">
                <span>Total GST Tax:</span>
                <span className="font-semibold">₹{taxTotal.toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-sm font-bold text-gray-900 pt-1 border-t border-gray-200">
                <span>Grand Total:</span>
                <span className="text-[#3949ab]">₹{totalAmount.toFixed(2)}</span>
              </div>
            </div>
          </div>
        </div>

        <div>
          <label className="block text-xs font-semibold text-gray-700 mb-1">
            Notes & Terms
          </label>
          <textarea
            rows={2}
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            className="w-full text-xs border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-[#3949ab]"
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
            {isSubmitting ? 'Saving...' : initialData ? 'Update Document' : 'Generate Document'}
          </button>
        </div>
      </form>
    </Modal>
  );
};
