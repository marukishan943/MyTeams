-- ==============================================================================
-- SUPABASE SQL SCHEMA: UPTEAMS EXPANDED PORTAL MODULES
-- Run this script in the Supabase Dashboard -> SQL Editor -> Run
-- ==============================================================================

-- 1. EXPENSES TABLE
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expense_number VARCHAR(50) NOT NULL DEFAULT '',
    staff_name VARCHAR(255) NOT NULL,
    category VARCHAR(50) NOT NULL DEFAULT 'Travel', -- 'Travel', 'Food', 'Hotel', 'Advance', 'Other'
    units NUMERIC(10, 2) DEFAULT 0, -- km if travel
    amount NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    approved_amount NUMERIC(15, 2) DEFAULT 0.00,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'Pending', -- 'Pending', 'Approved', 'Rejected'
    note TEXT DEFAULT '',
    receipt_url TEXT DEFAULT '',
    decision_comments TEXT DEFAULT '',
    approved_by VARCHAR(255) DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. INVENTORY & PRODUCTS TABLE
CREATE TABLE IF NOT EXISTS public.inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    sku VARCHAR(100) DEFAULT '',
    category VARCHAR(100) DEFAULT 'General',
    unit VARCHAR(50) DEFAULT 'Pcs',
    quantity NUMERIC(15, 2) NOT NULL DEFAULT 0,
    min_stock NUMERIC(15, 2) DEFAULT 10,
    rate NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    status VARCHAR(50) DEFAULT 'In Stock', -- 'In Stock', 'Low Stock', 'Out of Stock'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. PAYMENTS / COLLECTIONS TABLE
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_number VARCHAR(50) NOT NULL DEFAULT '',
    order_id UUID REFERENCES public.lead_orders(id) ON DELETE SET NULL,
    sales_id VARCHAR(50) DEFAULT '',
    contact_name VARCHAR(255) NOT NULL,
    company_name VARCHAR(255) DEFAULT '',
    mode VARCHAR(50) NOT NULL DEFAULT 'Cash', -- 'Cash', 'UPI', 'Cheque', 'Bank Transfer'
    amount NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    staff_name VARCHAR(255) NOT NULL DEFAULT 'Office',
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    reference_number VARCHAR(100) DEFAULT '',
    notes TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. TEAM USERS TABLE
CREATE TABLE IF NOT EXISTS public.team_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_code VARCHAR(50) NOT NULL DEFAULT '',
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    mobile VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'Staff', -- 'Admin', 'Manager', 'Staff'
    reporting_head VARCHAR(100) DEFAULT 'Admin',
    location_tracking BOOLEAN NOT NULL DEFAULT TRUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. COMPANY SETTINGS TABLE
CREATE TABLE IF NOT EXISTS public.company_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name VARCHAR(255) NOT NULL DEFAULT 'IV SQUARE STRUCTURE INDIA PVT LTD',
    brand_name VARCHAR(255) NOT NULL DEFAULT 'IV SQUARE STRUCTURE INDIA PVT LTD',
    phone VARCHAR(50) DEFAULT '9723793492',
    email VARCHAR(255) DEFAULT 'ivsquarestructure@gmail.com',
    website VARCHAR(255) DEFAULT 'https://ivsquarestructure.com/',
    gstin VARCHAR(100) DEFAULT '24AAFCI9953E1ZF',
    timezone VARCHAR(50) DEFAULT 'GMT+5:30',
    currency VARCHAR(20) DEFAULT 'INR',
    is_dsr_email BOOLEAN DEFAULT TRUE,
    invoice_prefix VARCHAR(20) DEFAULT 'INV-',
    proforma_prefix VARCHAR(20) DEFAULT 'PFI-',
    order_prefix VARCHAR(20) DEFAULT 'ORD-',
    bank_name VARCHAR(100) DEFAULT 'State Bank of India',
    bank_account_no VARCHAR(100) DEFAULT '38920194819',
    bank_ifsc VARCHAR(50) DEFAULT 'SBIN0001234',
    upi_id VARCHAR(100) DEFAULT 'ivsquare@sbi',
    terms TEXT DEFAULT '1. Goods once sold will not be taken back.\n2. Interest @ 18% p.a. will be charged after due date.\n3. Subject to Rajkot jurisdiction.',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. ENABLE ROW LEVEL SECURITY WITH PUBLIC READ/WRITE POLICIES
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all on expenses" ON public.expenses FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all on inventory" ON public.inventory FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all on payments" ON public.payments FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.team_users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all on team_users" ON public.team_users FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.company_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all on company_settings" ON public.company_settings FOR ALL USING (true) WITH CHECK (true);
