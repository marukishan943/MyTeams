import React, { useState } from 'react';
import {
  X,
  Eye,
  EyeOff,
  Layers,
  LayoutDashboard,
  CheckCircle2,
  RotateCcw,
  SlidersHorizontal,
  Target,
  Users,
  FileText,
  Receipt,
  BarChart3,
  Settings,
  Calendar,
  Clock,
  Phone,
  ListTodo,
  Loader2,
} from 'lucide-react';
import type { ModuleVisibilityConfig, DashboardCardsConfig } from '../../types/crm';

interface ModuleVisibilityModalProps {
  isOpen: boolean;
  onClose: () => void;
  modules: ModuleVisibilityConfig;
  onToggleModule: (key: keyof ModuleVisibilityConfig) => void;
  onSetAllModules: (visible: boolean) => void;
  cards: DashboardCardsConfig;
  onToggleCard: (key: keyof DashboardCardsConfig) => void;
  onSetAllCards: (visible: boolean) => void;
  onResetDefaults: () => void;
  isSaving?: boolean;
}

export const ModuleVisibilityModal: React.FC<ModuleVisibilityModalProps> = ({
  isOpen,
  onClose,
  modules,
  onToggleModule,
  onSetAllModules,
  cards,
  onToggleCard,
  onSetAllCards,
  onResetDefaults,
  isSaving = false,
}) => {
  const [activeTab, setActiveTab] = useState<'modules' | 'cards'>('modules');

  if (!isOpen) return null;

  const moduleItems: {
    key: keyof ModuleVisibilityConfig;
    label: string;
    description: string;
    icon: React.ElementType;
    color: string;
  }[] = [
    {
      key: 'leads',
      label: 'Leads Management',
      description: 'Pipelines, stages, lead conversion, and field inquiries',
      icon: Target,
      color: 'text-blue-600 bg-blue-50',
    },
    {
      key: 'customers',
      label: 'Customers Directory',
      description: 'Customer accounts, tiers (Gold/Silver), and lifetime ledgers',
      icon: Users,
      color: 'text-emerald-600 bg-emerald-50',
    },
    {
      key: 'sales',
      label: 'Sales & Invoices Suite',
      description: 'Proforma Invoices, Tax Invoices, Orders, Payments, and Inventory',
      icon: FileText,
      color: 'text-purple-600 bg-purple-50',
    },
    {
      key: 'expenses',
      label: 'Field Expenses Claims',
      description: 'Reimbursement claims, travel distance, receipt audit, and approvals',
      icon: Receipt,
      color: 'text-amber-600 bg-amber-50',
    },
    {
      key: 'reports',
      label: 'Reports & DSR Analytics',
      description: 'Daily Status Reports, staff scorecards, attendance, and conversion',
      icon: BarChart3,
      color: 'text-indigo-600 bg-indigo-50',
    },
    {
      key: 'settings',
      label: 'Settings & Team Config',
      description: 'Company profile, team hierarchy, GPS tracking toggles, and templates',
      icon: Settings,
      color: 'text-slate-600 bg-slate-50',
    },
  ];

  const cardItems: {
    key: keyof DashboardCardsConfig;
    label: string;
    description: string;
    icon: React.ElementType;
  }[] = [
    {
      key: 'quickStats',
      label: 'Quick Metric Counters',
      description: 'Top high-level counters: Total Leads, Customers, Orders, and Expenses',
      icon: Layers,
    },
    {
      key: 'leadsChart',
      label: 'Leads Pipeline Funnel',
      description: 'Funnel stages breakdown and mini stage progress bars',
      icon: Target,
    },
    {
      key: 'attendanceChart',
      label: 'Attendance & Punch Status',
      description: 'Field staff punch-in times and live present/absent metrics',
      icon: Clock,
    },
    {
      key: 'visitsChart',
      label: 'Field Client Visits',
      description: 'Completed field client check-ins and travel summaries',
      icon: Calendar,
    },
    {
      key: 'tasksChart',
      label: 'Tasks & Follow-ups Breakdown',
      description: 'Pending vs completed sales tasks and action items',
      icon: ListTodo,
    },
    {
      key: 'callsSummary',
      label: 'Calls & Communications',
      description: 'Field phone interactions and call duration tracking',
      icon: Phone,
    },
    {
      key: 'visitsList',
      label: 'Recent Visits Activity List',
      description: 'Live chronologic feed of field client meetings',
      icon: Calendar,
    },
    {
      key: 'tasksList',
      label: 'Assigned Field Tasks List',
      description: 'Actionable to-do list for field reps and sales executives',
      icon: ListTodo,
    },
    {
      key: 'ordersList',
      label: 'Recent Invoices & Orders List',
      description: 'Latest sales orders, payment statuses, and invoice values',
      icon: FileText,
    },
    {
      key: 'customerReminders',
      label: 'Customer Reminders & Follow-ups',
      description: 'Scheduled reminders for quotations, payments, and callbacks',
      icon: Clock,
    },
  ];

  const visibleModulesCount = Object.values(modules).filter(Boolean).length;
  const totalModulesCount = Object.keys(modules).length;

  const visibleCardsCount = Object.values(cards).filter(Boolean).length;
  const totalCardsCount = Object.keys(cards).length;

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-black/60 flex items-center justify-center p-4">
      <div className="relative bg-white rounded-2xl max-w-2xl w-full shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-200">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4.5 bg-gray-50 border-b border-gray-200">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-[#3949ab]/10 text-[#3949ab] flex items-center justify-center">
              <SlidersHorizontal className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base font-bold text-gray-900 flex items-center gap-2">
                <span>Manage Visible Modules & Cards</span>
                <span className="text-xs px-2 py-0.5 rounded-full bg-[#3949ab]/10 text-[#3949ab] font-bold">
                  Customizer
                </span>
              </h2>
              <p className="text-xs text-gray-500">
                Choose which modules and dashboard cards are displayed for your workspace.
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Tab switch */}
        <div className="px-6 pt-4 border-b border-gray-200 flex items-center justify-between flex-wrap gap-2">
          <div className="flex items-center space-x-2">
            <button
              onClick={() => setActiveTab('modules')}
              className={`pb-3 px-3 text-xs font-bold border-b-2 flex items-center space-x-2 transition-colors cursor-pointer ${
                activeTab === 'modules'
                  ? 'border-[#3949ab] text-[#3949ab]'
                  : 'border-transparent text-gray-500 hover:text-gray-900'
              }`}
            >
              <LayoutDashboard className="w-4 h-4" />
              <span>Navigation Modules ({visibleModulesCount}/{totalModulesCount})</span>
            </button>
            <button
              onClick={() => setActiveTab('cards')}
              className={`pb-3 px-3 text-xs font-bold border-b-2 flex items-center space-x-2 transition-colors cursor-pointer ${
                activeTab === 'cards'
                  ? 'border-[#3949ab] text-[#3949ab]'
                  : 'border-transparent text-gray-500 hover:text-gray-900'
              }`}
            >
              <Layers className="w-4 h-4" />
              <span>Dashboard Cards ({visibleCardsCount}/{totalCardsCount})</span>
            </button>
          </div>

          <div className="pb-3 flex items-center space-x-2 text-xs">
            <button
              onClick={() => {
                if (isSaving) return;
                if (activeTab === 'modules') onSetAllModules(true);
                else onSetAllCards(true);
              }}
              disabled={isSaving}
              className={`font-semibold ${isSaving ? 'text-gray-300 cursor-not-allowed' : 'text-[#3949ab] hover:underline cursor-pointer'}`}
            >
              Show All
            </button>
            <span className="text-gray-300">•</span>
            <button
              onClick={() => !isSaving && onResetDefaults()}
              disabled={isSaving}
              className={`flex items-center gap-1 ${isSaving ? 'text-gray-300 cursor-not-allowed' : 'text-gray-500 hover:text-gray-700 cursor-pointer'}`}
            >
              <RotateCcw className="w-3 h-3" />
              Reset Defaults
            </button>
          </div>
        </div>

        {/* Body Content */}
        <div className="p-6 max-h-[60vh] overflow-y-auto space-y-3">
          {activeTab === 'modules' ? (
            <div className="space-y-2.5">
              <div className="p-3 bg-blue-50/60 rounded-xl border border-blue-100 flex items-center justify-between text-xs text-blue-900">
                <div className="flex items-center space-x-2">
                  <LayoutDashboard className="w-4 h-4 text-blue-700 shrink-0" />
                  <span>
                    <b>Dashboard:</b> Always enabled as the default command center.
                  </span>
                </div>
                <span className="px-2 py-0.5 rounded-full bg-blue-200/80 text-blue-900 text-[10px] font-bold">
                  Always Active
                </span>
              </div>

              {moduleItems.map((mod) => {
                const Icon = mod.icon;
                const isVisible = modules[mod.key];
                return (
                  <div
                    key={mod.key}
                    onClick={() => !isSaving && onToggleModule(mod.key)}
                    className={`p-3.5 rounded-xl border transition-all flex items-center justify-between ${
                      isSaving
                        ? 'cursor-not-allowed opacity-70'
                        : 'cursor-pointer'
                    } ${
                      isVisible
                        ? 'bg-white border-gray-200 hover:border-[#3949ab]/40 shadow-2xs'
                        : 'bg-gray-50 border-gray-200/60 opacity-60'
                    }`}
                  >
                    <div className="flex items-center space-x-3 min-w-0 pr-3">
                      <div
                        className={`w-9 h-9 rounded-lg flex items-center justify-center shrink-0 ${mod.color}`}
                      >
                        <Icon className="w-4.5 h-4.5" />
                      </div>
                      <div className="min-w-0">
                        <div className="flex items-center space-x-2">
                          <span className="text-xs font-bold text-gray-900 truncate">
                            {mod.label}
                          </span>
                          <span
                            className={`text-[10px] px-1.5 py-0.2 rounded-full font-semibold ${
                              isVisible
                                ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                                : 'bg-gray-200 text-gray-600'
                            }`}
                          >
                            {isVisible ? 'Visible' : 'Hidden'}
                          </span>
                        </div>
                        <p className="text-[11px] text-gray-500 truncate mt-0.5">
                          {mod.description}
                        </p>
                      </div>
                    </div>

                    <div className="shrink-0 flex items-center">
                      {isSaving ? (
                        <Loader2 className="w-5 h-5 text-[#3949ab] animate-spin" />
                      ) : (
                        <div
                          className={`w-11 h-6 flex items-center rounded-full p-1 transition-colors duration-200 ease-in-out cursor-pointer ${
                            isVisible ? 'bg-[#3949ab]' : 'bg-gray-300'
                          }`}
                        >
                          <div
                            className={`bg-white w-4 h-4 rounded-full shadow-md transform transition-transform duration-200 ease-in-out ${
                              isVisible ? 'translate-x-5' : 'translate-x-0'
                            }`}
                          />
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="space-y-2.5">
              <p className="text-xs text-gray-500 mb-2">
                Toggle individual widget blocks on the main Dashboard. Customizable card layout.
              </p>
              {cardItems.map((card) => {
                const Icon = card.icon;
                const isVisible = cards[card.key];
                return (
                  <div
                    key={card.key}
                    onClick={() => !isSaving && onToggleCard(card.key)}
                    className={`p-3 rounded-xl border transition-all flex items-center justify-between ${
                      isSaving ? 'cursor-not-allowed opacity-70' : 'cursor-pointer'
                    } ${
                      isVisible
                        ? 'bg-white border-gray-200 hover:border-[#3949ab]/40 shadow-2xs'
                        : 'bg-gray-50 border-gray-200/60 opacity-60'
                    }`}
                  >
                    <div className="flex items-center space-x-3 min-w-0 pr-3">
                      <div className="w-8 h-8 rounded-lg bg-gray-100 text-gray-700 flex items-center justify-center shrink-0">
                        <Icon className="w-4 h-4" />
                      </div>
                      <div className="min-w-0">
                        <div className="flex items-center space-x-2">
                          <span className="text-xs font-bold text-gray-900 truncate">
                            {card.label}
                          </span>
                          {isVisible ? (
                            <Eye className="w-3.5 h-3.5 text-emerald-600" />
                          ) : (
                            <EyeOff className="w-3.5 h-3.5 text-gray-400" />
                          )}
                        </div>
                        <p className="text-[11px] text-gray-500 truncate mt-0.5">
                          {card.description}
                        </p>
                      </div>
                    </div>

                    <div className="shrink-0 flex items-center">
                      {isSaving ? (
                        <Loader2 className="w-4 h-4 text-[#3949ab] animate-spin" />
                      ) : (
                        <div
                          className={`w-10 h-5 flex items-center rounded-full p-0.5 transition-colors duration-200 ease-in-out cursor-pointer ${
                            isVisible ? 'bg-[#3949ab]' : 'bg-gray-300'
                          }`}
                        >
                          <div
                            className={`bg-white w-4 h-4 rounded-full shadow-md transform transition-transform duration-200 ease-in-out ${
                              isVisible ? 'translate-x-5' : 'translate-x-0'
                            }`}
                          />
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-4 bg-gray-50 border-t border-gray-200 flex items-center justify-between">
          <div className="text-xs text-gray-500 flex items-center gap-1.5">
            <CheckCircle2 className="w-4 h-4 text-emerald-600" />
            <span>Preferences saved automatically</span>
          </div>
          <button
            onClick={onClose}
            className="px-5 py-2 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-lg text-xs font-bold shadow-xs transition-colors cursor-pointer"
          >
            Apply & Done
          </button>
        </div>
      </div>
    </div>
  );
};
