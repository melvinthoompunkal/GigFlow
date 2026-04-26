# Manual Entry Data Integrity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace bucketed/binary onboarding inputs with real per-platform earnings, dependent count, and monthly rent; wire all collected data into local tax calculations and the Gemini analysis prompt; remove the demo-mode data leak in the bank connect flow.

**Architecture:** All new data fields live on `UserProfile`. Tax calculations read directly from those fields — no intermediate derived values. The Gemini prompt receives the full enriched profile. No new files; all changes are in-place edits.

**Tech Stack:** Flutter/Dart 3 (mobile), Next.js/TypeScript (backend), Google Gemini API

---

## File Map

| File | Change |
|---|---|
| `mobile/lib/models/user_profile.dart` | Add `platformEarnings`, `dependentCount`, `monthlyRent`; remove `hasDependents` field |
| `mobile/lib/utils/tax_calculations.dart` | Progressive state brackets; dependentCount; platform breakdown from real data |
| `mobile/lib/providers/user_profile_provider.dart` | Update demo profile and fallback to match new model |
| `mobile/lib/screens/onboarding/onboarding_survey_screen.dart` | New steps: per-platform earnings, dependent count, monthly rent |
| `mobile/lib/utils/claude_api.dart` | Include new fields in `_profileToJson` |
| `mobile/lib/screens/import/import_screen.dart` | Remove `activateDemoMode()` from `_connectToBank` |
| `src/app/api/analyze/route.ts` | Include per-platform earnings, dependentCount, monthlyRent in Gemini prompt |
| `mobile/test/tax_calculations_test.dart` | Unit tests for new tax calculation logic (create) |

---

### Task 1: Update UserProfile model

**Files:**
- Modify: `mobile/lib/models/user_profile.dart`

- [ ] **Step 1: Replace the UserProfile model**

Replace the entire file with:

```dart
enum Platform { uber, lyft, doordash, instacart, upwork, fiverr, amazonFlex, grubhub, taskrabbit, rover }

enum FilingStatus { single, marriedJoint, marriedSeparate, headOfHousehold }

enum VehicleType { car, suv, truck, motorcycle, bicycle, none }

enum HousingType { own, rent }

class Deduction {
  final String id;
  final String icon;
  final String name;
  final String explanation;
  final int value;
  final String eligibility;
  final String category;

  const Deduction({
    required this.id,
    required this.icon,
    required this.name,
    required this.explanation,
    required this.value,
    required this.eligibility,
    required this.category,
  });

  factory Deduction.fromJson(Map<String, dynamic> j) => Deduction(
        id: j['id'] as String,
        icon: j['icon'] as String,
        name: j['name'] as String,
        explanation: j['explanation'] as String,
        value: (j['value'] as num).toInt(),
        eligibility: j['eligibility'] as String,
        category: j['category'] as String,
      );
}

class TaxEstimate {
  final int selfEmployment;
  final int federal;
  final int state;
  final int total;
  final int monthly;
  final int quarterly;

  const TaxEstimate({
    required this.selfEmployment,
    required this.federal,
    required this.state,
    required this.total,
    required this.monthly,
    required this.quarterly,
  });

  factory TaxEstimate.fromJson(Map<String, dynamic> j) => TaxEstimate(
        selfEmployment: (j['selfEmployment'] as num).toInt(),
        federal: (j['federal'] as num).toInt(),
        state: (j['state'] as num).toInt(),
        total: (j['total'] as num).toInt(),
        monthly: (j['monthly'] as num).toInt(),
        quarterly: (j['quarterly'] as num).toInt(),
      );
}

class RoadmapStep {
  final String id;
  final int step;
  final String title;
  final String description;
  final String deadline;
  final String priority;
  final bool completed;

  const RoadmapStep({
    required this.id,
    required this.step,
    required this.title,
    required this.description,
    required this.deadline,
    required this.priority,
    required this.completed,
  });

  factory RoadmapStep.fromJson(Map<String, dynamic> j) => RoadmapStep(
        id: j['id'] as String,
        step: (j['step'] as num).toInt(),
        title: j['title'] as String,
        description: j['description'] as String,
        deadline: j['deadline'] as String,
        priority: j['priority'] as String,
        completed: j['completed'] as bool? ?? false,
      );
}

class ClaudeAnalysis {
  final List<Deduction> deductions;
  final TaxEstimate taxEstimate;
  final List<RoadmapStep> roadmap;

  const ClaudeAnalysis({
    required this.deductions,
    required this.taxEstimate,
    required this.roadmap,
  });
}

class Expenses {
  final int gas;
  final int phone;
  final int insurance;
  final int equipment;
  final int health;
  final int food;

  const Expenses({
    this.gas = 0,
    this.phone = 0,
    this.insurance = 0,
    this.equipment = 0,
    this.health = 0,
    this.food = 0,
  });

  Expenses copyWith({int? gas, int? phone, int? insurance, int? equipment, int? health, int? food}) {
    return Expenses(
      gas: gas ?? this.gas,
      phone: phone ?? this.phone,
      insurance: insurance ?? this.insurance,
      equipment: equipment ?? this.equipment,
      health: health ?? this.health,
      food: food ?? this.food,
    );
  }
}

class UserProfile {
  final List<Platform> platforms;
  final List<String> customPlatforms;
  /// Maps Platform.name (e.g. 'uber') → monthly earnings in dollars.
  final Map<String, int> platformEarnings;
  /// Computed from platformEarnings; stored separately for CSV/demo paths.
  final int monthlyEarnings;
  final FilingStatus filingStatus;
  final int dependentCount;
  final String state;
  final HousingType housingType;
  /// Monthly rent or mortgage payment. Used for home office deduction.
  final int monthlyRent;
  final bool hasHomeOffice;
  final VehicleType vehicleType;
  final Expenses expenses;
  final ClaudeAnalysis? claudeAnalysis;
  final bool isOnboarded;
  final bool isDemoMode;
  final bool isBankConnected;

  bool get hasDependents => dependentCount > 0;

  const UserProfile({
    this.platforms = const [],
    this.customPlatforms = const [],
    this.platformEarnings = const {},
    this.monthlyEarnings = 0,
    this.filingStatus = FilingStatus.single,
    this.dependentCount = 0,
    this.state = '',
    this.housingType = HousingType.rent,
    this.monthlyRent = 0,
    this.hasHomeOffice = false,
    this.vehicleType = VehicleType.car,
    this.expenses = const Expenses(),
    this.claudeAnalysis,
    this.isOnboarded = false,
    this.isDemoMode = false,
    this.isBankConnected = false,
  });

  UserProfile copyWith({
    List<Platform>? platforms,
    List<String>? customPlatforms,
    Map<String, int>? platformEarnings,
    int? monthlyEarnings,
    FilingStatus? filingStatus,
    int? dependentCount,
    String? state,
    HousingType? housingType,
    int? monthlyRent,
    bool? hasHomeOffice,
    VehicleType? vehicleType,
    Expenses? expenses,
    ClaudeAnalysis? claudeAnalysis,
    bool? isOnboarded,
    bool? isDemoMode,
    bool? isBankConnected,
  }) {
    return UserProfile(
      platforms: platforms ?? this.platforms,
      customPlatforms: customPlatforms ?? this.customPlatforms,
      platformEarnings: platformEarnings ?? this.platformEarnings,
      monthlyEarnings: monthlyEarnings ?? this.monthlyEarnings,
      filingStatus: filingStatus ?? this.filingStatus,
      dependentCount: dependentCount ?? this.dependentCount,
      state: state ?? this.state,
      housingType: housingType ?? this.housingType,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      hasHomeOffice: hasHomeOffice ?? this.hasHomeOffice,
      vehicleType: vehicleType ?? this.vehicleType,
      expenses: expenses ?? this.expenses,
      claudeAnalysis: claudeAnalysis ?? this.claudeAnalysis,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      isBankConnected: isBankConnected ?? this.isBankConnected,
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add mobile/lib/models/user_profile.dart
git commit -m "feat: add platformEarnings, dependentCount, monthlyRent to UserProfile"
```

---

### Task 2: Fix tax calculations

**Files:**
- Modify: `mobile/lib/utils/tax_calculations.dart`
- Create: `mobile/test/tax_calculations_test.dart`

- [ ] **Step 1: Write failing tests**

Create `mobile/test/tax_calculations_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gigflow/utils/tax_calculations.dart';
import 'package:gigflow/models/user_profile.dart';

void main() {
  group('estimateStateTax', () {
    test('Texas returns 0 (no income tax)', () {
      expect(estimateStateTax(50000, 'TX'), 0);
    });

    test('Florida returns 0 (no income tax)', () {
      expect(estimateStateTax(50000, 'FL'), 0);
    });

    test('California uses progressive brackets', () {
      // $50,000: bracket up to $54,081 at 6% after lower brackets
      // Should be significantly more than flat 9.3% of 50k ($4,650)
      // but the progressive result for 50k in CA is around $2,200-2,500
      final tax = estimateStateTax(50000, 'CA');
      expect(tax, greaterThan(1500));
      expect(tax, lessThan(4000));
    });

    test('New York uses progressive brackets', () {
      final tax = estimateStateTax(60000, 'NY');
      expect(tax, greaterThan(2000));
      expect(tax, lessThan(5000));
    });

    test('Unknown state uses 5% fallback', () {
      expect(estimateStateTax(40000, 'ZZ'), 2000);
    });
  });

  group('estimateFederalTax', () {
    test('dependentCount=0 has no child tax credit', () {
      final withZero = estimateFederalTax(50000, FilingStatus.single, 0);
      final withOne  = estimateFederalTax(50000, FilingStatus.single, 1);
      expect(withOne, lessThan(withZero));
      expect(withZero - withOne, 2000);
    });

    test('dependentCount=2 reduces tax by up to $4,000', () {
      final withZero = estimateFederalTax(50000, FilingStatus.single, 0);
      final withTwo  = estimateFederalTax(50000, FilingStatus.single, 2);
      expect(withZero - withTwo, 4000);
    });

    test('credit does not drive tax below zero', () {
      // Very low income, many dependents
      expect(estimateFederalTax(5000, FilingStatus.single, 10), 0);
    });
  });

  group('generatePlatformBreakdown', () {
    test('uses platformEarnings directly when provided', () {
      final profile = UserProfile(
        platforms: [Platform.uber, Platform.doordash],
        platformEarnings: {'uber': 2000, 'doordash': 1000},
        monthlyEarnings: 3000,
      );
      final breakdown = generatePlatformBreakdown(profile);
      final uber = breakdown.firstWhere((b) => b.platform == Platform.uber);
      final dd   = breakdown.firstWhere((b) => b.platform == Platform.doordash);
      expect(uber.monthly, 2000);
      expect(dd.monthly, 1000);
    });

    test('falls back to even split when platformEarnings is empty', () {
      final profile = UserProfile(
        platforms: [Platform.uber, Platform.lyft],
        platformEarnings: const {},
        monthlyEarnings: 2000,
      );
      final breakdown = generatePlatformBreakdown(profile);
      expect(breakdown.length, 2);
      // Each gets roughly 1000 (even split with jitter)
      for (final b in breakdown) {
        expect(b.monthly, greaterThan(0));
      }
    });
  });
}
```

- [ ] **Step 2: Run tests and confirm they fail**

```bash
cd mobile && flutter test test/tax_calculations_test.dart
```

Expected: compilation errors or failures — functions don't match new signatures yet.

- [ ] **Step 3: Replace tax_calculations.dart**

Replace the entire file:

```dart
import '../models/user_profile.dart';

class MonthlyDataPoint {
  final String month;
  final int earnings;
  final int projected;
  const MonthlyDataPoint({required this.month, required this.earnings, required this.projected});
}

class PlatformBreakdown {
  final Platform platform;
  final double share;
  final int monthly;
  final List<int> trend;
  const PlatformBreakdown({required this.platform, required this.share, required this.monthly, required this.trend});
}

List<MonthlyDataPoint> generateMonthlyData(int monthlyEarnings) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const variances = [0.82, 0.91, 0.88, 0.95, 1.04, 1.12, 1.08, 0.97, 1.15, 1.03, 0.94, 1.20];
  final currentMonth = DateTime.now().month - 1;
  return List.generate(12, (i) => MonthlyDataPoint(
    month: months[i],
    earnings: i <= currentMonth ? (monthlyEarnings * variances[i]).round() : 0,
    projected: i > currentMonth ? (monthlyEarnings * variances[i]).round() : 0,
  ));
}

List<PlatformBreakdown> generatePlatformBreakdown(UserProfile profile) {
  final platforms = profile.platforms;
  if (platforms.isEmpty) return [];
  final total = profile.monthlyEarnings;
  const trendMults = [0.8, 0.9, 1.0, 0.95, 1.1, 1.05];

  // Use real per-platform earnings when available
  if (profile.platformEarnings.isNotEmpty) {
    final grandTotal = profile.platformEarnings.values.fold(0, (s, v) => s + v);
    if (grandTotal == 0) return [];
    return platforms.map((p) {
      final monthly = profile.platformEarnings[p.name] ?? 0;
      final share = monthly / grandTotal;
      return PlatformBreakdown(
        platform: p,
        share: share,
        monthly: monthly,
        trend: trendMults.map((t) => (monthly * t * 0.2).round()).toList(),
      );
    }).where((b) => b.monthly > 0).toList();
  }

  // Fallback: jitter-based even split (demo mode / CSV import)
  final splits = List.generate(platforms.length, (i) {
    final base = 1.0 / platforms.length;
    final jitter = (i % 2 == 0 ? 0.15 : -0.1);
    return (base + jitter / platforms.length).clamp(0.05, 1.0);
  });
  final splitTotal = splits.reduce((a, b) => a + b);
  final normalized = splits.map((s) => s / splitTotal).toList();

  return List.generate(platforms.length, (i) => PlatformBreakdown(
    platform: platforms[i],
    share: normalized[i],
    monthly: (total * normalized[i]).round(),
    trend: trendMults.map((t) => (total * normalized[i] * t * 0.2).round()).toList(),
  ));
}

// ── Progressive tax helper ────────────────────────────────────────────────────

/// brackets: list of (upperLimit, rate). Last bracket upper = double.infinity.
int _progressive(int income, List<(double, double)> brackets) {
  double tax = 0;
  double prev = 0;
  for (final (limit, rate) in brackets) {
    if (income <= prev) break;
    final top = limit == double.infinity ? income.toDouble() : limit;
    final slice = (income < top ? income.toDouble() : top) - prev;
    tax += slice * rate;
    if (income <= limit) break;
    prev = limit;
  }
  return tax.round();
}

// ── State tax ─────────────────────────────────────────────────────────────────

int estimateStateTax(int annualIncome, String state) {
  const noTax = {'TX', 'FL', 'WA', 'NV', 'WY', 'SD', 'AK', 'TN', 'NH'};
  if (noTax.contains(state)) return 0;

  switch (state) {
    case 'CA':
      return _progressive(annualIncome, [
        (10412,  0.01), (24684,  0.02), (38959,  0.04),
        (54081,  0.06), (68350,  0.08), (349137, 0.093),
        (418961, 0.103),(698274, 0.113),(double.infinity, 0.123),
      ]);
    case 'NY':
      return _progressive(annualIncome, [
        (17150,  0.040), (23600,  0.045), (27900,  0.0525),
        (161550, 0.0585),(323200, 0.0625),(2155350, 0.0685),
        (double.infinity, 0.109),
      ]);
    case 'OR':
      return _progressive(annualIncome, [
        (17400, 0.0475),(43750, 0.0675),
        (250000, 0.0875),(double.infinity, 0.099),
      ]);
    case 'MN':
      return _progressive(annualIncome, [
        (31690,  0.0535),(104090, 0.068),
        (193240, 0.0785),(double.infinity, 0.0985),
      ]);
    case 'WI':
      return _progressive(annualIncome, [
        (13810,  0.0354),(27630,  0.0465),
        (304170, 0.053),(double.infinity, 0.0765),
      ]);
    case 'NJ':
      return _progressive(annualIncome, [
        (20000,  0.014),(35000,  0.0175),(40000,  0.035),
        (75000,  0.05525),(500000, 0.0637),(double.infinity, 0.1075),
      ]);
    case 'VA':
      return _progressive(annualIncome, [
        (3000,  0.02),(5000,  0.03),
        (17000, 0.05),(double.infinity, 0.0575),
      ]);
    case 'MD':
      return _progressive(annualIncome, [
        (1000,   0.02),(2000,   0.03),(3000,   0.04),
        (100000, 0.0475),(125000, 0.05),(150000, 0.0525),
        (250000, 0.055),(double.infinity, 0.0575),
      ]);
    case 'CT':
      return _progressive(annualIncome, [
        (10000,  0.02),(50000,  0.045),(100000, 0.055),
        (200000, 0.06),(250000, 0.065),(double.infinity, 0.0699),
      ]);
    case 'HI':
      return _progressive(annualIncome, [
        (9600,  0.014),(19200, 0.032),(28800, 0.055),
        (38400, 0.064),(48000, 0.068),(150000, 0.072),
        (175000, 0.076),(200000, 0.079),(double.infinity, 0.11),
      ]);
    case 'OH':
      return _progressive(annualIncome, [
        (26050, 0.0),(100000, 0.02765),(double.infinity, 0.0399),
      ]);
    // Flat-rate states
    case 'MA': return (annualIncome * 0.05).round();
    case 'IL': return (annualIncome * 0.0495).round();
    case 'PA': return (annualIncome * 0.0307).round();
    case 'CO': return (annualIncome * 0.044).round();
    case 'AZ': return (annualIncome * 0.025).round();
    case 'GA': return (annualIncome * 0.0549).round();
    case 'NC': return (annualIncome * 0.0475).round();
    case 'IN': return (annualIncome * 0.0305).round();
    case 'MI': return (annualIncome * 0.0425).round();
    case 'MO': return (annualIncome * 0.0495).round();
    case 'SC': return (annualIncome * 0.064).round();
    case 'AL': return (annualIncome * 0.05).round();
    case 'KY': return (annualIncome * 0.045).round();
    case 'LA': return (annualIncome * 0.0425).round();
    case 'MS': return (annualIncome * 0.05).round();
    case 'ID': return (annualIncome * 0.058).round();
    case 'UT': return (annualIncome * 0.0485).round();
    case 'NM': return (annualIncome * 0.059).round();
    case 'KS': return (annualIncome * 0.057).round();
    case 'IA': return (annualIncome * 0.06).round();
    case 'NE': return (annualIncome * 0.0664).round();
    case 'AR': return (annualIncome * 0.0475).round();
    case 'OK': return (annualIncome * 0.0475).round();
    case 'DE': return (annualIncome * 0.066).round();
    case 'RI': return (annualIncome * 0.0599).round();
    case 'VT': return (annualIncome * 0.0875).round();
    case 'ME': return (annualIncome * 0.0715).round();
    case 'ND': return (annualIncome * 0.025).round();
    case 'MT': return (annualIncome * 0.0675).round();
    case 'WV': return (annualIncome * 0.065).round();
    case 'AK': return 0;
    default:   return (annualIncome * 0.05).round();
  }
}

// ── Federal tax ───────────────────────────────────────────────────────────────

int estimateSelfEmploymentTax(int annualIncome) {
  final netEarnings = annualIncome * 0.9235;
  return (netEarnings * 0.153).round();
}

int estimateFederalTax(int annualIncome, FilingStatus filingStatus, int dependentCount) {
  final standardDeduction = filingStatus == FilingStatus.marriedJoint
      ? 29200
      : filingStatus == FilingStatus.headOfHousehold
          ? 21900
          : 14600;
  final seTaxDeduction = estimateSelfEmploymentTax(annualIncome) * 0.5;
  final taxableIncome = (annualIncome - standardDeduction - seTaxDeduction).clamp(0, double.infinity).toInt();

  int tax;
  if (filingStatus == FilingStatus.marriedJoint) {
    tax = _progressive(taxableIncome, [
      (23200,  0.10),(94300,  0.12),(201050, 0.22),
      (double.infinity, 0.24),
    ]);
  } else {
    tax = _progressive(taxableIncome, [
      (11600,  0.10),(47150,  0.12),(100525, 0.22),
      (double.infinity, 0.24),
    ]);
  }

  final credit = dependentCount * 2000;
  return (tax - credit).clamp(0, double.infinity).round();
}

// ── Full breakdown ────────────────────────────────────────────────────────────

TaxEstimate calculateTaxBreakdown(UserProfile profile) {
  final annual = profile.monthlyEarnings * 12;
  final se = estimateSelfEmploymentTax(annual);
  final federal = estimateFederalTax(annual, profile.filingStatus, profile.dependentCount);
  final state = estimateStateTax(annual, profile.state);
  final total = se + federal + state;
  return TaxEstimate(
    selfEmployment: se,
    federal: federal,
    state: state,
    total: total,
    monthly: (total / 12).round(),
    quarterly: (total / 4).round(),
  );
}

int calculateTaxHealthScore(UserProfile profile) {
  int score = 40;
  if (profile.platforms.isNotEmpty) score += 10;
  if (profile.vehicleType != VehicleType.none) score += 10;
  if (profile.hasHomeOffice) score += 10;
  if (profile.hasHomeOffice && profile.monthlyRent > 0) score += 5;
  if (profile.expenses.health > 0) score += 5;
  if (profile.expenses.phone > 0) score += 5;
  if (profile.hasDependents) score += 5;
  if (profile.claudeAnalysis != null) score += 10;
  return score.clamp(0, 100);
}
```

- [ ] **Step 4: Run tests and confirm they pass**

```bash
cd mobile && flutter test test/tax_calculations_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/utils/tax_calculations.dart mobile/test/tax_calculations_test.dart
git commit -m "feat: progressive state tax brackets, dependentCount credit, real platform breakdown"
```

---

### Task 3: Update provider and demo data

**Files:**
- Modify: `mobile/lib/providers/user_profile_provider.dart`

- [ ] **Step 1: Update provider to use new model fields**

Replace the entire file:

```dart
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

const _fallbackDeductions = [
  Deduction(id: 'ded-mileage', icon: '🚗', name: 'Standard Mileage Deduction', explanation: 'Deduct 67¢ per mile driven for gig work in 2024. Based on your vehicle type and estimated annual mileage.', value: 3685, eligibility: 'high', category: 'Vehicle'),
  Deduction(id: 'ded-phone', icon: '📱', name: 'Phone & Data Plan', explanation: 'Business-use portion of your phone bill. Gig apps require a phone — typically 80-90% deductible.', value: 540, eligibility: 'high', category: 'Technology'),
  Deduction(id: 'ded-se-tax', icon: '🏛️', name: 'Self-Employment Tax Deduction', explanation: 'Deduct 50% of your SE tax from gross income. This reduces your adjusted gross income automatically.', value: 1834, eligibility: 'high', category: 'Tax'),
  Deduction(id: 'ded-qbi', icon: '💼', name: 'Qualified Business Income (QBI)', explanation: 'Deduct up to 20% of qualified business income under Section 199A. Significant savings for sole proprietors.', value: 2160, eligibility: 'medium', category: 'Business'),
  Deduction(id: 'ded-health', icon: '🏥', name: 'Self-Employed Health Insurance', explanation: 'Deduct 100% of health insurance premiums if you are not eligible for employer coverage.', value: 1800, eligibility: 'medium', category: 'Health'),
  Deduction(id: 'ded-sep-ira', icon: '🏦', name: 'SEP-IRA Contribution', explanation: 'Contribute up to 25% of net self-employment income to a SEP-IRA and deduct the full amount.', value: 3600, eligibility: 'medium', category: 'Retirement'),
];

const _fallbackTaxEstimate = TaxEstimate(
  selfEmployment: 6786,
  federal: 3240,
  state: 1296,
  total: 11322,
  monthly: 944,
  quarterly: 2830,
);

const _fallbackRoadmap = [
  RoadmapStep(id: 'rm-1', step: 1, title: 'Open a dedicated business checking account', description: 'Separate your gig income from personal funds. Makes bookkeeping 10x easier and strengthens deduction claims.', deadline: 'This week', priority: 'high', completed: false),
  RoadmapStep(id: 'rm-2', step: 2, title: 'Set up automatic tax savings transfer', description: 'Auto-transfer 25% of every deposit to a high-yield savings account earmarked for quarterly taxes.', deadline: 'Within 2 weeks', priority: 'high', completed: false),
  RoadmapStep(id: 'rm-3', step: 3, title: 'Start tracking mileage with an app', description: 'Use MileIQ or Everlance to auto-track every business mile. This deduction alone saves you \$3,685.', deadline: 'Within 30 days', priority: 'medium', completed: false),
  RoadmapStep(id: 'rm-4', step: 4, title: 'File Q2 estimated taxes', description: 'Pay your Q2 estimated taxes by June 17, 2025 to avoid underpayment penalties. Amount: \$2,830.', deadline: 'Jun 17, 2025', priority: 'high', completed: false),
];

const _fallbackAnalysis = ClaudeAnalysis(
  deductions: _fallbackDeductions,
  taxEstimate: _fallbackTaxEstimate,
  roadmap: _fallbackRoadmap,
);

const _demoProfile = UserProfile(
  platforms: [Platform.uber, Platform.doordash, Platform.lyft],
  platformEarnings: {'uber': 1800, 'doordash': 1500, 'lyft': 900},
  monthlyEarnings: 4200,
  filingStatus: FilingStatus.single,
  dependentCount: 0,
  state: 'CA',
  housingType: HousingType.rent,
  monthlyRent: 1400,
  hasHomeOffice: true,
  vehicleType: VehicleType.car,
  expenses: Expenses(gas: 280, phone: 65, insurance: 150, equipment: 40, health: 180),
  isOnboarded: true,
  isDemoMode: true,
  claudeAnalysis: _fallbackAnalysis,
);

class UserProfileProvider extends ChangeNotifier {
  UserProfile _profile = const UserProfile();

  UserProfile get profile => _profile;
  ClaudeAnalysis get fallbackAnalysis => _fallbackAnalysis;

  void update(UserProfile Function(UserProfile) updater) {
    _profile = updater(_profile);
    notifyListeners();
  }

  void setAnalysis(ClaudeAnalysis? analysis) {
    _profile = _profile.copyWith(claudeAnalysis: analysis ?? _fallbackAnalysis);
    notifyListeners();
  }

  void activateDemoMode() {
    _profile = _demoProfile;
    notifyListeners();
  }

  void setIsBankConnected(bool value) {
    _profile = _profile.copyWith(isBankConnected: value);
    notifyListeners();
  }

  void reset() {
    _profile = const UserProfile();
    notifyListeners();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add mobile/lib/providers/user_profile_provider.dart
git commit -m "feat: update provider demo profile with real platformEarnings and new fields"
```

---

### Task 4: Fix the demo-mode leak in import screen

**Files:**
- Modify: `mobile/lib/screens/import/import_screen.dart`

- [ ] **Step 1: Remove activateDemoMode from _connectToBank**

In `_connectToBank()`, replace:

```dart
Future<void> _connectToBank() async {
    final provider = context.read<UserProfileProvider>();
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _PlaidConnectSheet(),
    );
    if (!mounted) return;
    provider.activateDemoMode();
    provider.setIsBankConnected(true);
    _navigateAfterImport();
  }
```

With:

```dart
Future<void> _connectToBank() async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _PlaidConnectSheet(),
    );
    if (!mounted) return;
    context.read<UserProfileProvider>().setIsBankConnected(true);
    _navigateAfterImport();
  }
```

- [ ] **Step 2: Commit**

```bash
git add mobile/lib/screens/import/import_screen.dart
git commit -m "fix: remove activateDemoMode from connectToBank — preserve real profile"
```

---

### Task 5: Add new onboarding steps

**Files:**
- Modify: `mobile/lib/screens/onboarding/onboarding_survey_screen.dart`

This is the largest change. The step switch-case renumbering and three new step widgets are the key work.

- [ ] **Step 1: Update _totalSteps, _canProceed, _handleComplete, and _buildStep**

Find and replace the `_OnboardingSurveyScreenState` class constants and methods:

Replace `const _totalSteps = 10;` with:
```dart
const _totalSteps = 11;
```

Replace `_canProceed()`:
```dart
bool _canProceed() {
    final p = context.read<UserProfileProvider>().profile;
    switch (_step) {
      case 0: return p.platforms.isNotEmpty || p.customPlatforms.isNotEmpty;
      case 1: return p.platformEarnings.values.any((v) => v > 0);
      case 4: return p.state.isNotEmpty;
      default: return true;
    }
  }
```

Replace `_handleComplete()`:
```dart
Future<void> _handleComplete() async {
    setState(() => _isLoading = true);
    final provider = context.read<UserProfileProvider>();
    // Compute total from per-platform earnings
    final total = provider.profile.platformEarnings.values.fold(0, (s, v) => s + v);
    provider.update((p) => p.copyWith(monthlyEarnings: total));
    final analysis = await fetchGigAnalysis(provider.profile);
    provider.setAnalysis(analysis);
    provider.update((p) => p.copyWith(isOnboarded: true));
    if (mounted) Navigator.pushReplacementNamed(context, '/income-dashboard');
  }
```

Replace `_buildStep()` — new step numbering (11 steps, 0–10):
```dart
Widget _buildStep(UserProfile profile, UserProfileProvider provider) {
    switch (_step) {
      case 0: return _StepPlatforms(
          platforms: profile.platforms,
          customPlatforms: profile.customPlatforms,
          onToggle: (p) {
            final next = profile.platforms.contains(p)
                ? profile.platforms.where((x) => x != p).toList()
                : [...profile.platforms, p];
            // Remove earnings for deselected platform
            final earnings = Map<String, int>.from(profile.platformEarnings)
              ..removeWhere((k, _) => !next.map((pl) => pl.name).contains(k));
            provider.update((pr) => pr.copyWith(platforms: next, platformEarnings: earnings));
          },
          onAddCustom: (name) {
            if (!profile.customPlatforms.contains(name)) {
              provider.update((pr) => pr.copyWith(customPlatforms: [...pr.customPlatforms, name]));
            }
          },
          onRemoveCustom: (name) {
            provider.update((pr) => pr.copyWith(customPlatforms: pr.customPlatforms.where((x) => x != name).toList()));
          },
        );
      case 1: return _StepPlatformEarnings(
          platforms: profile.platforms,
          customPlatforms: profile.customPlatforms,
          earnings: profile.platformEarnings,
          onChanged: (key, val) {
            final updated = Map<String, int>.from(profile.platformEarnings)..[key] = val;
            provider.update((p) => p.copyWith(platformEarnings: updated));
          },
        );
      case 2: return _StepFilingStatus(value: profile.filingStatus, onChange: (v) => provider.update((p) => p.copyWith(filingStatus: v)));
      case 3: return _StepDependentCount(
          value: profile.dependentCount,
          onChange: (v) => provider.update((p) => p.copyWith(dependentCount: v)),
        );
      case 4: return _StepState(
          value: profile.state,
          search: _stateSearch,
          onSearchChange: (v) => setState(() => _stateSearch = v),
          onSelect: (v) { provider.update((p) => p.copyWith(state: v)); setState(() => _stateSearch = ''); },
        );
      case 5: return _StepHousing(value: profile.housingType, onChange: (v) => provider.update((p) => p.copyWith(housingType: v)));
      case 6: return _StepMonthlyRent(
          housingType: profile.housingType,
          value: profile.monthlyRent,
          onChange: (v) => provider.update((p) => p.copyWith(monthlyRent: v)),
        );
      case 7: return _StepHomeOffice(value: profile.hasHomeOffice, onChange: (v) => provider.update((p) => p.copyWith(hasHomeOffice: v)));
      case 8: return _StepVehicle(value: profile.vehicleType, onChange: (v) => provider.update((p) => p.copyWith(vehicleType: v)));
      case 9: return _StepExpenses(expenses: profile.expenses, onChange: (key, val) => provider.update((p) => p.copyWith(expenses: _updateExpense(p.expenses, key, val))));
      case 10: return _StepReview(profile: profile);
      default: return const SizedBox.shrink();
    }
  }
```

- [ ] **Step 2: Add _StepPlatformEarnings widget**

Add this class after the existing `_StepPlatforms` class and before `_StepFilingStatus`:

```dart
// ── Step 1: Per-platform earnings ─────────────────────────────────────────────

class _StepPlatformEarnings extends StatelessWidget {
  final List<Platform> platforms;
  final List<String> customPlatforms;
  final Map<String, int> earnings;
  final void Function(String key, int val) onChanged;

  const _StepPlatformEarnings({
    required this.platforms,
    required this.customPlatforms,
    required this.earnings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final total = earnings.values.fold(0, (s, v) => s + v);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const ClampingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepHeader(
          'How much do you earn per platform?',
          'Set your average monthly earnings for each platform.',
        ),
        if (total > 0) Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: kGreenBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kGreenBorder)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total monthly', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 13)),
            Text('\$${_fmtNum(total)}/mo', style: GoogleFonts.dmMono(color: kGreen, fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
        ),
        ...platforms.map((p) {
          final cfg = kPlatformConfig[p]!;
          final val = earnings[p.name] ?? 0;
          return _EarningsSlider(
            emoji: cfg.emoji,
            label: cfg.label,
            value: val,
            onChanged: (v) => onChanged(p.name, v),
          );
        }),
        ...customPlatforms.map((name) {
          final val = earnings[name] ?? 0;
          return _EarningsSlider(
            emoji: '💼',
            label: name,
            value: val,
            onChanged: (v) => onChanged(name, v),
          );
        }),
      ]),
    );
  }
}

class _EarningsSlider extends StatelessWidget {
  final String emoji;
  final String label;
  final int value;
  final void Function(int) onChanged;

  const _EarningsSlider({
    required this.emoji,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: kCardDecoration(),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: kGreenBg, borderRadius: BorderRadius.circular(8)),
            child: Text(
              value == 0 ? 'Not set' : '\$${_fmtNum(value)}/mo',
              style: GoogleFonts.dmMono(color: value == 0 ? kTextMuted : kGreen, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: kGreen, inactiveTrackColor: kBorder,
            thumbColor: kGreen, overlayColor: kGreen.withValues(alpha: 0.12),
            trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 0, max: 8000,
            divisions: 160,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('\$0', style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 11)),
          Text('\$8,000', style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 11)),
        ]),
      ]),
    );
  }
}

String _fmtNum(int v) {
  final s = v.toString();
  final r = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) r.write(',');
    r.write(s[i]);
  }
  return r.toString();
}
```

- [ ] **Step 3: Add _StepDependentCount widget**

Replace the existing `_StepDependents` class with `_StepDependentCount`:

```dart
// ── Step 3: Dependent count ───────────────────────────────────────────────────

class _StepDependentCount extends StatelessWidget {
  final int value;
  final void Function(int) onChange;
  const _StepDependentCount({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final credit = value * 2000;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const ClampingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepHeader(
          'How many dependents do you claim?',
          'Each qualifying child gives you a \$2,000 Child Tax Credit.',
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: kCardDecoration(),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              GestureDetector(
                onTap: value > 0 ? () => onChange(value - 1) : null,
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: value > 0 ? kGreenBg : kBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: value > 0 ? kGreenBorder : kBorder),
                  ),
                  child: Icon(Icons.remove_rounded, color: value > 0 ? kGreen : kTextMuted, size: 22),
                ),
              ),
              const SizedBox(width: 32),
              Column(children: [
                Text('$value', style: GoogleFonts.dmMono(color: kTextPrimary, fontSize: 48, fontWeight: FontWeight.w800, height: 1.0)),
                Text(value == 1 ? 'dependent' : 'dependents', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 13)),
              ]),
              const SizedBox(width: 32),
              GestureDetector(
                onTap: value < 6 ? () => onChange(value + 1) : null,
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: value < 6 ? kGreenBg : kBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: value < 6 ? kGreenBorder : kBorder),
                  ),
                  child: Icon(Icons.add_rounded, color: value < 6 ? kGreen : kTextMuted, size: 22),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: credit > 0 ? kGreenBg : kBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: credit > 0 ? kGreenBorder : kBorder),
              ),
              child: Row(children: [
                Icon(credit > 0 ? Icons.savings_rounded : Icons.info_outline_rounded,
                    color: credit > 0 ? kGreen : kTextMuted, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  credit > 0
                      ? 'Estimated Child Tax Credit: \$${_fmtNum(credit)}/yr'
                      : 'No Child Tax Credit — set to 0 dependents',
                  style: GoogleFonts.dmSans(
                    color: credit > 0 ? kGreen : kTextMuted,
                    fontSize: 13, fontWeight: FontWeight.w500,
                  ),
                )),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}
```

- [ ] **Step 4: Add _StepMonthlyRent widget**

Add this class after `_StepHousing` and before `_StepHomeOffice`:

```dart
// ── Step 6: Monthly housing cost ──────────────────────────────────────────────

class _StepMonthlyRent extends StatelessWidget {
  final HousingType housingType;
  final int value;
  final void Function(int) onChange;
  const _StepMonthlyRent({required this.housingType, required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final isRent = housingType == HousingType.rent;
    final label = isRent ? 'Monthly Rent' : 'Monthly Mortgage Payment';
    final sublabel = isRent
        ? 'Used to calculate your home office deduction'
        : 'Mortgage interest portion may be deductible';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const ClampingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepHeader(label, sublabel),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: kCardDecoration(),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(label, style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: kGreenBg, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  value == 0 ? 'Skip / N/A' : '\$${_fmtNum(value)}/mo',
                  style: GoogleFonts.dmMono(color: value == 0 ? kTextMuted : kGreen, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: kGreen, inactiveTrackColor: kBorder,
                thumbColor: kGreen, overlayColor: kGreen.withValues(alpha: 0.12),
                trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: value.toDouble(),
                min: 0, max: 5000,
                divisions: 100,
                onChanged: (v) => onChange(v.round()),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Skip', style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 11)),
              Text('\$5,000', style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 11)),
            ]),
          ]),
        ),
        if (value > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kGreenBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kGreenBorder)),
            child: Row(children: [
              const Icon(Icons.home_work_rounded, color: kGreen, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'If you have a home office, ~10% of your ${isRent ? 'rent' : 'mortgage interest'} (\$${_fmtNum((value * 0.1).round())}/mo) may be deductible.',
                style: GoogleFonts.dmSans(color: kGreen, fontSize: 12),
              )),
            ]),
          ),
        ],
      ]),
    );
  }
}
```

- [ ] **Step 5: Remove old _StepDependents class**

Delete the entire `_StepDependents` class (it was replaced by `_StepDependentCount` in step 3).

- [ ] **Step 6: Update _StepReview to show new fields**

In `_StepReview.build()`, find the Review grid rows and add monthly rent and dependent count display. Replace the bottom info card block (after the last `Row(children: [...]`) with:

```dart
        // Add after the vehicle/home row:
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: kCardDecoration(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dependents', style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text('${profile.dependentCount}', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          ]))),
          const SizedBox(width: 10),
          Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: kCardDecoration(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(profile.housingType == HousingType.rent ? 'Monthly Rent' : 'Monthly Mortgage', style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(profile.monthlyRent == 0 ? '—' : '\$${_fmtNum(profile.monthlyRent)}', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          ]))),
        ]),
```

- [ ] **Step 7: Hot-reload and manually verify the onboarding flow**

Run on device/emulator:
```bash
cd mobile && flutter run
```

Walk through onboarding:
1. Select 2+ platforms → Continue
2. Adjust earnings sliders — "Total monthly" counter updates ✓ — Continue requires total > 0 ✓
3. Filing status → Continue
4. Dependents stepper: tap +/- → count updates, CTC note shows ✓
5. State → Continue
6. Housing type → Continue
7. Monthly rent slider → hint shows deduction estimate ✓
8. Home office, vehicle, expenses, review
9. Review card shows correct dependents + rent ✓
10. Tap "Analyze My Finances" → loading spinner → dashboard shows

Verify in dashboard:
- Platform breakdown matches what you entered (not fake jitter splits) ✓
- State tax is no longer "$2,380" for all states (CA should differ from TX) ✓

- [ ] **Step 8: Commit**

```bash
git add mobile/lib/screens/onboarding/onboarding_survey_screen.dart
git commit -m "feat: per-platform earnings step, dependent count stepper, monthly rent step"
```

---

### Task 6: Pass new fields to backend

**Files:**
- Modify: `mobile/lib/utils/claude_api.dart`
- Modify: `src/app/api/analyze/route.ts`

- [ ] **Step 1: Update _profileToJson in claude_api.dart**

Replace `_profileToJson`:

```dart
Map<String, dynamic> _profileToJson(UserProfile profile) {
  return {
    'platforms': [
      ...profile.platforms.map((p) => p.name),
      ...profile.customPlatforms,
    ],
    'platformEarnings': {
      for (final p in profile.platforms)
        p.name: profile.platformEarnings[p.name] ?? 0,
      for (final name in profile.customPlatforms)
        name: profile.platformEarnings[name] ?? 0,
    },
    'monthlyEarnings': profile.monthlyEarnings,
    'filingStatus': profile.filingStatus.name,
    'dependentCount': profile.dependentCount,
    'state': profile.state,
    'housingType': profile.housingType.name,
    'monthlyRent': profile.monthlyRent,
    'hasHomeOffice': profile.hasHomeOffice,
    'vehicleType': profile.vehicleType.name,
    'expenses': {
      'gas': profile.expenses.gas,
      'phone': profile.expenses.phone,
      'insurance': profile.expenses.insurance,
      'equipment': profile.expenses.equipment,
      'health': profile.expenses.health,
    },
  };
}
```

- [ ] **Step 2: Update the Gemini prompt in analyze/route.ts**

Replace the `prompt` template string:

```typescript
  const platformEarningsLines = Object.entries(profile.platformEarnings ?? {})
    .map(([p, v]) => `  - ${p}: $${v}/mo`)
    .join('\n');

  const prompt = `You are GigFlow AI, a specialized financial advisor for gig economy workers.
Analyzing profile:
- Platforms: ${platformNames}
- Per-platform monthly earnings:
${platformEarningsLines || '  (not provided)'}
- Total monthly earnings: $${profile.monthlyEarnings}
- Annual estimated: $${profile.monthlyEarnings * 12}
- Filing status: ${profile.filingStatus}
- Dependents: ${profile.dependentCount} (Child Tax Credit: $${(profile.dependentCount ?? 0) * 2000}/yr)
- State: ${profile.state}
- Housing: ${profile.housingType}${profile.monthlyRent > 0 ? ` — $${profile.monthlyRent}/mo` : ''}
- Home office: ${profile.hasHomeOffice}${profile.hasHomeOffice && profile.monthlyRent > 0 ? ` (est. deduction: $${Math.round(profile.monthlyRent * 0.1 * 12)}/yr)` : ''}
- Vehicle: ${profile.vehicleType}
- Monthly expenses: Gas $${profile.expenses?.gas}, Phone $${profile.expenses?.phone}, Insurance $${profile.expenses?.insurance}, Equipment $${profile.expenses?.equipment}, Health $${profile.expenses?.health}

Analyze this gig worker's tax situation and return ONLY valid JSON (no markdown, no code fences) with this exact structure:
{"deductions":[{"id":"unique-id","icon":"emoji","name":"name","explanation":"max 100 chars","value":1234,"eligibility":"high|medium|low","category":"Category"}],"taxEstimate":{"selfEmployment":1234,"federal":1234,"state":1234,"total":1234,"monthly":1234,"quarterly":1234},"roadmap":[{"id":"rm-1","step":1,"title":"title","description":"description","deadline":"timeframe","priority":"high|medium|low","completed":false}]}
Provide 5-7 deductions with accurate dollar values based on the actual earnings per platform above. Include accurate tax estimates for ${profile.state} using progressive brackets. Include 4 actionable roadmap steps.`;
```

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/utils/claude_api.dart src/app/api/analyze/route.ts
git commit -m "feat: pass platformEarnings, dependentCount, monthlyRent to Gemini analysis"
```

---

## Self-Review Checklist

- [x] **platformEarnings** — defined in model (Task 1), populated in onboarding step 1 (Task 5), used in `generatePlatformBreakdown` (Task 2), sent to backend (Task 6)
- [x] **dependentCount** — defined in model (Task 1), step 3 stepper (Task 5), used in `estimateFederalTax` (Task 2), sent to backend (Task 6)
- [x] **monthlyRent** — defined in model (Task 1), step 6 slider (Task 5), included in health score (Task 2), sent to backend (Task 6)
- [x] **State tax** — progressive brackets for 11 states + flat rates for 30 more + no-tax list (Task 2)
- [x] **Demo leak** — `activateDemoMode()` removed from `_connectToBank` (Task 4)
- [x] **Demo profile** — uses `platformEarnings`, `dependentCount`, `monthlyRent` (Task 3)
- [x] **_fmtNum** — defined once in onboarding file, used by all three new widgets; `_fmt` in dashboard file is separate and unchanged
- [x] **`_StepDependents` removed** — replaced by `_StepDependentCount` (Task 5 step 5)
- [x] **Step count** — `_totalSteps = 11`, switch goes 0–10, `_canProceed` covers cases 0, 1, 4 (Task 5 step 1)
- [x] **`generatePlatformBreakdown` signature** — changed to accept `UserProfile` instead of `(List<Platform>, int)`; dashboard call at `income_dashboard_screen.dart:85` must be updated to `generatePlatformBreakdown(profile)` — **GAP found, add fix below**

### Gap Fix: Update dashboard call to generatePlatformBreakdown

**Files:**
- Modify: `mobile/lib/screens/dashboard/income_dashboard_screen.dart`

In `_IncomeDashboardScreenState.build()`, find:

```dart
final platformBreakdown = generatePlatformBreakdown(profile.platforms, profile.monthlyEarnings);
```

Replace with:

```dart
final platformBreakdown = generatePlatformBreakdown(profile);
```

Add this as **Step 9** in Task 5 before the commit:

- [ ] **Step 9: Fix dashboard call to generatePlatformBreakdown**

In `mobile/lib/screens/dashboard/income_dashboard_screen.dart` line 85, replace:
```dart
final platformBreakdown = generatePlatformBreakdown(profile.platforms, profile.monthlyEarnings);
```
with:
```dart
final platformBreakdown = generatePlatformBreakdown(profile);
```
