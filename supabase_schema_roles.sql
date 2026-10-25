-- ==============================================================================
-- SUPABASE SQL MIGRATION: ROLES & GRANULAR PERMISSIONS
-- Run this script in the Supabase Dashboard -> SQL Editor -> Click 'Run'
-- ==============================================================================

-- 1. CREATE ROLES TABLE
CREATE TABLE IF NOT EXISTS public.roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    access VARCHAR(100) NOT NULL,
    users_count INTEGER DEFAULT 0,
    permissions JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_system BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS and permissive policy
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all on roles" ON public.roles;
CREATE POLICY "Allow all on roles" ON public.roles FOR ALL USING (true) WITH CHECK (true);

-- 2. INSERT DEFAULT ROLES (Admin, Manager, Staff) USING NATIVE jsonb_build_object
-- (Native function avoids all string escaping and JSON parser syntax issues)

-- ADMIN ROLE
INSERT INTO public.roles (id, name, access, users_count, is_system, permissions)
VALUES (
    '00000000-0000-0000-0000-000000000010'::uuid,
    'Admin',
    'Admin',
    1,
    TRUE,
    jsonb_build_object(
        'location_tracking', false,
        'visits', false,
        'tasks', true,
        'leads', jsonb_build_object('enabled', true, 'add', true, 'edit', true, 'delete', true, 'reports', true),
        'customers', jsonb_build_object('enabled', true, 'add', true, 'edit', true, 'delete', true),
        'quotations', true,
        'proforma_invoices', jsonb_build_object('enabled', true, 'add', true, 'edit', true, 'delete', true),
        'invoices', jsonb_build_object('enabled', true, 'add', true, 'edit', true, 'delete', true, 'reports', true),
        'orders', true,
        'inventory', jsonb_build_object('enabled', true, 'add', true),
        'payments', true,
        'attendance', false,
        'leaves', true,
        'expenses', jsonb_build_object('enabled', true, 'add', true, 'edit', true, 'decision', true, 'delete', true, 'reports', true),
        'forms', true,
        'pms', false,
        'payroll', false,
        'users', jsonb_build_object('enabled', true, 'add', true, 'edit', true, 'delete', true)
    )
)
ON CONFLICT (name) DO UPDATE 
SET permissions = EXCLUDED.permissions, updated_at = NOW();

-- MANAGER ROLE
INSERT INTO public.roles (id, name, access, users_count, is_system, permissions)
VALUES (
    '00000000-0000-0000-0000-000000000020'::uuid,
    'Manager',
    'Manager',
    1,
    TRUE,
    jsonb_build_object(
        'location_tracking', false,
        'visits', false,
        'tasks', true,
        'leads', jsonb_build_object('enabled', true, 'add', true, 'edit', true, 'delete', false, 'reports', true),
        'customers', jsonb_build_object('enabled', true, 'add', true, 'edit', true, 'delete', false),
        'quotations', true,
        'proforma_invoices', jsonb_build_object('enabled', true, 'add', true, 'edit', true, 'delete', false),
        'invoices', jsonb_build_object('enabled', true, 'add', true, 'edit', true, 'delete', false, 'reports', true),
        'orders', true,
        'inventory', jsonb_build_object('enabled', true, 'add', false),
        'payments', false,
        'attendance', false,
        'leaves', false,
        'expenses', jsonb_build_object('enabled', true, 'add', true, 'edit', true, 'decision', true, 'delete', false, 'reports', true),
        'forms', false,
        'pms', false,
        'payroll', false,
        'users', jsonb_build_object('enabled', false, 'add', false, 'edit', false, 'delete', false)
    )
)
ON CONFLICT (name) DO UPDATE 
SET permissions = EXCLUDED.permissions, updated_at = NOW();

-- STAFF ROLE
INSERT INTO public.roles (id, name, access, users_count, is_system, permissions)
VALUES (
    '00000000-0000-0000-0000-000000000030'::uuid,
    'Staff',
    'Staff',
    3,
    TRUE,
    jsonb_build_object(
        'location_tracking', true,
        'visits', true,
        'tasks', true,
        'leads', jsonb_build_object('enabled', true, 'add', true, 'edit', true, 'delete', false, 'reports', false),
        'customers', jsonb_build_object('enabled', true, 'add', true, 'edit', false, 'delete', false),
        'quotations', true,
        'proforma_invoices', jsonb_build_object('enabled', true, 'add', true, 'edit', false, 'delete', false),
        'invoices', jsonb_build_object('enabled', false, 'add', false, 'edit', false, 'delete', false, 'reports', false),
        'orders', true,
        'inventory', jsonb_build_object('enabled', true, 'add', false),
        'payments', false,
        'attendance', true,
        'leaves', true,
        'expenses', jsonb_build_object('enabled', true, 'add', true, 'edit', false, 'decision', false, 'delete', false, 'reports', false),
        'forms', true,
        'pms', false,
        'payroll', false,
        'users', jsonb_build_object('enabled', false, 'add', false, 'edit', false, 'delete', false)
    )
)
ON CONFLICT (name) DO UPDATE 
SET permissions = EXCLUDED.permissions, updated_at = NOW();
