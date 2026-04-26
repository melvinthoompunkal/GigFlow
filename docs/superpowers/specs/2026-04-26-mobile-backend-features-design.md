# GigFlow Mobile — Backend Features & Spending Tab

**Date:** 2026-04-26  
**Context:** Hackathon build — Android Studio emulator, Next.js backend on localhost (10.0.2.2:3000)

---

## Overview

Port three backend features (CSV upload, tax PDF download, Plaid integration) to the Flutter mobile app, and add a new 4th tab for Plaid spending analysis. The Plaid flow is a polished demo-first experience — real Plaid SDK is skipped in favour of a loading animation that resolves to demo data, ensuring zero live-demo failure risk.

---

## Architecture

### New Files
- `mobile/lib/screens/import/import_screen.dart` — 4-option data import screen
- `mobile/lib/screens/spending/spending_analysis_screen.dart` — new 4th tab
- `mobile/lib/utils/demo_data.dart` — centralised demo spending data
- `mobile/lib/utils/backend_api.dart` — HTTP calls to Next.js backend at `http://10.0.2.2:3000`

### Modified Files
- `mobile/pubspec.yaml` — add `file_picker`, `share_plus`, `path_provider`
- `mobile/lib/main.dart` — add `/import` and `/spending` routes
- `mobile/lib/widgets/app_tab_bar.dart` — extend to 4 tabs
- `mobile/lib/screens/splash_screen.dart` — route unonboarded users to `/import` instead of `/onboarding`
- `mobile/lib/screens/dashboard/income_dashboard_screen.dart` — add "Update Data" button
- `mobile/lib/screens/deductions/deductions_roadmap_screen.dart` — add PDF download button

---

## Feature 1: Data Import Screen (`import_screen.dart`)

A full-screen card-based picker shown during onboarding and accessible from the dashboard.

### Two contexts
- **Onboarding** (`isModal: false`): splash routes here via `pushReplacementNamed('/import')`. On success, each option calls `Navigator.pushReplacementNamed('/income-dashboard')`.
- **Dashboard modal** (`isModal: true`): opened via `Navigator.push(MaterialPageRoute(...))`. On success, each option calls `Navigator.pop()` and the dashboard rebuilds from provider state.

`ImportScreen` accepts `const ImportScreen({this.isModal = false})` to handle both contexts.

### Four option cards (top-to-bottom):

1. **Connect to Bank** — `account_balance_rounded` icon, subtitle "Securely import your transactions via Plaid"
   - Tap → show a `BottomSheet` with animated progress indicator and "Connecting to Plaid…" text for 1.5s
   - After delay → call `provider.activateDemoMode()` + `provider.setIsBankConnected(true)` → navigate per `isModal` flag
   - Dashboard checks `provider.profile.isBankConnected` to show a green "Bank Connected ✓" banner for 3s on first render, then auto-dismisses

2. **Demo Mode** — `auto_awesome_rounded` icon, subtitle "Explore with sample data — no account needed"
   - Tap → `provider.activateDemoMode()` → `Navigator.pushReplacementNamed('/income-dashboard')`

3. **Enter Manually** — `edit_rounded` icon, subtitle "Input your earnings step by step"
   - Tap → `Navigator.pushReplacementNamed('/onboarding')`

4. **Upload CSV** — `upload_file_rounded` icon, subtitle "Import earnings from Uber, DoorDash, Lyft and more"
   - Tap → `FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv'])`
   - On pick → POST multipart/form-data to `http://10.0.2.2:3000/api/parse-earnings`
   - On success → update provider with parsed earnings, navigate to `/income-dashboard`
   - On error → show `SnackBar` with error message

### Layout
- Header: GigFlow logo + tagline "How would you like to get started?"
- Cards use the existing `kCardDecoration()` pattern with green highlight on active state
- Cards are NOT selectable — each tap immediately acts
- Footer: small text "Your data stays private and secure"

---

## Feature 2: Spending Analysis Tab (`spending_analysis_screen.dart`)

New 4th tab in the bottom nav bar. Route: `/spending`.

### Structure (top-to-bottom):

**Header card** (green gradient, same as dashboard YTD card)
- Title: "Last 30 Days"
- Subtitle: "Spending Overview"
- Amount: `$2,847` (large, DM Mono)
- "Demo Data" badge: small grey pill, top-right corner

**Horizontal bar chart section**
- Title: "Spending by Category"
- 7 categories, each row: label left, filled bar centre, amount + % right
- Bar width proportional to % of total, max width = screen width minus padding
- Colour coding:
  - Groceries → `kGreen`
  - Eating Out → `kAmber`
  - Transportation → `kBlue`
  - Essentials → `kTeal`
  - Entertainment → `Color(0xFF8B5CF6)` (purple)
  - Shopping → `Color(0xFFEC4899)` (pink)
  - Other → `kTextMuted`
- Animated on screen entry via `TweenAnimationBuilder` (bars grow left-to-right, 600ms)

**Demo spending data** (in `demo_data.dart`):
```
Groceries       $612   21.5%
Eating Out      $498   17.5%
Transportation  $387   13.6%
Essentials      $341   12.0%
Entertainment   $284   10.0%
Shopping        $426   15.0%
Other           $299   10.5%
Total           $2,847
```

**Top Merchants section**
- Title: "Top Merchants"
- 5 rows: merchant name left, amount right (DM Mono)
- Data: Trader Joe's $214, Uber $187, McDonald's $143, Amazon $126, CVS $98

**Insight card** (green background, same as `kGreenBg`)
- Icon: `lightbulb_rounded` in green
- Text: "Eating out is your 2nd biggest spend at 17.5% of total. Cutting back by $100/mo saves $1,200/year."

---

## Feature 3: Tab Bar Update (`app_tab_bar.dart`)

Add Spending as the 3rd tab (between Deductions and Chat):

| Position | Label | Icon | Route |
|---|---|---|---|
| 0 | Dashboard | `bar_chart_rounded` | `/income-dashboard` |
| 1 | Deductions | `receipt_long_rounded` | `/deductions-roadmap` |
| 2 | Spending | `pie_chart_rounded` | `/spending` |
| 3 | AI Chat | `chat_bubble_rounded` | `/chat` |

---

## Feature 4: PDF Download (`deductions_roadmap_screen.dart`)

Add a "Download Tax Report" button at the bottom of the Deductions tab content (above the disclaimer, below the deduction card list).

- Style: full-width green outlined button (not filled, to differentiate from primary actions)
- Icon: `download_rounded`
- Tap flow:
  1. Show loading spinner inside button
  2. POST to `http://10.0.2.2:3000/api/report` with profile JSON
  3. On success → save bytes to temp file via `path_provider` → open Android share sheet via `share_plus`
  4. On error → `SnackBar("Could not generate report — is the backend running?")`

---

## Feature 5: Dashboard "Update Data" Button

In `income_dashboard_screen.dart`, add a compact row below the YTD header card:

- A pill-shaped button: `update_rounded` icon + "Update Data" label
- Tap → push `ImportScreen` as a full-screen modal (not replacement)
- After import returns, refresh provider if data changed

---

## Feature 6: `backend_api.dart`

```
const _base = 'http://10.0.2.2:3000';

Future<Map<String, dynamic>> uploadCsv(Uint8List bytes, String filename)
  → multipart POST to $_base/api/parse-earnings
  → returns parsed JSON or throws BackendException

Future<Uint8List> downloadReport(Map<String, dynamic> profileJson)
  → POST to $_base/api/report with JSON body
  → returns raw bytes or throws BackendException
```

---

## Dependencies to Add

```yaml
file_picker: ^8.1.2
share_plus: ^10.0.0
path_provider: ^2.1.4
```

---

## Splash Screen Routing Change

Current: unonboarded → `/onboarding`  
New: unonboarded → `/import`

The `Enter Manually` card on ImportScreen routes to `/onboarding`, preserving the existing flow.

---

## Provider Changes (`UserProfileProvider`)

- Add `isBankConnected` bool field to `UserProfile` model, default `false`
- Add `setIsBankConnected(bool)` method to provider
- Dashboard reads this field once on init, shows banner, then resets it to false via `WidgetsBinding.addPostFrameCallback`

---

## What Is NOT Changing

- Existing onboarding survey (unchanged, still accessible via "Enter Manually")
- Chat screen, deductions screen structure, dashboard charts
- Claude API direct calls (claude_api.dart)
- Demo data for income/deductions/roadmap (already in UserProfileProvider)
