import { supabase } from '../lib/supabase';
import type { ModuleVisibilityConfig, DashboardCardsConfig } from '../types/crm';

export const companySettingsService = {
  async fetchSettings(): Promise<{
    modules?: ModuleVisibilityConfig;
    cards?: DashboardCardsConfig;
  } | null> {
    try {
      const { data, error } = await supabase
        .from('company_settings')
        .select('*')
        .limit(1)
        .maybeSingle();

      if (error) {
        console.warn('Company settings fetch warning:', error.message);
        return null;
      }

      if (!data) return null;

      return {
        modules: data.enabled_modules as ModuleVisibilityConfig | undefined,
        cards: data.dashboard_cards as DashboardCardsConfig | undefined,
      };
    } catch (e) {
      console.warn('Unable to reach company_settings table:', e);
      return null;
    }
  },

  async updateModuleVisibility(
    modules: ModuleVisibilityConfig,
    cards?: DashboardCardsConfig
  ): Promise<void> {
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
    } catch (e) {
      console.warn('Could not persist visibility to Supabase:', e);
    }
  },
};
