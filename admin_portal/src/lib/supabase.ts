import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://tfmxyzrjvezfxurkkyhf.supabase.co';
const SUPABASE_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmbXh5enJqdmV6Znh1cmtreWhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4NjExMTUsImV4cCI6MjA5OTQzNzExNX0.gaiWZwvoNvacRUH1em_lK9XLijoy9ImHNeM87P03YjU';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
