import { supabase } from '../lib/supabase';
import type { Lead, LeadNote } from '../types/crm';

export const leadsService = {
  async fetchLeads(): Promise<Lead[]> {
    const { data, error } = await supabase
      .from('leads')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching leads:', error);
      throw error;
    }
    return data || [];
  },

  async createLead(lead: Partial<Lead>): Promise<Lead> {
    // Generate next lead number if not provided
    const leadNumber = lead.lead_number || Math.floor(100 + Math.random() * 900).toString();

    const newLead = {
      ...lead,
      lead_number: leadNumber,
      source: lead.source || 'call',
      stage: lead.stage || 'newLead',
      is_closed: lead.stage === 'converted' || lead.stage === 'disqualified',
      date: lead.date || new Date().toISOString(),
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    const { data, error } = await supabase
      .from('leads')
      .insert([newLead])
      .select()
      .single();

    if (error) {
      console.error('Error creating lead:', error);
      throw error;
    }
    return data;
  },

  async updateLead(id: string, updates: Partial<Lead>): Promise<Lead> {
    const updatePayload: Record<string, unknown> = {
      ...updates,
      updated_at: new Date().toISOString(),
    };

    if (updates.stage) {
      updatePayload.is_closed =
        updates.stage === 'converted' || updates.stage === 'disqualified';
    }

    const { data, error } = await supabase
      .from('leads')
      .update(updatePayload)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('Error updating lead:', error);
      throw error;
    }
    return data;
  },

  async deleteLead(id: string): Promise<void> {
    const { error } = await supabase.from('leads').delete().eq('id', id);
    if (error) {
      console.error('Error deleting lead:', error);
      throw error;
    }
  },

  async fetchLeadNotes(leadId: string): Promise<LeadNote[]> {
    const { data, error } = await supabase
      .from('lead_notes')
      .select('*')
      .eq('lead_id', leadId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching lead notes:', error);
      return [];
    }
    return data || [];
  },

  async addLeadNote(leadId: string, content: string): Promise<LeadNote> {
    const { data, error } = await supabase
      .from('lead_notes')
      .insert([{ lead_id: leadId, content, created_at: new Date().toISOString() }])
      .select()
      .single();

    if (error) {
      console.error('Error adding lead note:', error);
      throw error;
    }
    return data;
  },
};
