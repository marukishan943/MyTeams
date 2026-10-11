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

export interface Expense {
  id: string;
  expense_number: string;
  staff_name: string;
  category: 'Travel' | 'Food' | 'Hotel' | 'Advance' | 'Other';
  units?: number;
  amount: number;
  approved_amount?: number;
  date: string;
  status: 'Pending' | 'Approved' | 'Rejected';
  note?: string;
  receipt_url?: string;
  decision_comments?: string;
  created_at: string;
}

export interface InventoryItem {
  id: string;
  name: string;
  sku: string;
  category: string;
  unit: string;
  quantity: number;
  min_stock: number;
  rate: number;
  status: 'In Stock' | 'Low Stock' | 'Out of Stock';
  updated_at: string;
}

export interface PaymentRecord {
  id: string;
  payment_number: string;
  sales_id: string;
  contact_name: string;
  company_name?: string;
  mode: 'Cash' | 'UPI' | 'Cheque' | 'Bank Transfer';
  amount: number;
  staff_name: string;
  date: string;
  created_at: string;
}

export interface TeamUser {
  id: string;
  user_code: string;
  first_name: string;
  last_name: string;
  mobile: string;
  email: string;
  role: 'Admin' | 'Manager' | 'Staff';
  reporting_head: string;
  location_tracking: boolean;
  is_active: boolean;
  created_at: string;
}

export interface CompanyConfig {
  company_name: string;
  brand_name: string;
  phone: string;
  email: string;
  website: string;
  gstin: string;
  timezone: string;
  currency: string;
  is_dsr_email: boolean;
  invoice_prefix: string;
  proforma_prefix: string;
  order_prefix: string;
  bank_name: string;
  bank_account_no: string;
  bank_ifsc: string;
  upi_id: string;
  terms: string;
}

export interface DSRRecord {
  id: string;
  staff_name: string;
  date: string;
  attendance_status: 'Present' | 'On Leave' | 'Not Punched In';
  punch_in_time: string;
  distance_km: number;
  visits_count: number;
  leads_count: number;
  orders_value: number;
}

export interface UserProfile {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'manager' | 'staff';
  company: string;
}
