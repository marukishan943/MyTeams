import { supabase } from '../lib/supabase';
import type { MessageTemplate } from '../types/crm';

export const DEFAULT_TEMPLATES: MessageTemplate[] = [
  {
    id: 'tmpl-lead-followup',
    name: 'First Follow-Up Greeting',
    module: 'Leads',
    content: 'Hello {{name}}, following up on our recent discussion regarding your requirements with {{brand_name}}. Please let us know how we can assist you!',
    is_default: true,
    updated_at: '2026-10-25T00:00:00Z',
  },
  {
    id: 'tmpl-lead-intro',
    name: 'Company Introduction & Catalog',
    module: 'Leads',
    content: 'Dear {{name}}, greetings from {{brand_name}}! We received your inquiry and would be glad to share our product catalog and pricing with you.',
    is_default: false,
    updated_at: '2026-10-25T00:00:00Z',
  },
  {
    id: 'tmpl-customer-welcome',
    name: 'Customer Welcome Onboarding',
    module: 'Customers',
    content: 'Dear {{name}}, welcome to {{brand_name}}! Thank you for partnering with us. Your account is active.',
    is_default: true,
    updated_at: '2026-10-25T00:00:00Z',
  },
  {
    id: 'tmpl-pfi-share',
    name: 'Proforma Invoice Share',
    module: 'Proforma Invoices',
    content: 'Dear {{name}}, please find your Proforma Invoice {{id}} from {{brand_name}}. Total Amount: {{total}}. Kindly review.',
    is_default: true,
    updated_at: '2026-10-25T00:00:00Z',
  },
  {
    id: 'tmpl-invoice-payment',
    name: 'Invoice Payment Receipt',
    module: 'Invoices',
    content: 'Dear {{name}}, we have received your payment of {{amount}} against Invoice {{id}}. Thank you for your business with {{brand_name}}!',
    is_default: true,
    updated_at: '2026-10-25T00:00:00Z',
  },
];

export const templateService = {
  async fetchTemplates(): Promise<MessageTemplate[]> {
    // 1. Try local storage first for instant load
    const local = localStorage.getItem('myteams_message_templates');
    let templates: MessageTemplate[] = local ? JSON.parse(local) : DEFAULT_TEMPLATES;

    // 2. Best-effort sync with Supabase customers SYS_CONFIG record
    try {
      const { data } = await supabase
        .from('customers')
        .select('company')
        .eq('customer_number', 'SYS_CONFIG')
        .maybeSingle();

      if (data?.company) {
        const parsed = JSON.parse(data.company);
        if (parsed.templates && Array.isArray(parsed.templates) && parsed.templates.length > 0) {
          templates = parsed.templates;
          localStorage.setItem('myteams_message_templates', JSON.stringify(templates));
          return templates;
        }
      }
    } catch (_) {
      // ignore network errors and use local
    }

    if (!local) {
      localStorage.setItem('myteams_message_templates', JSON.stringify(DEFAULT_TEMPLATES));
    }
    return templates;
  },

  async saveTemplates(templates: MessageTemplate[]): Promise<void> {
    localStorage.setItem('myteams_message_templates', JSON.stringify(templates));

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
        templates,
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
      console.warn('Could not sync templates to cloud:', e);
    }
  },

  getDefaultTemplate(module: MessageTemplate['module'] = 'Leads'): MessageTemplate {
    try {
      const local = localStorage.getItem('myteams_message_templates');
      const list: MessageTemplate[] = local ? JSON.parse(local) : DEFAULT_TEMPLATES;
      const def = list.find((t) => t.module === module && t.is_default);
      if (def) return def;
      const anyMod = list.find((t) => t.module === module);
      if (anyMod) return anyMod;
      return DEFAULT_TEMPLATES[0];
    } catch {
      return DEFAULT_TEMPLATES[0];
    }
  },

  formatMessage(content: string, variables: Record<string, string | number | undefined | null>): string {
    let result = content;
    for (const [key, val] of Object.entries(variables)) {
      const pattern = new RegExp(`{{\\s*${key}\\s*}}`, 'gi');
      result = result.replace(pattern, val != null ? String(val) : '');
    }
    return result;
  },

  getWhatsAppUrl(phone: string, text: string): string {
    let cleanPhone = phone.replace(/[^0-9]/g, '');
    if (cleanPhone.length === 10) {
      cleanPhone = `91${cleanPhone}`;
    }
    const encoded = encodeURIComponent(text);
    return `https://wa.me/${cleanPhone}?text=${encoded}`;
  },
};
