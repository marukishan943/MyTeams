# MyTeams Web Admin Portal

A modern, responsive Web Admin Portal & CRM for **MY TEAMS**, inspired by UpTeams (`web.upteams.com`), connected directly to the shared Supabase backend.

---

## 🚀 Features

### 1. 🔐 Admin Authentication
- Secure authentication with Supabase Auth (`signInWithPassword`)
- Instant 1-Click Admin Access (`admin@myteams.com` / `admin123`)
- Persistent session storage in `localStorage`
- Profile display with Company (`IV SQUARE STRUCTURE INDIA PVT LTD`)

### 2. 📊 UpTeams-Inspired Dashboard
- **Top Bar**: Live date pill (`11 Oct 2026`), dynamic Staff filter dropdown, realtime refresh button.
- **Metrics Overview**:
  - Total Leads + Conversion rate + Stage breakdown (New, Contacted, Proposal Sent).
  - Customer Accounts + Active / Inactive breakdown.
  - Invoices Revenue & Proforma count.
  - Active Orders pipeline.
- **Quick Actions**: 1-click shortcuts to Add Lead, Add Customer, and Create Invoice.
- **Live Widgets**: Recent Leads feed and Recent Invoices/Orders breakdown.

### 3. 🎯 Full CRUD: Leads Management
- **Create**: Add new lead modal with lead number generator, contact info, company, territory, source, stage, estimated value, and notes.
- **Read**: Search by name, company, phone; filter by Pipeline Stage (New, Contacted, Proposal Sent, Converted, Disqualified); staff filtering; pagination.
- **Update**: Edit full lead information; 1-click stage progression pipeline in detail view.
- **Delete**: Delete lead with confirmation.
- **Lead Feed**: Interactive Notes stream to post updates on each lead.

### 4. 👥 Full CRUD: Customers Management
- **Create**: Add customer modal with auto customer number, business name, category (`Retailer`, `Distributor`, `Other`), status (`Active`, `Inactive`), GST, territory, address, and assigned staff.
- **Read**: Real-time search; category filtering pills; active/inactive filter; pagination.
- **Update**: Edit customer details; quick status toggle between Active and Inactive.
- **Delete**: Delete customer with confirmation modal.

### 5. 📑 Full CRUD: Sales & Invoicing Module
- **3 Tab Views**:
  - 🧾 **Tax Invoices**
  - 📋 **Proforma Invoices**
  - 📦 **Orders**
- **Create**: Generate Document modal with customer/lead selection, date, due date, status, and dynamic line items builder (Rate, Qty, GST %, line totals, automatic grand total calculation).
- **Read**: Tabular view with amounts, status badges, staff names, and filter by status (`open`, `pending`, `delivered`, `converted`).
- **Update**: Edit document and change status.
- **Delete**: Delete document with confirmation.
- **Printable Layout**: Professional invoice receipt view with company header, billing breakdown, notes, and browser print/PDF export.

---

## 🛠️ Tech Stack

- **Framework**: React 19 + TypeScript
- **Bundler**: Vite 8
- **Styling**: Tailwind CSS v4 + Lucide Icons
- **Backend / Database**: Supabase (`@supabase/supabase-js`)
- **Shared Tables**:
  - `public.leads`
  - `public.lead_notes`
  - `public.customers`
  - `public.lead_orders`

---

## 🏃 Getting Started

### Run Development Server
```bash
cd admin_portal
npm run dev
```
Open [http://localhost:5173](http://localhost:5173) in your browser.

### Build for Production
```bash
cd admin_portal
npm run build
```
The optimized bundle will be generated in `dist/`.

---

## 🚀 Publishing to Netlify

The project includes **`netlify.toml`** and **`public/_redirects`** preconfigured for single-page application routing.

### Method A: 1-Click Instant Deploy (Netlify Drop)
1. Ensure your build is generated: `npm run build`
2. Open **[https://app.netlify.com/drop](https://app.netlify.com/drop)** in your browser.
3. Drag and drop the **`d:\myteams\admin_portal\dist`** folder into the browser.
4. Your website is immediately published with a live HTTPS URL!

### Method B: Terminal Deploy (Netlify CLI)
1. Run in terminal:
   ```bash
   cd d:\myteams\admin_portal
   npx netlify login
   npx netlify deploy --prod --dir=dist
   ```
2. Follow the on-screen prompt to create or link your site.

### Method C: Continuous Deployment via GitHub
1. In your Netlify dashboard, click **Add new site** > **Import an existing project** > **GitHub** (`MyTeams`).
2. Configure settings:
   - **Base directory:** `admin_portal`
   - **Build command:** `npm run build`
   - **Publish directory:** `admin_portal/dist`
3. Click **Deploy Site**. Future git pushes will automatically deploy.

