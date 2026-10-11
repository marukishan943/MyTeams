import { supabase } from '../lib/supabase';
import type { ModuleVisibilityConfig, DashboardCardsConfig } from '../types/crm';

export const companySettingsService = {
  async fetchSettings(): Promise<{
    modules?: ModuleVisibilityConfig;
    cards?: DashboardCardsConfig;
  } | null> {
    // 1. Try company_settings table if it exists
    try {
      const { data, error } = await supabase
        .from('company_settings')
        .select('*')
        .limit(1)
        .maybeSingle();

      if (!error && data) {
        return {
          modules: data.enabled_modules as ModuleVisibilityConfig | undefined,
          cards: data.dashboard_cards as DashboardCardsConfig | undefined,
        };
      }
    } catch (_) {
      // Ignore and proceed to fallback
    }

    // 2. Fallback to SYS_CONFIG record in customers table (guaranteed cloud sync)
    try {
      const { data, error } = await supabase
        .from('customers')
        .select('company')
        .eq('customer_number', 'SYS_CONFIG')
        .maybeSingle();

      if (!error && data?.company) {
        const parsed = JSON.parse(data.company);
        return {
          modules: (parsed.modules || parsed) as ModuleVisibilityConfig | undefined,
          cards: parsed.cards as DashboardCardsConfig | undefined,
        };
      }
    } catch (e) {
      console.warn('Unable to reach SYS_CONFIG record in customers:', e);
    }

    return null;
  },

  async updateModuleVisibility(
    modules: ModuleVisibilityConfig,
    cards?: DashboardCardsConfig
  ): Promise<void> {
    // 1. Try company_settings table (best-effort)
    try {
      const { data: existing } = await supabase
        .from('company_settings')
        .select('id')
        .limit(1)
        .maybeSingle();

      const payload: Record<string, unknown> = {
        enabled_modules: modules,
        updated_at: new Date().toISOString(),
      };
      if (cards) {
        payload.dashboard_cards = cards;
      }

      if (existing?.id) {
        await supabase
          .from('company_settings')
          .update(payload)
          .eq('id', existing.id);
      } else {
        await supabase.from('company_settings').insert([
          {
            company_name: 'IV SQUARE STRUCTURE INDIA PVT LTD',
            ...payload,
          },
        ]);
      }
    } catch (_) {
      // If company_settings does not exist, silent continue to customer table fallback
    }

    // 2. Persist in SYS_CONFIG record in customers table for seamless sync across Web and Flutter Mobile
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

      const updatedCompanyJson = JSON.stringify({
        ...currentPayload,
        modules,
        ...(cards ? { cards } : {}),
      });

      if (existingConfig?.id) {
        await supabase
          .from('customers')
          .update({
            company: updatedCompanyJson,
            updated_at: new Date().toISOString(),
          })
          .eq('id', existingConfig.id);
      } else {
        await supabase.from('customers').insert([
          {
            customer_number: 'SYS_CONFIG',
            name: '__SYSTEM_SETTINGS__',
            company: updatedCompanyJson,
            phone: '0000000000',
            category: 'Other',
            status: 'Active',
            country: 'India',
            created_by: 'ISUN BEVERAGES',
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
          },
        ]);
      }
    } catch (e) {
      console.warn('Could not persist visibility config to customers SYS_CONFIG:', e);
    }
  },
};
