import { supabase } from '../lib/supabase';
import type { PaymentRecord } from '../types/crm';

const INITIAL_PAYMENTS: PaymentRecord[] = [
  {
    id: 'pay-1',
    payment_number: 'P-001',
    sales_id: 'INV-043',
    contact_name: 'Jignesh mehta',
    company_name: 'Express modify',
    mode: 'Cash',
    amount: 2749,
    staff_name: 'IV SQUARE',
    date: '2026-10-10',
    created_at: '2026-10-10T18:11:00Z',
  },
  {
    id: 'pay-2',
    payment_number: 'P-002',
    sales_id: 'INV-039',
    contact_name: 'Sunil patil',
    company_name: 'SHREE SOLAR VENTURES',
    mode: 'Cash',
    amount: 2484,
    staff_name: 'IV SQUARE',
    date: '2026-10-01',
    created_at: '2026-10-01T14:12:00Z',
  },
  {
    id: 'pay-3',
    payment_number: 'P-003',
    sales_id: 'INV-038',
    contact_name: 'NATIONAL DISTRIBUTION COMPANY',
    company_name: 'NATIONAL DISTRIBUTION COMPANY',
    mode: 'UPI',
    amount: 1705,
    staff_name: 'IV SQUARE',
    date: '2026-10-01',
    created_at: '2026-10-01T12:53:00Z',
  },
];

export const paymentsService = {
  async fetchPayments(): Promise<PaymentRecord[]> {
    try {
      const { data, error } = await supabase
        .from('payments')
        .select('*')
        .order('created_at', { ascending: false });

      if (error || !data || data.length === 0) {
        const local = localStorage.getItem('myteams_payments');
        return local ? JSON.parse(local) : INITIAL_PAYMENTS;
      }
      return data;
    } catch {
      const local = localStorage.getItem('myteams_payments');
      return local ? JSON.parse(local) : INITIAL_PAYMENTS;
    }
  },

  async recordPayment(payment: Partial<PaymentRecord>): Promise<PaymentRecord> {
    const newRecord: PaymentRecord = {
      id: `pay-${Date.now()}`,
      payment_number: `P-${Math.floor(100 + Math.random() * 900)}`,
      sales_id: payment.sales_id || `INV-${Math.floor(10 + Math.random() * 90)}`,
      contact_name: payment.contact_name || 'Client',
      company_name: payment.company_name || '',
      mode: payment.mode || 'Cash',
      amount: payment.amount || 0,
      staff_name: payment.staff_name || 'Office',
      date: payment.date || new Date().toISOString().split('T')[0],
      created_at: new Date().toISOString(),
    };

    try {
      await supabase.from('payments').insert([newRecord]);
    } catch (e) {
      console.warn(e);
    }

    const current = await this.fetchPayments();
    const updated = [newRecord, ...current];
    localStorage.setItem('myteams_payments', JSON.stringify(updated));
    return newRecord;
  },

  async deletePayment(id: string): Promise<void> {
    try {
      await supabase.from('payments').delete().eq('id', id);
    } catch (e) {
      console.warn(e);
    }
    const current = await this.fetchPayments();
    const updated = current.filter((p) => p.id !== id);
    localStorage.setItem('myteams_payments', JSON.stringify(updated));
  },
};
