-- ==============================================================================
-- SALES & PROFORMA INVOICES SCHEMA MIGRATION
-- ==============================================================================

-- 1. Enable lead_orders to support both Leads and Customers without FK restriction
ALTER TABLE public.lead_orders ALTER COLUMN lead_id DROP NOT NULL;
ALTER TABLE public.lead_orders DROP CONSTRAINT IF EXISTS lead_orders_lead_id_fkey;
ALTER TABLE public.lead_orders ADD COLUMN IF NOT EXISTS customer_id UUID;
ALTER TABLE public.lead_orders ADD COLUMN IF NOT EXISTS reference_name TEXT;
ALTER TABLE public.lead_orders ADD COLUMN IF NOT EXISTS notes TEXT;

-- 2. Performance indexes for Sales module
CREATE INDEX IF NOT EXISTS idx_lead_orders_type ON public.lead_orders(type);
CREATE INDEX IF NOT EXISTS idx_lead_orders_date ON public.lead_orders(date DESC);
CREATE INDEX IF NOT EXISTS idx_lead_orders_staff_name ON public.lead_orders(staff_name);
CREATE INDEX IF NOT EXISTS idx_lead_orders_status ON public.lead_orders(status);

-- 3. Safely ensure realtime publication includes lead_orders
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'lead_orders'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.lead_orders;
    END IF;
END $$;
