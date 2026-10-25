import React, { useState, useMemo, useRef, useEffect } from 'react';
import {
  Users,
  MessageSquare,
  Plus,
  CheckCircle,
  ToggleLeft,
  ToggleRight,
  Save,
  SlidersHorizontal,
  LayoutDashboard,
  Layers,
  RotateCcw,
  Loader2,
  Pencil,
  Trash2,
  X,
  Search,
  Download,
  ChevronLeft,
  ChevronRight,
  MapPin,
  ExternalLink,
  Shield,
  ShieldCheck,
  Phone,
  Mail,
  Smartphone,
  Clock,
  Lock,
  Star,
  User,
  Building,
  Globe,
  Layers as LayersIcon,
  MoreHorizontal,
  UploadCloud,
  HelpCircle,
  Send,
  ShoppingCart,
  Navigation,
  ArrowUpDown,
  Check,
  Tag,
} from 'lucide-react';
import * as XLSX from 'xlsx';
import type {
  TeamUser,
  AppRole,
  RolePermissions,
  UserModulePermissions,
  CompanyConfig,
  CompanyOffice,
  ModuleVisibilityConfig,
  DashboardCardsConfig,
  MessageTemplate,
} from '../../types/crm';
import { templateService } from '../../services/templateService';
import { officeService } from '../../services/officeService';
import { roleService, DEFAULT_ROLE_PERMISSIONS } from '../../services/roleService';

interface SettingsViewProps {
  users: TeamUser[];
  onAddUser: (user: Partial<TeamUser>) => Promise<void>;
  onUpdateUser?: (id: string, user: Partial<TeamUser>) => Promise<void>;
  onDeleteUser?: (id: string) => Promise<void>;
  onToggleTracking: (id: string) => void;
  onToggleActive: (id: string) => void;
  moduleVisibility?: ModuleVisibilityConfig;
  onToggleModule?: (key: keyof ModuleVisibilityConfig) => void;
  dashboardCards?: DashboardCardsConfig;
  onToggleCard?: (key: keyof DashboardCardsConfig) => void;
  onResetDefaults?: () => void;
  isSaving?: boolean;
}

const AVAILABLE_COLUMNS = [
  { key: 'user_code', label: 'User ID / Code' },
  { key: 'name', label: 'Member Name', locked: true },
  { key: 'mobile', label: 'Mobile Number' },
  { key: 'email', label: 'Email Address' },
  { key: 'role', label: 'Role & Hierarchy' },
  { key: 'reporting_head', label: 'Reporting Head' },
  { key: 'location_tracking', label: 'GPS Tracking' },
  { key: 'last_login', label: 'Last Login & Device' },
  { key: 'status', label: 'Status' },
  { key: 'actions', label: 'Actions' },
];


const PermSwitch: React.FC<{
  label: string;
  checked: boolean;
  onChange: (val: boolean) => void;
}> = ({ label, checked, onChange }) => (
  <div className="flex flex-col items-center select-none">
    <span className="text-[11px] font-semibold text-gray-500 mb-1">{label}</span>
    <button
      type="button"
      onClick={() => onChange(!checked)}
      className={`w-9 h-5 flex items-center rounded-full p-0.5 transition-colors cursor-pointer ${
        checked ? 'bg-[#1a237e]' : 'bg-gray-300'
      }`}
    >
      <div
        className={`bg-white w-4 h-4 rounded-full shadow-md transform transition-transform ${
          checked ? 'translate-x-4' : 'translate-x-0'
        }`}
      />
    </button>
  </div>
);

function getPageNumbers(currentPage: number, totalPages: number): (number | string)[] {
  if (totalPages <= 7) {
    return Array.from({ length: totalPages }, (_, i) => i + 1);
  }
  const pages: (number | string)[] = [];
  if (currentPage <= 4) {
    for (let i = 1; i <= 5; i++) pages.push(i);
    pages.push('...');
    pages.push(totalPages);
  } else if (currentPage >= totalPages - 3) {
    pages.push(1);
    pages.push('...');
    for (let i = totalPages - 4; i <= totalPages; i++) pages.push(i);
  } else {
    pages.push(1);
    pages.push('...');
    for (let i = currentPage - 1; i <= currentPage + 1; i++) pages.push(i);
    pages.push('...');
    pages.push(totalPages);
  }
  return pages;
}

function getDefaultPermissions(role: 'Admin' | 'Manager' | 'Staff'): UserModulePermissions {
  if (role === 'Admin') {
    return {
      leads_view: 'all',
      leads_create: true,
      leads_edit: true,
      leads_delete: true,
      leads_export: true,
      customers_view: 'all',
      customers_create: true,
      customers_edit: true,
      customers_export: true,
      sales_pfi: true,
      sales_invoice: true,
      sales_payment: true,
      sales_export: true,
      visits_tracking: true,
      visits_routes: true,
    };
  }
  if (role === 'Manager') {
    return {
      leads_view: 'all',
      leads_create: true,
      leads_edit: true,
      leads_delete: false,
      leads_export: true,
      customers_view: 'all',
      customers_create: true,
      customers_edit: true,
      customers_export: true,
      sales_pfi: true,
      sales_invoice: true,
      sales_payment: true,
      sales_export: true,
      visits_tracking: true,
      visits_routes: true,
    };
  }
  return {
    leads_view: 'own',
    leads_create: true,
    leads_edit: true,
    leads_delete: false,
    leads_export: false,
    customers_view: 'own',
    customers_create: true,
    customers_edit: true,
    customers_export: false,
    sales_pfi: true,
    sales_invoice: false,
    sales_payment: true,
    sales_export: false,
    visits_tracking: true,
    visits_routes: false,
  };
}

export const SettingsView: React.FC<SettingsViewProps> = ({
  users,
  onAddUser,
  onUpdateUser,
  onDeleteUser,
  onToggleTracking,
  onToggleActive,
  moduleVisibility,
  onToggleModule,
  dashboardCards,
  onToggleCard,
  onResetDefaults,
  isSaving = false,
}) => {
  // Navigation State
  const [activeTab, setActiveTab] = useState<
    'profile' | 'company' | 'sales_settings' | 'templates' | 'users' | 'roles' | 'modules'
  >('company');

  const [companySubTab, setCompanySubTab] = useState<'profile' | 'offices' | 'settings' | 'reminders'>('profile');


  // ========================================================
  // 6. ROLES & PERMISSIONS STATE (Screenshots 161941, 161958, 162039, 162052)
  // ========================================================
  const [roles, setRoles] = useState<AppRole[]>([]);
  const [rolesSubView, setRolesSubView] = useState<'list' | 'edit' | 'create'>('list');
  const [currentEditingRole, setCurrentEditingRole] = useState<AppRole | null>(null);
  const [formRoleName, setFormRoleName] = useState('');
  const [formRoleAccess, setFormRoleAccess] = useState('Admin');
  const [formRolePermissions, setFormRolePermissions] = useState<RolePermissions>(
    DEFAULT_ROLE_PERMISSIONS.admin
  );
  const [isSavingRole, setIsSavingRole] = useState(false);
  const [roleSavedSuccess, setRoleSavedSuccess] = useState(false);
  const [activeRoleMenuId, setActiveRoleMenuId] = useState<string | null>(null);
  const [rolePageSize, setRolePageSize] = useState(10);
  const [roleCurrentPage, setRoleCurrentPage] = useState(1);

  useEffect(() => {
    roleService.fetchRoles().then(setRoles);
  }, []);

  const handleOpenAddRole = () => {
    setCurrentEditingRole(null);
    setFormRoleName('');
    setFormRoleAccess('Staff');
    setFormRolePermissions(JSON.parse(JSON.stringify(DEFAULT_ROLE_PERMISSIONS.staff)));
    setRolesSubView('create');
  };

  const handleOpenEditRole = (role: AppRole) => {
    setCurrentEditingRole(role);
    setFormRoleName(role.name);
    setFormRoleAccess(role.access);
    setFormRolePermissions(JSON.parse(JSON.stringify(role.permissions)));
    setRolesSubView('edit');
  };

  const handleDeleteRole = async (roleId: string) => {
    if (!confirm('Are you sure you want to delete this custom role?')) return;
    const next = roles.filter((r) => r.id !== roleId);
    setRoles(next);
    await roleService.saveRoles(next);
  };

  const handleSaveRole = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formRoleName.trim()) {
      alert('Please enter a role name.');
      return;
    }
    setIsSavingRole(true);
    try {
      let nextRoles: AppRole[];
      if (currentEditingRole) {
        nextRoles = roles.map((r) =>
          r.id === currentEditingRole.id
            ? {
                ...r,
                name: formRoleName.trim(),
                access: formRoleAccess,
                permissions: formRolePermissions,
                updated_at: new Date().toISOString(),
              }
            : r
        );
      } else {
        const newRole: AppRole = {
          id: 'role-' + Date.now(),
          name: formRoleName.trim(),
          access: formRoleAccess,
          users_count: 0,
          permissions: formRolePermissions,
          is_system: false,
          created_at: new Date().toISOString(),
        };
        nextRoles = [...roles, newRole];
      }

      await roleService.saveRoles(nextRoles);
      setRoles(nextRoles);

      // Map to module visibility and apply immediately to control shown modules
      const targetRole =
        nextRoles.find((r) => r.name.toLowerCase() === formRoleName.toLowerCase()) ||
        nextRoles[0];
      const newVis = roleService.mapRoleToModuleVisibility(targetRole);

      if (onToggleModule && moduleVisibility) {
        (Object.keys(newVis) as (keyof ModuleVisibilityConfig)[]).forEach((key) => {
          if (moduleVisibility[key] !== newVis[key]) {
            onToggleModule(key);
          }
        });
      }
      localStorage.setItem('myteams_module_visibility', JSON.stringify(newVis));
      localStorage.setItem(
        'myteams_current_role_permissions',
        JSON.stringify(targetRole.permissions)
      );

      setRoleSavedSuccess(true);
      setTimeout(() => {
        setRoleSavedSuccess(false);
        setRolesSubView('list');
      }, 1000);
    } catch (err) {
      console.error('Failed to save role:', err);
    } finally {
      setIsSavingRole(false);
    }
  };

  // ========================================================
  // 1. MY PROFILE STATE (Screenshot 2026-10-25 153809.png)
  // ========================================================
  const [profileFirstName, setProfileFirstName] = useState(() => {
    return localStorage.getItem('myteams_user_first_name') || 'ADMIN';
  });
  const [profileLastName, setProfileLastName] = useState(() => {
    return localStorage.getItem('myteams_user_last_name') || 'ADMIN';
  });
  const [profileMobile, setProfileMobile] = useState(() => {
    return localStorage.getItem('myteams_user_mobile') || '9999999999';
  });
  const [profileEmail] = useState(() => {
    return localStorage.getItem('myteams_user_email') || 'ivsquarestructure@gmail.com';
  });
  const [profilePhoto, setProfilePhoto] = useState<string | null>(() => {
    return localStorage.getItem('myteams_user_photo') || null;
  });
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [profileSavedSuccess, setProfileSavedSuccess] = useState(false);

  const handleSaveMyProfile = (e: React.FormEvent) => {
    e.preventDefault();
    if (newPassword && newPassword !== confirmPassword) {
      alert('New password and confirmation password do not match.');
      return;
    }
    localStorage.setItem('myteams_user_first_name', profileFirstName);
    localStorage.setItem('myteams_user_last_name', profileLastName);
    localStorage.setItem('myteams_user_mobile', profileMobile);
    if (profilePhoto) {
      localStorage.setItem('myteams_user_photo', profilePhoto);
    }
    setProfileSavedSuccess(true);
    setNewPassword('');
    setConfirmPassword('');
    setTimeout(() => setProfileSavedSuccess(false), 3000);
  };

  const handleProfilePhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = () => {
        setProfilePhoto(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  // ========================================================
  // 2. COMPANY PROFILE STATE (Screenshots 154110 & 154203)
  // ========================================================
  const [company, setCompany] = useState<CompanyConfig>(() => {
    const saved = localStorage.getItem('myteams_company_config');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch {
        // ignore
      }
    }
    return {
      company_name: 'IV SQUARE STRUCTURE  INDIA PVT LTD',
      brand_name: 'IV SQUARE STRUCTURE  INDIA PVT LTD',
      phone: '9723793492',
      email: 'ivsquarestructure@gmail.com',
      website: 'https://ivsquarestructure.com/',
      gstin: '24AAFCI9953E1ZF',
      billing_address:
        '1103, R K World Tower , Near Shitalpark , Nr. Ayodhyachowk , 150ft Ring Road, RAJKOT, GUJARAT, India - 360006.',
      timezone: 'Asia/Kolkata (GMT+5:30)',
      currency: 'India Rupee',
      is_dsr_email: true,
      invoice_prefix: 'INV-',
      proforma_prefix: 'PFI-',
      order_prefix: 'ORD-',
      bank_name: 'State Bank of India',
      bank_account_no: '38920194819',
      bank_ifsc: 'SBIN0001234',
      upi_id: 'ivsquare@sbi',
      terms: '1. Goods once sold will not be taken back.\n2. Interest @ 18% p.a. after due date.\n3. Subject to Rajkot jurisdiction.',
    };
  });

  const [companySavedSuccess, setCompanySavedSuccess] = useState(false);
  const [isEditingBillingAddress, setIsEditingBillingAddress] = useState(false);
  const [tempBillingAddress, setTempBillingAddress] = useState(company.billing_address || '');

  const handleSaveCompany = (e: React.FormEvent) => {
    e.preventDefault();
    localStorage.setItem('myteams_company_config', JSON.stringify(company));
    setCompanySavedSuccess(true);
    setTimeout(() => setCompanySavedSuccess(false), 3000);
  };

  const handleSaveBillingAddress = () => {
    const updated = { ...company, billing_address: tempBillingAddress.trim() };
    setCompany(updated);
    localStorage.setItem('myteams_company_config', JSON.stringify(updated));
    setIsEditingBillingAddress(false);
  };

  // ========================================================
  // 3. OFFICES STATE (Screenshots 154128 & 154139)
  // ========================================================
  const [offices, setOffices] = useState<CompanyOffice[]>([]);
  const [isOfficeModalOpen, setIsOfficeModalOpen] = useState(false);
  const [editingOffice, setEditingOffice] = useState<CompanyOffice | null>(null);
  const [officeName, setOfficeName] = useState('');
  const [officeLocation, setOfficeLocation] = useState('22.3039, 70.8022');
  const [officeAddress, setOfficeAddress] = useState('');
  const [officeCity, setOfficeCity] = useState('');
  const [officeState, setOfficeState] = useState('');
  const [officePincode, setOfficePincode] = useState('');
  const [officeCountry, setOfficeCountry] = useState('India');
  const [activeOfficeMenuId, setActiveOfficeMenuId] = useState<string | null>(null);

  // Map Modal for Office Location (opens when map icon is tapped)
  const [isMapModalOpen, setIsMapModalOpen] = useState(false);
  const [mapPickerLat, setMapPickerLat] = useState(22.3039);
  const [mapPickerLng, setMapPickerLng] = useState(70.8022);
  const [mapLocationSource, setMapLocationSource] = useState<'form' | 'table'>('form');
  const [viewingOfficeOnMap, setViewingOfficeOnMap] = useState<CompanyOffice | null>(null);
  const [isGettingCurrentLocation, setIsGettingCurrentLocation] = useState(false);

  useEffect(() => {
    officeService.fetchOffices().then(setOffices);
  }, []);

  const handleOpenAddOffice = () => {
    setEditingOffice(null);
    setOfficeName('');
    setOfficeLocation('22.3039, 70.8022');
    setOfficeAddress('');
    setOfficeCity('Rajkot');
    setOfficeState('Gujarat');
    setOfficePincode('360006');
    setOfficeCountry('India');
    setIsOfficeModalOpen(true);
  };

  const handleOpenEditOffice = (off: CompanyOffice) => {
    setEditingOffice(off);
    setOfficeName(off.name);
    setOfficeLocation(off.location || '22.3039, 70.8022');
    setOfficeAddress(off.address);
    setOfficeCity(off.city || '');
    setOfficeState(off.state || '');
    setOfficePincode(off.pincode || '');
    setOfficeCountry(off.country || 'India');
    setActiveOfficeMenuId(null);
    setIsOfficeModalOpen(true);
  };

  const handleSaveOffice = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!officeName.trim()) return;

    let updated: CompanyOffice[];
    if (editingOffice) {
      updated = offices.map((o) =>
        o.id === editingOffice.id
          ? {
              ...o,
              name: officeName.trim(),
              location: officeLocation.trim(),
              address: officeAddress.trim(),
              city: officeCity.trim(),
              state: officeState.trim(),
              pincode: officePincode.trim(),
              country: officeCountry,
            }
          : o
      );
    } else {
      const newOffice: CompanyOffice = {
        id: `off-${Date.now()}`,
        name: officeName.trim(),
        location: officeLocation.trim(),
        address: officeAddress.trim(),
        city: officeCity.trim(),
        state: officeState.trim(),
        pincode: officePincode.trim(),
        country: officeCountry,
        users_count: 0,
        is_default: offices.length === 0,
      };
      updated = [...offices, newOffice];
    }

    setOffices(updated);
    await officeService.saveOffices(updated);
    setIsOfficeModalOpen(false);
    setEditingOffice(null);
  };

  const handleDeleteOffice = async (off: CompanyOffice) => {
    if (!window.confirm(`Are you sure you want to delete office "${off.name}"?`)) return;
    const updated = offices.filter((o) => o.id !== off.id);
    setOffices(updated);
    await officeService.saveOffices(updated);
    setActiveOfficeMenuId(null);
  };

  const handleSetDefaultOffice = async (offId: string) => {
    const updated = offices.map((o) => ({
      ...o,
      is_default: o.id === offId,
    }));
    setOffices(updated);
    await officeService.saveOffices(updated);
    setActiveOfficeMenuId(null);
  };

  // Open map from Add/Edit Office Form
  const handleOpenMapFromForm = () => {
    setMapLocationSource('form');
    setViewingOfficeOnMap(null);
    if (officeLocation.includes(',')) {
      const [latStr, lngStr] = officeLocation.split(',');
      const parsedLat = parseFloat(latStr.trim());
      const parsedLng = parseFloat(lngStr.trim());
      if (!isNaN(parsedLat) && !isNaN(parsedLng)) {
        setMapPickerLat(parsedLat);
        setMapPickerLng(parsedLng);
      }
    }
    setIsMapModalOpen(true);
  };

  // Open map from table row Location icon
  const handleOpenMapFromRow = (off: CompanyOffice) => {
    setMapLocationSource('table');
    setViewingOfficeOnMap(off);
    if (off.location && off.location.includes(',')) {
      const [latStr, lngStr] = off.location.split(',');
      const parsedLat = parseFloat(latStr.trim());
      const parsedLng = parseFloat(lngStr.trim());
      if (!isNaN(parsedLat) && !isNaN(parsedLng)) {
        setMapPickerLat(parsedLat);
        setMapPickerLng(parsedLng);
      }
    } else {
      setMapPickerLat(22.3039);
      setMapPickerLng(70.8022);
    }
    setIsMapModalOpen(true);
  };

  const handleUseCurrentGPSLocation = () => {
    if (!navigator.geolocation) {
      alert('Geolocation is not supported by your browser.');
      return;
    }
    setIsGettingCurrentLocation(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setIsGettingCurrentLocation(false);
        setMapPickerLat(pos.coords.latitude);
        setMapPickerLng(pos.coords.longitude);
      },
      (err) => {
        setIsGettingCurrentLocation(false);
        alert(`Unable to retrieve GPS location: ${err.message}`);
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  };

  const handleConfirmMapLocation = () => {
    const coords = `${mapPickerLat.toFixed(4)}, ${mapPickerLng.toFixed(4)}`;
    if (mapLocationSource === 'form') {
      setOfficeLocation(coords);
    }
    setIsMapModalOpen(false);
  };

  // ========================================================
  // 4. USERS & TEAM STATE (Parity features retained)
  // ========================================================
  const [searchQuery, setSearchQuery] = useState('');
  const [roleFilter, setRoleFilter] = useState<'all' | 'Admin' | 'Manager' | 'Staff'>('all');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'inactive'>('all');
  const [trackingFilter, setTrackingFilter] = useState<'all' | 'active' | 'disabled'>('all');

  const [visibleColumns, setVisibleColumns] = useState<Record<string, boolean>>(() => {
    const saved = localStorage.getItem('myteams_users_visible_columns');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch {
        // ignore
      }
    }
    return {
      user_code: true,
      name: true,
      mobile: true,
      email: true,
      role: true,
      reporting_head: true,
      location_tracking: true,
      last_login: true,
      status: true,
      actions: true,
    };
  });
  const [isColumnsDropdownOpen, setIsColumnsDropdownOpen] = useState(false);
  const columnsDropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (columnsDropdownRef.current && !columnsDropdownRef.current.contains(e.target as Node)) {
        setIsColumnsDropdownOpen(false);
      }
    };
    if (isColumnsDropdownOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isColumnsDropdownOpen]);

  const toggleColumnVisibility = (key: string) => {
    const updated = { ...visibleColumns, [key]: !visibleColumns[key] };
    setVisibleColumns(updated);
    localStorage.setItem('myteams_users_visible_columns', JSON.stringify(updated));
  };

  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);
  const [selectedLocationUser, setSelectedLocationUser] = useState<TeamUser | null>(null);

  const [isUserModalOpen, setIsUserModalOpen] = useState(false);
  const [editingUser, setEditingUser] = useState<TeamUser | null>(null);
  const [userModalTab, setUserModalTab] = useState<'profile' | 'permissions'>('profile');
  const [isSubmittingUser, setIsSubmittingUser] = useState(false);
  const [newFirstName, setNewFirstName] = useState('');
  const [newLastName, setNewLastName] = useState('');
  const [newMobile, setNewMobile] = useState('');
  const [newEmail, setNewEmail] = useState('');
  const [newRole, setNewRole] = useState<'Admin' | 'Manager' | 'Staff'>('Staff');
  const [newReportingHead, setNewReportingHead] = useState('ADMIN ADMIN');
  const [newLocationTracking, setNewLocationTracking] = useState(true);
  const [newIsActive, setNewIsActive] = useState(true);
  const [newPermissions, setNewPermissions] = useState<UserModulePermissions>(() =>
    getDefaultPermissions('Staff')
  );

  const handleOpenAddUser = () => {
    setEditingUser(null);
    setUserModalTab('profile');
    setNewFirstName('');
    setNewLastName('');
    setNewMobile('');
    setNewEmail('');
    setNewRole('Staff');
    setNewReportingHead('ADMIN ADMIN');
    setNewLocationTracking(true);
    setNewIsActive(true);
    setNewPermissions(getDefaultPermissions('Staff'));
    setIsUserModalOpen(true);
  };

  const handleOpenEditUser = (u: TeamUser) => {
    setEditingUser(u);
    setUserModalTab('profile');
    setNewFirstName(u.first_name);
    setNewLastName(u.last_name);
    setNewMobile(u.mobile);
    setNewEmail(u.email);
    setNewRole(u.role);
    setNewReportingHead(u.reporting_head || 'ADMIN ADMIN');
    setNewLocationTracking(u.location_tracking ?? true);
    setNewIsActive(u.is_active ?? true);
    setNewPermissions(u.permissions || getDefaultPermissions(u.role));
    setIsUserModalOpen(true);
  };

  const handleRoleChangeInModal = (role: 'Admin' | 'Manager' | 'Staff') => {
    setNewRole(role);
    setNewPermissions(getDefaultPermissions(role));
  };

  const handleDeleteUser = async (u: TeamUser) => {
    if (!onDeleteUser) return;
    const confirmDelete = window.confirm(
      `Are you sure you want to remove team member ${u.first_name} ${u.last_name}?`
    );
    if (confirmDelete) {
      await onDeleteUser(u.id);
    }
  };

  const handleSaveUser = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newFirstName.trim() || !newMobile.trim()) return;

    setIsSubmittingUser(true);
    try {
      if (editingUser) {
        if (onUpdateUser) {
          await onUpdateUser(editingUser.id, {
            first_name: newFirstName.trim(),
            last_name: newLastName.trim(),
            mobile: newMobile.trim(),
            email: newEmail.trim(),
            role: newRole,
            reporting_head: newReportingHead,
            location_tracking: newLocationTracking,
            is_active: newIsActive,
            permissions: newPermissions,
          });
        }
      } else {
        await onAddUser({
          first_name: newFirstName.trim(),
          last_name: newLastName.trim(),
          mobile: newMobile.trim(),
          email: newEmail.trim(),
          role: newRole,
          reporting_head: newReportingHead,
          location_tracking: newLocationTracking,
          is_active: newIsActive,
          permissions: newPermissions,
        });
      }
      setIsUserModalOpen(false);
      setEditingUser(null);
    } finally {
      setIsSubmittingUser(false);
    }
  };

  const reportingHeadOptions = useMemo(() => {
    return Array.from(
      new Set([
        'ADMIN ADMIN',
        'JITESHBHAI VASANIYA',
        '-',
        ...users
          .filter((u) => !editingUser || u.id !== editingUser.id)
          .map((u) => `${u.first_name} ${u.last_name}`.trim())
          .filter(Boolean),
      ])
    );
  }, [users, editingUser]);

  const filteredUsers = useMemo(() => {
    return users.filter((u) => {
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase().trim();
        const fullName = `${u.first_name} ${u.last_name}`.toLowerCase();
        const code = (u.user_code || '').toLowerCase();
        const mobile = (u.mobile || '').toLowerCase();
        const email = (u.email || '').toLowerCase();
        const head = (u.reporting_head || '').toLowerCase();
        if (
          !fullName.includes(q) &&
          !code.includes(q) &&
          !mobile.includes(q) &&
          !email.includes(q) &&
          !head.includes(q)
        ) {
          return false;
        }
      }

      if (roleFilter !== 'all' && u.role !== roleFilter) return false;
      if (statusFilter === 'active' && !u.is_active) return false;
      if (statusFilter === 'inactive' && u.is_active) return false;
      if (trackingFilter === 'active' && !u.location_tracking) return false;
      if (trackingFilter === 'disabled' && u.location_tracking) return false;

      return true;
    });
  }, [users, searchQuery, roleFilter, statusFilter, trackingFilter]);

  useEffect(() => {
    setCurrentPage(1);
  }, [searchQuery, roleFilter, statusFilter, trackingFilter]);

  const totalPages = Math.max(1, Math.ceil(filteredUsers.length / itemsPerPage));
  const paginatedUsers = useMemo(() => {
    const start = (currentPage - 1) * itemsPerPage;
    return filteredUsers.slice(start, start + itemsPerPage);
  }, [filteredUsers, currentPage, itemsPerPage]);

  const activeUsersCount = useMemo(() => users.filter((u) => u.is_active).length, [users]);
  const totalLicenseCount = Math.max(10, users.length + 5);

  const hasActiveFilters =
    searchQuery.trim() !== '' ||
    roleFilter !== 'all' ||
    statusFilter !== 'all' ||
    trackingFilter !== 'all';

  const resetAllFilters = () => {
    setSearchQuery('');
    setRoleFilter('all');
    setStatusFilter('all');
    setTrackingFilter('all');
  };

  const handleDownloadAllUsers = () => {
    if (filteredUsers.length === 0) {
      alert('No users available to export.');
      return;
    }

    const exportRows = filteredUsers.map((u) => ({
      'Staff Code': `#${u.user_code}`,
      'Full Name': `${u.first_name} ${u.last_name}`,
      'Mobile Number': u.mobile,
      'Email Address': u.email || 'N/A',
      'Role': u.role,
      'Reporting Head': u.reporting_head || '-',
      'GPS Location Tracking': u.location_tracking ? 'Active' : 'Disabled',
      'Account Status': u.is_active ? 'Active' : 'Inactive',
      'Last Login': u.last_login || 'N/A',
      'App / Device': u.device_info || 'Mobile App',
      'Leads Visibility': u.permissions?.leads_view === 'own' ? 'Own Assigned' : 'All Leads',
      'Customers Visibility': u.permissions?.customers_view === 'own' ? 'Own Assigned' : 'All Customers',
      'Sales Invoicing': u.permissions?.sales_invoice ? 'Allowed' : 'Restricted',
      'Member Since': u.created_at ? new Date(u.created_at).toLocaleDateString('en-GB') : 'N/A',
    }));

    const worksheet = XLSX.utils.json_to_sheet(exportRows);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Users');

    const dateStr = new Date().toISOString().split('T')[0];
    XLSX.writeFile(workbook, `Users_${dateStr}.xlsx`);
  };

  // ========================================================
  // 5. MESSAGE TEMPLATES STATE (Preserved)
  // ========================================================
  const [templates, setTemplates] = useState<MessageTemplate[]>([]);
  const [templateFilter, setTemplateFilter] = useState<
    'All' | 'Leads' | 'Customers' | 'Invoices' | 'Proforma Invoices' | 'General'
  >('All');
  const [isTemplateModalOpen, setIsTemplateModalOpen] = useState(false);
  const [editingTemplate, setEditingTemplate] = useState<MessageTemplate | null>(null);
  const [tmplName, setTmplName] = useState('');
  const [tmplModule, setTmplModule] = useState<MessageTemplate['module']>('Leads');
  const [tmplContent, setTmplContent] = useState('');
  const [tmplIsDefault, setTmplIsDefault] = useState(false);
  const tmplTextareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    templateService.fetchTemplates().then(setTemplates);
  }, []);

  const handleOpenAddTemplate = () => {
    setEditingTemplate(null);
    setTmplName('');
    setTmplModule('Leads');
    setTmplContent('Hello {{name}}, following up on our recent discussion regarding your requirements with {{brand_name}}.');
    setTmplIsDefault(templates.filter((t) => t.module === 'Leads').length === 0);
    setIsTemplateModalOpen(true);
  };

  const handleOpenEditTemplate = (tmpl: MessageTemplate) => {
    setEditingTemplate(tmpl);
    setTmplName(tmpl.name);
    setTmplModule(tmpl.module);
    setTmplContent(tmpl.content);
    setTmplIsDefault(tmpl.is_default);
    setIsTemplateModalOpen(true);
  };

  const handleToggleDefaultTemplate = async (tmplId: string, module: MessageTemplate['module']) => {
    const updated = templates.map((t) => {
      if (t.module === module) {
        return { ...t, is_default: t.id === tmplId };
      }
      return t;
    });
    setTemplates(updated);
    await templateService.saveTemplates(updated);
  };

  const handleDeleteTemplate = async (tmpl: MessageTemplate) => {
    if (!window.confirm(`Are you sure you want to delete template "${tmpl.name}"?`)) return;
    const updated = templates.filter((t) => t.id !== tmpl.id);
    setTemplates(updated);
    await templateService.saveTemplates(updated);
  };

  const handleSaveTemplate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!tmplName.trim() || !tmplContent.trim()) return;

    let updated: MessageTemplate[];
    if (editingTemplate) {
      updated = templates.map((t) => {
        if (t.id === editingTemplate.id) {
          return {
            ...t,
            name: tmplName.trim(),
            module: tmplModule,
            content: tmplContent.trim(),
            is_default: tmplIsDefault,
            updated_at: new Date().toISOString(),
          };
        }
        if (tmplIsDefault && t.module === tmplModule && t.id !== editingTemplate.id) {
          return { ...t, is_default: false };
        }
        return t;
      });
    } else {
      const newTmpl: MessageTemplate = {
        id: `tmpl-${Date.now()}`,
        name: tmplName.trim(),
        module: tmplModule,
        content: tmplContent.trim(),
        is_default: tmplIsDefault,
        updated_at: new Date().toISOString(),
      };
      updated = tmplIsDefault
        ? [...templates.map((t) => (t.module === tmplModule ? { ...t, is_default: false } : t)), newTmpl]
        : [...templates, newTmpl];
    }

    setTemplates(updated);
    await templateService.saveTemplates(updated);
    setIsTemplateModalOpen(false);
    setEditingTemplate(null);
  };

  const insertVariableTag = (tag: string) => {
    if (tmplTextareaRef.current) {
      const start = tmplTextareaRef.current.selectionStart;
      const end = tmplTextareaRef.current.selectionEnd;
      const current = tmplContent;
      const next = current.substring(0, start) + tag + current.substring(end);
      setTmplContent(next);
      setTimeout(() => {
        if (tmplTextareaRef.current) {
          tmplTextareaRef.current.focus();
          tmplTextareaRef.current.setSelectionRange(start + tag.length, start + tag.length);
        }
      }, 0);
    } else {
      setTmplContent((prev) => prev + tag);
    }
  };

  const filteredTemplates = useMemo(() => {
    if (templateFilter === 'All') return templates;
    return templates.filter((t) => t.module === templateFilter);
  }, [templates, templateFilter]);

  return (
    <div className="space-y-4">
      {/* Settings Container Layout matching Screenshot 2026-10-25 153809.png */}
      <div className="flex flex-col lg:flex-row gap-5 items-start">
        {/* Left Settings Navigation Menu */}
        <div className="w-full lg:w-56 shrink-0 bg-white rounded-xl border border-gray-200 shadow-2xs p-3 space-y-4">
          <div>
            <h3 className="font-bold text-sm text-gray-900 px-3 py-1 mb-1">Settings</h3>
            <div className="space-y-0.5">
              <button
                type="button"
                onClick={() => setActiveTab('profile')}
                className={`w-full flex items-center space-x-2.5 px-3 py-2 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                  activeTab === 'profile'
                    ? 'bg-[#1a237e] text-white shadow-xs'
                    : 'text-gray-600 hover:bg-gray-100'
                }`}
              >
                <User className="w-4 h-4" />
                <span>My Profile</span>
              </button>
              <button
                type="button"
                onClick={() => setActiveTab('company')}
                className={`w-full flex items-center space-x-2.5 px-3 py-2 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                  activeTab === 'company'
                    ? 'bg-[#1a237e] text-white shadow-xs'
                    : 'text-gray-600 hover:bg-gray-100'
                }`}
              >
                <Building className="w-4 h-4" />
                <span>Company Profile</span>
              </button>
            </div>
          </div>

          <div>
            <div className="text-[10px] font-bold text-gray-400 uppercase tracking-wider px-3 mb-1">CRM</div>
            <div className="space-y-0.5">
              <button
                type="button"
                onClick={() => setActiveTab('sales_settings')}
                className={`w-full flex items-center space-x-2.5 px-3 py-2 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                  activeTab === 'sales_settings'
                    ? 'bg-[#1a237e] text-white shadow-xs'
                    : 'text-gray-600 hover:bg-gray-100'
                }`}
              >
                <ShoppingCart className="w-4 h-4" />
                <span>Sales Settings</span>
              </button>
              <button
                type="button"
                onClick={() => setActiveTab('templates')}
                className={`w-full flex items-center space-x-2.5 px-3 py-2 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                  activeTab === 'templates'
                    ? 'bg-[#1a237e] text-white shadow-xs'
                    : 'text-gray-600 hover:bg-gray-100'
                }`}
              >
                <Send className="w-4 h-4" />
                <span>Templates</span>
              </button>
            </div>
          </div>

          <div>
            <div className="text-[10px] font-bold text-gray-400 uppercase tracking-wider px-3 mb-1">Organization</div>
            <div className="space-y-0.5">
              <button
                type="button"
                onClick={() => setActiveTab('users')}
                className={`w-full flex items-center space-x-2.5 px-3 py-2 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                  activeTab === 'users'
                    ? 'bg-[#1a237e] text-white shadow-xs'
                    : 'text-gray-600 hover:bg-gray-100'
                }`}
              >
                <Users className="w-4 h-4" />
                <span>Users</span>
              </button>
              <button
                type="button"
                onClick={() => {
                  setActiveTab('roles');
                  setRolesSubView('list');
                }}
                className={`w-full flex items-center space-x-2.5 px-3 py-2 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                  activeTab === 'roles'
                    ? 'bg-[#1a237e] text-white shadow-xs'
                    : 'text-gray-600 hover:bg-gray-100'
                }`}
              >
                <ShieldCheck className="w-4 h-4" />
                <span>Roles</span>
              </button>
              <button
                type="button"
                onClick={() => setActiveTab('modules')}
                className={`w-full flex items-center space-x-2.5 px-3 py-2 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                  activeTab === 'modules'
                    ? 'bg-[#1a237e] text-white shadow-xs'
                    : 'text-gray-600 hover:bg-gray-100'
                }`}
              >
                <SlidersHorizontal className="w-4 h-4" />
                <span>Modules & Cards</span>
              </button>
            </div>
          </div>
        </div>

        {/* Right Content Panel */}
        <div className="flex-1 w-full min-w-0 space-y-4">
          {/* Breadcrumb matching screenshots */}
          <div className="flex items-center text-xs text-gray-500 space-x-1.5 font-medium">
            <span className="text-[#1a237e] hover:underline cursor-pointer">Dashboard</span>
            <span>&gt;</span>
            <span className="text-[#1a237e] hover:underline cursor-pointer">Settings</span>
            <span>&gt;</span>
            <span className="text-gray-700 font-bold">
              {activeTab === 'profile'
                ? 'My Profile'
                : activeTab === 'company'
                ? 'Company Profile'
                : activeTab === 'sales_settings'
                ? 'Sales Settings'
                : activeTab === 'templates'
                ? 'Templates'
                : activeTab === 'users'
                ? 'Users & Team Hierarchy'
                : activeTab === 'roles'
                ? rolesSubView === 'list'
                  ? 'Roles'
                  : rolesSubView === 'create'
                  ? 'Add Role'
                  : 'Edit Role'
                : 'Modules & Cards'}
            </span>
          </div>

          {/* SCREEN 1: MY PROFILE (Screenshot 2026-10-25 153809.png) */}
          {activeTab === 'profile' && (
            <div className="space-y-3">
              <h2 className="text-base font-bold text-gray-900">My Profile</h2>
              <form onSubmit={handleSaveMyProfile} className="bg-white p-6 rounded-xl border border-gray-200 shadow-2xs space-y-4 text-xs">
                {profileSavedSuccess && (
                  <div className="p-3 bg-emerald-50 border border-emerald-200 rounded-lg text-emerald-800 font-semibold flex items-center gap-2">
                    <CheckCircle className="w-4 h-4 text-emerald-600" />
                    <span>Profile updated successfully!</span>
                  </div>
                )}

                {/* Row 1: First Name & Last Name */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label className="block font-semibold text-gray-700 mb-1">
                      First Name <span className="text-rose-500">*</span>
                    </label>
                    <input
                      type="text"
                      required
                      value={profileFirstName}
                      onChange={(e) => setProfileFirstName(e.target.value)}
                      className="w-full border border-gray-300 rounded-lg p-2.5 focus:border-[#1a237e] focus:outline-none"
                    />
                  </div>
                  <div>
                    <label className="block font-semibold text-gray-700 mb-1">
                      Last Name <span className="text-rose-500">*</span>
                    </label>
                    <input
                      type="text"
                      required
                      value={profileLastName}
                      onChange={(e) => setProfileLastName(e.target.value)}
                      className="w-full border border-gray-300 rounded-lg p-2.5 focus:border-[#1a237e] focus:outline-none"
                    />
                  </div>
                </div>

                {/* Row 2: Mobile & Email (Username) */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label className="block font-semibold text-gray-700 mb-1">Mobile</label>
                    <div className="flex rounded-lg border border-gray-300 overflow-hidden focus-within:border-[#1a237e]">
                      <span className="bg-gray-50 px-3 flex items-center justify-center border-r border-gray-300 text-gray-400">
                        <Phone className="w-4 h-4" />
                      </span>
                      <input
                        type="text"
                        value={profileMobile}
                        onChange={(e) => setProfileMobile(e.target.value)}
                        className="w-full p-2.5 focus:outline-none"
                      />
                    </div>
                  </div>
                  <div>
                    <label className="block font-semibold text-gray-700 mb-1">
                      Email (Username) <span className="text-rose-500">*</span>
                    </label>
                    <div className="flex rounded-lg border border-gray-200 overflow-hidden bg-gray-100">
                      <span className="bg-gray-100 px-3 flex items-center justify-center border-r border-gray-200 text-gray-400">
                        <Mail className="w-4 h-4" />
                      </span>
                      <input
                        type="email"
                        disabled
                        value={profileEmail}
                        className="w-full p-2.5 bg-gray-100 text-gray-500 cursor-not-allowed focus:outline-none"
                      />
                    </div>
                  </div>
                </div>

                {/* Row 3: Photo Upload Box */}
                <div>
                  <label className="block font-semibold text-gray-700 mb-1">Photo</label>
                  <label className="border-2 border-dashed border-gray-200 hover:border-gray-300 rounded-xl h-32 flex flex-col items-center justify-center cursor-pointer transition-colors bg-gray-50/50 hover:bg-gray-50">
                    <input
                      type="file"
                      accept="image/*"
                      onChange={handleProfilePhotoUpload}
                      className="hidden"
                    />
                    {profilePhoto ? (
                      <div className="flex items-center gap-3">
                        <img
                          src={profilePhoto}
                          alt="Profile Preview"
                          className="w-16 h-16 rounded-full object-cover border border-gray-200 shadow-xs"
                        />
                        <span className="text-xs text-gray-600 font-semibold underline">Click to change photo</span>
                      </div>
                    ) : (
                      <div className="text-center space-y-1">
                        <UploadCloud className="w-6 h-6 text-gray-400 mx-auto" />
                        <span className="text-xs text-gray-500 font-medium block">Drop files here to upload</span>
                      </div>
                    )}
                  </label>
                </div>

                {/* Row 4: New Password & Confirm New Password */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label className="block font-semibold text-gray-700 mb-1">New Password</label>
                    <input
                      type="password"
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                      placeholder="Leave blank to keep current password"
                      className="w-full border border-gray-300 rounded-lg p-2.5 focus:border-[#1a237e] focus:outline-none"
                    />
                  </div>
                  <div>
                    <label className="block font-semibold text-gray-700 mb-1">Confirm New Password</label>
                    <input
                      type="password"
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      placeholder="Confirm new password"
                      className="w-full border border-gray-300 rounded-lg p-2.5 focus:border-[#1a237e] focus:outline-none"
                    />
                  </div>
                </div>

                {/* Save & Cancel Buttons */}
                <div className="pt-3 border-t border-gray-100 flex items-center space-x-2">
                  <button
                    type="submit"
                    className="px-5 py-2 bg-[#1a237e] hover:bg-[#283593] text-white rounded-md font-semibold shadow-xs cursor-pointer transition-colors"
                  >
                    Save
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      setNewPassword('');
                      setConfirmPassword('');
                    }}
                    className="px-4 py-2 border border-gray-300 hover:bg-gray-100 text-gray-700 rounded-md font-semibold cursor-pointer transition-colors"
                  >
                    Cancel
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* SCREEN 2: COMPANY PROFILE (Screenshots 154110, 154128, 154139, 154203) */}
          {activeTab === 'company' && (
            <div className="space-y-4">
              <h2 className="text-base font-bold text-gray-900">Company Profile</h2>

              {/* Sub-Tabs: Profile | Offices | Settings | Reminders (exact match to Screenshot 154110) */}
              <div className="border-b border-gray-200 flex items-center space-x-6 text-xs font-bold bg-white px-4 pt-3 rounded-t-xl">
                <button
                  type="button"
                  onClick={() => setCompanySubTab('profile')}
                  className={`pb-2.5 transition-all cursor-pointer ${
                    companySubTab === 'profile'
                      ? 'text-[#1a237e] border-b-2 border-[#1a237e]'
                      : 'text-gray-500 hover:text-gray-700'
                  }`}
                >
                  Profile
                </button>
                <button
                  type="button"
                  onClick={() => setCompanySubTab('offices')}
                  className={`pb-2.5 transition-all cursor-pointer ${
                    companySubTab === 'offices'
                      ? 'text-[#1a237e] border-b-2 border-[#1a237e]'
                      : 'text-gray-500 hover:text-gray-700'
                  }`}
                >
                  Offices
                </button>
                <button
                  type="button"
                  onClick={() => setCompanySubTab('settings')}
                  className={`pb-2.5 transition-all cursor-pointer ${
                    companySubTab === 'settings'
                      ? 'text-[#1a237e] border-b-2 border-[#1a237e]'
                      : 'text-gray-500 hover:text-gray-700'
                  }`}
                >
                  Settings
                </button>
                <button
                  type="button"
                  onClick={() => setCompanySubTab('reminders')}
                  className={`pb-2.5 transition-all cursor-pointer ${
                    companySubTab === 'reminders'
                      ? 'text-[#1a237e] border-b-2 border-[#1a237e]'
                      : 'text-gray-500 hover:text-gray-700'
                  }`}
                >
                  Reminders
                </button>
              </div>

              {/* SUB-TAB A: PROFILE & BILLING DETAILS (Screenshot 154110) */}
              {companySubTab === 'profile' && (
                <form onSubmit={handleSaveCompany} className="space-y-4 text-xs">
                  {companySavedSuccess && (
                    <div className="p-3 bg-emerald-50 border border-emerald-200 rounded-lg text-emerald-800 font-semibold flex items-center gap-2">
                      <CheckCircle className="w-4 h-4 text-emerald-600" />
                      <span>Company profile saved successfully!</span>
                    </div>
                  )}

                  {/* Card 1: Top Brand, Phone, Logo, Email, Website */}
                  <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-2xs space-y-4">
                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
                      {/* Left Column */}
                      <div className="space-y-4">
                        {/* Brand */}
                        <div>
                          <label className="block font-semibold text-gray-700 mb-1 flex items-center gap-1">
                            <span>Brand</span>
                            <span title="Your public registered brand name" className="text-gray-400 cursor-help">
                              <HelpCircle className="w-3.5 h-3.5" />
                            </span>
                          </label>
                          <div className="flex rounded-lg border border-gray-300 overflow-hidden focus-within:border-[#1a237e]">
                            <span className="bg-gray-50 px-3 flex items-center justify-center border-r border-gray-300 text-gray-400">
                              <LayersIcon className="w-4 h-4" />
                            </span>
                            <input
                              type="text"
                              value={company.brand_name}
                              onChange={(e) => setCompany({ ...company, brand_name: e.target.value })}
                              className="w-full p-2.5 focus:outline-none"
                            />
                          </div>
                        </div>

                        {/* Logo Upload Box */}
                        <div>
                          <label className="block font-semibold text-gray-700 mb-1">Logo</label>
                          <div className="border border-gray-200 hover:border-gray-300 rounded-xl h-32 flex flex-col items-center justify-center cursor-pointer transition-colors bg-white">
                            <span className="text-xs text-gray-500 font-medium">Drop files here to upload</span>
                          </div>
                        </div>
                      </div>

                      {/* Right Column */}
                      <div className="space-y-4">
                        {/* Phone */}
                        <div>
                          <label className="block font-semibold text-gray-700 mb-1">Phone</label>
                          <div className="flex rounded-lg border border-gray-300 overflow-hidden focus-within:border-[#1a237e]">
                            <span className="bg-gray-50 px-3 flex items-center justify-center border-r border-gray-300 text-gray-600 font-semibold text-xs">
                              +91
                            </span>
                            <input
                              type="text"
                              value={company.phone}
                              onChange={(e) => setCompany({ ...company, phone: e.target.value })}
                              className="w-full p-2.5 focus:outline-none"
                            />
                          </div>
                        </div>

                        {/* Email */}
                        <div>
                          <label className="block font-semibold text-gray-700 mb-1">Email</label>
                          <div className="flex rounded-lg border border-gray-300 overflow-hidden focus-within:border-[#1a237e]">
                            <span className="bg-gray-50 px-3 flex items-center justify-center border-r border-gray-300 text-gray-400">
                              <Mail className="w-4 h-4" />
                            </span>
                            <input
                              type="email"
                              value={company.email}
                              onChange={(e) => setCompany({ ...company, email: e.target.value })}
                              className="w-full p-2.5 focus:outline-none"
                            />
                          </div>
                        </div>

                        {/* Website */}
                        <div>
                          <label className="block font-semibold text-gray-700 mb-1">Website</label>
                          <div className="flex rounded-lg border border-gray-300 overflow-hidden focus-within:border-[#1a237e]">
                            <span className="bg-gray-50 px-3 flex items-center justify-center border-r border-gray-300 text-gray-400">
                              <Globe className="w-4 h-4" />
                            </span>
                            <input
                              type="text"
                              value={company.website}
                              onChange={(e) => setCompany({ ...company, website: e.target.value })}
                              className="w-full p-2.5 focus:outline-none"
                            />
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Card 2: Billing Details */}
                  <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-2xs space-y-4">
                    <h3 className="font-bold text-sm text-gray-900 border-b border-gray-100 pb-2">
                      Billing Details
                    </h3>

                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-5 items-start">
                      {/* Left: Company & GST */}
                      <div className="space-y-4">
                        <div>
                          <label className="block font-semibold text-gray-700 mb-1 flex items-center gap-1">
                            <span>Company</span> <span className="text-rose-500">*</span>
                            <span title="Your legal registered business name" className="text-gray-400 cursor-help">
                              <HelpCircle className="w-3.5 h-3.5" />
                            </span>
                          </label>
                          <div className="flex rounded-lg border border-gray-300 overflow-hidden focus-within:border-[#1a237e]">
                            <span className="bg-gray-50 px-3 flex items-center justify-center border-r border-gray-300 text-gray-400">
                              <Building className="w-4 h-4" />
                            </span>
                            <input
                              type="text"
                              required
                              value={company.company_name}
                              onChange={(e) => setCompany({ ...company, company_name: e.target.value })}
                              className="w-full p-2.5 focus:outline-none"
                            />
                          </div>
                        </div>

                        <div>
                          <label className="block font-semibold text-gray-700 mb-1">GST</label>
                          <input
                            type="text"
                            value={company.gstin}
                            onChange={(e) => setCompany({ ...company, gstin: e.target.value })}
                            className="w-full border border-gray-300 rounded-lg p-2.5 font-mono uppercase focus:border-[#1a237e] focus:outline-none"
                          />
                        </div>
                      </div>

                      {/* Right: Address with pencil icon */}
                      <div>
                        <div className="flex items-center justify-between mb-1">
                          <label className="font-semibold text-gray-700 flex items-center gap-1">
                            <span>Address</span>
                            <button
                              type="button"
                              onClick={() => {
                                setTempBillingAddress(company.billing_address || '');
                                setIsEditingBillingAddress(true);
                              }}
                              className="text-[#1a237e] hover:text-[#283593] p-1 cursor-pointer"
                              title="Edit address"
                            >
                              <Pencil className="w-3.5 h-3.5" />
                            </button>
                          </label>
                        </div>

                        {isEditingBillingAddress ? (
                          <div className="space-y-2">
                            <textarea
                              rows={4}
                              value={tempBillingAddress}
                              onChange={(e) => setTempBillingAddress(e.target.value)}
                              className="w-full border border-[#1a237e] rounded-lg p-3 text-xs focus:outline-none"
                            />
                            <div className="flex justify-end gap-2">
                              <button
                                type="button"
                                onClick={() => setIsEditingBillingAddress(false)}
                                className="px-3 py-1 border border-gray-300 rounded text-xs hover:bg-gray-50 cursor-pointer"
                              >
                                Cancel
                              </button>
                              <button
                                type="button"
                                onClick={handleSaveBillingAddress}
                                className="px-3 py-1 bg-[#1a237e] text-white rounded text-xs font-semibold cursor-pointer"
                              >
                                Update Address
                              </button>
                            </div>
                          </div>
                        ) : (
                          <div className="p-4 rounded-xl border border-gray-200 bg-gray-50/50 flex items-start space-x-3 min-h-[110px]">
                            <MapPin className="w-4 h-4 text-gray-500 shrink-0 mt-0.5" />
                            <p className="text-gray-700 leading-relaxed font-medium">
                              {company.billing_address || '1103, R K World Tower , Near Shitalpark , Nr. Ayodhyachowk , 150ft Ring Road, RAJKOT, GUJARAT, India - 360006.'}
                            </p>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Save & Cancel Buttons */}
                  <div className="pt-2 flex items-center space-x-2">
                    <button
                      type="submit"
                      className="px-5 py-2 bg-[#1a237e] hover:bg-[#283593] text-white rounded-md font-semibold shadow-xs cursor-pointer transition-colors"
                    >
                      Save
                    </button>
                    <button
                      type="button"
                      onClick={() => {}}
                      className="px-4 py-2 border border-gray-300 hover:bg-gray-100 text-gray-700 rounded-md font-semibold cursor-pointer transition-colors"
                    >
                      Cancel
                    </button>
                  </div>
                </form>
              )}

              {/* SUB-TAB B: OFFICES TABLE (Screenshot 154128) */}
              {companySubTab === 'offices' && (
                <div className="bg-white rounded-xl border border-gray-200 shadow-2xs overflow-hidden space-y-4 text-xs">
                  {/* Top Header Bar with Add Office */}
                  <div className="p-4 border-b border-gray-100 flex items-center justify-between">
                    <div>
                      <h3 className="font-bold text-sm text-gray-900">Branch & Registered Offices</h3>
                      <p className="text-gray-500 text-[11px]">Geo-fenced office locations for employee check-in and attendance</p>
                    </div>
                    <button
                      type="button"
                      onClick={handleOpenAddOffice}
                      className="inline-flex items-center space-x-1.5 px-3.5 py-1.5 bg-[#1a237e] hover:bg-[#283593] text-white rounded-md text-xs font-semibold shadow-xs cursor-pointer transition-colors"
                    >
                      <Plus className="w-4 h-4" />
                      <span>Add Office</span>
                    </button>
                  </div>

                  {/* Offices Table */}
                  <div className="overflow-x-auto">
                    <table className="w-full text-left text-xs text-gray-700">
                      <thead className="bg-gray-50 text-gray-500 font-semibold text-[11px] border-b border-gray-200">
                        <tr>
                          <th className="px-4 py-3">
                            <div className="flex items-center space-x-1 cursor-pointer">
                              <span>Name</span>
                              <ArrowUpDown className="w-3 h-3 text-gray-400" />
                            </div>
                          </th>
                          <th className="px-4 py-3">Address</th>
                          <th className="px-4 py-3 text-center">Location</th>
                          <th className="px-4 py-3 text-center">Users</th>
                          <th className="px-4 py-3 text-right"></th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-100">
                        {offices.map((off) => (
                          <tr key={off.id} className="hover:bg-gray-50/70 transition-colors">
                            <td className="px-4 py-3.5 font-bold text-gray-900">
                              <div className="flex items-center space-x-2">
                                <span>{off.name}</span>
                                {off.is_default && (
                                  <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#1a237e]/10 text-[#1a237e]">
                                    Default
                                  </span>
                                )}
                              </div>
                            </td>
                            <td className="px-4 py-3.5 text-gray-700 max-w-md">
                              {off.address}
                            </td>
                            <td className="px-4 py-3.5 text-center">
                              <button
                                type="button"
                                onClick={() => handleOpenMapFromRow(off)}
                                className="p-1 text-[#1a237e] hover:bg-[#1a237e]/10 rounded-md transition-colors cursor-pointer"
                                title="View Location on Map"
                              >
                                <MapPin className="w-4 h-4" />
                              </button>
                            </td>
                            <td className="px-4 py-3.5 text-center font-bold text-gray-800">
                              {off.users_count || 5}
                            </td>
                            <td className="px-4 py-3.5 text-right relative">
                              <button
                                type="button"
                                onClick={() =>
                                  setActiveOfficeMenuId(activeOfficeMenuId === off.id ? null : off.id)
                                }
                                className="p-1.5 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-md cursor-pointer"
                              >
                                <MoreHorizontal className="w-4 h-4" />
                              </button>

                              {activeOfficeMenuId === off.id && (
                                <div className="absolute right-4 top-10 z-50 w-36 bg-white rounded-lg shadow-xl border border-gray-200 py-1 text-xs animate-in fade-in">
                                  <button
                                    type="button"
                                    onClick={() => handleOpenEditOffice(off)}
                                    className="w-full text-left px-3 py-1.5 hover:bg-gray-50 flex items-center space-x-2 text-gray-700 cursor-pointer"
                                  >
                                    <Pencil className="w-3.5 h-3.5" />
                                    <span>Edit</span>
                                  </button>
                                  {!off.is_default && (
                                    <button
                                      type="button"
                                      onClick={() => handleSetDefaultOffice(off.id)}
                                      className="w-full text-left px-3 py-1.5 hover:bg-gray-50 flex items-center space-x-2 text-gray-700 cursor-pointer"
                                    >
                                      <Star className="w-3.5 h-3.5 text-emerald-600" />
                                      <span>Set Default</span>
                                    </button>
                                  )}
                                  <button
                                    type="button"
                                    onClick={() => handleDeleteOffice(off)}
                                    className="w-full text-left px-3 py-1.5 hover:bg-rose-50 text-rose-600 flex items-center space-x-2 cursor-pointer"
                                  >
                                    <Trash2 className="w-3.5 h-3.5" />
                                    <span>Delete</span>
                                  </button>
                                </div>
                              )}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>

                  {/* Pagination matching Screenshot 154128 */}
                  <div className="p-4 border-t border-gray-100 flex items-center justify-end space-x-3 text-xs text-gray-500">
                    <span>Showing 1 - {offices.length} of {offices.length}</span>
                    <select
                      className="border border-gray-300 rounded px-2 py-1 text-xs bg-white text-gray-700"
                      defaultValue={10}
                    >
                      <option value={10}>10</option>
                      <option value={25}>25</option>
                    </select>
                    <div className="flex items-center space-x-1">
                      <button disabled className="p-1 rounded text-gray-300 cursor-not-allowed">
                        <ChevronLeft className="w-4 h-4" />
                      </button>
                      <button className="w-6 h-6 rounded bg-[#1a237e] text-white font-bold flex items-center justify-center">
                        1
                      </button>
                      <button disabled className="p-1 rounded text-gray-300 cursor-not-allowed">
                        <ChevronRight className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              )}

              {/* SUB-TAB C: SETTINGS (Screenshot 154203) */}
              {companySubTab === 'settings' && (
                <form onSubmit={handleSaveCompany} className="bg-white p-6 rounded-xl border border-gray-200 shadow-2xs space-y-4 text-xs">
                  {companySavedSuccess && (
                    <div className="p-3 bg-emerald-50 border border-emerald-200 rounded-lg text-emerald-800 font-semibold flex items-center gap-2">
                      <CheckCircle className="w-4 h-4 text-emerald-600" />
                      <span>Company settings saved successfully!</span>
                    </div>
                  )}

                  {/* Timezone */}
                  <div className="max-w-xl">
                    <label className="block font-semibold text-gray-700 mb-1">
                      Timezone <span className="text-rose-500">*</span>
                    </label>
                    <select
                      value={company.timezone}
                      onChange={(e) => setCompany({ ...company, timezone: e.target.value })}
                      className="w-full border border-gray-300 rounded-lg p-2.5 bg-white text-gray-700 focus:border-[#1a237e] focus:outline-none"
                    >
                      <option value="Asia/Kolkata (GMT+5:30)">Asia/Kolkata (GMT+5:30)</option>
                      <option value="GMT+5:30">GMT+5:30 (India Standard Time)</option>
                      <option value="UTC">UTC</option>
                    </select>
                  </div>

                  {/* Currency */}
                  <div className="max-w-xl">
                    <label className="block font-semibold text-gray-700 mb-1">
                      Currency <span className="text-rose-500">*</span>
                    </label>
                    <select
                      value={company.currency}
                      onChange={(e) => setCompany({ ...company, currency: e.target.value })}
                      className="w-full border border-gray-300 rounded-lg p-2.5 bg-white text-gray-700 focus:border-[#1a237e] focus:outline-none"
                    >
                      <option value="India Rupee">India Rupee (₹)</option>
                      <option value="INR">INR (₹)</option>
                      <option value="USD">USD ($)</option>
                    </select>
                  </div>

                  {/* DSR Email Checkbox */}
                  <div className="pt-1">
                    <label className="flex items-center space-x-2 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={company.is_dsr_email}
                        onChange={(e) => setCompany({ ...company, is_dsr_email: e.target.checked })}
                        className="rounded text-[#1a237e] focus:ring-[#1a237e]"
                      />
                      <span className="font-semibold text-gray-700">DSR Email</span>
                    </label>
                  </div>

                  {/* Save & Cancel */}
                  <div className="pt-3 border-t border-gray-100 flex items-center space-x-2">
                    <button
                      type="submit"
                      className="px-5 py-2 bg-[#1a237e] hover:bg-[#283593] text-white rounded-md font-semibold shadow-xs cursor-pointer transition-colors"
                    >
                      Save
                    </button>
                    <button
                      type="button"
                      onClick={() => {}}
                      className="px-4 py-2 border border-gray-300 hover:bg-gray-100 text-gray-700 rounded-md font-semibold cursor-pointer transition-colors"
                    >
                      Cancel
                    </button>
                  </div>
                </form>
              )}

              {/* SUB-TAB D: REMINDERS */}
              {companySubTab === 'reminders' && (
                <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-2xs space-y-4 text-xs">
                  <h3 className="font-bold text-sm text-gray-900 border-b border-gray-100 pb-2">
                    Automated Notifications & Reminders
                  </h3>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label className="block font-semibold text-gray-700 mb-1">
                        Daily Follow-Up Digest Time
                      </label>
                      <input
                        type="text"
                        defaultValue="10:00 AM"
                        className="w-full border border-gray-300 rounded-lg p-2.5"
                      />
                    </div>
                    <div>
                      <label className="block font-semibold text-gray-700 mb-1">
                        Invoice Due Date Advance Notice (Days)
                      </label>
                      <input
                        type="number"
                        defaultValue={3}
                        className="w-full border border-gray-300 rounded-lg p-2.5"
                      />
                    </div>
                  </div>
                  <div className="pt-2 flex items-center space-x-2">
                    <button
                      type="button"
                      onClick={() => alert('Reminder configurations saved.')}
                      className="px-5 py-2 bg-[#1a237e] hover:bg-[#283593] text-white rounded-md font-semibold shadow-xs cursor-pointer"
                    >
                      Save
                    </button>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* SCREEN 3: USERS & TEAM (Parity retained) */}
          {activeTab === 'users' && (
            <div className="space-y-3">
              {/* License Alert Banner */}
              <div className="bg-gradient-to-r from-blue-50/90 via-indigo-50/70 to-blue-50/90 border border-blue-200/80 rounded-xl p-3.5 shadow-2xs flex flex-wrap items-center justify-between gap-3 text-xs">
                <div className="flex items-center space-x-3">
                  <div className="w-9 h-9 rounded-lg bg-[#3949ab] text-white flex items-center justify-center shrink-0 shadow-xs">
                    <ShieldCheck className="w-5 h-5 text-white" />
                  </div>
                  <div>
                    <div className="flex items-center space-x-2">
                      <span className="font-bold text-gray-900 text-sm">Workspace License Allocation</span>
                      <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#3949ab] text-white">
                        Enterprise Workspace
                      </span>
                    </div>
                    <p className="text-gray-600 text-[11px] mt-0.5">
                      Real-time GPS tracking, attendance geo-fencing, and granular role permissions enabled.
                    </p>
                  </div>
                </div>

                <div className="flex items-center space-x-3">
                  <div className="text-right">
                    <div className="text-xs font-bold text-gray-800">
                      Active Users: <span className="text-[#3949ab] font-extrabold">{activeUsersCount}</span> / {totalLicenseCount} Licenses
                    </div>
                    <div className="w-32 bg-gray-200 h-1.5 rounded-full overflow-hidden mt-1">
                      <div
                        className="bg-[#3949ab] h-full rounded-full transition-all duration-300"
                        style={{ width: `${Math.min(100, (activeUsersCount / totalLicenseCount) * 100)}%` }}
                      />
                    </div>
                  </div>
                  <span className="px-2.5 py-1 bg-emerald-100 text-emerald-800 text-[11px] font-bold rounded-lg border border-emerald-200">
                    {totalLicenseCount - activeUsersCount} Free Seats
                  </span>
                </div>
              </div>

              {/* Users Filter Block */}
              <div className="bg-white rounded-xl border border-gray-200 shadow-2xs p-3.5 space-y-3">
                <div className="flex flex-wrap items-center justify-between gap-2.5">
                  <div className="flex flex-wrap items-center gap-2 flex-1 min-w-[280px]">
                    <div className="relative flex-1 min-w-[200px] max-w-sm">
                      <Search className="w-3.5 h-3.5 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                      <input
                        type="text"
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        placeholder="Search by name, mobile, email, code..."
                        className="w-full pl-8 pr-7 py-1.5 text-xs border border-gray-200 rounded-lg bg-gray-50/50 focus:bg-white focus:outline-none focus:ring-1 focus:ring-[#3949ab] focus:border-[#3949ab] transition-colors"
                      />
                      {searchQuery && (
                        <button
                          onClick={() => setSearchQuery('')}
                          className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                        >
                          <X className="w-3.5 h-3.5" />
                        </button>
                      )}
                    </div>

                    <select
                      value={roleFilter}
                      onChange={(e) => setRoleFilter(e.target.value as typeof roleFilter)}
                      className="px-2.5 py-1.5 text-xs border border-gray-200 rounded-lg bg-white text-gray-700 focus:outline-none focus:ring-1 focus:ring-[#3949ab] cursor-pointer"
                    >
                      <option value="all">All Roles</option>
                      <option value="Admin">Admin</option>
                      <option value="Manager">Manager</option>
                      <option value="Staff">Field Staff</option>
                    </select>

                    <select
                      value={statusFilter}
                      onChange={(e) => setStatusFilter(e.target.value as typeof statusFilter)}
                      className="px-2.5 py-1.5 text-xs border border-gray-200 rounded-lg bg-white text-gray-700 focus:outline-none focus:ring-1 focus:ring-[#3949ab] cursor-pointer"
                    >
                      <option value="all">All Status</option>
                      <option value="active">Active</option>
                      <option value="inactive">Inactive</option>
                    </select>

                    <select
                      value={trackingFilter}
                      onChange={(e) => setTrackingFilter(e.target.value as typeof trackingFilter)}
                      className="px-2.5 py-1.5 text-xs border border-gray-200 rounded-lg bg-white text-gray-700 focus:outline-none focus:ring-1 focus:ring-[#3949ab] cursor-pointer"
                    >
                      <option value="all">All GPS Tracking</option>
                      <option value="active">GPS Enabled</option>
                      <option value="disabled">GPS Disabled</option>
                    </select>

                    {hasActiveFilters && (
                      <button
                        onClick={resetAllFilters}
                        className="inline-flex items-center gap-1 text-[11px] font-semibold text-rose-600 hover:text-rose-700 px-2 py-1 rounded-md hover:bg-rose-50 transition-colors cursor-pointer"
                      >
                        <RotateCcw className="w-3 h-3" />
                        <span>Clear</span>
                      </button>
                    )}
                  </div>

                  <div className="flex items-center gap-2">
                    <div className="relative" ref={columnsDropdownRef}>
                      <button
                        type="button"
                        onClick={() => setIsColumnsDropdownOpen((v) => !v)}
                        className="inline-flex items-center space-x-1.5 px-3 py-1.5 border border-gray-200 rounded-lg text-xs font-semibold text-gray-700 bg-white hover:bg-gray-50 transition-colors cursor-pointer shadow-2xs"
                      >
                        <SlidersHorizontal className="w-3.5 h-3.5 text-[#3949ab]" />
                        <span>Columns</span>
                      </button>

                      {isColumnsDropdownOpen && (
                        <div className="absolute right-0 top-9 z-50 w-52 bg-white rounded-xl shadow-xl border border-gray-200 p-2 text-xs space-y-1 animate-in fade-in zoom-in-95">
                          <div className="px-2 py-1 text-[11px] font-bold text-gray-500 uppercase tracking-wider border-b border-gray-100 flex items-center justify-between">
                            <span>Show/Hide Columns</span>
                            <button
                              onClick={() => setIsColumnsDropdownOpen(false)}
                              className="text-gray-400 hover:text-gray-600"
                            >
                              <X className="w-3.5 h-3.5" />
                            </button>
                          </div>
                          <div className="max-h-60 overflow-y-auto space-y-0.5 pt-1">
                            {AVAILABLE_COLUMNS.map((col) => {
                              const isChecked = visibleColumns[col.key] ?? true;
                              return (
                                <label
                                  key={col.key}
                                  className={`flex items-center space-x-2 px-2 py-1.5 rounded-md hover:bg-gray-50 cursor-pointer ${
                                    col.locked ? 'opacity-60 cursor-not-allowed' : ''
                                  }`}
                                >
                                  <input
                                    type="checkbox"
                                    disabled={col.locked}
                                    checked={isChecked}
                                    onChange={() => !col.locked && toggleColumnVisibility(col.key)}
                                    className="rounded text-[#3949ab] focus:ring-[#3949ab]"
                                  />
                                  <span className="text-gray-700 text-xs font-medium">{col.label}</span>
                                </label>
                              );
                            })}
                          </div>
                        </div>
                      )}
                    </div>

                    <button
                      onClick={handleOpenAddUser}
                      className="inline-flex items-center space-x-1.5 px-3.5 py-1.5 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-lg text-xs font-semibold shadow-xs cursor-pointer transition-colors"
                    >
                      <Plus className="w-4 h-4" />
                      <span>Add User</span>
                    </button>
                  </div>
                </div>
              </div>

              {/* Users Table */}
              <div className="bg-white rounded-xl border border-gray-200 shadow-2xs overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs text-gray-700">
                    <thead className="bg-gray-50 text-gray-500 font-semibold uppercase text-[11px] border-b border-gray-200">
                      <tr>
                        {visibleColumns.user_code && <th className="px-4 py-3">ID</th>}
                        {visibleColumns.name && <th className="px-4 py-3">Member Name</th>}
                        {visibleColumns.mobile && <th className="px-4 py-3">Mobile</th>}
                        {visibleColumns.email && <th className="px-4 py-3">Email</th>}
                        {visibleColumns.role && <th className="px-4 py-3">Role</th>}
                        {visibleColumns.reporting_head && <th className="px-4 py-3">Reporting Head</th>}
                        {visibleColumns.location_tracking && <th className="px-4 py-3 text-center">GPS Tracking & Live Map</th>}
                        {visibleColumns.last_login && <th className="px-4 py-3">Last Login / Device</th>}
                        {visibleColumns.status && <th className="px-4 py-3 text-center">Status</th>}
                        {visibleColumns.actions && <th className="px-4 py-3 text-right">Actions</th>}
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100">
                      {paginatedUsers.map((u) => (
                        <tr key={u.id} className="hover:bg-gray-50/80 transition-colors">
                          {visibleColumns.user_code && (
                            <td className="px-4 py-3 font-mono font-bold text-gray-900">#{u.user_code}</td>
                          )}
                          {visibleColumns.name && (
                            <td className="px-4 py-3">
                              <div className="flex items-center space-x-2.5">
                                <div className="relative">
                                  <div className="w-7 h-7 rounded-full bg-[#3949ab] text-white font-bold flex items-center justify-center text-[10px] shadow-2xs">
                                    {u.first_name[0]}{u.last_name[0]}
                                  </div>
                                  <span
                                    className={`absolute -bottom-0.5 -right-0.5 w-2.5 h-2.5 rounded-full border-2 border-white ${
                                      u.is_active ? 'bg-emerald-500' : 'bg-gray-300'
                                    }`}
                                  />
                                </div>
                                <div>
                                  <button
                                    type="button"
                                    onClick={() => handleOpenEditUser(u)}
                                    className="font-bold text-gray-900 hover:text-[#3949ab] hover:underline text-left cursor-pointer"
                                  >
                                    {u.first_name} {u.last_name}
                                  </button>
                                  <div className="text-[10px] text-gray-400">
                                    {u.role === 'Admin' ? 'System Administrator' : u.role === 'Manager' ? 'Branch / Team Manager' : 'Field Sales Executive'}
                                  </div>
                                </div>
                              </div>
                            </td>
                          )}
                          {visibleColumns.mobile && (
                            <td className="px-4 py-3">
                              <a href={`tel:${u.mobile}`} className="inline-flex items-center gap-1 text-gray-800 hover:text-[#3949ab] font-medium">
                                <Phone className="w-3 h-3 text-gray-400" />
                                <span>{u.mobile}</span>
                              </a>
                            </td>
                          )}
                          {visibleColumns.email && (
                            <td className="px-4 py-3">
                              {u.email ? (
                                <a href={`mailto:${u.email}`} className="inline-flex items-center gap-1 text-gray-600 hover:text-[#3949ab]">
                                  <Mail className="w-3 h-3 text-gray-400" />
                                  <span className="truncate max-w-[150px]">{u.email}</span>
                                </a>
                              ) : (
                                <span className="text-gray-400">—</span>
                              )}
                            </td>
                          )}
                          {visibleColumns.role && (
                            <td className="px-4 py-3">
                              <span
                                className={`px-2 py-0.5 rounded-full text-[11px] font-semibold ${
                                  u.role === 'Admin'
                                    ? 'bg-purple-50 text-purple-700 border border-purple-200'
                                    : u.role === 'Manager'
                                    ? 'bg-blue-50 text-blue-700 border border-blue-200'
                                    : 'bg-gray-100 text-gray-700 border border-gray-200'
                                }`}
                              >
                                {u.role}
                              </span>
                            </td>
                          )}
                          {visibleColumns.reporting_head && (
                            <td className="px-4 py-3 text-gray-600 font-medium">{u.reporting_head || '—'}</td>
                          )}
                          {visibleColumns.location_tracking && (
                            <td className="px-4 py-3 text-center">
                              <div className="inline-flex items-center gap-1.5 justify-center">
                                <button
                                  onClick={() => onToggleTracking(u.id)}
                                  className="cursor-pointer inline-flex items-center gap-1 font-semibold text-xs transition-colors"
                                >
                                  {u.location_tracking ? (
                                    <span className="text-emerald-600 flex items-center gap-1">
                                      <ToggleRight className="w-5 h-5 text-emerald-600" /> Active
                                    </span>
                                  ) : (
                                    <span className="text-gray-400 flex items-center gap-1">
                                      <ToggleLeft className="w-5 h-5 text-gray-400" /> Disabled
                                    </span>
                                  )}
                                </button>
                                <button
                                  type="button"
                                  onClick={() => setSelectedLocationUser(u)}
                                  className="p-1 rounded-md text-[#3949ab] hover:bg-[#3949ab]/10 transition-colors cursor-pointer"
                                  title="View GPS location"
                                >
                                  <MapPin className="w-4 h-4" />
                                </button>
                              </div>
                            </td>
                          )}
                          {visibleColumns.last_login && (
                            <td className="px-4 py-3">
                              <div className="space-y-0.5">
                                <div className="flex items-center gap-1 text-gray-800 font-medium">
                                  <Clock className="w-3 h-3 text-gray-400" />
                                  <span>{u.last_login || 'Today, 10:45 AM'}</span>
                                </div>
                                <div className="flex items-center gap-1 text-[10px] text-gray-500">
                                  <Smartphone className="w-2.5 h-2.5 text-gray-400" />
                                  <span>{u.device_info || 'Android 14 (MyTeams v2.4)'}</span>
                                </div>
                              </div>
                            </td>
                          )}
                          {visibleColumns.status && (
                            <td className="px-4 py-3 text-center">
                              <button
                                onClick={() => onToggleActive(u.id)}
                                className={`px-2.5 py-0.5 rounded-full text-[11px] font-semibold cursor-pointer transition-colors ${
                                  u.is_active
                                    ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                                    : 'bg-rose-50 text-rose-700 border border-rose-200'
                                }`}
                              >
                                {u.is_active ? 'Active' : 'Inactive'}
                              </button>
                            </td>
                          )}
                          {visibleColumns.actions && (
                            <td className="px-4 py-3 text-right">
                              <div className="flex items-center justify-end space-x-1">
                                <button
                                  type="button"
                                  onClick={() => handleOpenEditUser(u)}
                                  className="p-1.5 text-gray-500 hover:text-[#3949ab] hover:bg-[#3949ab]/10 rounded-lg transition-colors cursor-pointer"
                                >
                                  <Pencil className="w-4 h-4" />
                                </button>
                                {onDeleteUser && (
                                  <button
                                    type="button"
                                    onClick={() => handleDeleteUser(u)}
                                    className="p-1.5 text-gray-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors cursor-pointer"
                                  >
                                    <Trash2 className="w-4 h-4" />
                                  </button>
                                )}
                              </div>
                            </td>
                          )}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                {/* Bottom Bar: Download All & Pagination */}
                <div className="w-full px-4 py-3 border-t border-gray-200 flex flex-wrap items-center justify-between gap-3 text-xs text-gray-500 bg-white">
                  <div>
                    <button
                      onClick={handleDownloadAllUsers}
                      className="inline-flex items-center gap-2 px-3.5 py-2 bg-[#3949ab] hover:bg-[#303f9f] text-white text-xs font-semibold rounded shadow-xs transition-colors cursor-pointer"
                    >
                      <Download className="w-4 h-4" />
                      <span>Download All</span>
                    </button>
                  </div>
                  <div className="flex flex-wrap items-center gap-3">
                    <span className="text-gray-500 text-xs">
                      Showing {filteredUsers.length === 0 ? 0 : (currentPage - 1) * itemsPerPage + 1} -{' '}
                      {Math.min(currentPage * itemsPerPage, filteredUsers.length)} of {filteredUsers.length.toLocaleString()}
                    </span>
                    <select
                      value={itemsPerPage}
                      onChange={(e) => {
                        setItemsPerPage(Number(e.target.value));
                        setCurrentPage(1);
                      }}
                      className="border border-gray-300 rounded px-2 py-1 text-xs text-gray-700 bg-white"
                    >
                      <option value={10}>10</option>
                      <option value={25}>25</option>
                      <option value={50}>50</option>
                    </select>
                    <div className="flex items-center gap-1">
                      <button
                        disabled={currentPage === 1}
                        onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                        className="min-w-[28px] h-7 px-1.5 rounded flex items-center justify-center text-[#3949ab] hover:bg-gray-100 disabled:text-gray-300 cursor-pointer"
                      >
                        <ChevronLeft className="w-4 h-4" />
                      </button>
                      {getPageNumbers(currentPage, totalPages).map((p, idx) => {
                        if (typeof p === 'string') {
                          return <span key={`ellipsis-${idx}`} className="px-1 text-gray-400">...</span>;
                        }
                        const isActive = p === currentPage;
                        return (
                          <button
                            key={`page-${p}`}
                            onClick={() => setCurrentPage(p)}
                            className={`min-w-[28px] h-7 px-2 rounded flex items-center justify-center text-xs cursor-pointer ${
                              isActive ? 'bg-[#3949ab] text-white font-semibold' : 'text-[#3949ab] hover:bg-gray-100'
                            }`}
                          >
                            {p}
                          </button>
                        );
                      })}
                      <button
                        disabled={currentPage === totalPages || filteredUsers.length === 0}
                        onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                        className="min-w-[28px] h-7 px-1.5 rounded flex items-center justify-center text-[#3949ab] hover:bg-gray-100 disabled:text-gray-300 cursor-pointer"
                      >
                        <ChevronRight className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* SCREEN 4: SALES & DOCUMENT SETTINGS */}
          {activeTab === 'sales_settings' && (
            <div className="space-y-3">
              <h2 className="text-base font-bold text-gray-900">Sales Settings</h2>
              <form onSubmit={handleSaveCompany} className="bg-white p-6 rounded-xl border border-gray-200 shadow-2xs space-y-4 text-xs">
                <h3 className="font-bold text-sm text-gray-900 border-b border-gray-100 pb-2">
                  Invoicing Rules, Prefixes & Banking Configuration
                </h3>

                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                  <div>
                    <label className="block font-semibold text-gray-700 mb-1">Tax Invoice Prefix</label>
                    <input
                      type="text"
                      value={company.invoice_prefix}
                      onChange={(e) => setCompany({ ...company, invoice_prefix: e.target.value })}
                      className="w-full border border-gray-300 rounded-lg p-2 font-mono uppercase"
                    />
                  </div>
                  <div>
                    <label className="block font-semibold text-gray-700 mb-1">Proforma Invoice Prefix</label>
                    <input
                      type="text"
                      value={company.proforma_prefix}
                      onChange={(e) => setCompany({ ...company, proforma_prefix: e.target.value })}
                      className="w-full border border-gray-300 rounded-lg p-2 font-mono uppercase"
                    />
                  </div>
                  <div>
                    <label className="block font-semibold text-gray-700 mb-1">Order Prefix</label>
                    <input
                      type="text"
                      value={company.order_prefix}
                      onChange={(e) => setCompany({ ...company, order_prefix: e.target.value })}
                      className="w-full border border-gray-300 rounded-lg p-2 font-mono uppercase"
                    />
                  </div>
                </div>

                <h4 className="font-bold text-gray-800 pt-2 text-xs uppercase tracking-wider">
                  Bank Account Details (Printed on Invoices & Proforma)
                </h4>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label className="block font-semibold text-gray-700 mb-1">Bank Name</label>
                    <input
                      type="text"
                      value={company.bank_name}
                      onChange={(e) => setCompany({ ...company, bank_name: e.target.value })}
                      className="w-full border border-gray-300 rounded-lg p-2"
                    />
                  </div>
                  <div>
                    <label className="block font-semibold text-gray-700 mb-1">Account Number</label>
                    <input
                      type="text"
                      value={company.bank_account_no}
                      onChange={(e) => setCompany({ ...company, bank_account_no: e.target.value })}
                      className="w-full border border-gray-300 rounded-lg p-2 font-mono"
                    />
                  </div>
                  <div>
                    <label className="block font-semibold text-gray-700 mb-1">IFSC Code</label>
                    <input
                      type="text"
                      value={company.bank_ifsc}
                      onChange={(e) => setCompany({ ...company, bank_ifsc: e.target.value })}
                      className="w-full border border-gray-300 rounded-lg p-2 font-mono uppercase"
                    />
                  </div>
                  <div>
                    <label className="block font-semibold text-gray-700 mb-1">UPI ID (QR Payment)</label>
                    <input
                      type="text"
                      value={company.upi_id}
                      onChange={(e) => setCompany({ ...company, upi_id: e.target.value })}
                      className="w-full border border-gray-300 rounded-lg p-2 font-mono"
                    />
                  </div>
                </div>

                <div>
                  <label className="block font-semibold text-gray-700 mb-1">Default Terms & Conditions</label>
                  <textarea
                    rows={3}
                    value={company.terms}
                    onChange={(e) => setCompany({ ...company, terms: e.target.value })}
                    className="w-full border border-gray-300 rounded-lg p-2"
                  />
                </div>

                <div className="pt-3 border-t border-gray-100 flex justify-end">
                  <button
                    type="submit"
                    className="inline-flex items-center space-x-1.5 px-5 py-2 bg-[#1a237e] hover:bg-[#283593] text-white rounded-lg font-semibold shadow-xs cursor-pointer"
                  >
                    <Save className="w-4 h-4" />
                    <span>Save Invoicing Settings</span>
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* SCREEN 5: MESSAGE TEMPLATES */}
          {activeTab === 'templates' && (
            <div className="space-y-4">
              <h2 className="text-base font-bold text-gray-900">Message Templates</h2>
              <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-2xs space-y-5 text-xs">
                <div className="flex flex-wrap items-center justify-between gap-3 border-b border-gray-100 pb-3">
                  <div>
                    <h3 className="font-bold text-sm text-gray-900 flex items-center gap-2">
                      <MessageSquare className="w-4 h-4 text-[#1a237e]" />
                      <span>WhatsApp & Notification Templates</span>
                    </h3>
                    <p className="text-gray-500 text-[11px] mt-0.5">
                      Configure message templates and set the default template automatically used when contacting leads on WhatsApp.
                    </p>
                  </div>
                  <button
                    onClick={handleOpenAddTemplate}
                    className="inline-flex items-center space-x-1.5 px-3.5 py-2 bg-[#1a237e] hover:bg-[#283593] text-white rounded-lg text-xs font-semibold shadow-xs cursor-pointer transition-colors"
                  >
                    <Plus className="w-4 h-4" />
                    <span>Add Template</span>
                  </button>
                </div>

                <div className="flex items-center gap-1.5 overflow-x-auto pb-1">
                  {(['All', 'Leads', 'Customers', 'Invoices', 'Proforma Invoices', 'General'] as const).map((mod) => {
                    const isActive = templateFilter === mod;
                    const count = mod === 'All' ? templates.length : templates.filter((t) => t.module === mod).length;
                    return (
                      <button
                        key={mod}
                        onClick={() => setTemplateFilter(mod)}
                        className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all cursor-pointer whitespace-nowrap flex items-center gap-1.5 ${
                          isActive
                            ? 'bg-[#1a237e] text-white shadow-xs'
                            : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                        }`}
                      >
                        <span>{mod}</span>
                        <span className={`text-[10px] px-1.5 py-0.2 rounded-full ${isActive ? 'bg-white/20 text-white' : 'bg-gray-200 text-gray-700'}`}>
                          {count}
                        </span>
                      </button>
                    );
                  })}
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {filteredTemplates.map((tmpl) => {
                    const samplePreview = templateService.formatMessage(tmpl.content, {
                      name: 'Rajesh Patel',
                      companyName: 'Shreeji Enterprise',
                      brand_name: company.brand_name || 'IV SQUARE STRUCTURE INDIA PVT LTD',
                      phone: '9876543210',
                      stage: 'Contacted',
                      id: 'INV-2026-081',
                      total: '₹45,000',
                    });

                    return (
                      <div
                        key={tmpl.id}
                        className={`p-4 rounded-xl border transition-all flex flex-col justify-between space-y-3 ${
                          tmpl.is_default
                            ? 'border-emerald-300 bg-emerald-50/20 shadow-2xs'
                            : 'border-gray-200 bg-white hover:border-gray-300'
                        }`}
                      >
                        <div>
                          <div className="flex items-start justify-between gap-2">
                            <div className="space-y-1">
                              <div className="flex items-center space-x-2">
                                <span className="font-bold text-gray-900 text-sm">{tmpl.name}</span>
                                <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-blue-50 text-blue-700 border border-blue-200">
                                  {tmpl.module}
                                </span>
                              </div>
                            </div>

                            <div className="flex items-center space-x-1 shrink-0">
                              <button
                                type="button"
                                onClick={() => handleOpenEditTemplate(tmpl)}
                                className="p-1.5 text-gray-500 hover:text-[#1a237e] hover:bg-[#1a237e]/10 rounded-lg transition-colors cursor-pointer"
                                title="Edit Template"
                              >
                                <Pencil className="w-3.5 h-3.5" />
                              </button>
                              <button
                                type="button"
                                onClick={() => handleDeleteTemplate(tmpl)}
                                className="p-1.5 text-gray-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors cursor-pointer"
                                title="Delete Template"
                              >
                                <Trash2 className="w-3.5 h-3.5" />
                              </button>
                            </div>
                          </div>

                          <div className="mt-2 flex items-center justify-between">
                            {tmpl.is_default ? (
                              <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-emerald-100 text-emerald-800 border border-emerald-300">
                                <Star className="w-3 h-3 fill-emerald-600 text-emerald-600" />
                                <span>Default WhatsApp Message</span>
                              </span>
                            ) : (
                              <button
                                type="button"
                                onClick={() => handleToggleDefaultTemplate(tmpl.id, tmpl.module)}
                                className="inline-flex items-center gap-1 text-[11px] font-semibold text-gray-500 hover:text-emerald-700 hover:bg-emerald-50 px-2 py-0.5 rounded-md border border-gray-200 transition-colors cursor-pointer"
                              >
                                <Star className="w-3 h-3 text-gray-400" />
                                <span>Set as Default</span>
                              </button>
                            )}
                            <span className="text-[10px] text-gray-400">
                              {tmpl.module === 'Leads' ? 'Used in Lead Detail WhatsApp' : ''}
                            </span>
                          </div>
                        </div>

                        <div className="p-3 bg-gray-50 rounded-lg border border-gray-100 font-mono text-[11px] text-gray-700 whitespace-pre-wrap leading-relaxed">
                          {tmpl.content}
                        </div>

                        <div className="pt-2 border-t border-gray-100 space-y-1">
                          <span className="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">
                            Live Lead Preview (Rajesh Patel):
                          </span>
                          <div className="p-2.5 bg-emerald-50/70 rounded-lg border border-emerald-100 text-[11px] text-emerald-900 font-sans leading-relaxed">
                            💬 &ldquo;{samplePreview}&rdquo;
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          )}

          
          {/* ======================================================== */}
          {/* SCREEN 7: ROLES & PERMISSIONS                            */}
          {/* (Screenshots 161941, 161958, 162039, 162052)            */}
          {/* ======================================================== */}
          {activeTab === 'roles' && (
            <div className="space-y-4">
              {roleSavedSuccess && (
                <div className="p-3 bg-green-50 border border-green-200 text-green-700 rounded-lg flex items-center space-x-2 text-xs font-semibold animate-in fade-in">
                  <CheckCircle className="w-4 h-4 text-green-600 flex-shrink-0" />
                  <span>Role permissions updated successfully! Module visibility and user access controls updated.</span>
                </div>
              )}

              {rolesSubView === 'list' ? (
                /* VIEW 1: ROLES MATRIX TABLE (Screenshots 161941 & 161958) */
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <h2 className="text-lg font-bold text-gray-900">Roles</h2>
                    </div>
                    <button
                      type="button"
                      onClick={handleOpenAddRole}
                      className="px-4 py-2 bg-[#1a237e] hover:bg-[#151c65] text-white rounded-lg font-bold text-xs flex items-center space-x-1.5 shadow-sm transition-all cursor-pointer"
                    >
                      <Plus className="w-4 h-4" />
                      <span>Add Role</span>
                    </button>
                  </div>

                  {/* Matrix Data Table */}
                  <div className="bg-white border border-gray-200 rounded-xl shadow-xs overflow-hidden">
                    <div className="overflow-x-auto">
                      <table className="w-full text-xs text-left border-collapse min-w-[1500px]">
                        <thead>
                          <tr className="bg-[#f8fafc] text-gray-700 font-bold border-b border-gray-200 select-none">
                            <th className="py-3 px-4 min-w-[120px]">
                              <div className="flex items-center space-x-1 cursor-pointer">
                                <span>Name</span>
                                <ArrowUpDown className="w-3 h-3 text-gray-400" />
                              </div>
                            </th>
                            <th className="py-3 px-3 min-w-[100px]">
                              <div className="flex items-center space-x-1 cursor-pointer">
                                <span>Access</span>
                                <ArrowUpDown className="w-3 h-3 text-gray-400" />
                              </div>
                            </th>
                            <th className="py-3 px-3 min-w-[80px]">
                              <div className="flex items-center space-x-1 cursor-pointer">
                                <span>Users</span>
                                <ArrowUpDown className="w-3 h-3 text-gray-400" />
                              </div>
                            </th>
                            <th className="py-3 px-2 text-center min-w-[120px]">Location Tracking</th>
                            <th className="py-3 px-2 text-center min-w-[80px]">Visits</th>
                            <th className="py-3 px-2 text-center min-w-[80px]">Tasks</th>
                            <th className="py-3 px-2 text-center min-w-[80px]">Leads</th>
                            <th className="py-3 px-2 text-center min-w-[90px]">Customers</th>
                            <th className="py-3 px-2 text-center min-w-[90px]">Quotations</th>
                            <th className="py-3 px-2 text-center min-w-[130px]">Proforma Invoices</th>
                            <th className="py-3 px-2 text-center min-w-[90px]">Invoices</th>
                            <th className="py-3 px-2 text-center min-w-[80px]">Orders</th>
                            <th className="py-3 px-2 text-center min-w-[90px]">Inventory</th>
                            <th className="py-3 px-2 text-center min-w-[90px]">Payments</th>
                            <th className="py-3 px-2 text-center min-w-[90px]">Attendance</th>
                            <th className="py-3 px-2 text-center min-w-[80px]">Leaves</th>
                            <th className="py-3 px-2 text-center min-w-[90px]">Expenses</th>
                            <th className="py-3 px-2 text-center min-w-[80px]">Forms</th>
                            <th className="py-3 px-2 text-center min-w-[80px]">PMS</th>
                            <th className="py-3 px-2 text-center min-w-[80px]">Payroll</th>
                            <th className="py-3 px-3 text-center min-w-[50px]"></th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100">
                          {roles.map((role) => {
                            const userCount =
                              users.filter(
                                (u) => u.role.toLowerCase() === role.access.toLowerCase()
                              ).length || role.users_count;
                            const p = role.permissions;

                            return (
                              <tr
                                key={role.id}
                                className="hover:bg-blue-50/30 transition-colors group"
                              >
                                <td className="py-3 px-4 font-bold text-[#1a237e]">
                                  <button
                                    type="button"
                                    onClick={() => handleOpenEditRole(role)}
                                    className="hover:underline cursor-pointer text-left"
                                  >
                                    {role.name}
                                  </button>
                                </td>
                                <td className="py-3 px-3 text-gray-700">{role.access}</td>
                                <td className="py-3 px-3 font-semibold text-gray-900">{userCount}</td>
                                <td className="py-3 px-2 text-center">
                                  {p.location_tracking ? (
                                    <Check className="w-4 h-4 text-[#1a237e] stroke-[2.5] mx-auto" />
                                  ) : (
                                    <X className="w-4 h-4 text-gray-300 stroke-[2] mx-auto" />
                                  )}
                                </td>
                                <td className="py-3 px-2 text-center">
                                  {p.visits ? (
                                    <Check className="w-4 h-4 text-[#1a237e] stroke-[2.5] mx-auto" />
                                  ) : (
                                    <X className="w-4 h-4 text-gray-300 stroke-[2] mx-auto" />
                                  )}
                                </td>
                                <td className="py-3 px-2 text-center">
                                  {p.tasks ? (
                                    <Check className="w-4 h-4 text-[#1a237e] stroke-[2.5] mx-auto" />
                                  ) : (
                                    <X className="w-4 h-4 text-gray-300 stroke-[2] mx-auto" />
                                  )}
                                </td>
                                <td className="py-3 px-2 text-center">
                                  {p.leads?.enabled ? (
                                    <Check className="w-4 h-4 text-[#1a237e] stroke-[2.5] mx-auto" />
                                  ) : (
                                    <X className="w-4 h-4 text-gray-300 stroke-[2] mx-auto" />
                                  )}
                                </td>
                                <td className="py-3 px-2 text-center">
                                  {p.customers?.enabled ? (
                                    <Check className="w-4 h-4 text-[#1a237e] stroke-[2.5] mx-auto" />
                                  ) : (
                                    <X className="w-4 h-4 text-gray-300 stroke-[2] mx-auto" />
                                  )}
                                </td>
                                <td className="py-3 px-2 text-center">
                                  {p.quotations ? (
                                    <Check className="w-4 h-4 text-[#1a237e] stroke-[2.5] mx-auto" />
                                  ) : (
                                    <X className="w-4 h-4 text-gray-300 stroke-[2] mx-auto" />
                                  )}
                                </td>
                                <td className="py-3 px-2 text-center">
                                  {p.proforma_invoices?.enabled ? (
                                    <Check className="w-4 h-4 text-[#1a237e] stroke-[2.5] mx-auto" />
                                  ) : (
                                    <X className="w-4 h-4 text-gray-300 stroke-[2] mx-auto" />
                                  )}
                                </td>
                                <td className="py-3 px-2 text-center">
                                  {p.invoices?.enabled ? (
                                    <Check className="w-4 h-4 text-[#1a237e] stroke-[2.5] mx-auto" />
                                  ) : (
                                    <X className="w-4 h-4 text-gray-300 stroke-[2] mx-auto" />
                                  )}
                                </td>
                                <td className="py-3 px-2 text-center">
                                  {p.orders ? (
                                    <Check className="w-4 h-4 text-[#1a237e] stroke-[2.5] mx-auto" />
                                  ) : (
                                    <X className="w-4 h-4 text-gray-300 stroke-[2] mx-auto" />
                                  )}
                                </td>
                                <td className="py-3 px-2 text-center">
                                  {p.inventory?.enabled ? (
                                    <Check className="w-4 h-4 text-[#1a237e] stroke-[2.5] mx-auto" />
                                  ) : (
                                    <X className="w-4 h-4 text-gray-300 stroke-[2] mx-auto" />
                                  )}
                                </td>
                                <td className="py-3 px-2 text-center">
                                  {p.payments ? (
                                    <Check className="w-4 h-4 text-[#1a237e] stroke-[2.5] mx-auto" />
                                  ) : (
                                    <X className="w-4 h-4 text-gray-300 stroke-[2] mx-auto" />
                                  )}
                                </td>
                                <td className="py-3 px-2 text-center">
                                  {p.attendance ? (
                                    <Check className="w-4 h-4 text-[#1a237e] stroke-[2.5] mx-auto" />
                                  ) : (
                                    <X className="w-4 h-4 text-gray-300 stroke-[2] mx-auto" />
                                  )}
                                </td>
                                <td className="py-3 px-2 text-center">
                                  {p.leaves ? (
                                    <Check className="w-4 h-4 text-[#1a237e] stroke-[2.5] mx-auto" />
                                  ) : (
                                    <X className="w-4 h-4 text-gray-300 stroke-[2] mx-auto" />
                                  )}
                                </td>
                                <td className="py-3 px-2 text-center">
                                  {p.expenses?.enabled ? (
                                    <Check className="w-4 h-4 text-[#1a237e] stroke-[2.5] mx-auto" />
                                  ) : (
                                    <X className="w-4 h-4 text-gray-300 stroke-[2] mx-auto" />
                                  )}
                                </td>
                                <td className="py-3 px-2 text-center">
                                  {p.forms ? (
                                    <Check className="w-4 h-4 text-[#1a237e] stroke-[2.5] mx-auto" />
                                  ) : (
                                    <X className="w-4 h-4 text-gray-300 stroke-[2] mx-auto" />
                                  )}
                                </td>
                                <td className="py-3 px-2 text-center">
                                  {p.pms ? (
                                    <Check className="w-4 h-4 text-[#1a237e] stroke-[2.5] mx-auto" />
                                  ) : (
                                    <X className="w-4 h-4 text-gray-300 stroke-[2] mx-auto" />
                                  )}
                                </td>
                                <td className="py-3 px-2 text-center">
                                  {p.payroll ? (
                                    <Check className="w-4 h-4 text-[#1a237e] stroke-[2.5] mx-auto" />
                                  ) : (
                                    <X className="w-4 h-4 text-gray-300 stroke-[2] mx-auto" />
                                  )}
                                </td>
                                <td className="py-3 px-3 text-center relative">
                                  <button
                                    type="button"
                                    onClick={() =>
                                      setActiveRoleMenuId(
                                        activeRoleMenuId === role.id ? null : role.id
                                      )
                                    }
                                    className="p-1 hover:bg-gray-100 rounded text-[#1a237e] cursor-pointer"
                                  >
                                    <MoreHorizontal className="w-5 h-5" />
                                  </button>
                                  {activeRoleMenuId === role.id && (
                                    <div className="absolute right-3 top-8 z-30 w-32 bg-white border border-gray-200 rounded-lg shadow-xl py-1 text-xs">
                                      <button
                                        type="button"
                                        onClick={() => {
                                          setActiveRoleMenuId(null);
                                          handleOpenEditRole(role);
                                        }}
                                        className="w-full flex items-center space-x-2 px-3 py-2 text-gray-700 hover:bg-gray-50 cursor-pointer font-medium"
                                      >
                                        <Pencil className="w-3.5 h-3.5 text-[#1a237e]" />
                                        <span>Edit</span>
                                      </button>
                                      {!role.is_system && (
                                        <button
                                          type="button"
                                          onClick={() => {
                                            setActiveRoleMenuId(null);
                                            handleDeleteRole(role.id);
                                          }}
                                          className="w-full flex items-center space-x-2 px-3 py-2 text-red-600 hover:bg-red-50 cursor-pointer font-medium"
                                        >
                                          <Trash2 className="w-3.5 h-3.5 text-red-600" />
                                          <span>Delete</span>
                                        </button>
                                      )}
                                    </div>
                                  )}
                                </td>
                              </tr>
                            );
                          })}
                        </tbody>
                        <tfoot>
                          <tr className="bg-white border-t border-gray-200 font-bold">
                            <td className="py-3 px-4 text-gray-900">Total</td>
                            <td></td>
                            <td className="py-3 px-3 text-gray-900">
                              {roles.reduce((acc, r) => {
                                const c =
                                  users.filter(
                                    (u) => u.role.toLowerCase() === r.access.toLowerCase()
                                  ).length || r.users_count;
                                return acc + c;
                              }, 0)}
                            </td>
                            <td colSpan={18} className="py-3 px-4"></td>
                          </tr>
                        </tfoot>
                      </table>
                    </div>

                    {/* Pagination Bar */}
                    <div className="px-5 py-3 bg-white border-t border-gray-200 flex flex-col sm:flex-row items-center justify-between text-xs text-gray-500 gap-2">
                      <div>
                        Showing 1 - {roles.length} of {roles.length}
                      </div>
                      <div className="flex items-center space-x-3">
                        <div className="flex items-center space-x-1">
                          <select
                            value={rolePageSize}
                            onChange={(e) => setRolePageSize(Number(e.target.value))}
                            className="bg-gray-50 border border-gray-200 rounded px-2 py-1 text-xs text-gray-700"
                          >
                            <option value={10}>10</option>
                            <option value={25}>25</option>
                            <option value={50}>50</option>
                          </select>
                        </div>
                        <div className="flex items-center space-x-1">
                          <button
                            type="button"
                            disabled
                            className="p-1 rounded border border-gray-200 text-gray-400 cursor-not-allowed"
                          >
                            <ChevronLeft className="w-4 h-4" />
                          </button>
                          <button type="button" onClick={() => setRoleCurrentPage(1)} className="w-7 h-7 bg-[#1a237e] text-white rounded font-bold flex items-center justify-center cursor-pointer">{roleCurrentPage}</button>
                          <button
                            type="button"
                            disabled
                            className="p-1 rounded border border-gray-200 text-gray-400 cursor-not-allowed"
                          >
                            <ChevronRight className="w-4 h-4" />
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              ) : (
                /* VIEW 2: ADD / EDIT ROLE SCREEN (Screenshots 162039 & 162052) */
                <form onSubmit={handleSaveRole} className="space-y-4">
                  <div>
                    <h2 className="text-xl font-bold text-gray-900">
                      {formRoleName || 'Add Role'}
                    </h2>
                  </div>

                  {/* Top Card: Basic Info */}
                  <div className="bg-white border border-gray-200 rounded-xl p-5 shadow-xs">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <label className="block text-xs font-medium text-gray-700 mb-1">
                          Name <span className="text-red-500">*</span>
                        </label>
                        <input
                          type="text"
                          required
                          value={formRoleName}
                          onChange={(e) => setFormRoleName(e.target.value)}
                          placeholder="e.g. Admin, Manager, Sales Lead"
                          className="w-full px-3 py-2 border border-gray-200 rounded-lg text-xs font-semibold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#1a237e] bg-white"
                        />
                      </div>
                      <div>
                        <label className="block text-xs font-medium text-gray-700 mb-1">
                          Access <span className="text-red-500">*</span>
                        </label>
                        <div className="relative">
                          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-gray-400">
                            <Tag className="w-4 h-4" />
                          </div>
                          {rolesSubView === 'create' ? (
                            <select
                              value={formRoleAccess}
                              onChange={(e) => setFormRoleAccess(e.target.value)}
                              className="w-full pl-9 pr-3 py-2 bg-gray-50 border border-gray-200 rounded-lg text-xs font-semibold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#1a237e]"
                            >
                              <option value="Admin">Admin</option>
                              <option value="Manager">Manager</option>
                              <option value="Staff">Staff</option>
                            </select>
                          ) : (
                            <input
                              type="text"
                              value={formRoleAccess}
                              readOnly
                              className="w-full pl-9 pr-3 py-2 bg-gray-50 border border-gray-200 rounded-lg text-xs font-semibold text-gray-600 cursor-not-allowed"
                            />
                          )}
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Permissions Section */}
                  <div className="space-y-2.5">
                    <h3 className="text-sm font-bold text-gray-900 pt-1">Permissions</h3>

                    {/* 1. Location Tracking */}
                    <div className="bg-white border border-gray-200 rounded-lg px-4 py-3 flex items-center shadow-xs">
                      <label className="flex items-center space-x-3 cursor-pointer select-none">
                        <input
                          type="checkbox"
                          checked={formRolePermissions.location_tracking}
                          onChange={(e) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              location_tracking: e.target.checked,
                            })
                          }
                          className="w-4 h-4 rounded text-[#1a237e] border-gray-300"
                        />
                        <span className="text-xs font-semibold text-gray-800">
                          Location Tracking
                        </span>
                      </label>
                    </div>

                    {/* 2. Visits */}
                    <div className="bg-white border border-gray-200 rounded-lg px-4 py-3 flex items-center shadow-xs">
                      <label className="flex items-center space-x-3 cursor-pointer select-none">
                        <input
                          type="checkbox"
                          checked={formRolePermissions.visits}
                          onChange={(e) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              visits: e.target.checked,
                            })
                          }
                          className="w-4 h-4 rounded text-[#1a237e] border-gray-300"
                        />
                        <span className="text-xs font-semibold text-gray-800">Visits</span>
                      </label>
                    </div>

                    {/* 3. Tasks */}
                    <div className="bg-white border border-gray-200 rounded-lg px-4 py-3 flex items-center shadow-xs">
                      <label className="flex items-center space-x-3 cursor-pointer select-none">
                        <input
                          type="checkbox"
                          checked={formRolePermissions.tasks}
                          onChange={(e) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              tasks: e.target.checked,
                            })
                          }
                          className="w-4 h-4 rounded text-[#1a237e] border-gray-300"
                        />
                        <span className="text-xs font-semibold text-gray-800">Tasks</span>
                      </label>
                    </div>

                    {/* 4. Leads */}
                    <div className="bg-white border border-gray-200 rounded-lg px-4 py-3 flex flex-col sm:flex-row sm:items-center justify-between gap-3 shadow-xs">
                      <label className="flex items-center space-x-3 cursor-pointer select-none">
                        <input
                          type="checkbox"
                          checked={formRolePermissions.leads?.enabled}
                          onChange={(e) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              leads: {
                                ...formRolePermissions.leads,
                                enabled: e.target.checked,
                              },
                            })
                          }
                          className="w-4 h-4 rounded text-[#1a237e] border-gray-300"
                        />
                        <span className="text-xs font-semibold text-gray-800">Leads</span>
                      </label>
                      <div className="flex items-center space-x-8 pl-7 sm:pl-0">
                        <PermSwitch
                          label="Add"
                          checked={!!formRolePermissions.leads?.add}
                          onChange={(v) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              leads: { ...formRolePermissions.leads, add: v },
                            })
                          }
                        />
                        <PermSwitch
                          label="Edit"
                          checked={!!formRolePermissions.leads?.edit}
                          onChange={(v) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              leads: { ...formRolePermissions.leads, edit: v },
                            })
                          }
                        />
                        <PermSwitch
                          label="Delete"
                          checked={!!formRolePermissions.leads?.delete}
                          onChange={(v) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              leads: { ...formRolePermissions.leads, delete: v },
                            })
                          }
                        />
                        <PermSwitch
                          label="Reports"
                          checked={!!formRolePermissions.leads?.reports}
                          onChange={(v) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              leads: { ...formRolePermissions.leads, reports: v },
                            })
                          }
                        />
                      </div>
                    </div>

                    {/* 5. Customers */}
                    <div className="bg-white border border-gray-200 rounded-lg px-4 py-3 flex flex-col sm:flex-row sm:items-center justify-between gap-3 shadow-xs">
                      <label className="flex items-center space-x-3 cursor-pointer select-none">
                        <input
                          type="checkbox"
                          checked={formRolePermissions.customers?.enabled}
                          onChange={(e) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              customers: {
                                ...formRolePermissions.customers,
                                enabled: e.target.checked,
                              },
                            })
                          }
                          className="w-4 h-4 rounded text-[#1a237e] border-gray-300"
                        />
                        <span className="text-xs font-semibold text-gray-800">Customers</span>
                      </label>
                      <div className="flex items-center space-x-8 pl-7 sm:pl-0">
                        <PermSwitch
                          label="Add"
                          checked={!!formRolePermissions.customers?.add}
                          onChange={(v) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              customers: { ...formRolePermissions.customers, add: v },
                            })
                          }
                        />
                        <PermSwitch
                          label="Edit"
                          checked={!!formRolePermissions.customers?.edit}
                          onChange={(v) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              customers: { ...formRolePermissions.customers, edit: v },
                            })
                          }
                        />
                        <PermSwitch
                          label="Delete"
                          checked={!!formRolePermissions.customers?.delete}
                          onChange={(v) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              customers: { ...formRolePermissions.customers, delete: v },
                            })
                          }
                        />
                      </div>
                    </div>

                    {/* 6. Sales Group Card */}
                    <div className="bg-white border border-gray-200 rounded-lg p-4 shadow-xs space-y-4">
                      <div className="text-xs font-bold text-gray-900">Sales</div>

                      {/* Quotations */}
                      <div className="pl-2">
                        <label className="flex items-center space-x-3 cursor-pointer select-none">
                          <input
                            type="checkbox"
                            checked={formRolePermissions.quotations}
                            onChange={(e) =>
                              setFormRolePermissions({
                                ...formRolePermissions,
                                quotations: e.target.checked,
                              })
                            }
                            className="w-4 h-4 rounded text-[#1a237e] border-gray-300"
                          />
                          <span className="text-xs font-semibold text-gray-800">
                            Quotations
                          </span>
                        </label>
                      </div>

                      {/* Proforma Invoices */}
                      <div className="pl-2 flex flex-col sm:flex-row sm:items-center justify-between gap-3 pt-1 border-t border-gray-50">
                        <label className="flex items-center space-x-3 cursor-pointer select-none">
                          <input
                            type="checkbox"
                            checked={formRolePermissions.proforma_invoices?.enabled}
                            onChange={(e) =>
                              setFormRolePermissions({
                                ...formRolePermissions,
                                proforma_invoices: {
                                  ...formRolePermissions.proforma_invoices,
                                  enabled: e.target.checked,
                                },
                              })
                            }
                            className="w-4 h-4 rounded text-[#1a237e] border-gray-300"
                          />
                          <span className="text-xs font-semibold text-gray-800">
                            Proforma Invoices
                          </span>
                        </label>
                        <div className="flex items-center space-x-8 pl-7 sm:pl-0">
                          <PermSwitch
                            label="Add"
                            checked={!!formRolePermissions.proforma_invoices?.add}
                            onChange={(v) =>
                              setFormRolePermissions({
                                ...formRolePermissions,
                                proforma_invoices: {
                                  ...formRolePermissions.proforma_invoices,
                                  add: v,
                                },
                              })
                            }
                          />
                          <PermSwitch
                            label="Edit"
                            checked={!!formRolePermissions.proforma_invoices?.edit}
                            onChange={(v) =>
                              setFormRolePermissions({
                                ...formRolePermissions,
                                proforma_invoices: {
                                  ...formRolePermissions.proforma_invoices,
                                  edit: v,
                                },
                              })
                            }
                          />
                          <PermSwitch
                            label="Delete"
                            checked={!!formRolePermissions.proforma_invoices?.delete}
                            onChange={(v) =>
                              setFormRolePermissions({
                                ...formRolePermissions,
                                proforma_invoices: {
                                  ...formRolePermissions.proforma_invoices,
                                  delete: v,
                                },
                              })
                            }
                          />
                        </div>
                      </div>

                      {/* Invoices */}
                      <div className="pl-2 flex flex-col sm:flex-row sm:items-center justify-between gap-3 pt-1 border-t border-gray-50">
                        <label className="flex items-center space-x-3 cursor-pointer select-none">
                          <input
                            type="checkbox"
                            checked={formRolePermissions.invoices?.enabled}
                            onChange={(e) =>
                              setFormRolePermissions({
                                ...formRolePermissions,
                                invoices: {
                                  ...formRolePermissions.invoices,
                                  enabled: e.target.checked,
                                },
                              })
                            }
                            className="w-4 h-4 rounded text-[#1a237e] border-gray-300"
                          />
                          <span className="text-xs font-semibold text-gray-800">Invoices</span>
                        </label>
                        <div className="flex items-center space-x-8 pl-7 sm:pl-0">
                          <PermSwitch
                            label="Add"
                            checked={!!formRolePermissions.invoices?.add}
                            onChange={(v) =>
                              setFormRolePermissions({
                                ...formRolePermissions,
                                invoices: { ...formRolePermissions.invoices, add: v },
                              })
                            }
                          />
                          <PermSwitch
                            label="Edit"
                            checked={!!formRolePermissions.invoices?.edit}
                            onChange={(v) =>
                              setFormRolePermissions({
                                ...formRolePermissions,
                                invoices: { ...formRolePermissions.invoices, edit: v },
                              })
                            }
                          />
                          <PermSwitch
                            label="Delete"
                            checked={!!formRolePermissions.invoices?.delete}
                            onChange={(v) =>
                              setFormRolePermissions({
                                ...formRolePermissions,
                                invoices: { ...formRolePermissions.invoices, delete: v },
                              })
                            }
                          />
                          <PermSwitch
                            label="Reports"
                            checked={!!formRolePermissions.invoices?.reports}
                            onChange={(v) =>
                              setFormRolePermissions({
                                ...formRolePermissions,
                                invoices: { ...formRolePermissions.invoices, reports: v },
                              })
                            }
                          />
                        </div>
                      </div>

                      {/* Orders */}
                      <div className="pl-2 pt-1 border-t border-gray-50">
                        <label className="flex items-center space-x-3 cursor-pointer select-none">
                          <input
                            type="checkbox"
                            checked={formRolePermissions.orders}
                            onChange={(e) =>
                              setFormRolePermissions({
                                ...formRolePermissions,
                                orders: e.target.checked,
                              })
                            }
                            className="w-4 h-4 rounded text-[#1a237e] border-gray-300"
                          />
                          <span className="text-xs font-semibold text-gray-800">Orders</span>
                        </label>
                      </div>

                      {/* Inventory */}
                      <div className="pl-2 flex flex-col sm:flex-row sm:items-center justify-between gap-3 pt-1 border-t border-gray-50">
                        <label className="flex items-center space-x-3 cursor-pointer select-none">
                          <input
                            type="checkbox"
                            checked={formRolePermissions.inventory?.enabled}
                            onChange={(e) =>
                              setFormRolePermissions({
                                ...formRolePermissions,
                                inventory: {
                                  ...formRolePermissions.inventory,
                                  enabled: e.target.checked,
                                },
                              })
                            }
                            className="w-4 h-4 rounded text-[#1a237e] border-gray-300"
                          />
                          <span className="text-xs font-semibold text-gray-800">Inventory</span>
                        </label>
                        <div className="flex items-center space-x-8 pl-7 sm:pl-0">
                          <PermSwitch
                            label="Add"
                            checked={!!formRolePermissions.inventory?.add}
                            onChange={(v) =>
                              setFormRolePermissions({
                                ...formRolePermissions,
                                inventory: { ...formRolePermissions.inventory, add: v },
                              })
                            }
                          />
                        </div>
                      </div>

                      {/* Payments */}
                      <div className="pl-2 pt-1 border-t border-gray-50">
                        <label className="flex items-center space-x-3 cursor-pointer select-none">
                          <input
                            type="checkbox"
                            checked={formRolePermissions.payments}
                            onChange={(e) =>
                              setFormRolePermissions({
                                ...formRolePermissions,
                                payments: e.target.checked,
                              })
                            }
                            className="w-4 h-4 rounded text-[#1a237e] border-gray-300"
                          />
                          <span className="text-xs font-semibold text-gray-800">Payments</span>
                        </label>
                      </div>
                    </div>

                    {/* 7. Attendance */}
                    <div className="bg-white border border-gray-200 rounded-lg px-4 py-3 flex items-center shadow-xs">
                      <label className="flex items-center space-x-3 cursor-pointer select-none">
                        <input
                          type="checkbox"
                          checked={formRolePermissions.attendance}
                          onChange={(e) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              attendance: e.target.checked,
                            })
                          }
                          className="w-4 h-4 rounded text-[#1a237e] border-gray-300"
                        />
                        <span className="text-xs font-semibold text-gray-800">Attendance</span>
                      </label>
                    </div>

                    {/* 8. Leaves */}
                    <div className="bg-white border border-gray-200 rounded-lg px-4 py-3 flex items-center shadow-xs">
                      <label className="flex items-center space-x-3 cursor-pointer select-none">
                        <input
                          type="checkbox"
                          checked={formRolePermissions.leaves}
                          onChange={(e) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              leaves: e.target.checked,
                            })
                          }
                          className="w-4 h-4 rounded text-[#1a237e] border-gray-300"
                        />
                        <span className="text-xs font-semibold text-gray-800">Leaves</span>
                      </label>
                    </div>

                    {/* 9. Expenses */}
                    <div className="bg-white border border-gray-200 rounded-lg px-4 py-3 flex flex-col sm:flex-row sm:items-center justify-between gap-3 shadow-xs">
                      <label className="flex items-center space-x-3 cursor-pointer select-none">
                        <input
                          type="checkbox"
                          checked={formRolePermissions.expenses?.enabled}
                          onChange={(e) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              expenses: {
                                ...formRolePermissions.expenses,
                                enabled: e.target.checked,
                              },
                            })
                          }
                          className="w-4 h-4 rounded text-[#1a237e] border-gray-300"
                        />
                        <span className="text-xs font-semibold text-gray-800">Expenses</span>
                      </label>
                      <div className="flex items-center space-x-7 pl-7 sm:pl-0">
                        <PermSwitch
                          label="Add"
                          checked={!!formRolePermissions.expenses?.add}
                          onChange={(v) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              expenses: { ...formRolePermissions.expenses, add: v },
                            })
                          }
                        />
                        <PermSwitch
                          label="Edit"
                          checked={!!formRolePermissions.expenses?.edit}
                          onChange={(v) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              expenses: { ...formRolePermissions.expenses, edit: v },
                            })
                          }
                        />
                        <PermSwitch
                          label="Decision"
                          checked={!!formRolePermissions.expenses?.decision}
                          onChange={(v) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              expenses: { ...formRolePermissions.expenses, decision: v },
                            })
                          }
                        />
                        <PermSwitch
                          label="Delete"
                          checked={!!formRolePermissions.expenses?.delete}
                          onChange={(v) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              expenses: { ...formRolePermissions.expenses, delete: v },
                            })
                          }
                        />
                        <PermSwitch
                          label="Reports"
                          checked={!!formRolePermissions.expenses?.reports}
                          onChange={(v) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              expenses: { ...formRolePermissions.expenses, reports: v },
                            })
                          }
                        />
                      </div>
                    </div>

                    {/* 10. Forms */}
                    <div className="bg-white border border-gray-200 rounded-lg px-4 py-3 flex items-center shadow-xs">
                      <label className="flex items-center space-x-3 cursor-pointer select-none">
                        <input
                          type="checkbox"
                          checked={formRolePermissions.forms}
                          onChange={(e) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              forms: e.target.checked,
                            })
                          }
                          className="w-4 h-4 rounded text-[#1a237e] border-gray-300"
                        />
                        <span className="text-xs font-semibold text-gray-800">Forms</span>
                      </label>
                    </div>

                    {/* 11. PMS */}
                    <div className="bg-white border border-gray-200 rounded-lg px-4 py-3 flex items-center shadow-xs">
                      <label className="flex items-center space-x-3 cursor-pointer select-none">
                        <input
                          type="checkbox"
                          checked={formRolePermissions.pms}
                          onChange={(e) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              pms: e.target.checked,
                            })
                          }
                          className="w-4 h-4 rounded text-[#1a237e] border-gray-300"
                        />
                        <span className="text-xs font-semibold text-gray-800">PMS</span>
                      </label>
                    </div>

                    {/* 12. Payroll */}
                    <div className="bg-white border border-gray-200 rounded-lg px-4 py-3 flex items-center shadow-xs">
                      <label className="flex items-center space-x-3 cursor-pointer select-none">
                        <input
                          type="checkbox"
                          checked={formRolePermissions.payroll}
                          onChange={(e) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              payroll: e.target.checked,
                            })
                          }
                          className="w-4 h-4 rounded text-[#1a237e] border-gray-300"
                        />
                        <span className="text-xs font-semibold text-gray-800">Payroll</span>
                      </label>
                    </div>

                    {/* 13. Users */}
                    <div className="bg-white border border-gray-200 rounded-lg px-4 py-3 flex flex-col sm:flex-row sm:items-center justify-between gap-3 shadow-xs">
                      <label className="flex items-center space-x-3 cursor-pointer select-none">
                        <input
                          type="checkbox"
                          checked={formRolePermissions.users?.enabled}
                          onChange={(e) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              users: {
                                ...formRolePermissions.users,
                                enabled: e.target.checked,
                              },
                            })
                          }
                          className="w-4 h-4 rounded text-[#1a237e] border-gray-300"
                        />
                        <span className="text-xs font-semibold text-gray-800">Users</span>
                      </label>
                      <div className="flex items-center space-x-8 pl-7 sm:pl-0">
                        <PermSwitch
                          label="Add"
                          checked={!!formRolePermissions.users?.add}
                          onChange={(v) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              users: { ...formRolePermissions.users, add: v },
                            })
                          }
                        />
                        <PermSwitch
                          label="Edit"
                          checked={!!formRolePermissions.users?.edit}
                          onChange={(v) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              users: { ...formRolePermissions.users, edit: v },
                            })
                          }
                        />
                        <PermSwitch
                          label="Delete"
                          checked={!!formRolePermissions.users?.delete}
                          onChange={(v) =>
                            setFormRolePermissions({
                              ...formRolePermissions,
                              users: { ...formRolePermissions.users, delete: v },
                            })
                          }
                        />
                      </div>
                    </div>
                  </div>

                  {/* Bottom Action Buttons */}
                  <div className="flex items-center space-x-3 pt-3">
                    <button
                      type="submit"
                      disabled={isSavingRole}
                      className="px-6 py-2.5 bg-[#1a237e] hover:bg-[#151c65] text-white rounded-lg font-bold text-xs shadow-sm transition-all cursor-pointer flex items-center space-x-2"
                    >
                      {isSavingRole && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                      <span>Save</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => setRolesSubView('list')}
                      className="px-5 py-2.5 bg-white border border-gray-300 hover:bg-gray-50 text-gray-700 rounded-lg font-bold text-xs transition-all cursor-pointer"
                    >
                      Cancel
                    </button>
                  </div>
                </form>
              )}
            </div>
          )}


          {/* SCREEN 6: MODULES & CARDS VISIBILITY */}
          {activeTab === 'modules' && (
            <div className="space-y-4">
              <h2 className="text-base font-bold text-gray-900">Modules & Cards Visibility</h2>
              <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-2xs space-y-6 text-xs">
                <div className="flex items-center justify-between border-b border-gray-100 pb-3 flex-wrap gap-2">
                  <div>
                    <h3 className="font-bold text-sm text-gray-900 flex items-center gap-2">
                      <span>Modules & Dashboard Cards Visibility Control</span>
                      <span className="text-[10px] px-2 py-0.5 rounded-full bg-[#1a237e]/10 text-[#1a237e] font-bold">
                        Dashboard Customizer
                      </span>
                      {isSaving && (
                        <span className="inline-flex items-center gap-1.5 text-[11px] font-semibold text-[#1a237e] bg-[#1a237e]/10 px-2 py-0.5 rounded-full">
                          <Loader2 className="w-3.5 h-3.5 animate-spin" />
                          Saving to cloud...
                        </span>
                      )}
                    </h3>
                    <p className="text-gray-500 text-[11px]">
                      Enable or disable system modules and dashboard widgets for your workspace.
                    </p>
                  </div>
                  {onResetDefaults && (
                    <button
                      type="button"
                      onClick={() => !isSaving && onResetDefaults()}
                      disabled={isSaving}
                      className="inline-flex items-center space-x-1.5 px-3 py-1.5 border border-gray-200 rounded-lg text-xs font-semibold text-gray-700 hover:bg-gray-50 cursor-pointer"
                    >
                      <RotateCcw className="w-3.5 h-3.5" />
                      <span>Reset All Defaults</span>
                    </button>
                  )}
                </div>

                <div className="space-y-3">
                  <h4 className="font-bold text-xs text-gray-800 uppercase tracking-wider flex items-center gap-2">
                    <LayoutDashboard className="w-4 h-4 text-[#1a237e]" />
                    <span>Main Navigation Modules</span>
                  </h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    {[
                      { key: 'leads' as const, label: 'Leads Management', desc: 'Inquiries, stages, scoring, WhatsApp chat, and conversion to customer' },
                      { key: 'customers' as const, label: 'Customers Directory', desc: 'Customer accounts, tiers (Gold/Silver), and purchase history' },
                      { key: 'sales' as const, label: 'Sales & Invoices Suite', desc: 'Proforma Invoices, Tax Invoices, Orders, Payments, and Stock Inventory' },
                      { key: 'expenses' as const, label: 'Field Expenses Claims', desc: 'Staff reimbursement claims, travel distance, receipt audit, and approvals' },
                      { key: 'reports' as const, label: 'Reports & DSR Analytics', desc: 'Daily Status Reports, staff scorecards, and conversion funnel' },
                      { key: 'settings' as const, label: 'Workspace Settings', desc: 'Company profile, team hierarchy, GPS tracking toggles, and templates' },
                    ].map((m) => {
                      const isVisible = moduleVisibility ? moduleVisibility[m.key] : true;
                      return (
                        <div
                          key={m.key}
                          onClick={() => !isSaving && onToggleModule && onToggleModule(m.key)}
                          className="p-3.5 rounded-xl border border-gray-200 transition-all flex items-center justify-between cursor-pointer bg-gray-50/50 hover:bg-white hover:border-[#1a237e]/40"
                        >
                          <div className="min-w-0 pr-3">
                            <div className="flex items-center space-x-2">
                              <span className="font-bold text-gray-900">{m.label}</span>
                              <span className={`text-[10px] px-1.5 py-0.2 rounded-full font-semibold ${
                                isVisible ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' : 'bg-gray-200 text-gray-600'
                              }`}>
                                {isVisible ? 'Active' : 'Hidden'}
                              </span>
                            </div>
                            <p className="text-gray-500 text-[11px] mt-0.5">{m.desc}</p>
                          </div>
                          <div className="shrink-0">
                            {isVisible ? (
                              <ToggleRight className="w-6 h-6 text-[#1a237e]" />
                            ) : (
                              <ToggleLeft className="w-6 h-6 text-gray-300" />
                            )}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>

                <div className="space-y-3 pt-3 border-t border-gray-100">
                  <h4 className="font-bold text-xs text-gray-800 uppercase tracking-wider flex items-center gap-2">
                    <Layers className="w-4 h-4 text-[#1a237e]" />
                    <span>Dashboard Cards & Widgets</span>
                  </h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
                    {[
                      { key: 'quickStats' as const, label: 'Metric KPI Counters' },
                      { key: 'leadsChart' as const, label: 'Leads Pipeline Funnel' },
                      { key: 'attendanceChart' as const, label: 'Attendance & Punch Status' },
                      { key: 'visitsChart' as const, label: 'Field Client Visits' },
                      { key: 'tasksChart' as const, label: 'Field Tasks Breakdown' },
                      { key: 'callsSummary' as const, label: 'Calls Summary Log' },
                      { key: 'visitsList' as const, label: 'Recent Leads Feed' },
                      { key: 'ordersList' as const, label: 'Recent Invoices & Orders' },
                      { key: 'customerReminders' as const, label: 'Customer Reminders' },
                    ].map((c) => {
                      const isVisible = dashboardCards ? dashboardCards[c.key] : true;
                      return (
                        <div
                          key={c.key}
                          onClick={() => !isSaving && onToggleCard && onToggleCard(c.key)}
                          className="p-3 rounded-lg border border-gray-200 transition-all flex items-center justify-between cursor-pointer bg-gray-50/50 hover:bg-white hover:border-[#1a237e]/40"
                        >
                          <span className={`font-semibold ${isVisible ? 'text-gray-900' : 'text-gray-400'}`}>
                            {c.label}
                          </span>
                          <div className="shrink-0">
                            {isVisible ? (
                              <ToggleRight className="w-5 h-5 text-[#1a237e]" />
                            ) : (
                              <ToggleLeft className="w-5 h-5 text-gray-300" />
                            )}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* ======================================================== */}
      {/* MODAL 1: ADD / EDIT OFFICE (Screenshot 154139)           */}
      {/* ======================================================== */}
      {isOfficeModalOpen && (
        <div className="fixed inset-0 z-50 overflow-y-auto bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md overflow-hidden text-xs animate-in fade-in zoom-in-95">
            <div className="bg-[#1a237e] text-white px-4 py-3 flex items-center justify-between font-bold text-sm">
              <span>{editingOffice ? 'Edit Office' : 'Add Office'}</span>
              <button
                type="button"
                onClick={() => {
                  setIsOfficeModalOpen(false);
                  setEditingOffice(null);
                }}
                className="text-white/80 hover:text-white cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSaveOffice} className="p-5 space-y-3.5">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold text-gray-700 mb-1">
                    Name <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="text"
                    required
                    value={officeName}
                    onChange={(e) => setOfficeName(e.target.value)}
                    placeholder="e.g. Head Office"
                    className="w-full border border-gray-300 rounded-lg p-2 focus:border-[#1a237e] focus:outline-none"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-gray-700 mb-1">
                    Location <span className="text-rose-500">*</span>
                  </label>
                  <div className="flex items-center gap-1.5">
                    <input
                      type="text"
                      readOnly
                      value={officeLocation}
                      className="w-full border border-gray-200 bg-gray-100 rounded-lg p-2 font-mono text-[11px] text-gray-600 focus:outline-none"
                    />
                    <button
                      type="button"
                      onClick={handleOpenMapFromForm}
                      className="p-2 bg-[#1a237e] hover:bg-[#283593] text-white rounded-lg cursor-pointer transition-colors shrink-0"
                      title="Tap location icon to open map and pick coordinates"
                    >
                      <MapPin className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>

              <div>
                <label className="block font-semibold text-gray-700 mb-1">Address</label>
                <textarea
                  rows={3}
                  value={officeAddress}
                  onChange={(e) => setOfficeAddress(e.target.value)}
                  placeholder="Street address, building, landmark..."
                  className="w-full border border-gray-300 rounded-lg p-2 focus:border-[#1a237e] focus:outline-none"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold text-gray-700 mb-1">City</label>
                  <input
                    type="text"
                    value={officeCity}
                    onChange={(e) => setOfficeCity(e.target.value)}
                    placeholder="e.g. Rajkot"
                    className="w-full border border-gray-300 rounded-lg p-2 focus:border-[#1a237e] focus:outline-none"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-gray-700 mb-1">State</label>
                  <input
                    type="text"
                    value={officeState}
                    onChange={(e) => setOfficeState(e.target.value)}
                    placeholder="e.g. Gujarat"
                    className="w-full border border-gray-300 rounded-lg p-2 focus:border-[#1a237e] focus:outline-none"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold text-gray-700 mb-1">Pincode</label>
                  <input
                    type="text"
                    value={officePincode}
                    onChange={(e) => setOfficePincode(e.target.value)}
                    placeholder="e.g. 360006"
                    className="w-full border border-gray-300 rounded-lg p-2 focus:border-[#1a237e] focus:outline-none"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-gray-700 mb-1">Country</label>
                  <select
                    value={officeCountry}
                    onChange={(e) => setOfficeCountry(e.target.value)}
                    className="w-full border border-gray-300 rounded-lg p-2 bg-white text-gray-700 focus:border-[#1a237e] focus:outline-none"
                  >
                    <option value="India">India</option>
                    <option value="United States">United States</option>
                    <option value="UAE">United Arab Emirates</option>
                  </select>
                </div>
              </div>

              <div className="pt-3 border-t border-gray-100 flex items-center space-x-2">
                <button
                  type="submit"
                  className="px-5 py-2 bg-[#1a237e] hover:bg-[#283593] text-white rounded-md font-semibold cursor-pointer transition-colors"
                >
                  Save
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setIsOfficeModalOpen(false);
                    setEditingOffice(null);
                  }}
                  className="px-4 py-2 border border-gray-300 hover:bg-gray-100 text-gray-700 rounded-md font-semibold cursor-pointer transition-colors"
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* MODAL 2: INTERACTIVE MAP MODAL (when location icon tapped)*/}
      {/* ======================================================== */}
      {isMapModalOpen && (
        <div className="fixed inset-0 z-50 overflow-y-auto bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-xl overflow-hidden border border-gray-100 text-xs animate-in fade-in zoom-in-95">
            <div className="bg-[#1a237e] text-white px-5 py-3.5 flex items-center justify-between font-bold text-sm">
              <div className="flex items-center space-x-2">
                <MapPin className="w-4 h-4 text-white" />
                <span>
                  {viewingOfficeOnMap ? `Office Location: ${viewingOfficeOnMap.name}` : 'Select Office Location on Map'}
                </span>
              </div>
              <button
                type="button"
                onClick={() => setIsMapModalOpen(false)}
                className="text-white/80 hover:text-white cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-5 space-y-4">
              {/* Coordinates Bar */}
              <div className="flex flex-wrap items-center justify-between gap-2 p-3 rounded-xl bg-gray-50 border border-gray-200">
                <div className="flex items-center space-x-2">
                  <span className="font-semibold text-gray-600 text-xs">GPS Coordinates:</span>
                  <span className="font-mono font-bold text-gray-900 text-xs">
                    {mapPickerLat.toFixed(4)}, {mapPickerLng.toFixed(4)}
                  </span>
                </div>
                {mapLocationSource === 'form' && (
                  <button
                    type="button"
                    onClick={handleUseCurrentGPSLocation}
                    disabled={isGettingCurrentLocation}
                    className="inline-flex items-center gap-1.5 px-3 py-1 bg-white hover:bg-gray-100 border border-gray-300 rounded-lg text-xs font-semibold text-gray-700 cursor-pointer shadow-2xs"
                  >
                    {isGettingCurrentLocation ? (
                      <Loader2 className="w-3.5 h-3.5 animate-spin text-[#1a237e]" />
                    ) : (
                      <Navigation className="w-3.5 h-3.5 text-[#1a237e]" />
                    )}
                    <span>Use My Current GPS</span>
                  </button>
                )}
              </div>

              {/* Styled Interactive Map Preview Card */}
              <div className="relative h-64 w-full rounded-xl overflow-hidden border border-gray-300 bg-slate-100 flex items-center justify-center shadow-inner">
                <div className="absolute inset-0 opacity-25 bg-[radial-gradient(#1a237e_1px,transparent_1px)] [background-size:18px_18px]" />
                
                {/* Radar pulse animation */}
                <div className="absolute w-28 h-28 rounded-full bg-[#1a237e]/15 animate-ping" />
                <div className="absolute w-14 h-14 rounded-full bg-[#1a237e]/20 flex items-center justify-center">
                  <div className="w-8 h-8 rounded-full bg-[#1a237e] text-white flex items-center justify-center shadow-xl">
                    <MapPin className="w-5 h-5 text-white" />
                  </div>
                </div>

                {/* Bottom Address / Info Pill */}
                <div className="absolute bottom-3 left-3 right-3 bg-white/95 backdrop-blur-xs p-3 rounded-xl border border-gray-200 shadow-md flex items-center justify-between">
                  <div className="truncate pr-3">
                    <div className="font-bold text-gray-900 text-xs truncate">
                      {viewingOfficeOnMap?.name || officeName || 'Office Geo-Fence Target'}
                    </div>
                    <div className="text-[11px] text-gray-600 truncate mt-0.5">
                      {viewingOfficeOnMap?.address || officeAddress || '1103, R K World Tower, 150ft Ring Road, Rajkot'}
                    </div>
                  </div>
                  <a
                    href={`https://www.google.com/maps/search/?api=1&query=${mapPickerLat},${mapPickerLng}`}
                    target="_blank"
                    rel="noreferrer"
                    className="shrink-0 px-3 py-1.5 bg-[#1a237e] hover:bg-[#283593] text-white rounded-lg text-xs font-bold inline-flex items-center gap-1 shadow-xs transition-colors"
                  >
                    <span>Google Maps</span>
                    <ExternalLink className="w-3.5 h-3.5" />
                  </a>
                </div>
              </div>

              {/* Footer Buttons */}
              <div className="pt-2 border-t border-gray-100 flex items-center justify-end space-x-2">
                <button
                  type="button"
                  onClick={() => setIsMapModalOpen(false)}
                  className="px-4 py-2 border border-gray-300 hover:bg-gray-100 text-gray-700 rounded-md font-semibold cursor-pointer"
                >
                  Close
                </button>
                {mapLocationSource === 'form' && (
                  <button
                    type="button"
                    onClick={handleConfirmMapLocation}
                    className="px-5 py-2 bg-[#1a237e] hover:bg-[#283593] text-white rounded-md font-semibold cursor-pointer shadow-xs transition-colors"
                  >
                    Confirm Location
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* MODAL 3: USER LOCATION PREVIEW MODAL                     */}
      {/* ======================================================== */}
      {selectedLocationUser && (
        <div className="fixed inset-0 z-50 overflow-y-auto bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden border border-gray-100 animate-in fade-in zoom-in-95 text-xs">
            <div className="p-4 bg-gradient-to-r from-[#1a237e] to-[#3949ab] text-white flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center font-bold text-sm">
                  {selectedLocationUser.first_name[0]}{selectedLocationUser.last_name[0]}
                </div>
                <div>
                  <h3 className="font-bold text-sm leading-tight">
                    {selectedLocationUser.first_name} {selectedLocationUser.last_name}
                  </h3>
                  <div className="flex items-center space-x-2 text-[11px] text-white/80 mt-0.5">
                    <span>Staff #{selectedLocationUser.user_code}</span>
                    <span>•</span>
                    <span>{selectedLocationUser.role}</span>
                  </div>
                </div>
              </div>
              <button
                onClick={() => setSelectedLocationUser(null)}
                className="p-1 rounded-lg text-white/70 hover:text-white hover:bg-white/10 transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-5 space-y-4">
              <div className="flex items-center justify-between p-3 rounded-xl bg-gray-50 border border-gray-200">
                <div className="flex items-center space-x-2">
                  <span className={`w-3 h-3 rounded-full ${selectedLocationUser.location_tracking ? 'bg-emerald-500 animate-pulse' : 'bg-gray-400'}`} />
                  <span className="font-bold text-gray-800">
                    {selectedLocationUser.location_tracking ? 'Real-time GPS Tracking Active' : 'GPS Tracking Disabled'}
                  </span>
                </div>
                <span className="text-[11px] font-semibold text-gray-500">
                  {selectedLocationUser.last_location?.updated_at || '15 mins ago'}
                </span>
              </div>

              <div className="relative h-48 w-full rounded-xl overflow-hidden border border-gray-200 bg-slate-100 flex items-center justify-center">
                <div className="absolute inset-0 opacity-20 bg-[radial-gradient(#3949ab_1px,transparent_1px)] [background-size:16px_16px]" />
                <div className="absolute w-24 h-24 rounded-full bg-[#3949ab]/15 animate-ping" />
                <div className="absolute w-12 h-12 rounded-full bg-[#3949ab]/25 flex items-center justify-center">
                  <div className="w-7 h-7 rounded-full bg-[#3949ab] text-white flex items-center justify-center shadow-lg">
                    <MapPin className="w-4 h-4 text-white" />
                  </div>
                </div>

                <div className="absolute bottom-3 left-3 right-3 bg-white/95 backdrop-blur-xs p-2.5 rounded-lg border border-gray-200 shadow-sm flex items-center justify-between">
                  <div className="truncate pr-2">
                    <div className="font-bold text-gray-900 text-xs truncate">
                      {selectedLocationUser.last_location?.address || 'Kuvadva Road, Rajkot, Gujarat'}
                    </div>
                    <div className="text-[10px] text-gray-500 font-mono mt-0.5">
                      Lat: {selectedLocationUser.last_location?.lat || 22.3039}, Lng: {selectedLocationUser.last_location?.lng || 70.8022}
                    </div>
                  </div>
                  <a
                    href={`https://www.google.com/maps/search/?api=1&query=${selectedLocationUser.last_location?.lat || 22.3039},${selectedLocationUser.last_location?.lng || 70.8022}`}
                    target="_blank"
                    rel="noreferrer"
                    className="shrink-0 px-2.5 py-1.5 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-md text-[11px] font-bold inline-flex items-center gap-1 shadow-2xs transition-colors"
                  >
                    <span>Google Maps</span>
                    <ExternalLink className="w-3 h-3" />
                  </a>
                </div>
              </div>
            </div>

            <div className="p-4 bg-gray-50 border-t border-gray-100 flex justify-end">
              <button
                type="button"
                onClick={() => setSelectedLocationUser(null)}
                className="px-4 py-2 bg-white border border-gray-200 hover:bg-gray-100 text-gray-700 font-semibold rounded-lg text-xs cursor-pointer"
              >
                Close Preview
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* MODAL 4: ADD / EDIT MESSAGE TEMPLATE MODAL               */}
      {/* ======================================================== */}
      {isTemplateModalOpen && (
        <div className="fixed inset-0 z-50 overflow-y-auto bg-black/50 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg border border-gray-100 overflow-hidden text-xs animate-in fade-in zoom-in-95">
            <div className="p-4 border-b border-gray-100 flex items-center justify-between bg-gray-50/70">
              <div>
                <h3 className="text-base font-bold text-gray-900">
                  {editingTemplate ? 'Edit Message Template' : 'Create New Message Template'}
                </h3>
                <p className="text-gray-500 text-[11px] mt-0.5">
                  Configure text and dynamic tags for automatic WhatsApp messaging
                </p>
              </div>
              <button
                type="button"
                onClick={() => {
                  setIsTemplateModalOpen(false);
                  setEditingTemplate(null);
                }}
                className="p-1.5 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSaveTemplate} className="p-5 space-y-4">
              <div>
                <label className="block font-semibold text-gray-700 mb-1">Template Name *</label>
                <input
                  type="text"
                  required
                  value={tmplName}
                  onChange={(e) => setTmplName(e.target.value)}
                  placeholder="e.g. Lead Follow-Up Greeting"
                  className="w-full border border-gray-300 rounded-lg p-2 focus:ring-[#1a237e] focus:border-[#1a237e]"
                />
              </div>

              <div>
                <label className="block font-semibold text-gray-700 mb-1">Target Module *</label>
                <select
                  value={tmplModule}
                  onChange={(e) => setTmplModule(e.target.value as MessageTemplate['module'])}
                  className="w-full border border-gray-300 rounded-lg p-2 bg-white font-medium"
                >
                  <option value="Leads">Leads Management</option>
                  <option value="Customers">Customers Directory</option>
                  <option value="Invoices">Tax Invoices</option>
                  <option value="Proforma Invoices">Proforma Invoices</option>
                  <option value="General">General Inquiries</option>
                </select>
              </div>

              <div>
                <div className="flex items-center justify-between mb-1.5">
                  <label className="font-semibold text-gray-700">Dynamic Variable Tags</label>
                  <span className="text-[10px] text-gray-400">Click a tag to insert</span>
                </div>
                <div className="flex flex-wrap gap-1.5 p-2 bg-gray-50 rounded-lg border border-gray-200">
                  {[
                    { tag: '{{name}}', label: 'Lead Name' },
                    { tag: '{{companyName}}', label: 'Company' },
                    { tag: '{{brand_name}}', label: 'Your Brand' },
                    { tag: '{{phone}}', label: 'Phone' },
                    { tag: '{{stage}}', label: 'Lead Stage' },
                    { tag: '{{total}}', label: 'Total Amount' },
                    { tag: '{{id}}', label: 'Doc ID' },
                  ].map((v) => (
                    <button
                      key={v.tag}
                      type="button"
                      onClick={() => insertVariableTag(v.tag)}
                      className="px-2 py-1 bg-white hover:bg-[#1a237e] hover:text-white text-gray-700 font-mono text-[10px] font-bold rounded border border-gray-200 transition-colors shadow-2xs cursor-pointer"
                    >
                      + {v.tag}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block font-semibold text-gray-700 mb-1">Message Content *</label>
                <textarea
                  ref={tmplTextareaRef}
                  required
                  rows={4}
                  value={tmplContent}
                  onChange={(e) => setTmplContent(e.target.value)}
                  placeholder="Type your message with dynamic tags like {{name}}..."
                  className="w-full border border-gray-300 rounded-lg p-2.5 font-sans focus:ring-[#1a237e] focus:border-[#1a237e]"
                />
              </div>

              <label className="flex items-center space-x-2.5 cursor-pointer p-2.5 rounded-lg border border-gray-200 hover:bg-gray-50">
                <input
                  type="checkbox"
                  checked={tmplIsDefault}
                  onChange={(e) => setTmplIsDefault(e.target.checked)}
                  className="rounded text-[#1a237e] focus:ring-[#1a237e]"
                />
                <div>
                  <span className="font-bold text-gray-800 block">
                    Set as Default WhatsApp Template for {tmplModule}
                  </span>
                  <span className="text-[11px] text-gray-500">
                    When contacting from {tmplModule === 'Leads' ? 'lead detail' : 'this module'}, this template will be pre-filled automatically.
                  </span>
                </div>
              </label>

              <div className="pt-3 border-t border-gray-100 flex items-center justify-end space-x-2">
                <button
                  type="button"
                  onClick={() => {
                    setIsTemplateModalOpen(false);
                    setEditingTemplate(null);
                  }}
                  className="px-4 py-2 border border-gray-300 rounded-lg font-semibold text-gray-700 hover:bg-gray-100 cursor-pointer"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-[#1a237e] hover:bg-[#283593] text-white rounded-lg font-semibold shadow-xs cursor-pointer transition-colors"
                >
                  {editingTemplate ? 'Update Template' : 'Save Template'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* MODAL 5: ADD / EDIT USER MODAL                           */}
      {/* ======================================================== */}
      {isUserModalOpen && (
        <div className="fixed inset-0 z-50 overflow-y-auto bg-black/50 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl border border-gray-100 overflow-hidden text-xs animate-in fade-in zoom-in-95">
            <div className="p-4 border-b border-gray-100 flex items-center justify-between bg-gray-50/70">
              <div>
                <h3 className="text-base font-bold text-gray-900">
                  {editingUser ? 'Edit Team Member Profile & Access' : 'Add New Field Team Member'}
                </h3>
                <p className="text-gray-500 text-[11px] mt-0.5">
                  {editingUser
                    ? `Updating staff member #${editingUser.user_code} (${editingUser.first_name} ${editingUser.last_name})`
                    : 'Assign reporting hierarchy and configure module data permissions'}
                </p>
              </div>
              <button
                type="button"
                onClick={() => {
                  setIsUserModalOpen(false);
                  setEditingUser(null);
                }}
                className="p-1.5 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="flex border-b border-gray-200 bg-white px-4 pt-2">
              <button
                type="button"
                onClick={() => setUserModalTab('profile')}
                className={`px-4 py-2 text-xs font-bold border-b-2 transition-colors cursor-pointer ${
                  userModalTab === 'profile'
                    ? 'border-[#3949ab] text-[#3949ab]'
                    : 'border-transparent text-gray-500 hover:text-gray-700'
                }`}
              >
                1. Member Profile & Hierarchy
              </button>
              <button
                type="button"
                onClick={() => setUserModalTab('permissions')}
                className={`px-4 py-2 text-xs font-bold border-b-2 transition-colors cursor-pointer flex items-center gap-1.5 ${
                  userModalTab === 'permissions'
                    ? 'border-[#3949ab] text-[#3949ab]'
                    : 'border-transparent text-gray-500 hover:text-gray-700'
                }`}
              >
                <Lock className="w-3.5 h-3.5" />
                <span>2. Granular Module Permissions</span>
              </button>
            </div>

            <form onSubmit={handleSaveUser}>
              <div className="p-6 space-y-4 max-h-[68vh] overflow-y-auto">
                {userModalTab === 'profile' && (
                  <div className="space-y-3.5">
                    <div className="grid grid-cols-2 gap-3">
                      <div>
                        <label className="block font-semibold text-gray-700 mb-1">First Name *</label>
                        <input
                          type="text"
                          required
                          value={newFirstName}
                          onChange={(e) => setNewFirstName(e.target.value)}
                          placeholder="e.g. Ramesh"
                          className="w-full border border-gray-300 rounded-lg p-2 focus:ring-[#3949ab] focus:border-[#3949ab]"
                        />
                      </div>
                      <div>
                        <label className="block font-semibold text-gray-700 mb-1">Last Name</label>
                        <input
                          type="text"
                          value={newLastName}
                          onChange={(e) => setNewLastName(e.target.value)}
                          placeholder="e.g. Patel"
                          className="w-full border border-gray-300 rounded-lg p-2 focus:ring-[#3949ab] focus:border-[#3949ab]"
                        />
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-3">
                      <div>
                        <label className="block font-semibold text-gray-700 mb-1">Mobile Number *</label>
                        <input
                          type="text"
                          required
                          value={newMobile}
                          onChange={(e) => setNewMobile(e.target.value)}
                          placeholder="10-digit mobile"
                          className="w-full border border-gray-300 rounded-lg p-2 focus:ring-[#3949ab] focus:border-[#3949ab]"
                        />
                      </div>
                      <div>
                        <label className="block font-semibold text-gray-700 mb-1">Email Address</label>
                        <input
                          type="email"
                          value={newEmail}
                          onChange={(e) => setNewEmail(e.target.value)}
                          placeholder="work email"
                          className="w-full border border-gray-300 rounded-lg p-2 focus:ring-[#3949ab] focus:border-[#3949ab]"
                        />
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-3">
                      <div>
                        <label className="block font-semibold text-gray-700 mb-1">Assigned Role</label>
                        <select
                          value={newRole}
                          onChange={(e) =>
                            handleRoleChangeInModal(e.target.value as 'Admin' | 'Manager' | 'Staff')
                          }
                          className="w-full border border-gray-300 rounded-lg p-2 bg-white font-medium"
                        >
                          <option value="Staff">Field Staff (Executive)</option>
                          <option value="Manager">Manager (Team Leader)</option>
                          <option value="Admin">Administrator (Full Access)</option>
                        </select>
                      </div>
                      <div>
                        <label className="block font-semibold text-gray-700 mb-1">Reporting Head</label>
                        <select
                          value={newReportingHead}
                          onChange={(e) => setNewReportingHead(e.target.value)}
                          className="w-full border border-gray-300 rounded-lg p-2 bg-white font-medium"
                        >
                          {reportingHeadOptions.map((head) => (
                            <option key={head} value={head}>
                              {head}
                            </option>
                          ))}
                        </select>
                      </div>
                    </div>

                    <div className="pt-3 border-t border-gray-100 space-y-2.5">
                      <label className="flex items-center space-x-2.5 cursor-pointer p-2 rounded-lg hover:bg-gray-50 border border-gray-100">
                        <input
                          type="checkbox"
                          checked={newLocationTracking}
                          onChange={(e) => setNewLocationTracking(e.target.checked)}
                          className="rounded text-[#3949ab] focus:ring-[#3949ab]"
                        />
                        <div>
                          <span className="font-bold text-gray-800 block">
                            Enable Real-time GPS Location Tracking
                          </span>
                          <span className="text-[11px] text-gray-500">
                            Logs route history, distance traveled, and client check-in coordinates.
                          </span>
                        </div>
                      </label>

                      <label className="flex items-center space-x-2.5 cursor-pointer p-2 rounded-lg hover:bg-gray-50 border border-gray-100">
                        <input
                          type="checkbox"
                          checked={newIsActive}
                          onChange={(e) => setNewIsActive(e.target.checked)}
                          className="rounded text-[#3949ab] focus:ring-[#3949ab]"
                        />
                        <div>
                          <span className="font-bold text-gray-800 block">
                            Active Account Status
                          </span>
                          <span className="text-[11px] text-gray-500">
                            Allow user to log in to the mobile app and submit daily reports.
                          </span>
                        </div>
                      </label>
                    </div>
                  </div>
                )}

                {userModalTab === 'permissions' && (
                  <div className="space-y-4">
                    <div className="p-3 bg-blue-50/80 border border-blue-200 rounded-xl flex items-center justify-between">
                      <div className="flex items-center space-x-2">
                        <Shield className="w-4 h-4 text-[#3949ab]" />
                        <span className="text-gray-800 font-semibold">
                          Permissions configured for <strong className="text-[#3949ab]">{newRole}</strong> role
                        </span>
                      </div>
                      <button
                        type="button"
                        onClick={() => setNewPermissions(getDefaultPermissions(newRole))}
                        className="text-[11px] font-bold text-[#3949ab] hover:underline cursor-pointer"
                      >
                        Reset Role Defaults
                      </button>
                    </div>

                    <div className="p-3.5 bg-gray-50 rounded-xl border border-gray-200 space-y-2.5">
                      <div className="flex items-center justify-between border-b border-gray-200 pb-2">
                        <span className="font-bold text-gray-900 text-xs">Leads Management Access</span>
                        <div className="flex items-center space-x-2">
                          <label className="inline-flex items-center space-x-1 cursor-pointer">
                            <input
                              type="radio"
                              name="leads_view"
                              checked={newPermissions.leads_view === 'all'}
                              onChange={() =>
                                setNewPermissions({ ...newPermissions, leads_view: 'all' })
                              }
                              className="text-[#3949ab] focus:ring-[#3949ab]"
                            />
                            <span className="text-[11px] font-medium text-gray-700">View All Leads</span>
                          </label>
                          <label className="inline-flex items-center space-x-1 cursor-pointer">
                            <input
                              type="radio"
                              name="leads_view"
                              checked={newPermissions.leads_view === 'own'}
                              onChange={() =>
                                setNewPermissions({ ...newPermissions, leads_view: 'own' })
                              }
                              className="text-[#3949ab] focus:ring-[#3949ab]"
                            />
                            <span className="text-[11px] font-medium text-gray-700">Own Only</span>
                          </label>
                        </div>
                      </div>
                      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 pt-1">
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.leads_create}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, leads_create: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Create Leads</span>
                        </label>
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.leads_edit}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, leads_edit: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Edit Leads</span>
                        </label>
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.leads_delete}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, leads_delete: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Delete Leads</span>
                        </label>
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.leads_export}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, leads_export: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Excel Export</span>
                        </label>
                      </div>
                    </div>

                    <div className="p-3.5 bg-gray-50 rounded-xl border border-gray-200 space-y-2.5">
                      <div className="flex items-center justify-between border-b border-gray-200 pb-2">
                        <span className="font-bold text-gray-900 text-xs">Customers Directory Access</span>
                        <div className="flex items-center space-x-2">
                          <label className="inline-flex items-center space-x-1 cursor-pointer">
                            <input
                              type="radio"
                              name="customers_view"
                              checked={newPermissions.customers_view === 'all'}
                              onChange={() =>
                                setNewPermissions({ ...newPermissions, customers_view: 'all' })
                              }
                              className="text-[#3949ab] focus:ring-[#3949ab]"
                            />
                            <span className="text-[11px] font-medium text-gray-700">View All Customers</span>
                          </label>
                          <label className="inline-flex items-center space-x-1 cursor-pointer">
                            <input
                              type="radio"
                              name="customers_view"
                              checked={newPermissions.customers_view === 'own'}
                              onChange={() =>
                                setNewPermissions({ ...newPermissions, customers_view: 'own' })
                              }
                              className="text-[#3949ab] focus:ring-[#3949ab]"
                            />
                            <span className="text-[11px] font-medium text-gray-700">Own Only</span>
                          </label>
                        </div>
                      </div>
                      <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 pt-1">
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.customers_create}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, customers_create: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Add Customers</span>
                        </label>
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.customers_edit}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, customers_edit: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Edit Customer Profile</span>
                        </label>
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.customers_export}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, customers_export: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Excel Export</span>
                        </label>
                      </div>
                    </div>

                    <div className="p-3.5 bg-gray-50 rounded-xl border border-gray-200 space-y-2.5">
                      <div className="font-bold text-gray-900 text-xs border-b border-gray-200 pb-2">
                        Sales, Invoices & Payments Collection
                      </div>
                      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 pt-1">
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.sales_pfi}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, sales_pfi: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Create Proforma (PFI)</span>
                        </label>
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.sales_invoice}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, sales_invoice: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Generate Tax Invoice</span>
                        </label>
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.sales_payment}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, sales_payment: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Record Payments</span>
                        </label>
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.sales_export}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, sales_export: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Export Sales Data</span>
                        </label>
                      </div>
                    </div>

                    <div className="p-3.5 bg-gray-50 rounded-xl border border-gray-200 space-y-2.5">
                      <div className="font-bold text-gray-900 text-xs border-b border-gray-200 pb-2">
                        Visits & GPS Attendance Tracking
                      </div>
                      <div className="grid grid-cols-2 gap-2 pt-1">
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.visits_tracking}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, visits_tracking: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Live GPS Location Tracking</span>
                        </label>
                        <label className="flex items-center space-x-1.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={!!newPermissions.visits_routes}
                            onChange={(e) =>
                              setNewPermissions({ ...newPermissions, visits_routes: e.target.checked })
                            }
                            className="rounded text-[#3949ab]"
                          />
                          <span className="text-gray-700">Route & Daily Trail History</span>
                        </label>
                      </div>
                    </div>
                  </div>
                )}
              </div>

              <div className="p-4 bg-gray-50 border-t border-gray-100 flex items-center justify-between">
                <div>
                  {userModalTab === 'profile' ? (
                    <button
                      type="button"
                      onClick={() => setUserModalTab('permissions')}
                      className="px-3 py-1.5 text-xs font-bold text-[#3949ab] hover:bg-[#3949ab]/10 rounded-lg transition-colors cursor-pointer"
                    >
                      Next: Permissions →
                    </button>
                  ) : (
                    <button
                      type="button"
                      onClick={() => setUserModalTab('profile')}
                      className="px-3 py-1.5 text-xs font-bold text-gray-600 hover:bg-gray-200 rounded-lg transition-colors cursor-pointer"
                    >
                      ← Back to Profile
                    </button>
                  )}
                </div>

                <div className="flex items-center space-x-2">
                  <button
                    type="button"
                    onClick={() => {
                      setIsUserModalOpen(false);
                      setEditingUser(null);
                    }}
                    className="px-4 py-2 border border-gray-300 rounded-lg font-semibold text-gray-700 hover:bg-gray-100 cursor-pointer"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={isSubmittingUser}
                    className="px-5 py-2 bg-[#3949ab] hover:bg-[#303f9f] text-white rounded-lg font-semibold flex items-center space-x-1.5 cursor-pointer disabled:opacity-50 shadow-xs"
                  >
                    {isSubmittingUser && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                    <span>{editingUser ? 'Save Changes' : 'Create Member'}</span>
                  </button>
                </div>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
