# GigFlow — Financial OS for Gig Workers

GigFlow is a full-stack mobile + web application that helps gig economy workers manage taxes, track income, find deductions, and understand their finances. It combines a Flutter mobile app with a Next.js backend powered by Claude AI.

---

## Features

- **Income Dashboard** — YTD earnings, month-over-month trends, per-platform breakdown including custom jobs
- **Tax Snapshot** — Real-time federal, state, and self-employment tax estimates using 2024 IRS brackets for all filing statuses
- **Tax Optimizer** — Personalized deductions calculated from your actual profile (mileage, home office, phone, health insurance, SEP-IRA, QBI, and more)
- **Spending Analysis** — Manual expense entry with live percentage breakdown chart, Plaid bank connection, or demo data
- **AI Chat Advisor** — Conversational financial assistant powered by Claude, with full profile context
- **Financial Analysis** — AI-generated deduction roadmap and tax strategy via Google Gemini
- **PDF Tax Report** — Downloadable tax summary report
- **Data Import** — CSV upload, Plaid bank sync, or manual entry
- **Onboarding Survey** — 11-step profile builder covering platforms, per-platform earnings, filing status, dependents, state, housing, home office, vehicle, and expenses

---

## Tech Stack

### Mobile (Flutter)
| Package | Purpose |
|---|---|
| Flutter / Dart 3.5 | Mobile framework |
| Provider | State management |
| Google Fonts | Typography (DM Sans, DM Mono) |
| fl_chart | Charts and data visualization |
| http | Backend API communication |
| file_picker | CSV file upload |
| share_plus | PDF sharing |
| path_provider | File system access |

### Backend (Next.js)
| Package | Purpose |
|---|---|
| Next.js 15 / React 19 | API routes and web layer |
| TypeScript | Type safety |
| Tailwind CSS | Styling |
| Anthropic Claude (`claude-haiku-4-5-20251001`) | AI chat advisor |
| Google Gemini (`gemini-2.0-flash`) | Financial analysis |
| Plaid | Bank account connection |
| pdf-lib | PDF tax report generation |
| Recharts | Web charts |
| Framer Motion | Animations |
| Lucide React / Heroicons | Icons |
| Sonner | Toast notifications |

---

## Project Structure

```
GigFlow/
├── mobile/                        # Flutter mobile app
│   └── lib/
│       ├── models/                # UserProfile, Deduction, TaxEstimate, etc.
│       ├── providers/             # UserProfileProvider (state)
│       ├── screens/
│       │   ├── dashboard/         # Income dashboard
│       │   ├── deductions/        # Tax optimizer & deduction cards
│       │   ├── spending/          # Spending analysis
│       │   ├── import/            # Data import (CSV, Plaid, manual)
│       │   └── onboarding/        # 11-step survey
│       ├── utils/
│       │   ├── tax_calculations.dart   # Local tax engine (2024 IRS brackets)
│       │   ├── backend_api.dart        # HTTP client for Next.js backend
│       │   ├── claude_api.dart         # Chat + analysis API wrappers
│       │   ├── colors.dart             # Design tokens
│       │   └── constants.dart          # Platform configs, vehicle rates
│       └── widgets/               # Shared UI components
│
├── src/                           # Next.js backend
│   └── app/
│       └── api/
│           ├── chat/              # Claude chat endpoint
│           ├── analyze/           # Gemini financial analysis endpoint
│           ├── report/            # PDF generation endpoint
│           └── parse-earnings/    # CSV parsing endpoint
│
├── package.json
└── mobile/pubspec.yaml
```

---

## Getting Started

### Prerequisites
- Node.js 18+
- Flutter SDK 3.5+
- Android emulator or physical device

### Backend

1. Install dependencies:
```bash
npm install
```

2. Create a `.env.local` file in the project root:
```env
ANTHROPIC_API_KEY=your_claude_api_key
GEMINI_API_KEY=your_gemini_api_key
PLAID_CLIENT_ID=your_plaid_client_id
PLAID_SECRET=your_plaid_secret
```

3. Start the dev server:
```bash
npm run dev
```

The backend runs on `http://localhost:4028`.

### Mobile App

1. Install Flutter dependencies:
```bash
cd mobile
flutter pub get
```

2. Run on Android emulator (the app talks to `10.0.2.2:4028` which maps to your machine's localhost):
```bash
flutter run
```

---

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/chat` | Claude AI chat with profile context |
| POST | `/api/analyze` | Gemini financial analysis (deductions + roadmap) |
| POST | `/api/report` | Generate PDF tax report |
| POST | `/api/parse-earnings` | Parse CSV earnings file |

---

## Tax Engine

GigFlow calculates taxes locally using real 2024 IRS data — no AI guessing for core numbers:

- **Federal tax** — All 7 progressive brackets (10%–37%) for single, married filing jointly, married filing separately, and head of household
- **Self-employment tax** — 15.3% on 92.35% of net earnings
- **State tax** — Flat and progressive rates for all 50 states (no-tax states return $0)
- **Deductions** — Mileage (67¢/mile), home office (12% of rent), phone (85%), SE tax deduction, QBI (20%), health insurance, equipment, SEP-IRA (25% net, max $66k)

---

## Scripts

```bash
npm run dev          # Start backend dev server (port 4028)
npm run build        # Production build
npm run lint         # ESLint check
npm run lint:fix     # Auto-fix lint issues
npm run format       # Prettier format
npm run type-check   # TypeScript check
```
