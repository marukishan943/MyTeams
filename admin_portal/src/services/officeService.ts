import { supabase } from '../lib/supabase';

export interface CompanyOffice {
  id: string;
  name: string;
  address: string;
  city?: string;
  state?: string;
  pincode?: string;
  country?: string;
  location?: string;
  users_count: number;
  is_default: boolean;
}

export const DEFAULT_OFFICES: CompanyOffice[] = [
  {
    id: 'off-001',
    name: 'Head Office',
    address: '1103, R K World Tower , Near Shitalpark , Nr. Ayodhyachowk , 150ft Ring Road, RAJKOT, GUJARAT, India - 360006.',
    city: 'Rajkot',
    state: 'Gujarat',
    pincode: '360006',
    country: 'India',
    location: '22.3039, 70.8022',
    users_count: 5,
    is_default: true,
  },
];

export const officeService = {
  async fetchOffices(): Promise<CompanyOffice[]> {
    const local = localStorage.getItem('myteams_company_offices');
    let offices: CompanyOffice[] = local ? JSON.parse(local) : DEFAULT_OFFICES;

    // 1. Try company_offices table if it exists in Supabase
    try {
      const { data, error } = await supabase
        .from('company_offices')
        .select('*')
        .order('is_default', { ascending: false });

      if (!error && data && data.length > 0) {
        offices = data;
        localStorage.setItem('myteams_company_offices', JSON.stringify(offices));
        return offices;
      }
    } catch (_) {
      // ignore
    }

    // 2. Try SYS_CONFIG record in customers
    try {
      const { data } = await supabase
        .from('customers')
        .select('company')
        .eq('customer_number', 'SYS_CONFIG')
        .maybeSingle();

      if (data?.company) {
        const parsed = JSON.parse(data.company);
        if (parsed.offices && Array.isArray(parsed.offices) && parsed.offices.length > 0) {
          offices = parsed.offices;
          localStorage.setItem('myteams_company_offices', JSON.stringify(offices));
          return offices;
        }
      }
    } catch (_) {
      // ignore
    }

    if (!local) {
      localStorage.setItem('myteams_company_offices', JSON.stringify(DEFAULT_OFFICES));
    }
    return offices;
  },

  async saveOffices(offices: CompanyOffice[]): Promise<void> {
    localStorage.setItem('myteams_company_offices', JSON.stringify(offices));

    // Best-effort sync to Supabase customers SYS_CONFIG
    try {
      const { data: existingConfig } = await supabase
        .from('customers')
        .select('id, company')
        .eq('customer_number', 'SYS_CONFIG')
        .maybeSingle();

      let currentPayload: Record<string, unknown> = {};
      if (existingConfig?.company) {
        try {
          currentPayload = JSON.parse(existingConfig.company);
        } catch (_) {}
      }

      const updatedJson = JSON.stringify({
        ...currentPayload,
        offices,
        updated_at: new Date().toISOString(),
      });

      if (existingConfig?.id) {
        await supabase
          .from('customers')
          .update({
            company: updatedJson,
            updated_at: new Date().toISOString(),
          })
          .eq('id', existingConfig.id);
      }
    } catch (e) {
      console.warn('Could not sync offices to cloud:', e);
    }
  },
};
