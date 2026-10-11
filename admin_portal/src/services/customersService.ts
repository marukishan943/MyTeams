import { supabase } from '../lib/supabase';
import type { Customer } from '../types/crm';

export const customersService = {
  async fetchCustomers(): Promise<Customer[]> {
    const { data, error } = await supabase
      .from('customers')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching customers:', error);
      throw error;
    }
    return data || [];
  },

  async createCustomer(customer: Partial<Customer>): Promise<Customer> {
    const customerNumber =
      customer.customer_number || Math.floor(1000 + Math.random() * 9000).toString();

    const newCustomer = {
      ...customer,
      customer_number: customerNumber,
      category: customer.category || 'Retailer',
      status: customer.status || 'Active',
      country: customer.country || 'India',
      created_by: customer.created_by || 'ISUN BEVERAGES',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    const { data, error } = await supabase
      .from('customers')
      .insert([newCustomer])
      .select()
      .single();

    if (error) {
      console.error('Error creating customer:', error);
      throw error;
    }
    return data;
  },

  async updateCustomer(id: string, updates: Partial<Customer>): Promise<Customer> {
    const updatePayload = {
      ...updates,
      updated_at: new Date().toISOString(),
    };

    const { data, error } = await supabase
      .from('customers')
      .update(updatePayload)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('Error updating customer:', error);
      throw error;
    }
    return data;
  },

  async deleteCustomer(id: string): Promise<void> {
    const { error } = await supabase.from('customers').delete().eq('id', id);
    if (error) {
      console.error('Error deleting customer:', error);
      throw error;
    }
  },
};
