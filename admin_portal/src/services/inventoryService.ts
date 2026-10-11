import { supabase } from '../lib/supabase';
import type { InventoryItem } from '../types/crm';

const INITIAL_INVENTORY: InventoryItem[] = [
  {
    id: 'inv-1',
    name: 'ZINC SPRAY 500ML',
    sku: 'ZS-500',
    category: 'ZINC SPRAY',
    unit: 'Bottles',
    quantity: 2240,
    min_stock: 100,
    rate: 280,
    status: 'In Stock',
    updated_at: '2026-10-10T13:24:00Z',
  },
  {
    id: 'inv-2',
    name: 'ZINC SPRAY 400ML',
    sku: 'ZS-400',
    category: 'ZINC SPRAY',
    unit: 'Bottles',
    quantity: 2004,
    min_stock: 100,
    rate: 240,
    status: 'In Stock',
    updated_at: '2026-10-10T13:24:00Z',
  },
  {
    id: 'inv-3',
    name: 'ZINC SPRAY 200ML',
    sku: 'ZS-200',
    category: 'ZINC SPRAY',
    unit: 'Bottles',
    quantity: 2700,
    min_stock: 150,
    rate: 160,
    status: 'In Stock',
    updated_at: '2026-10-10T13:24:00Z',
  },
  {
    id: 'inv-4',
    name: 'TRANSPORT SERVICE',
    sku: 'TR-01',
    category: 'TRANSPORT',
    unit: 'Trips',
    quantity: -11,
    min_stock: 0,
    rate: 500,
    status: 'Low Stock',
    updated_at: '2026-10-10T13:24:00Z',
  },
];

export const inventoryService = {
  async fetchInventory(): Promise<InventoryItem[]> {
    try {
      const { data, error } = await supabase
        .from('inventory')
        .select('*')
        .order('name', { ascending: true });

      if (error || !data || data.length === 0) {
        const local = localStorage.getItem('myteams_inventory');
        return local ? JSON.parse(local) : INITIAL_INVENTORY;
      }
      return data;
    } catch {
      const local = localStorage.getItem('myteams_inventory');
      return local ? JSON.parse(local) : INITIAL_INVENTORY;
    }
  },

  async addProduct(item: Partial<InventoryItem>): Promise<InventoryItem> {
    const qty = item.quantity || 0;
    const min = item.min_stock || 10;
    const status: InventoryItem['status'] =
      qty <= 0 ? 'Out of Stock' : qty <= min ? 'Low Stock' : 'In Stock';

    const newItem: InventoryItem = {
      id: `inv-${Date.now()}`,
      name: item.name || '',
      sku: item.sku || `SKU-${Math.floor(100 + Math.random() * 900)}`,
      category: item.category || 'General',
      unit: item.unit || 'Pcs',
      quantity: qty,
      min_stock: min,
      rate: item.rate || 0,
      status,
      updated_at: new Date().toISOString(),
    };

    try {
      await supabase.from('inventory').insert([newItem]);
    } catch (e) {
      console.warn(e);
    }

    const current = await this.fetchInventory();
    const updated = [newItem, ...current];
    localStorage.setItem('myteams_inventory', JSON.stringify(updated));
    return newItem;
  },

  async updateStock(id: string, deltaQty: number): Promise<void> {
    const current = await this.fetchInventory();
    const updated = current.map((i) => {
      if (i.id === id) {
        const newQty = i.quantity + deltaQty;
        const newStatus: InventoryItem['status'] =
          newQty <= 0 ? 'Out of Stock' : newQty <= i.min_stock ? 'Low Stock' : 'In Stock';
        return {
          ...i,
          quantity: newQty,
          status: newStatus,
          updated_at: new Date().toISOString(),
        };
      }
      return i;
    });

    try {
      const changed = updated.find((i) => i.id === id);
      if (changed) {
        await supabase
          .from('inventory')
          .update({
            quantity: changed.quantity,
            status: changed.status,
            updated_at: changed.updated_at,
          })
          .eq('id', id);
      }
    } catch (e) {
      console.warn(e);
    }

    localStorage.setItem('myteams_inventory', JSON.stringify(updated));
  },

  async deleteProduct(id: string): Promise<void> {
    try {
      await supabase.from('inventory').delete().eq('id', id);
    } catch (e) {
      console.warn(e);
    }
    const current = await this.fetchInventory();
    const updated = current.filter((i) => i.id !== id);
    localStorage.setItem('myteams_inventory', JSON.stringify(updated));
  },
};
