import { useState, useEffect, useCallback } from 'react';
import { useAuth } from './context/AuthContext';
import { LoginView } from './components/auth/LoginView';
import { Sidebar } from './components/common/Sidebar';
import { Navbar } from './components/common/Navbar';
import { ToastContainer, type ToastMessage } from './components/common/Toast';
import { DashboardView } from './components/dashboard/DashboardView';

// Leads Components
import { LeadsList } from './components/leads/LeadsList';
import { LeadFormModal } from './components/leads/LeadFormModal';
import { LeadDetailModal } from './components/leads/LeadDetailModal';

// Customers Components
import { CustomersList } from './components/customers/CustomersList';
import { CustomerFormModal } from './components/customers/CustomerFormModal';
import { CustomerDetailModal } from './components/customers/CustomerDetailModal';

// Sales Components
import { SalesList } from './components/sales/SalesList';
import { OrderFormModal } from './components/sales/OrderFormModal';
import { OrderDetailModal } from './components/sales/OrderDetailModal';
import { PaymentModal } from './components/sales/PaymentModal';
import { InventoryModal } from './components/sales/InventoryModal';

// Expenses Components
import { ExpensesList } from './components/expenses/ExpensesList';
import { ExpenseFormModal } from './components/expenses/ExpenseFormModal';
import { ExpenseApproveModal } from './components/expenses/ExpenseApproveModal';

// Reports & Settings Components
import { ReportsView } from './components/reports/ReportsView';
import { SettingsView } from './components/settings/SettingsView';
import { ModuleVisibilityModal } from './components/common/ModuleVisibilityModal';

// Services
import { leadsService } from './services/leadsService';
import { customersService } from './services/customersService';
import { salesService } from './services/salesService';
import { expensesService } from './services/expensesService';
import { inventoryService } from './services/inventoryService';
import { paymentsService } from './services/paymentsService';
import { usersService } from './services/usersService';
import { companySettingsService } from './services/companySettingsService';

import type {
  Lead,
  Customer,
  SalesOrder,
  Expense,
  InventoryItem,
  PaymentRecord,
  TeamUser,
  ModuleVisibilityConfig,
  DashboardCardsConfig,
} from './types/crm';

const DEFAULT_MODULES: ModuleVisibilityConfig = {
  leads: true,
  customers: true,
  sales: true,
  expenses: true,
  reports: true,
  settings: true,
};

const DEFAULT_DASHBOARD_CARDS: DashboardCardsConfig = {
  quickStats: true,
  leadsChart: true,
  attendanceChart: true,
  visitsChart: true,
  tasksChart: true,
  callsSummary: true,
  visitsList: true,
  tasksList: true,
  ordersList: true,
  customerReminders: true,
};

export function App() {
  const { isAuthenticated, isLoading: authLoading } = useAuth();

  // Navigation & Layout State
  const [currentTab, setCurrentTab] = useState<string>('dashboard');
  const [isSidebarOpenMobile, setIsSidebarOpenMobile] = useState<boolean>(false);
  const [selectedStaff, setSelectedStaff] = useState<string>('All');

  // Module & Dashboard Card Visibility Customizer
  const [moduleVisibility, setModuleVisibility] = useState<ModuleVisibilityConfig>(() => {
    try {
      const saved = localStorage.getItem('myteams_module_visibility');
      if (saved) return JSON.parse(saved);
    } catch (e) {}
    return DEFAULT_MODULES;
  });

  const [dashboardCards, setDashboardCards] = useState<DashboardCardsConfig>(() => {
    try {
      const saved = localStorage.getItem('myteams_dashboard_cards');
      if (saved) return JSON.parse(saved);
    } catch (e) {}
    return DEFAULT_DASHBOARD_CARDS;
  });

  const [isModuleModalOpen, setIsModuleModalOpen] = useState(false);
  const [isSavingVisibility, setIsSavingVisibility] = useState(false);

  // Sync to localStorage and Supabase Cloud — with loading + toast feedback
  const handleToggleModule = async (key: keyof ModuleVisibilityConfig) => {
    if (isSavingVisibility) return;
    const next: ModuleVisibilityConfig = { ...moduleVisibility, [key]: !moduleVisibility[key] };
    setModuleVisibility(next);
    localStorage.setItem('myteams_module_visibility', JSON.stringify(next));
    setIsSavingVisibility(true);
    try {
      await companySettingsService.updateModuleVisibility(next, dashboardCards);
      addToast('success', `Module "${key}" ${next[key] ? 'enabled' : 'hidden'} successfully.`);
    } catch {
      addToast('error', 'Failed to save module visibility. Please try again.');
    } finally {
      setIsSavingVisibility(false);
    }
  };

  const handleSetAllModules = async (visible: boolean) => {
    if (isSavingVisibility) return;
    const next: ModuleVisibilityConfig = {
      leads: visible,
      customers: visible,
      sales: visible,
      expenses: visible,
      reports: visible,
      settings: visible,
    };
    setModuleVisibility(next);
    localStorage.setItem('myteams_module_visibility', JSON.stringify(next));
    setIsSavingVisibility(true);
    try {
      await companySettingsService.updateModuleVisibility(next, dashboardCards);
      addToast('success', visible ? 'All modules are now visible.' : 'All modules hidden.');
    } catch {
      addToast('error', 'Failed to save module visibility. Please try again.');
    } finally {
      setIsSavingVisibility(false);
    }
  };

  const handleToggleCard = async (key: keyof DashboardCardsConfig) => {
    if (isSavingVisibility) return;
    const next: DashboardCardsConfig = { ...dashboardCards, [key]: !dashboardCards[key] };
    setDashboardCards(next);
    localStorage.setItem('myteams_dashboard_cards', JSON.stringify(next));
    setIsSavingVisibility(true);
    try {
      await companySettingsService.updateModuleVisibility(moduleVisibility, next);
      addToast('success', `Card "${key}" ${next[key] ? 'shown' : 'hidden'} successfully.`);
    } catch {
      addToast('error', 'Failed to save card visibility. Please try again.');
    } finally {
      setIsSavingVisibility(false);
    }
  };

  const handleSetAllCards = async (visible: boolean) => {
    if (isSavingVisibility) return;
    const next: DashboardCardsConfig = {
      quickStats: visible,
      leadsChart: visible,
      attendanceChart: visible,
      visitsChart: visible,
      tasksChart: visible,
      callsSummary: visible,
      visitsList: visible,
      tasksList: visible,
      ordersList: visible,
      customerReminders: visible,
    };
    setDashboardCards(next);
    localStorage.setItem('myteams_dashboard_cards', JSON.stringify(next));
    setIsSavingVisibility(true);
    try {
      await companySettingsService.updateModuleVisibility(moduleVisibility, next);
      addToast('success', visible ? 'All dashboard cards are now visible.' : 'All dashboard cards hidden.');
    } catch {
      addToast('error', 'Failed to save card visibility. Please try again.');
    } finally {
      setIsSavingVisibility(false);
    }
  };

  const handleResetDefaults = async () => {
    if (isSavingVisibility) return;
    setModuleVisibility(DEFAULT_MODULES);
    setDashboardCards(DEFAULT_DASHBOARD_CARDS);
    localStorage.removeItem('myteams_module_visibility');
    localStorage.removeItem('myteams_dashboard_cards');
    setIsSavingVisibility(true);
    try {
      await companySettingsService.updateModuleVisibility(DEFAULT_MODULES, DEFAULT_DASHBOARD_CARDS);
      addToast('info', 'Visibility preferences reset to default.');
    } catch {
      addToast('error', 'Failed to reset visibility defaults.');
    } finally {
      setIsSavingVisibility(false);
    }
  };

  // Redirect if current tab becomes hidden
  useEffect(() => {
    if (
      currentTab !== 'dashboard' &&
      moduleVisibility[currentTab as keyof ModuleVisibilityConfig] === false
    ) {
      setCurrentTab('dashboard');
    }
  }, [currentTab, moduleVisibility]);

  // CRM Data State
  const [leads, setLeads] = useState<Lead[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [orders, setOrders] = useState<SalesOrder[]>([]);
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [inventory, setInventory] = useState<InventoryItem[]>([]);
  const [payments, setPayments] = useState<PaymentRecord[]>([]);
  const [users, setUsers] = useState<TeamUser[]>([]);

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
  const [isRecordPaymentOpen, setIsRecordPaymentOpen] = useState(false);
  const [isAddInventoryOpen, setIsAddInventoryOpen] = useState(false);

  // Modals: Expenses
  const [isAddExpenseOpen, setIsAddExpenseOpen] = useState(false);
  const [reviewExpense, setReviewExpense] = useState<Expense | null>(null);

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
      const [
        leadsData,
        customersData,
        ordersData,
        expensesData,
        inventoryData,
        paymentsData,
        usersData,
        settingsData,
      ] = await Promise.all([
        leadsService.fetchLeads(),
        customersService.fetchCustomers(),
        salesService.fetchOrders(),
        expensesService.fetchExpenses(),
        inventoryService.fetchInventory(),
        paymentsService.fetchPayments(),
        usersService.fetchUsers(),
        companySettingsService.fetchSettings(),
      ]);

      setLeads(leadsData);
      setCustomers(customersData);
      setOrders(ordersData);
      setExpenses(expensesData);
      setInventory(inventoryData);
      setPayments(paymentsData);
      setUsers(usersData);

      if (settingsData?.modules) {
        setModuleVisibility(settingsData.modules);
        localStorage.setItem('myteams_module_visibility', JSON.stringify(settingsData.modules));
      }
      if (settingsData?.cards) {
        setDashboardCards(settingsData.cards);
        localStorage.setItem('myteams_dashboard_cards', JSON.stringify(settingsData.cards));
      }
    } catch (err: unknown) {
      console.error('Failed to load CRM data:', err);
      addToast('error', 'Failed to synchronize latest data.');
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
      'Sachin Chauhan',
      'Isha Vora',
      ...users.map((u) => `${u.first_name} ${u.last_name}`).filter(Boolean),
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

  const displayedExpenses =
    selectedStaff === 'All'
      ? expenses
      : expenses.filter((e) => e.staff_name === selectedStaff);

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

  const handleConvertToCustomer = async (lead: Lead) => {
    try {
      const newCustomer = await customersService.createCustomer({
        name: lead.name,
        company: lead.company || lead.name,
        phone: lead.phone,
        email: lead.email || '',
        website: lead.website || '',
        gst: lead.gst || '',
        territory: lead.territory || 'RAJKOT',
        city: lead.city || 'RAJKOT',
        state: lead.state || '',
        pincode: lead.pincode || '',
        address: lead.address || '',
        staff_name: lead.staff_name || '',
        category: 'Retailer',
        status: 'Active',
      });
      setCustomers((prev) => [newCustomer, ...prev]);

      const updatedLead = await leadsService.updateLead(lead.id, { stage: 'converted' });
      setLeads((prev) => prev.map((l) => (l.id === updatedLead.id ? updatedLead : l)));
      if (detailLead?.id === updatedLead.id) setDetailLead(updatedLead);

      addToast('success', `Lead #${lead.lead_number} converted to customer #${newCustomer.customer_number}.`);
    } catch (err) {
      console.error('Error converting lead to customer:', err);
      addToast('error', 'Failed to convert lead to customer.');
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

  // Payments Handlers
  const handleRecordPayment = async (data: Partial<PaymentRecord>) => {
    const created = await paymentsService.recordPayment(data);
    setPayments((prev) => [created, ...prev]);
    addToast('success', `Payment receipt ${created.payment_number} recorded.`);
  };

  const handleDeletePayment = async (id: string) => {
    await paymentsService.deletePayment(id);
    setPayments((prev) => prev.filter((p) => p.id !== id));
    addToast('info', 'Payment record deleted.');
  };

  // Inventory Handlers
  const handleAddProduct = async (data: Partial<InventoryItem>) => {
    const created = await inventoryService.addProduct(data);
    setInventory((prev) => [created, ...prev]);
    addToast('success', `Product "${created.name}" added to catalog.`);
  };

  const handleAdjustStock = async (id: string, delta: number) => {
    await inventoryService.updateStock(id, delta);
    setInventory((prev) =>
      prev.map((i) => (i.id === id ? { ...i, quantity: i.quantity + delta } : i))
    );
    addToast('info', `Stock updated by ${delta > 0 ? `+${delta}` : delta} units.`);
  };

  const handleDeleteInventory = async (id: string) => {
    await inventoryService.deleteProduct(id);
    setInventory((prev) => prev.filter((i) => i.id !== id));
    addToast('info', 'Product removed from catalog.');
  };

  // ==========================================
  // EXPENSES CRUD HANDLERS
  // ==========================================
  const handleSaveExpense = async (data: Partial<Expense>) => {
    const created = await expensesService.createExpense(data);
    setExpenses((prev) => [created, ...prev]);
    addToast('success', `Expense claim #${created.expense_number} submitted.`);
  };

  const handleDecideExpense = async (
    id: string,
    status: 'Approved' | 'Rejected',
    approvedAmount: number,
    comments?: string
  ) => {
    await expensesService.updateExpenseStatus(id, status, approvedAmount, comments);
    setExpenses((prev) =>
      prev.map((e) =>
        e.id === id
          ? {
              ...e,
              status,
              approved_amount: approvedAmount,
              decision_comments: comments,
            }
          : e
      )
    );
    addToast(
      status === 'Approved' ? 'success' : 'info',
      `Expense claim #${id} marked as ${status}.`
    );
  };

  const handleDeleteExpense = async (id: string) => {
    await expensesService.deleteExpense(id);
    setExpenses((prev) => prev.filter((e) => e.id !== id));
    addToast('info', 'Expense claim deleted.');
  };

  // ==========================================
  // USERS & SETTINGS HANDLERS
  // ==========================================
  const handleAddUser = async (data: Partial<TeamUser>) => {
    const created = await usersService.createUser(data);
    setUsers((prev) => [...prev, created]);
    addToast('success', `Team member ${created.first_name} added.`);
  };

  const handleUpdateUser = async (id: string, data: Partial<TeamUser>) => {
    const updated = await usersService.updateUser(id, data);
    setUsers((prev) => prev.map((u) => (u.id === id ? updated : u)));
    addToast('success', `Team member ${updated.first_name} ${updated.last_name} updated successfully.`);
  };

  const handleDeleteUser = async (id: string) => {
    const target = users.find((u) => u.id === id);
    await usersService.deleteUser(id);
    setUsers((prev) => prev.filter((u) => u.id !== id));
    addToast('info', `Team member ${target ? target.first_name : ''} removed.`);
  };

  const handleToggleTracking = async (id: string) => {
    await usersService.toggleTracking(id);
    setUsers((prev) =>
      prev.map((u) => (u.id === id ? { ...u, location_tracking: !u.location_tracking } : u))
    );
    addToast('info', 'GPS Tracking status toggled.');
  };

  const handleToggleActive = async (id: string) => {
    await usersService.toggleActive(id);
    setUsers((prev) =>
      prev.map((u) => (u.id === id ? { ...u, is_active: !u.is_active } : u))
    );
    addToast('info', 'User active status updated.');
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
      {/* Sidebar with all 7 UpTeams main sections */}
      <Sidebar
        currentTab={currentTab}
        setCurrentTab={setCurrentTab}
        isOpen={isSidebarOpenMobile}
        onCloseMobile={() => setIsSidebarOpenMobile(false)}
        counts={{
          leads: leads.length,
          customers: customers.length,
          sales: orders.length,
          expenses: expenses.length,
        }}
        moduleVisibility={moduleVisibility}
        onOpenModuleVisibility={() => setIsModuleModalOpen(true)}
      />

      {/* Main Content Area */}
      <div className="flex-1 lg:ml-64 flex flex-col min-h-screen">
        {currentTab !== 'leads' && currentTab !== 'customers' && currentTab !== 'sales' && (
          <Navbar
            onToggleSidebar={() => setIsSidebarOpenMobile((prev) => !prev)}
            currentTab={currentTab}
            selectedStaff={selectedStaff}
            setSelectedStaff={setSelectedStaff}
            staffList={staffList}
            onRefresh={loadAllData}
            isRefreshing={isRefreshing}
            onOpenModuleVisibility={() => setIsModuleModalOpen(true)}
            visibleModulesCount={Object.values(moduleVisibility).filter(Boolean).length}
            totalModulesCount={Object.keys(moduleVisibility).length}
          />
        )}

        <main className={currentTab === 'leads' || currentTab === 'customers' || currentTab === 'sales' ? 'flex-1 w-full p-0' : 'flex-1 p-4 sm:p-6 lg:p-8 max-w-7xl w-full mx-auto'}>
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
                  moduleVisibility={moduleVisibility}
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
                  cardsConfig={dashboardCards}
                  onToggleCard={handleToggleCard}
                  onResetCards={handleResetDefaults}
                  onSetAllCards={handleSetAllCards}
                  isSaving={isSavingVisibility}
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
                  onConvertToCustomer={handleConvertToCustomer}
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
                  onToggleStatus={handleCustomerToggleStatus}
                  staffList={staffList}
                />
              )}

              {currentTab === 'sales' && (
                <SalesList
                  orders={displayedOrders}
                  payments={payments}
                  inventory={inventory}
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
                  onDeleteOrder={handleDeleteOrder}
                  onOpenRecordPayment={() => setIsRecordPaymentOpen(true)}
                  onDeletePayment={handleDeletePayment}
                  onOpenAddInventory={() => setIsAddInventoryOpen(true)}
                  onAdjustStock={handleAdjustStock}
                  onDeleteInventory={handleDeleteInventory}
                  onUpdateStatus={handleOrderStatusChange}
                  staffList={staffList}
                />
              )}

              {currentTab === 'expenses' && (
                <ExpensesList
                  expenses={displayedExpenses}
                  onOpenAdd={() => setIsAddExpenseOpen(true)}
                  onReview={(exp) => setReviewExpense(exp)}
                  onDelete={handleDeleteExpense}
                />
              )}

              {currentTab === 'reports' && (
                <ReportsView
                  leads={displayedLeads}
                  customers={displayedCustomers}
                  orders={displayedOrders}
                  expenses={displayedExpenses}
                  staffList={staffList}
                />
              )}

              {currentTab === 'settings' && (
                <SettingsView
                  users={users}
                  onAddUser={handleAddUser}
                  onUpdateUser={handleUpdateUser}
                  onDeleteUser={handleDeleteUser}
                  onToggleTracking={handleToggleTracking}
                  onToggleActive={handleToggleActive}
                  moduleVisibility={moduleVisibility}
                  onToggleModule={handleToggleModule}
                  dashboardCards={dashboardCards}
                  onToggleCard={handleToggleCard}
                  onResetDefaults={handleResetDefaults}
                  isSaving={isSavingVisibility}
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

      {/* Record Payment & Inventory Modals */}
      <PaymentModal
        isOpen={isRecordPaymentOpen}
        onClose={() => setIsRecordPaymentOpen(false)}
        onSubmit={handleRecordPayment}
        staffList={staffList}
      />

      <InventoryModal
        isOpen={isAddInventoryOpen}
        onClose={() => setIsAddInventoryOpen(false)}
        onSubmit={handleAddProduct}
      />

      {/* Expenses Modals */}
      <ExpenseFormModal
        isOpen={isAddExpenseOpen}
        onClose={() => setIsAddExpenseOpen(false)}
        onSubmit={handleSaveExpense}
        staffList={staffList}
      />

      <ExpenseApproveModal
        expense={reviewExpense}
        isOpen={!!reviewExpense}
        onClose={() => setReviewExpense(null)}
        onDecide={handleDecideExpense}
      />

      {/* Module & Dashboard Cards Visibility Customizer Modal */}
      <ModuleVisibilityModal
        isOpen={isModuleModalOpen}
        onClose={() => setIsModuleModalOpen(false)}
        modules={moduleVisibility}
        onToggleModule={handleToggleModule}
        onSetAllModules={handleSetAllModules}
        cards={dashboardCards}
        onToggleCard={handleToggleCard}
        onSetAllCards={handleSetAllCards}
        onResetDefaults={handleResetDefaults}
        isSaving={isSavingVisibility}
      />

      {/* Toast Alerts */}
      <ToastContainer toasts={toasts} onDismiss={removeToast} />
    </div>
  );
}

export default App;
