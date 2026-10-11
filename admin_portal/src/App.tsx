import { useState, useEffect, useCallback } from 'react';
import { useAuth } from './context/AuthContext';
import { LoginView } from './components/auth/LoginView';
import { Sidebar } from './components/common/Sidebar';
import { Navbar } from './components/common/Navbar';
import { ToastContainer, type ToastMessage } from './components/common/Toast';
import { DashboardView } from './components/dashboard/DashboardView';
import { LeadsList } from './components/leads/LeadsList';
import { LeadFormModal } from './components/leads/LeadFormModal';
import { LeadDetailModal } from './components/leads/LeadDetailModal';
import { CustomersList } from './components/customers/CustomersList';
import { CustomerFormModal } from './components/customers/CustomerFormModal';
import { CustomerDetailModal } from './components/customers/CustomerDetailModal';
import { SalesList } from './components/sales/SalesList';
import { OrderFormModal } from './components/sales/OrderFormModal';
import { OrderDetailModal } from './components/sales/OrderDetailModal';

import { leadsService } from './services/leadsService';
import { customersService } from './services/customersService';
import { salesService } from './services/salesService';

import type { Lead, Customer, SalesOrder } from './types/crm';

export function App() {
  const { isAuthenticated, isLoading: authLoading } = useAuth();

  // Navigation & Layout State
  const [currentTab, setCurrentTab] = useState<string>('dashboard');
  const [isSidebarOpenMobile, setIsSidebarOpenMobile] = useState<boolean>(false);
  const [selectedStaff, setSelectedStaff] = useState<string>('All');

  // CRM Data State
  const [leads, setLeads] = useState<Lead[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [orders, setOrders] = useState<SalesOrder[]>([]);
  const [isLoadingData, setIsLoadingData] = useState<boolean>(true);
  const [isRefreshing, setIsRefreshing] = useState<boolean>(false);

  // Toast Alerts State
  const [toasts, setToasts] = useState<ToastMessage[]>([]);

  // Modals: Leads
  const [isAddLeadOpen, setIsAddLeadOpen] = useState(false);
  const [editingLead, setEditingLead] = useState<Lead | null>(null);
  const [detailLead, setDetailLead] = useState<Lead | null>(null);

  // Modals: Customers
  const [isAddCustomerOpen, setIsAddCustomerOpen] = useState(false);
  const [editingCustomer, setEditingCustomer] = useState<Customer | null>(null);
  const [detailCustomer, setDetailCustomer] = useState<Customer | null>(null);

  // Modals: Sales Orders / Invoices
  const [isAddOrderOpen, setIsAddOrderOpen] = useState(false);
  const [defaultOrderType, setDefaultOrderType] = useState<SalesOrder['type']>('invoice');
  const [editingOrder, setEditingOrder] = useState<SalesOrder | null>(null);
  const [detailOrder, setDetailOrder] = useState<SalesOrder | null>(null);

  const addToast = (type: 'success' | 'error' | 'info', message: string) => {
    const id = Date.now().toString();
    setToasts((prev) => [...prev, { id, type, message }]);
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, 4000);
  };

  const removeToast = (id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  };

  // Fetch all CRM records
  const loadAllData = useCallback(async () => {
    try {
      setIsRefreshing(true);
      const [leadsData, customersData, ordersData] = await Promise.all([
        leadsService.fetchLeads(),
        customersService.fetchCustomers(),
        salesService.fetchOrders(),
      ]);
      setLeads(leadsData);
      setCustomers(customersData);
      setOrders(ordersData);
    } catch (err: unknown) {
      console.error('Failed to load CRM data:', err);
      addToast('error', 'Failed to synchronize latest data from Supabase.');
    } finally {
      setIsLoadingData(false);
      setIsRefreshing(false);
    }
  }, []);

  useEffect(() => {
    if (isAuthenticated) {
      loadAllData();
    }
  }, [isAuthenticated, loadAllData]);

  // Dynamic Staff List
  const staffList = Array.from(
    new Set([
      'Kishan Maru',
      'Mehul Ajagya',
      ...leads.map((l) => l.staff_name).filter(Boolean),
      ...customers.map((c) => c.staff_name).filter(Boolean),
      ...orders.map((o) => o.staff_name).filter(Boolean),
    ] as string[])
  ).filter((s) => s.trim().length > 0);

  // Filter items by staff if selected
  const displayedLeads =
    selectedStaff === 'All'
      ? leads
      : leads.filter((l) => l.staff_name === selectedStaff);

  const displayedCustomers =
    selectedStaff === 'All'
      ? customers
      : customers.filter((c) => c.staff_name === selectedStaff);

  const displayedOrders =
    selectedStaff === 'All'
      ? orders
      : orders.filter((o) => o.staff_name === selectedStaff);

  // ==========================================
  // LEADS CRUD HANDLERS
  // ==========================================
  const handleSaveLead = async (leadData: Partial<Lead>) => {
    if (editingLead) {
      const updated = await leadsService.updateLead(editingLead.id, leadData);
      setLeads((prev) => prev.map((l) => (l.id === updated.id ? updated : l)));
      if (detailLead?.id === updated.id) setDetailLead(updated);
      addToast('success', `Lead #${updated.lead_number} updated successfully.`);
    } else {
      const created = await leadsService.createLead(leadData);
      setLeads((prev) => [created, ...prev]);
      addToast('success', `Lead #${created.lead_number} added successfully.`);
    }
    setEditingLead(null);
  };

  const handleDeleteLead = async (id: string) => {
    try {
      await leadsService.deleteLead(id);
      setLeads((prev) => prev.filter((l) => l.id !== id));
      if (detailLead?.id === id) setDetailLead(null);
      addToast('info', 'Lead deleted from database.');
    } catch {
      addToast('error', 'Could not delete lead.');
    }
  };

  const handleLeadStageChange = async (leadId: string, stage: Lead['stage']) => {
    try {
      const updated = await leadsService.updateLead(leadId, { stage });
      setLeads((prev) => prev.map((l) => (l.id === updated.id ? updated : l)));
      if (detailLead?.id === updated.id) setDetailLead(updated);
      addToast('success', `Lead status updated to ${stage}.`);
    } catch {
      addToast('error', 'Failed to change stage.');
    }
  };

  // ==========================================
  // CUSTOMERS CRUD HANDLERS
  // ==========================================
  const handleSaveCustomer = async (custData: Partial<Customer>) => {
    if (editingCustomer) {
      const updated = await customersService.updateCustomer(editingCustomer.id, custData);
      setCustomers((prev) => prev.map((c) => (c.id === updated.id ? updated : c)));
      if (detailCustomer?.id === updated.id) setDetailCustomer(updated);
      addToast('success', `Customer #${updated.customer_number} updated.`);
    } else {
      const created = await customersService.createCustomer(custData);
      setCustomers((prev) => [created, ...prev]);
      addToast('success', `Customer #${created.customer_number} added.`);
    }
    setEditingCustomer(null);
  };

  const handleDeleteCustomer = async (id: string) => {
    try {
      await customersService.deleteCustomer(id);
      setCustomers((prev) => prev.filter((c) => c.id !== id));
      if (detailCustomer?.id === id) setDetailCustomer(null);
      addToast('info', 'Customer deleted from database.');
    } catch {
      addToast('error', 'Could not delete customer.');
    }
  };

  const handleCustomerToggleStatus = async (
    customerId: string,
    newStatus: 'Active' | 'Inactive'
  ) => {
    try {
      const updated = await customersService.updateCustomer(customerId, {
        status: newStatus,
      });
      setCustomers((prev) => prev.map((c) => (c.id === updated.id ? updated : c)));
      if (detailCustomer?.id === updated.id) setDetailCustomer(updated);
      addToast('success', `Customer marked as ${newStatus}.`);
    } catch {
      addToast('error', 'Failed to update customer status.');
    }
  };

  // ==========================================
  // SALES CRUD HANDLERS
  // ==========================================
  const handleSaveOrder = async (orderData: Partial<SalesOrder>) => {
    if (editingOrder) {
      const updated = await salesService.updateOrder(editingOrder.id, orderData);
      setOrders((prev) => prev.map((o) => (o.id === updated.id ? updated : o)));
      if (detailOrder?.id === updated.id) setDetailOrder(updated);
      addToast('success', `${updated.type.replace('_', ' ')} #${updated.order_number} updated.`);
    } else {
      const created = await salesService.createOrder(orderData);
      setOrders((prev) => [created, ...prev]);
      addToast('success', `${created.type.replace('_', ' ')} #${created.order_number} created.`);
    }
    setEditingOrder(null);
  };

  const handleDeleteOrder = async (id: string) => {
    try {
      await salesService.deleteOrder(id);
      setOrders((prev) => prev.filter((o) => o.id !== id));
      if (detailOrder?.id === id) setDetailOrder(null);
      addToast('info', 'Sales document deleted.');
    } catch {
      addToast('error', 'Could not delete sales document.');
    }
  };

  const handleOrderStatusChange = async (
    id: string,
    newStatus: SalesOrder['status']
  ) => {
    try {
      const updated = await salesService.updateOrder(id, { status: newStatus });
      setOrders((prev) => prev.map((o) => (o.id === updated.id ? updated : o)));
      if (detailOrder?.id === updated.id) setDetailOrder(updated);
      addToast('success', `Status updated to ${newStatus}.`);
    } catch {
      addToast('error', 'Failed to update order status.');
    }
  };

  // If checking authentication
  if (authLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center space-y-3">
          <div className="w-10 h-10 border-4 border-[#3949ab] border-t-transparent rounded-full animate-spin mx-auto" />
          <p className="text-xs font-semibold text-gray-500">Initializing MyTeams Portal...</p>
        </div>
      </div>
    );
  }

  // If not logged in, render the login view
  if (!isAuthenticated) {
    return <LoginView />;
  }

  return (
    <div className="min-h-screen bg-[#f4f6f9] flex">
      {/* Sidebar */}
      <Sidebar
        currentTab={currentTab}
        setCurrentTab={setCurrentTab}
        isOpen={isSidebarOpenMobile}
        onCloseMobile={() => setIsSidebarOpenMobile(false)}
        counts={{
          leads: leads.length,
          customers: customers.length,
          sales: orders.length,
        }}
      />

      {/* Main Content Area */}
      <div className="flex-1 lg:ml-64 flex flex-col min-h-screen">
        <Navbar
          onToggleSidebar={() => setIsSidebarOpenMobile((prev) => !prev)}
          currentTab={currentTab}
          selectedStaff={selectedStaff}
          setSelectedStaff={setSelectedStaff}
          staffList={staffList}
          onRefresh={loadAllData}
          isRefreshing={isRefreshing}
        />

        <main className="flex-1 p-4 sm:p-6 lg:p-8 max-w-7xl w-full mx-auto">
          {isLoadingData ? (
            <div className="flex items-center justify-center py-24">
              <div className="text-center space-y-3">
                <div className="w-8 h-8 border-3 border-[#3949ab] border-t-transparent rounded-full animate-spin mx-auto" />
                <p className="text-xs text-gray-500">Connecting to Supabase...</p>
              </div>
            </div>
          ) : (
            <>
              {currentTab === 'dashboard' && (
                <DashboardView
                  leads={displayedLeads}
                  customers={displayedCustomers}
                  orders={displayedOrders}
                  onNavigateTab={(tab) => setCurrentTab(tab)}
                  onOpenAddLead={() => {
                    setEditingLead(null);
                    setIsAddLeadOpen(true);
                  }}
                  onOpenAddCustomer={() => {
                    setEditingCustomer(null);
                    setIsAddCustomerOpen(true);
                  }}
                  onOpenAddOrder={() => {
                    setEditingOrder(null);
                    setDefaultOrderType('invoice');
                    setIsAddOrderOpen(true);
                  }}
                  onSelectLead={(lead) => setDetailLead(lead)}
                  onSelectOrder={(order) => setDetailOrder(order)}
                />
              )}

              {currentTab === 'leads' && (
                <LeadsList
                  leads={displayedLeads}
                  onOpenAdd={() => {
                    setEditingLead(null);
                    setIsAddLeadOpen(true);
                  }}
                  onOpenEdit={(lead) => {
                    setEditingLead(lead);
                    setIsAddLeadOpen(true);
                  }}
                  onOpenDetail={(lead) => setDetailLead(lead)}
                  onDelete={handleDeleteLead}
                  staffList={staffList}
                />
              )}

              {currentTab === 'customers' && (
                <CustomersList
                  customers={displayedCustomers}
                  onOpenAdd={() => {
                    setEditingCustomer(null);
                    setIsAddCustomerOpen(true);
                  }}
                  onOpenEdit={(customer) => {
                    setEditingCustomer(customer);
                    setIsAddCustomerOpen(true);
                  }}
                  onOpenDetail={(customer) => setDetailCustomer(customer)}
                  onDelete={handleDeleteCustomer}
                />
              )}

              {currentTab === 'sales' && (
                <SalesList
                  orders={displayedOrders}
                  onOpenAdd={(type) => {
                    setEditingOrder(null);
                    setDefaultOrderType(type);
                    setIsAddOrderOpen(true);
                  }}
                  onOpenEdit={(order) => {
                    setEditingOrder(order);
                    setIsAddOrderOpen(true);
                  }}
                  onOpenDetail={(order) => setDetailOrder(order)}
                  onDelete={handleDeleteOrder}
                />
              )}
            </>
          )}
        </main>
      </div>

      {/* Leads Modals */}
      <LeadFormModal
        isOpen={isAddLeadOpen}
        onClose={() => {
          setIsAddLeadOpen(false);
          setEditingLead(null);
        }}
        onSubmit={handleSaveLead}
        initialData={editingLead}
        staffList={staffList}
      />

      <LeadDetailModal
        lead={detailLead}
        isOpen={!!detailLead}
        onClose={() => setDetailLead(null)}
        onEdit={(lead) => {
          setEditingLead(lead);
          setIsAddLeadOpen(true);
        }}
        onDelete={handleDeleteLead}
        onStageChange={handleLeadStageChange}
      />

      {/* Customers Modals */}
      <CustomerFormModal
        isOpen={isAddCustomerOpen}
        onClose={() => {
          setIsAddCustomerOpen(false);
          setEditingCustomer(null);
        }}
        onSubmit={handleSaveCustomer}
        initialData={editingCustomer}
        staffList={staffList}
      />

      <CustomerDetailModal
        customer={detailCustomer}
        isOpen={!!detailCustomer}
        onClose={() => setDetailCustomer(null)}
        onEdit={(cust) => {
          setEditingCustomer(cust);
          setIsAddCustomerOpen(true);
        }}
        onDelete={handleDeleteCustomer}
        onToggleStatus={handleCustomerToggleStatus}
      />

      {/* Sales Orders Modals */}
      <OrderFormModal
        isOpen={isAddOrderOpen}
        onClose={() => {
          setIsAddOrderOpen(false);
          setEditingOrder(null);
        }}
        onSubmit={handleSaveOrder}
        initialData={editingOrder}
        defaultType={defaultOrderType}
        customers={customers}
        leads={leads}
        staffList={staffList}
      />

      <OrderDetailModal
        order={detailOrder}
        isOpen={!!detailOrder}
        onClose={() => setDetailOrder(null)}
        onEdit={(order) => {
          setEditingOrder(order);
          setIsAddOrderOpen(true);
        }}
        onDelete={handleDeleteOrder}
        onUpdateStatus={handleOrderStatusChange}
      />

      {/* Toast Alerts */}
      <ToastContainer toasts={toasts} onDismiss={removeToast} />
    </div>
  );
}

export default App;
