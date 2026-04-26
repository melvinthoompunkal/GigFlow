---
date: 2026-04-26
topic: Manual Entry Data Integrity
status: approved
---

# Manual Entry Data Integrity

## Problem

Manual onboarding collects data that is never fully used:
- Earnings entered as a bucket range (not real dollars), then platform breakdown is faked with jitter math
- Dependents is a yes/no binary; tax code gives $2,000 Child Tax Credit *per child*
- "Connect to Bank" calls `activateDemoMode()`, overwriting any real profile with demo data
- The AI analysis prompt receives real profile fields, but the dashboard's local tax calculations use the same imprecise inputs

## Scope

Flutter mobile app only. No web dashboard changes.

---

## Changes

### 1. Model — `user_profile.dart`

- Add `platformEarnings: Map<String, int>` — maps platform enum name → monthly earnings in dollars
- Replace `hasDependents: bool` with `dependentCount: int` (getter `hasDependents => dependentCount > 0`)
- Add `monthlyRent: int` — monthly housing cost (rent or mortgage); used for home office deduction
- Update `copyWith()` and default values

### 2. Onboarding — `onboarding_survey_screen.dart`

Total steps increases from 10 → 11. New step order (0-indexed):

| # | Step | Change |
|---|---|---|
| 0 | Platforms | unchanged |
| 1 | **Per-platform earnings** | NEW — replaces bucket picker |
| 2 | Filing status | unchanged |
| 3 | **Dependent count** | CHANGED — was yes/no |
| 4 | State | unchanged |
| 5 | Housing type | unchanged |
| 6 | **Monthly housing cost** | NEW |
| 7 | Home office | unchanged |
| 8 | Vehicle | unchanged |
| 9 | Expenses | unchanged |
| 10 | Review | unchanged |

- `_StepPlatformEarnings`: one slider per selected platform + custom platforms, range $0–$8,000, step $50. `canProceed` (case 1): `platformEarnings.values.any((v) => v > 0)`.
- `_StepDependentCount`: stepper 0–6 with inline CTC impact note (`count × $2,000/yr saved`).
- `_StepMonthlyRent`: slider $0–$5,000, step $50. Label adapts: "Monthly Rent" or "Monthly Mortgage" based on housingType. Always optional (canProceed = true).
- `_handleComplete()`: sets `monthlyEarnings = platformEarnings.values.fold(0, (s,v)=>s+v)` before analysis call.

### 3. Tax Calculations — `tax_calculations.dart`

- **State tax**: replace flat-rate map with `_progressive()` helper + full bracket tables for CA, NY, OR, MN, WI, NJ, VA, MD, CT, HI, OH. Flat rates for MA, IL, PA, CO, AZ, GA, NC, IN, MI, MO. Zero for TX, FL, WA, NV, WY, SD, AK, TN, NH.
- `estimateFederalTax()`: `dependentCount: int` replaces `hasDependents: bool`. Credit = `min(dependentCount * 2000, tax)`.
- `generatePlatformBreakdown()`: reads `profile.platformEarnings[platform.name]` directly. Falls back to jitter only when map is empty.
- `calculateTaxBreakdown()`: passes `profile.dependentCount`.
- `calculateTaxHealthScore()`: uses `profile.dependentCount > 0`; adds points for `monthlyRent > 0 && hasHomeOffice`.

### 4. Provider — `user_profile_provider.dart`

- Demo profile: set `platformEarnings: {'uber': 1800, 'doordash': 1500, 'lyft': 900}`, `dependentCount: 0`, `monthlyRent: 1400`.
- Fallback analysis unchanged in content.

### 5. Import Screen — `import_screen.dart`

- `_connectToBank()`: remove `provider.activateDemoMode()`. Only call `provider.setIsBankConnected(true)`.

### 6. Backend Prompt — `claude_api.dart` + `analyze/route.ts`

- `_profileToJson()`: include `platformEarnings` map, `dependentCount`, `monthlyRent`.
- `analyze/route.ts`: expand Gemini prompt to include per-platform breakdown, dependent count, monthly rent.

---

## Data Flow After Fix

```
Onboarding:
  User picks platforms → enters $ per platform → sum = monthlyEarnings stored in profile

Dashboard:
  generatePlatformBreakdown() reads platformEarnings directly → real split, no jitter

Tax calc:
  estimateFederalTax(dependentCount) → dependentCount * 2000 credit

AI analysis:
  _profileToJson() sends platformEarnings + dependentCount → Gemini sees real numbers

Import screen:
  "Connect to Bank" → isBankConnected = true, profile unchanged
```

---

## Out of Scope

- Web dashboard changes
- Plaid real transaction ingestion (stays as stub)
- Chat streaming via Gemini backend
- CSV import enhancements
