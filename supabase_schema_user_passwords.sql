-- ==============================================================================
-- SUPABASE SQL MIGRATION: TEAM USER PASSWORDS & AUTH SYNC
-- Run this script in the Supabase Dashboard -> SQL Editor -> Click 'Run'
-- ==============================================================================

-- 1. Ensure pgcrypto extension is enabled for bcrypt hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- 2. Add 'password' column to team_users table so passwords configured in web portal are stored
ALTER TABLE public.team_users ADD COLUMN IF NOT EXISTS password TEXT DEFAULT '';

-- 3. Stored procedure to set / update user password in Supabase auth.users
-- This allows the Admin Web Portal to set or change passwords for team members
-- so they can log in seamlessly on the MyTeams mobile app!
CREATE OR REPLACE FUNCTION public.admin_set_user_password(target_email text, new_password text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
    v_user_id uuid;
    v_encrypted_pw text;
BEGIN
    IF target_email IS NULL OR trim(target_email) = '' OR new_password IS NULL OR trim(new_password) = '' THEN
        RETURN json_build_object('success', false, 'error', 'Email and password are required');
    END IF;

    -- Generate bcrypt password hash using pgcrypto
    v_encrypted_pw := extensions.crypt(trim(new_password), extensions.gen_salt('bf'));
    
    -- Check if user already exists in auth.users
    SELECT id INTO v_user_id FROM auth.users WHERE lower(email) = lower(trim(target_email));
    
    IF v_user_id IS NOT NULL THEN
        -- User exists: Update password, mark email confirmed, update timestamp
        UPDATE auth.users
        SET encrypted_password = v_encrypted_pw,
            email_confirmed_at = COALESCE(email_confirmed_at, now()),
            updated_at = now()
        WHERE id = v_user_id;

        -- Also sync password to team_users table
        UPDATE public.team_users
        SET password = trim(new_password)
        WHERE lower(email) = lower(trim(target_email));
        
        RETURN json_build_object('success', true, 'action', 'updated', 'user_id', v_user_id);
    ELSE
        -- User does not exist in auth.users: Create new user
        v_user_id := gen_random_uuid();
        INSERT INTO auth.users (
            instance_id,
            id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            raw_app_meta_data,
            raw_user_meta_data,
            created_at,
            updated_at
        ) VALUES (
            '00000000-0000-0000-0000-000000000000'::uuid,
            v_user_id,
            'authenticated',
            'authenticated',
            lower(trim(target_email)),
            v_encrypted_pw,
            now(),
            '{"provider":"email","providers":["email"]}'::jsonb,
            json_build_object('email', lower(trim(target_email)), 'email_verified', true)::jsonb,
            now(),
            now()
        );

        -- Also add email identity record for auth
        BEGIN
            INSERT INTO auth.identities (
                id,
                user_id,
                identity_data,
                provider,
                provider_id,
                last_sign_in_at,
                created_at,
                updated_at
            ) VALUES (
                gen_random_uuid(),
                v_user_id,
                json_build_object('sub', v_user_id::text, 'email', lower(trim(target_email)))::jsonb,
                'email',
                v_user_id::text,
                now(),
                now(),
                now()
            ) ON CONFLICT DO NOTHING;
        EXCEPTION WHEN OTHERS THEN
            -- Ignore if identity already exists
        END;

        -- Also sync password to team_users table
        UPDATE public.team_users
        SET password = trim(new_password)
        WHERE lower(email) = lower(trim(target_email));

        RETURN json_build_object('success', true, 'action', 'created', 'user_id', v_user_id);
    END IF;
END;
$$;

-- 4. Grant execute permission to anon, authenticated, and service_role
GRANT EXECUTE ON FUNCTION public.admin_set_user_password(text, text) TO anon, authenticated, service_role;
