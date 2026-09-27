-- ==============================================================================
-- SUPABASE SQL SCHEMA: LEAD MANAGEMENT SYSTEM (CRM)
-- Run this script in the Supabase Dashboard -> SQL Editor -> Run
-- ==============================================================================

-- Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 1. LEADS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.leads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    lead_number VARCHAR(50) NOT NULL DEFAULT '',
    staff_name VARCHAR(255) DEFAULT '',
    name VARCHAR(255) NOT NULL,
    company VARCHAR(255) DEFAULT '',
    phone VARCHAR(50) NOT NULL,
    email VARCHAR(255) DEFAULT '',
    website VARCHAR(255) DEFAULT '',
    gst VARCHAR(100) DEFAULT '',
    territory VARCHAR(255) DEFAULT '',
    address TEXT DEFAULT '',
    city VARCHAR(100) DEFAULT '',
    state VARCHAR(100) DEFAULT '',
    pincode VARCHAR(20) DEFAULT '',
    country VARCHAR(100) DEFAULT 'India',
    date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    source VARCHAR(50) NOT NULL DEFAULT 'call', -- 'call', 'email', 'website', 'others'
    stage VARCHAR(50) NOT NULL DEFAULT 'newLead', -- 'newLead', 'contacted', 'proposalSent', 'disqualified', 'converted'
    rating INT DEFAULT 0 CHECK (rating >= 0 AND rating <= 5),
    title VARCHAR(255) DEFAULT '',
    value NUMERIC(15, 2) DEFAULT 0.00,
    note TEXT DEFAULT '',
    visit_images TEXT[] DEFAULT ARRAY[]::TEXT[],
    is_closed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 2. LEAD NOTES TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.lead_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id UUID NOT NULL REFERENCES public.leads(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 3. LEAD VISITS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.lead_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id UUID NOT NULL REFERENCES public.leads(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    staff_name VARCHAR(255) DEFAULT '',
    purpose VARCHAR(50) NOT NULL DEFAULT 'meeting', -- 'meeting', 'followup'
    date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_time TIMESTAMPTZ,
    subject VARCHAR(255) DEFAULT '',
    description TEXT DEFAULT '',
    images TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 4. LEAD TASKS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.lead_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id UUID NOT NULL REFERENCES public.leads(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    staff_name VARCHAR(255) DEFAULT '',
    type VARCHAR(50) NOT NULL DEFAULT 'call', -- 'call', 'email'
    start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_time TIMESTAMPTZ,
    subject VARCHAR(255) DEFAULT '',
    description TEXT DEFAULT '',
    priority INT DEFAULT 0 CHECK (priority >= 0 AND priority <= 3), -- 0: normal, 1: low, 2: medium, 3: high
    checklist TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 5. INDEXES FOR PERFORMANCE
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_leads_stage ON public.leads(stage);
CREATE INDEX IF NOT EXISTS idx_leads_is_closed ON public.leads(is_closed);
CREATE INDEX IF NOT EXISTS idx_leads_created_at ON public.leads(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_leads_user_id ON public.leads(user_id);
CREATE INDEX IF NOT EXISTS idx_lead_notes_lead_id ON public.lead_notes(lead_id);
CREATE INDEX IF NOT EXISTS idx_lead_visits_lead_id ON public.lead_visits(lead_id);
CREATE INDEX IF NOT EXISTS idx_lead_tasks_lead_id ON public.lead_tasks(lead_id);

-- ==============================================================================
-- 6. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lead_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lead_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lead_tasks ENABLE ROW LEVEL SECURITY;

-- Leads RLS Policies (Allow access to authenticated users or public demo access)
CREATE POLICY "Allow select on leads" ON public.leads
    FOR SELECT USING (true);

CREATE POLICY "Allow insert on leads" ON public.leads
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow update on leads" ON public.leads
    FOR UPDATE USING (true);

CREATE POLICY "Allow delete on leads" ON public.leads
    FOR DELETE USING (true);

-- Lead Notes RLS Policies
CREATE POLICY "Allow all on lead_notes" ON public.lead_notes
    FOR ALL USING (true) WITH CHECK (true);

-- Lead Visits RLS Policies
CREATE POLICY "Allow all on lead_visits" ON public.lead_visits
    FOR ALL USING (true) WITH CHECK (true);

-- Lead Tasks RLS Policies
CREATE POLICY "Allow all on lead_tasks" ON public.lead_tasks
    FOR ALL USING (true) WITH CHECK (true);

-- ==============================================================================
-- 7. AUTO-UPDATE UPDATED_AT TRIGGER
-- ==============================================================================
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS set_leads_updated_at ON public.leads;
CREATE TRIGGER set_leads_updated_at
    BEFORE UPDATE ON public.leads
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

-- ==============================================================================
-- 8. INITIAL SAMPLE LEADS DATA (OPTIONAL)
-- ==============================================================================
INSERT INTO public.leads (lead_number, staff_name, name, company, phone, email, city, territory, source, stage, rating, is_closed)
VALUES 
('074', 'Bhavin Prajapati', 'abc', 'abc Pvt Ltd', '+911234567891', 'marukishan67@gmail.com', 'RAJKOT', 'METODA', 'call', 'newLead', 3, false),
('073', 'Mehul Ajagya', 'Mr. Vinay Gajera', 'Gajera Enterprises', '+919876543210', 'vinay.gajera@gmail.com', 'GONDAL', 'GONDAL', 'website', 'newLead', 4, false),
('071', 'Mehul Ajagya', 'Narayanbhai - Petlad', 'Narayan Trading Co.', '+919988776655', 'narayan@petlad.com', 'Petlad', 'PETLAD', 'call', 'newLead', 2, false)
ON CONFLICT DO NOTHING;
-- ==============================================================================
-- 9. TASK UPDATES (NOTES & TIMELOGS)
-- ==============================================================================
-- Add notes column to existing lead_tasks table
ALTER TABLE public.lead_tasks 
ADD COLUMN IF NOT EXISTS notes JSONB DEFAULT '[]'::jsonb;

-- Create the new task_logs table
CREATE TABLE IF NOT EXISTS public.task_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES public.lead_tasks(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_task_logs_task_id ON public.task_logs(task_id);

-- RLS Policies for task_logs
ALTER TABLE public.task_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all on task_logs" ON public.task_logs
    FOR ALL USING (true) WITH CHECK (true);
-- ==============================================================================
-- 10. SUBTASKS SUPPORT (SELF-REFERENCING TASK)
-- ==============================================================================
ALTER TABLE public.lead_tasks 
ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES public.lead_tasks(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_lead_tasks_parent_id ON public.lead_tasks(parent_id);

-- ==============================================================================
-- 11. LEAD ORDERS & ITEMS SUPPORT
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.lead_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id UUID NOT NULL REFERENCES public.leads(id) ON DELETE CASCADE,
    order_number TEXT NOT NULL,
    staff_name TEXT NOT NULL,
    date DATE NOT NULL,
    due_date DATE,
    status TEXT NOT NULL DEFAULT 'open',
    taxable_amount NUMERIC NOT NULL DEFAULT 0.0,
    discount_type TEXT NOT NULL DEFAULT 'fixed',
    discount_value NUMERIC NOT NULL DEFAULT 0.0,
    total_discount NUMERIC NOT NULL DEFAULT 0.0,
    round_off BOOLEAN NOT NULL DEFAULT false,
    total_amount NUMERIC NOT NULL DEFAULT 0.0,
    items JSONB DEFAULT '[]'::jsonb,
    type TEXT NOT NULL DEFAULT 'order',  -- 'order' | 'invoice' | 'proforma_invoice'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Migration: add type column to existing lead_orders table (safe to run multiple times)
ALTER TABLE public.lead_orders ADD COLUMN IF NOT EXISTS type TEXT NOT NULL DEFAULT 'order';

CREATE INDEX IF NOT EXISTS idx_lead_orders_lead_id ON public.lead_orders(lead_id);

ALTER TABLE public.lead_orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all on lead_orders" ON public.lead_orders
    FOR ALL USING (true) WITH CHECK (true);

-- ==============================================================================
-- 12. LEAD ORDER PAYMENTS SUPPORT
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.order_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.lead_orders(id) ON DELETE CASCADE,
    amount NUMERIC NOT NULL DEFAULT 0.0,
    mode TEXT NOT NULL DEFAULT 'Online',
    date DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_payments_order_id ON public.order_payments(order_id);

ALTER TABLE public.order_payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all on order_payments" ON public.order_payments
    FOR ALL USING (true) WITH CHECK (true);

-- ==============================================================================
-- 13. CUSTOMERS SUPPORT
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    customer_number VARCHAR(50) NOT NULL DEFAULT '',
    staff_name VARCHAR(255) DEFAULT '',
    name VARCHAR(255) NOT NULL,
    company VARCHAR(255) DEFAULT '',
    phone VARCHAR(50) NOT NULL,
    email VARCHAR(255) DEFAULT '',
    website VARCHAR(255) DEFAULT '',
    category VARCHAR(50) DEFAULT 'Retailer',
    status VARCHAR(50) DEFAULT 'Active',
    gst VARCHAR(100) DEFAULT '',
    territory VARCHAR(255) DEFAULT '',
    address TEXT DEFAULT '',
    city VARCHAR(100) DEFAULT '',
    state VARCHAR(100) DEFAULT '',
    pincode VARCHAR(20) DEFAULT '',
    country VARCHAR(100) DEFAULT 'India',
    visit_images TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_by VARCHAR(255) DEFAULT 'ISUN BEVERAGES',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Migration if table was previously created without status:
ALTER TABLE public.customers ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'Active';

ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all on customers" ON public.customers;
CREATE POLICY "Allow all on customers" ON public.customers
    FOR ALL USING (true) WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_customers_customer_number ON public.customers(customer_number);
CREATE INDEX IF NOT EXISTS idx_customers_created_at ON public.customers(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_customers_category ON public.customers(category);
CREATE INDEX IF NOT EXISTS idx_customers_status ON public.customers(status);
CREATE INDEX IF NOT EXISTS idx_customers_territory ON public.customers(territory);
CREATE INDEX IF NOT EXISTS idx_customers_staff_name ON public.customers(staff_name);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'customers'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.customers;
    END IF;
END $$;

-- Sample customer data
INSERT INTO public.customers (customer_number, staff_name, name, company, phone, email, territory, city, category, status, created_by, created_at)
VALUES
('1125', 'Mehul Ajagya', 'synchro electricals', 'synchro electricals', '+919876543210', 'synchro@gmail.com', 'PAL/RAVKI/LODHIKA', 'RAJKOT', 'Retailer', 'Active', 'ISUN BEVERAGES', '2026-09-25 17:08:00+05:30'),
('1124', 'Mehul Ajagya', 'AIIMS HOSPITAL Canteen', '', '+919876543211', '', 'RAJKOT', 'RAJKOT', 'Retailer', 'Active', 'ISUN BEVERAGES', '2026-09-25 16:30:00+05:30'),
('1123', 'Mehul Ajagya', 'Shiv Hospital - Hemantbhai', '', '+919876543212', '', 'RAJKOT', 'RAJKOT', 'Retailer', 'Active', 'ISUN BEVERAGES', '2026-09-25 15:45:00+05:30'),
('1121', 'Mehul Ajagya', 'Abbazbhai', '', '+919876543213', '', 'GONDAL', 'GONDAL', 'Distributor', 'Active', 'ISUN BEVERAGES', '2026-09-25 14:15:00+05:30'),
('1120', 'Mehul Ajagya', 'Mr. Ayushraj Chauhan', '', '+919876543214', '', 'RAJKOT', 'Rajkot', 'Retailer', 'Active', 'ISUN BEVERAGES', '2026-09-25 13:00:00+05:30'),
('1119', 'Prashantkumar', 'Madhuvan pan PARLOR', 'MADHUVAN PAN PARLOR', '+919876543215', '', 'METODA', 'METODA', 'Retailer', 'Active', 'ISUN BEVERAGES', '2026-09-24 11:20:00+05:30'),
('1118', 'Prashantkumar', 'Patel pan. Syam kutir', 'PATEL PAN PARLOR syam kutir', '+919876543216', '', 'METODA', 'METODA', 'Retailer', 'Active', 'ISUN BEVERAGES', '2026-09-24 10:15:00+05:30'),
('1117', 'Prashantkumar', 'KRUPA PAN PARLOR', 'KRUPA PAN PARLOR syam kutir', '+919876543217', '', 'METODA', 'METODA', 'Retailer', 'Active', 'ISUN BEVERAGES', '2026-09-23 18:40:00+05:30'),
('1116', 'Prashantkumar', 'Prit kirana stor', 'PRIT KIRANA STOR.', '+919876543218', '', 'METODA', 'METODA', 'Retailer', 'Active', 'ISUN BEVERAGES', '2026-09-23 17:05:00+05:30')
ON CONFLICT DO NOTHING;

