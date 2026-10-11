import { supabase } from '../lib/supabase';
import type { Expense } from '../types/crm';

// Default initial records matching UpTeams inspected data
const INITIAL_EXPENSES: Expense[] = [
  {
    id: 'exp-105',
    expense_number: '105',
    staff_name: 'Mehul Ajagya',
    category: 'Food',
    amount: 210,
    approved_amount: 210,
    date: '2026-10-10',
    status: 'Pending',
    note: 'Client meeting lunch in Gondal',
    receipt_url: '',
    created_at: '2026-10-10T12:41:00Z',
  },
  {
    id: 'exp-104',
    expense_number: '104',
    staff_name: 'Mehul Ajagya',
    category: 'Travel',
    units: 14.5,
    amount: 81,
    approved_amount: 81,
    date: '2026-10-09',
    status: 'Pending',
    note: 'Visit to Rajkot GIDC Industrial Area',
    receipt_url: 'https://images.unsplash.com/photo-1554415707-9e49fa747687?w=300',
    created_at: '2026-10-09T10:15:00Z',
  },
  {
    id: 'exp-103',
    expense_number: '103',
    staff_name: 'Mehul Ajagya',
    category: 'Food',
    amount: 663,
    approved_amount: 600,
    date: '2026-10-09',
    status: 'Pending',
    note: 'Dinner with prospective distributor',
    receipt_url: 'https://images.unsplash.com/photo-1554415707-9e49fa747687?w=300',
    created_at: '2026-10-09T20:30:00Z',
  },
  {
    id: 'exp-102',
    expense_number: '102',
    staff_name: 'Mehul Ajagya',
    category: 'Travel',
    units: 24,
    amount: 135,
    approved_amount: 135,
    date: '2026-10-09',
    status: 'Pending',
    note: 'Shree Ram Traders visit travel fuel',
    receipt_url: 'https://images.unsplash.com/photo-1554415707-9e49fa747687?w=300',
    created_at: '2026-10-09T16:20:00Z',
  },
  {
    id: 'exp-101',
    expense_number: '101',
    staff_name: 'Kishan Maru',
    category: 'Travel',
    units: 52,
    amount: 290,
    approved_amount: 290,
    date: '2026-10-09',
    status: 'Approved',
    note: 'Rajkot to Morbi highway site visit',
    receipt_url: '',
    created_at: '2026-10-09T14:10:00Z',
  },
];

export const expensesService = {
  async fetchExpenses(): Promise<Expense[]> {
    try {
      const { data, error } = await supabase
        .from('expenses')
        .select('*')
        .order('created_at', { ascending: false });

      if (error || !data || data.length === 0) {
        // Fallback to local storage or initial expenses
        const local = localStorage.getItem('myteams_expenses');
        return local ? JSON.parse(local) : INITIAL_EXPENSES;
      }
      return data;
    } catch {
      const local = localStorage.getItem('myteams_expenses');
      return local ? JSON.parse(local) : INITIAL_EXPENSES;
    }
  },

  async createExpense(expense: Partial<Expense>): Promise<Expense> {
    const newExp: Expense = {
      id: `exp-${Date.now()}`,
      expense_number: Math.floor(100 + Math.random() * 900).toString(),
      staff_name: expense.staff_name || 'Staff',
      category: expense.category || 'Travel',
      units: expense.units || 0,
      amount: expense.amount || 0,
      approved_amount: expense.approved_amount || expense.amount || 0,
      date: expense.date || new Date().toISOString().split('T')[0],
      status: 'Pending',
      note: expense.note || '',
      receipt_url: expense.receipt_url || '',
      created_at: new Date().toISOString(),
    };

    try {
      await supabase.from('expenses').insert([newExp]);
    } catch (e) {
      console.warn('Could not persist to Supabase, saving locally', e);
    }

    const current = await this.fetchExpenses();
    const updated = [newExp, ...current];
    localStorage.setItem('myteams_expenses', JSON.stringify(updated));
    return newExp;
  },

  async updateExpenseStatus(
    id: string,
    status: 'Approved' | 'Rejected',
    approvedAmount: number,
    comments?: string
  ): Promise<void> {
    try {
      await supabase
        .from('expenses')
        .update({
          status,
          approved_amount: approvedAmount,
          decision_comments: comments,
          updated_at: new Date().toISOString(),
        })
        .eq('id', id);
    } catch (e) {
      console.warn(e);
    }

    const current = await this.fetchExpenses();
    const updated = current.map((exp) =>
      exp.id === id
        ? {
            ...exp,
            status,
            approved_amount: approvedAmount,
            decision_comments: comments,
          }
        : exp
    );
    localStorage.setItem('myteams_expenses', JSON.stringify(updated));
  },

  async deleteExpense(id: string): Promise<void> {
    try {
      await supabase.from('expenses').delete().eq('id', id);
    } catch (e) {
      console.warn(e);
    }
    const current = await this.fetchExpenses();
    const updated = current.filter((exp) => exp.id !== id);
    localStorage.setItem('myteams_expenses', JSON.stringify(updated));
  },
};
