-- ==============================================================================
-- SUPABASE SQL MIGRATION: OFFICES, TEMPLATES & SETTINGS ENHANCEMENTS
-- Run this script in the Supabase Dashboard -> SQL Editor -> Click 'Run'
-- ==============================================================================

-- 1. COMPANY OFFICES TABLE
CREATE TABLE IF NOT EXISTS public.company_offices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL DEFAULT '',
    city VARCHAR(100) DEFAULT '',
    state VARCHAR(100) DEFAULT '',
    pincode VARCHAR(20) DEFAULT '',
    country VARCHAR(100) DEFAULT 'India',
    location VARCHAR(255) DEFAULT '',
    latitude NUMERIC(10, 7) DEFAULT NULL,
    longitude NUMERIC(10, 7) DEFAULT NULL,
    users_count INTEGER DEFAULT 0,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS and permissive policy
ALTER TABLE public.company_offices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all on company_offices" ON public.company_offices;
CREATE POLICY "Allow all on company_offices" ON public.company_offices FOR ALL USING (true) WITH CHECK (true);

-- Insert Default Head Office if not exists
INSERT INTO public.company_offices (id, name, address, city, state, pincode, country, location, latitude, longitude, users_count, is_default)
SELECT 
    '00000000-0000-0000-0000-000000000001'::uuid,
    'Head Office',
    '1103, R K World Tower , Near Shitalpark , Nr. Ayodhyachowk , 150ft Ring Road, RAJKOT, GUJARAT, India - 360006.',
    'Rajkot',
    'Gujarat',
    '360006',
    'India',
    '22.3039, 70.8022',
    22.3039,
    70.8022,
    1,
    TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM public.company_offices WHERE is_default = TRUE OR name = 'Head Office'
);


-- 2. MESSAGE TEMPLATES TABLE (WhatsApp, SMS, Email)
CREATE TABLE IF NOT EXISTS public.message_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    channel VARCHAR(50) NOT NULL DEFAULT 'whatsapp', -- 'whatsapp', 'email', 'sms'
    category VARCHAR(100) DEFAULT 'General',
    content TEXT NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS and permissive policy
ALTER TABLE public.message_templates ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all on message_templates" ON public.message_templates;
CREATE POLICY "Allow all on message_templates" ON public.message_templates FOR ALL USING (true) WITH CHECK (true);

-- Insert Default WhatsApp Templates if not exists
INSERT INTO public.message_templates (id, title, channel, category, content, is_default)
SELECT 
    '10000000-0000-0000-0000-000000000001'::uuid,
    'Lead Introduction (WhatsApp)',
    'whatsapp',
    'Leads',
    'Hello {name}, thank you for contacting {company}! We received your inquiry and our team is happy to assist you. Let us know a convenient time to discuss your requirements.',
    TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM public.message_templates WHERE title = 'Lead Introduction (WhatsApp)'
);

INSERT INTO public.message_templates (id, title, channel, category, content, is_default)
SELECT 
    '10000000-0000-0000-0000-000000000002'::uuid,
    'Lead Follow-up (WhatsApp)',
    'whatsapp',
    'Leads',
    'Hi {name}, following up regarding our previous conversation about {company} services. Please let us know if you have any questions or if you would like a product catalog.',
    FALSE
WHERE NOT EXISTS (
    SELECT 1 FROM public.message_templates WHERE title = 'Lead Follow-up (WhatsApp)'
);

INSERT INTO public.message_templates (id, title, channel, category, content, is_default)
SELECT 
    '10000000-0000-0000-0000-000000000003'::uuid,
    'Order Confirmation',
    'whatsapp',
    'Sales',
    'Dear {name}, thank you for your order with {company}! Your order has been placed and is currently being processed. Reach out anytime if you need assistance.',
    FALSE
WHERE NOT EXISTS (
    SELECT 1 FROM public.message_templates WHERE title = 'Order Confirmation'
);


-- 3. ENSURE COMPANY SETTINGS TABLE & COLUMNS
CREATE TABLE IF NOT EXISTS public.company_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name VARCHAR(255) NOT NULL DEFAULT 'IV SQUARE STRUCTURE INDIA PVT LTD',
    brand_name VARCHAR(255) NOT NULL DEFAULT 'IV SQUARE STRUCTURE INDIA PVT LTD',
    phone VARCHAR(50) DEFAULT '+91 97237 93492',
    email VARCHAR(255) DEFAULT 'ivsquarestructure@gmail.com',
    website VARCHAR(255) DEFAULT 'https://ivsquarestructure.com/',
    gstin VARCHAR(100) DEFAULT '24AAFCI9953E1ZF',
    billing_address TEXT DEFAULT '1103, R K World Tower , Near Shitalpark , Nr. Ayodhyachowk , 150ft Ring Road, RAJKOT, GUJARAT, India - 360006.',
    logo_url TEXT DEFAULT '',
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
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Alter table safely if already existing to add missing columns
ALTER TABLE public.company_settings ADD COLUMN IF NOT EXISTS billing_address TEXT DEFAULT '1103, R K World Tower , Near Shitalpark , Nr. Ayodhyachowk , 150ft Ring Road, RAJKOT, GUJARAT, India - 360006.';
ALTER TABLE public.company_settings ADD COLUMN IF NOT EXISTS logo_url TEXT DEFAULT '';
ALTER TABLE public.company_settings ADD COLUMN IF NOT EXISTS brand_name VARCHAR(255) DEFAULT 'IV SQUARE STRUCTURE INDIA PVT LTD';
ALTER TABLE public.company_settings ADD COLUMN IF NOT EXISTS timezone VARCHAR(50) DEFAULT 'GMT+5:30';
ALTER TABLE public.company_settings ADD COLUMN IF NOT EXISTS currency VARCHAR(20) DEFAULT 'INR';
ALTER TABLE public.company_settings ADD COLUMN IF NOT EXISTS is_dsr_email BOOLEAN DEFAULT TRUE;

-- Ensure RLS on company_settings
ALTER TABLE public.company_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all on company_settings" ON public.company_settings;
CREATE POLICY "Allow all on company_settings" ON public.company_settings FOR ALL USING (true) WITH CHECK (true);

-- Insert default company_settings row if table is empty
INSERT INTO public.company_settings (
    company_name,
    brand_name,
    phone,
    email,
    website,
    gstin,
    billing_address,
    timezone,
    currency,
    is_dsr_email
)
SELECT 
    'IV SQUARE STRUCTURE INDIA PVT LTD',
    'IV SQUARE STRUCTURE INDIA PVT LTD',
    '+91 97237 93492',
    'ivsquarestructure@gmail.com',
    'https://ivsquarestructure.com/',
    '24AAFCI9953E1ZF',
    '1103, R K World Tower , Near Shitalpark , Nr. Ayodhyachowk , 150ft Ring Road, RAJKOT, GUJARAT, India - 360006.',
    'GMT+5:30',
    'INR',
    TRUE
WHERE NOT EXISTS (SELECT 1 FROM public.company_settings LIMIT 1);


-- 4. ENSURE TEAM USERS TABLE & COLUMNS
CREATE TABLE IF NOT EXISTS public.team_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_code VARCHAR(50) NOT NULL DEFAULT '',
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    mobile VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'Staff',
    reporting_head VARCHAR(100) DEFAULT 'Admin',
    location_tracking BOOLEAN NOT NULL DEFAULT TRUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    device_info TEXT DEFAULT '',
    last_location TEXT DEFAULT '',
    last_login TIMESTAMPTZ DEFAULT NULL,
    permissions JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Safely add missing columns on team_users if already existing
ALTER TABLE public.team_users ADD COLUMN IF NOT EXISTS device_info TEXT DEFAULT '';
ALTER TABLE public.team_users ADD COLUMN IF NOT EXISTS last_location TEXT DEFAULT '';
ALTER TABLE public.team_users ADD COLUMN IF NOT EXISTS last_login TIMESTAMPTZ DEFAULT NULL;
ALTER TABLE public.team_users ADD COLUMN IF NOT EXISTS permissions JSONB DEFAULT '{}'::jsonb;

-- Ensure RLS on team_users
ALTER TABLE public.team_users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all on team_users" ON public.team_users;
CREATE POLICY "Allow all on team_users" ON public.team_users FOR ALL USING (true) WITH CHECK (true);
