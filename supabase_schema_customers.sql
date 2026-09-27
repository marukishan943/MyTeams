-- ==============================================================================
-- SUPABASE SQL SCHEMA: CUSTOMER MODULE
-- Run this script in the Supabase Dashboard -> SQL Editor -> Run
-- ==============================================================================

-- 1. CUSTOMERS TABLE
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
    category VARCHAR(50) DEFAULT 'Retailer', -- 'Retailer', 'Distributor', 'Other'
    status VARCHAR(50) DEFAULT 'Active', -- 'Active', 'Inactive'
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

-- Migration if table already created:
ALTER TABLE public.customers ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'Active';

-- 2. ENABLE ROW LEVEL SECURITY
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all on customers" ON public.customers;
CREATE POLICY "Allow all on customers" ON public.customers
    FOR ALL USING (true) WITH CHECK (true);

-- 3. INDEXES
CREATE INDEX IF NOT EXISTS idx_customers_customer_number ON public.customers(customer_number);
CREATE INDEX IF NOT EXISTS idx_customers_created_at ON public.customers(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_customers_category ON public.customers(category);
CREATE INDEX IF NOT EXISTS idx_customers_status ON public.customers(status);
CREATE INDEX IF NOT EXISTS idx_customers_territory ON public.customers(territory);
CREATE INDEX IF NOT EXISTS idx_customers_staff_name ON public.customers(staff_name);

-- 4. ENABLE REALTIME SAFELY
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

-- 4. AUTO-UPDATE UPDATED_AT TRIGGER
DROP TRIGGER IF EXISTS set_customers_updated_at ON public.customers;
CREATE TRIGGER set_customers_updated_at
    BEFORE UPDATE ON public.customers
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

-- 5. INITIAL SAMPLE CUSTOMERS DATA (From reference screenshots)
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
