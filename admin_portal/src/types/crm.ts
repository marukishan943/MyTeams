export interface Lead {
  id: string;
  lead_number: string;
  name: string;
  company?: string;
  phone: string;
  email?: string;
  website?: string;
  gst?: string;
  territory?: string;
  address?: string;
  city?: string;
  state?: string;
  pincode?: string;
  country?: string;
  date?: string;
  source: 'call' | 'email' | 'website' | 'others';
  stage: 'newLead' | 'contacted' | 'proposalSent' | 'disqualified' | 'converted';
  rating?: number;
  title?: string;
  value?: number;
  note?: string;
  visit_images?: string[];
  is_closed: boolean;
  staff_name?: string;
  user_id?: string;
  created_at: string;
  updated_at?: string;
}

export interface LeadNote {
  id: string;
  lead_id: string;
  user_id?: string;
  content: string;
  created_at: string;
}

export interface Customer {
  id: string;
  customer_number: string;
  name: string;
  company?: string;
  phone: string;
  email?: string;
  website?: string;
  category: 'Retailer' | 'Distributor' | 'Other';
  status: 'Active' | 'Inactive';
  gst?: string;
  territory?: string;
  address?: string;
  city?: string;
  state?: string;
  pincode?: string;
  country?: string;
  visit_images?: string[];
  staff_name?: string;
  created_by?: string;
  created_at: string;
  updated_at?: string;
}

export interface OrderItem {
  id: string;
  product: string;
  quantity: number;
  rate: number;
  tax_percent: number;
  discount: number;
  description?: string;
}

export interface SalesOrder {
  id: string;
  order_number: string;
  lead_id?: string | null;
  customer_id?: string | null;
  reference_name?: string | null;
  notes?: string | null;
  type: 'order' | 'invoice' | 'proforma_invoice';
  status: 'open' | 'pending' | 'delivered' | 'converted';
  date: string;
  due_date?: string | null;
  staff_name?: string;
  taxable_amount: number;
  discount_type?: 'fixed' | 'percentage';
  discount_value?: number;
  total_discount?: number;
  round_off?: boolean;
  total_amount: number;
  items: OrderItem[];
  created_at: string;
  updated_at?: string;
}

export interface UserProfile {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'manager' | 'staff';
  company: string;
}
