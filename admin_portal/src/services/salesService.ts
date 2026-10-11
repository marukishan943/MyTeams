import { supabase } from '../lib/supabase';
import type { SalesOrder } from '../types/crm';

export const salesService = {
  async fetchOrders(type?: 'order' | 'invoice' | 'proforma_invoice'): Promise<SalesOrder[]> {
    let query = supabase
      .from('lead_orders')
      .select('*')
      .order('created_at', { ascending: false });

    if (type) {
      query = query.eq('type', type);
    }

    const { data, error } = await query;
    if (error) {
      console.error('Error fetching sales orders:', error);
      throw error;
    }
    return (data || []).map((order) => ({
      ...order,
      items: Array.isArray(order.items) ? order.items : [],
    }));
  },

  async createOrder(order: Partial<SalesOrder>): Promise<SalesOrder> {
    const orderNumber =
      order.order_number || Math.floor(1000 + Math.random() * 9000).toString();

    const newOrder = {
      ...order,
      order_number: orderNumber,
      type: order.type || 'invoice',
      status: order.status || 'open',
      date: order.date || new Date().toISOString().split('T')[0],
      items: order.items || [],
      taxable_amount: order.taxable_amount || 0,
      discount_value: order.discount_value || 0,
      total_amount: order.total_amount || 0,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    const { data, error } = await supabase
      .from('lead_orders')
      .insert([newOrder])
      .select()
      .single();

    if (error) {
      console.error('Error creating sales order:', error);
      throw error;
    }
    return {
      ...data,
      items: Array.isArray(data.items) ? data.items : [],
    };
  },

  async updateOrder(id: string, updates: Partial<SalesOrder>): Promise<SalesOrder> {
    const updatePayload = {
      ...updates,
      updated_at: new Date().toISOString(),
    };

    const { data, error } = await supabase
      .from('lead_orders')
      .update(updatePayload)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('Error updating sales order:', error);
      throw error;
    }
    return {
      ...data,
      items: Array.isArray(data.items) ? data.items : [],
    };
  },

  async deleteOrder(id: string): Promise<void> {
    const { error } = await supabase.from('lead_orders').delete().eq('id', id);
    if (error) {
      console.error('Error deleting sales order:', error);
      throw error;
    }
  },
};
