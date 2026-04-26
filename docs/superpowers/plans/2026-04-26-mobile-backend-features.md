# GigFlow Mobile — Backend Features & Spending Tab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add CSV upload, tax PDF download, Plaid import flow, and a Spending analysis tab to the Flutter mobile app.

**Architecture:** All new screens follow existing patterns (Consumer<UserProfileProvider>, kCardDecoration, DM Sans/Mono fonts). Backend calls go to `http://10.0.2.2:3000` (Android emulator → localhost Next.js). Plaid flow is demo-first: 1.5s animation resolves to demo data with zero live-demo failure risk.

**Tech Stack:** Flutter/Dart, Provider, `file_picker ^8.1.2`, `share_plus ^10.0.0`, `path_provider ^2.1.4`, `http` (already installed), `fl_chart` (already installed)

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Modify | `mobile/pubspec.yaml` | Add 3 new packages |
| Modify | `mobile/lib/models/user_profile.dart` | Add `isBankConnected` field |
| Modify | `mobile/lib/providers/user_profile_provider.dart` | Add `setIsBankConnected()` |
| Create | `mobile/lib/utils/demo_data.dart` | Spending categories + top merchants |
| Create | `mobile/lib/utils/backend_api.dart` | CSV upload + PDF download HTTP calls |
| Create | `mobile/lib/screens/import/import_screen.dart` | 4-option data import picker |
| Create | `mobile/lib/screens/spending/spending_analysis_screen.dart` | Spending tab with animated bars |
| Modify | `mobile/lib/main.dart` | Add `/import` and `/spending` routes |
| Modify | `mobile/lib/widgets/app_tab_bar.dart` | Add Spending as 4th tab |
| Modify | `mobile/lib/screens/splash_screen.dart` | Route unonboarded → `/import` |
| Modify | `mobile/lib/screens/dashboard/income_dashboard_screen.dart` | Bank Connected banner + Update Data button |
| Modify | `mobile/lib/screens/deductions/deductions_roadmap_screen.dart` | PDF download button |
| Modify | `mobile/test/widget_test.dart` | Widget tests for new screens |

---

## Task 1: Add Dependencies

**Files:**
- Modify: `mobile/pubspec.yaml`

- [ ] **Step 1: Add packages**

Replace the `dependencies:` block in `mobile/pubspec.yaml` with:
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.2
  google_fonts: ^6.2.1
  http: ^1.2.1
  fl_chart: ^0.68.0
  file_picker: ^8.1.2
  share_plus: ^10.0.0
  path_provider: ^2.1.4
```

- [ ] **Step 2: Fetch packages**

Run from `mobile/` directory:
```
flutter pub get
```
Expected: `Got dependencies!` with no errors.

- [ ] **Step 3: Commit**
```bash
git add mobile/pubspec.yaml mobile/pubspec.lock
git commit -m "feat: add file_picker, share_plus, path_provider dependencies"
```

---

## Task 2: Add `isBankConnected` to Model + Provider

**Files:**
- Modify: `mobile/lib/models/user_profile.dart`
- Modify: `mobile/lib/providers/user_profile_provider.dart`

- [ ] **Step 1: Add field to UserProfile**

Replace the entire `UserProfile` class in `mobile/lib/models/user_profile.dart` with:
```dart
class UserProfile {
  final List<Platform> platforms;
  final int monthlyEarnings;
  final FilingStatus filingStatus;
  final bool hasDependents;
  final String state;
  final HousingType housingType;
  final bool hasHomeOffice;
  final VehicleType vehicleType;
  final Expenses expenses;
  final ClaudeAnalysis? claudeAnalysis;
  final bool isOnboarded;
  final bool isDemoMode;
  final bool isBankConnected;
  final List<String> customPlatforms;

  const UserProfile({
    this.platforms = const [],
    this.customPlatforms = const [],
    this.monthlyEarnings = 0,
    this.filingStatus = FilingStatus.single,
    this.hasDependents = false,
    this.state = '',
    this.housingType = HousingType.rent,
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
    int? monthlyEarnings,
    FilingStatus? filingStatus,
    bool? hasDependents,
    String? state,
    HousingType? housingType,
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
      monthlyEarnings: monthlyEarnings ?? this.monthlyEarnings,
      filingStatus: filingStatus ?? this.filingStatus,
      hasDependents: hasDependents ?? this.hasDependents,
      state: state ?? this.state,
      housingType: housingType ?? this.housingType,
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

- [ ] **Step 2: Add `setIsBankConnected` to provider**

In `mobile/lib/providers/user_profile_provider.dart`, add this method after `activateDemoMode()`:
```dart
void setIsBankConnected(bool value) {
  _profile = _profile.copyWith(isBankConnected: value);
  notifyListeners();
}
```

- [ ] **Step 3: Verify build compiles**

Run: `flutter build apk --debug 2>&1 | tail -5`
Expected: `Build complete.` with no errors.

- [ ] **Step 4: Commit**
```bash
git add mobile/lib/models/user_profile.dart mobile/lib/providers/user_profile_provider.dart
git commit -m "feat: add isBankConnected to UserProfile and provider"
```

---

## Task 3: Create `demo_data.dart`

**Files:**
- Create: `mobile/lib/utils/demo_data.dart`

- [ ] **Step 1: Create the file**

```dart
import 'package:flutter/material.dart';
import 'colors.dart';

class SpendingCategory {
  final String label;
  final int amount;
  final double percentage;
  final Color color;
  const SpendingCategory({
    required this.label,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class TopMerchant {
  final String name;
  final int amount;
  const TopMerchant({required this.name, required this.amount});
}

const kDemoTotalSpend = 2847;

const kDemoSpendingCategories = [
  SpendingCategory(label: 'Groceries',      amount: 612, percentage: 0.215, color: kGreen),
  SpendingCategory(label: 'Shopping',       amount: 426, percentage: 0.150, color: Color(0xFFEC4899)),
  SpendingCategory(label: 'Eating Out',     amount: 498, percentage: 0.175, color: kAmber),
  SpendingCategory(label: 'Transportation', amount: 387, percentage: 0.136, color: kBlue),
  SpendingCategory(label: 'Essentials',     amount: 341, percentage: 0.120, color: kTeal),
  SpendingCategory(label: 'Entertainment',  amount: 284, percentage: 0.100, color: Color(0xFF8B5CF6)),
  SpendingCategory(label: 'Other',          amount: 299, percentage: 0.105, color: kTextMuted),
];

const kDemoTopMerchants = [
  TopMerchant(name: "Trader Joe's", amount: 214),
  TopMerchant(name: 'Uber',         amount: 187),
  TopMerchant(name: "McDonald's",   amount: 143),
  TopMerchant(name: 'Amazon',       amount: 126),
  TopMerchant(name: 'CVS Pharmacy', amount: 98),
];
```

- [ ] **Step 2: Commit**
```bash
git add mobile/lib/utils/demo_data.dart
git commit -m "feat: add spending demo data constants"
```

---

## Task 4: Create `backend_api.dart`

**Files:**
- Create: `mobile/lib/utils/backend_api.dart`
- Modify: `mobile/test/widget_test.dart`

- [ ] **Step 1: Create the file**

```dart
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

const _base = 'http://10.0.2.2:3000';

class BackendException implements Exception {
  final String message;
  const BackendException(this.message);
  @override
  String toString() => message;
}

Future<Map<String, dynamic>> uploadCsv(Uint8List bytes, String filename) async {
  final uri = Uri.parse('$_base/api/parse-earnings');
  final request = http.MultipartRequest('POST', uri)
    ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
  final streamed = await request.send().timeout(const Duration(seconds: 15));
  final body = await streamed.stream.bytesToString();
  if (streamed.statusCode != 200) throw BackendException('Upload failed: $body');
  return json.decode(body) as Map<String, dynamic>;
}

Future<Uint8List> downloadReport(Map<String, dynamic> profileJson) async {
  final uri = Uri.parse('$_base/api/report');
  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'profile': profileJson}),
  ).timeout(const Duration(seconds: 15));
  if (response.statusCode != 200) {
    throw BackendException('Report failed (${response.statusCode}): ${response.body}');
  }
  return response.bodyBytes;
}
```

- [ ] **Step 2: Write unit test**

Replace `mobile/test/widget_test.dart` with:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gigflow/main.dart';
import 'package:gigflow/providers/user_profile_provider.dart';
import 'package:gigflow/utils/backend_api.dart';
import 'package:gigflow/screens/import/import_screen.dart';
import 'package:gigflow/screens/spending/spending_analysis_screen.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProfileProvider(),
        child: const GigFlowApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  test('BackendException message is readable', () {
    const e = BackendException('test error');
    expect(e.toString(), 'test error');
  });

  testWidgets('ImportScreen shows 4 option cards', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProfileProvider(),
        child: const MaterialApp(home: ImportScreen()),
      ),
    );
    expect(find.text('Connect to Bank'), findsOneWidget);
    expect(find.text('Demo Mode'), findsOneWidget);
    expect(find.text('Enter Manually'), findsOneWidget);
    expect(find.text('Upload CSV'), findsOneWidget);
  });

  testWidgets('SpendingAnalysisScreen shows key sections', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProfileProvider(),
        child: const MaterialApp(home: SpendingAnalysisScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('Spending Overview'), findsOneWidget);
    expect(find.text('Spending by Category'), findsOneWidget);
    expect(find.text('Top Merchants'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run tests (will fail until import_screen and spending_analysis_screen exist — that's expected)**

Note: tests for ImportScreen and SpendingAnalysisScreen will fail with "Cannot resolve" until Tasks 5 and 6 are done. Run only the BackendException test now:
```
flutter test test/widget_test.dart --name "BackendException"
```
Expected: `All tests passed!`

- [ ] **Step 4: Commit**
```bash
git add mobile/lib/utils/backend_api.dart mobile/test/widget_test.dart
git commit -m "feat: add backend_api.dart for CSV upload and PDF download"
```

---

## Task 5: Create `import_screen.dart`

**Files:**
- Create: `mobile/lib/screens/import/import_screen.dart`

- [ ] **Step 1: Create the file**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/user_profile_provider.dart';
import '../../utils/colors.dart';
import '../../utils/backend_api.dart';

class ImportScreen extends StatefulWidget {
  final bool isModal;
  const ImportScreen({super.key, this.isModal = false});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _csvLoading = false;

  void _navigateAfterImport() {
    if (widget.isModal) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/income-dashboard');
    }
  }

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

  void _useDemo() {
    context.read<UserProfileProvider>().activateDemoMode();
    _navigateAfterImport();
  }

  void _enterManually() {
    if (widget.isModal) {
      Navigator.pop(context);
      Navigator.pushNamed(context, '/onboarding');
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  Future<void> _uploadCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    final file = result.files.single;
    setState(() => _csvLoading = true);
    try {
      final data = await uploadCsv(file.bytes!, file.name);
      if (!mounted) return;
      final provider = context.read<UserProfileProvider>();
      provider.update((p) => p.copyWith(
        monthlyEarnings: (data['monthlyAverage'] as num?)?.toInt() ?? p.monthlyEarnings,
        isOnboarded: true,
      ));
      _navigateAfterImport();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not parse CSV — is the backend running?'),
          backgroundColor: kRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _csvLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (widget.isModal) ...[
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded, color: kTextSecondary, size: 24),
              ),
              const SizedBox(height: 16),
            ],
            RichText(text: TextSpan(children: [
              TextSpan(text: 'gig', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
              TextSpan(text: 'Flow', style: GoogleFonts.dmSans(color: kGreen, fontSize: 22, fontWeight: FontWeight.w800)),
            ])),
            const SizedBox(height: 8),
            Text('How would you like to get started?', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Choose how to import your financial data.', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 14)),
            const SizedBox(height: 28),
            _ImportCard(
              icon: Icons.account_balance_rounded,
              iconColor: kBlue,
              iconBg: kBlueBg,
              title: 'Connect to Bank',
              subtitle: 'Securely import your transactions via Plaid',
              onTap: _connectToBank,
            ),
            const SizedBox(height: 12),
            _ImportCard(
              icon: Icons.auto_awesome_rounded,
              iconColor: kGreen,
              iconBg: kGreenBg,
              title: 'Demo Mode',
              subtitle: 'Explore with sample data — no account needed',
              onTap: _useDemo,
            ),
            const SizedBox(height: 12),
            _ImportCard(
              icon: Icons.edit_rounded,
              iconColor: kAmber,
              iconBg: kAmberBg,
              title: 'Enter Manually',
              subtitle: 'Input your earnings step by step',
              onTap: _enterManually,
            ),
            const SizedBox(height: 12),
            _ImportCard(
              icon: Icons.upload_file_rounded,
              iconColor: kTeal,
              iconBg: const Color(0xFFECFEFE),
              title: 'Upload CSV',
              subtitle: 'Import earnings from Uber, DoorDash, Lyft and more',
              onTap: _csvLoading ? null : _uploadCsv,
              trailing: _csvLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: kTeal, strokeWidth: 2))
                  : null,
            ),
            const SizedBox(height: 36),
            Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock_outline_rounded, color: kTextMuted, size: 13),
                const SizedBox(width: 5),
                Text('Your data stays private and secure', style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 12)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ImportCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ImportCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: kCardDecoration(),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
          ])),
          trailing ?? Icon(Icons.chevron_right_rounded, color: onTap == null ? kBorder : kTextMuted, size: 20),
        ]),
      ),
    );
  }
}

class _PlaidConnectSheet extends StatefulWidget {
  const _PlaidConnectSheet();

  @override
  State<_PlaidConnectSheet> createState() => _PlaidConnectSheetState();
}

class _PlaidConnectSheetState extends State<_PlaidConnectSheet> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: kBlueBg, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.account_balance_rounded, color: kBlue, size: 28),
        ),
        const SizedBox(height: 16),
        Text('Connecting to Plaid...', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Securely linking your bank account', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 13)),
        const SizedBox(height: 24),
        const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          child: LinearProgressIndicator(color: kBlue, backgroundColor: kBorder, minHeight: 4),
        ),
      ]),
    );
  }
}
```

- [ ] **Step 2: Run widget test for ImportScreen**

Run: `flutter test test/widget_test.dart --name "ImportScreen"`
Expected: `All tests passed!`

- [ ] **Step 3: Commit**
```bash
git add mobile/lib/screens/import/import_screen.dart
git commit -m "feat: add ImportScreen with Plaid animation, demo, manual, and CSV upload options"
```

---

## Task 6: Create `spending_analysis_screen.dart`

**Files:**
- Create: `mobile/lib/screens/spending/spending_analysis_screen.dart`

- [ ] **Step 1: Create the file**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/colors.dart';
import '../../utils/demo_data.dart';
import '../../widgets/app_tab_bar.dart';

class SpendingAnalysisScreen extends StatelessWidget {
  const SpendingAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  _buildBarChart(),
                  const SizedBox(height: 16),
                  _buildTopMerchants(),
                  const SizedBox(height: 16),
                  _buildInsightCard(),
                  const SizedBox(height: 24),
                ]),
              ),
            ]),
          ),
        ),
        const AppTabBar(),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kGreenDark, kGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Last 30 Days', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13)),
            Text('Spending Overview', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
            child: Text('Demo Data', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(
          '\$${_fmt(kDemoTotalSpend)}',
          style: GoogleFonts.dmMono(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
        ),
        Text('total spent', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }

  Widget _buildBarChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: kCardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Spending by Category', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOut,
          builder: (_, anim, __) => Column(
            children: kDemoSpendingCategories
                .map((cat) => _SpendingBar(cat: cat, animValue: anim))
                .toList(),
          ),
        ),
      ]),
    );
  }

  Widget _buildTopMerchants() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: kCardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Top Merchants', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...kDemoTopMerchants.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: kGreenLight, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(m.name, style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 14)),
            ]),
            Text(
              '\$${m.amount}',
              style: GoogleFonts.dmMono(color: kTextSecondary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ]),
        )),
      ]),
    );
  }

  Widget _buildInsightCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kGreenBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGreenBorder),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.lightbulb_rounded, color: kGreen, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Eating out is your 2nd biggest spend at 17.5% of total. Cutting back by \$100/mo saves \$1,200/year.',
            style: GoogleFonts.dmSans(color: kGreen, fontSize: 13),
          ),
        ),
      ]),
    );
  }

  String _fmt(int v) {
    final s = v.toString();
    final r = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) r.write(',');
      r.write(s[i]);
    }
    return r.toString();
  }
}

class _SpendingBar extends StatelessWidget {
  final SpendingCategory cat;
  final double animValue;
  const _SpendingBar({required this.cat, required this.animValue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        SizedBox(
          width: 95,
          child: Text(
            cat.label,
            style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Stack(children: [
            Container(
              height: 8,
              decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(4)),
            ),
            FractionallySizedBox(
              widthFactor: (cat.percentage * animValue).clamp(0.0, 1.0),
              child: Container(
                height: 8,
                decoration: BoxDecoration(color: cat.color, borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text(
              '\$${cat.amount}',
              style: GoogleFonts.dmMono(color: kTextPrimary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Text(
              '${(cat.percentage * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 11),
            ),
          ]),
        ),
      ]),
    );
  }
}
```

- [ ] **Step 2: Run widget test for SpendingAnalysisScreen**

Run: `flutter test test/widget_test.dart --name "SpendingAnalysisScreen"`
Expected: `All tests passed!`

- [ ] **Step 3: Commit**
```bash
git add mobile/lib/screens/spending/spending_analysis_screen.dart
git commit -m "feat: add SpendingAnalysisScreen with animated horizontal bar chart"
```

---

## Task 7: Wire Routes, Tab Bar, and Splash Screen

**Files:**
- Modify: `mobile/lib/main.dart`
- Modify: `mobile/lib/widgets/app_tab_bar.dart`
- Modify: `mobile/lib/screens/splash_screen.dart`

- [ ] **Step 1: Update main.dart — add imports and routes**

At the top of `mobile/lib/main.dart`, add two imports after the existing import block:
```dart
import 'screens/import/import_screen.dart';
import 'screens/spending/spending_analysis_screen.dart';
```

Replace the `routes:` map in `GigFlowApp.build()`:
```dart
routes: {
  '/': (ctx) => const SplashScreen(),
  '/import': (ctx) => const ImportScreen(),
  '/onboarding': (ctx) => const OnboardingSurveyScreen(),
  '/loading': (ctx) => const LoadingScreen(),
  '/income-dashboard': (ctx) => const IncomeDashboardScreen(),
  '/deductions-roadmap': (ctx) => const DeductionsRoadmapScreen(),
  '/spending': (ctx) => const SpendingAnalysisScreen(),
  '/chat': (ctx) => const ChatScreen(),
},
```

- [ ] **Step 2: Update splash_screen.dart — route to /import**

In `mobile/lib/screens/splash_screen.dart`, change `_navigate()` to:
```dart
void _navigate() {
  if (!mounted) return;
  final profile = context.read<UserProfileProvider>().profile;
  if (profile.isOnboarded || profile.isDemoMode) {
    Navigator.pushReplacementNamed(context, '/income-dashboard');
  } else {
    Navigator.pushReplacementNamed(context, '/import');
  }
}
```

- [ ] **Step 3: Update app_tab_bar.dart — add 4th tab**

Replace the `_tabs` const in `mobile/lib/widgets/app_tab_bar.dart`:
```dart
const _tabs = [
  _Tab('Dashboard',  Icons.bar_chart_rounded,   '/income-dashboard'),
  _Tab('Deductions', Icons.receipt_long_rounded, '/deductions-roadmap'),
  _Tab('Spending',   Icons.pie_chart_rounded,    '/spending'),
  _Tab('AI Chat',    Icons.chat_bubble_rounded,  '/chat'),
];
```

- [ ] **Step 4: Build to verify no errors**

Run: `flutter build apk --debug 2>&1 | tail -5`
Expected: `Build complete.`

- [ ] **Step 5: Run all tests**

Run: `flutter test`
Expected: All 4 tests pass.

- [ ] **Step 6: Commit**
```bash
git add mobile/lib/main.dart mobile/lib/widgets/app_tab_bar.dart mobile/lib/screens/splash_screen.dart
git commit -m "feat: add /import and /spending routes, 4-tab nav, update splash routing"
```

---

## Task 8: Update Dashboard — Bank Connected Banner + Update Data Button

**Files:**
- Modify: `mobile/lib/screens/dashboard/income_dashboard_screen.dart`

- [ ] **Step 1: Add import for ImportScreen at the top**

Add to the import block of `income_dashboard_screen.dart`:
```dart
import '../import/import_screen.dart';
```

- [ ] **Step 2: Add `_showBankBanner` state and `initState`**

In `_IncomeDashboardScreenState`, add after `bool _showDemoToast = false;`:
```dart
bool _showBankBanner = false;

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    final provider = context.read<UserProfileProvider>();
    if (provider.profile.isBankConnected) {
      setState(() => _showBankBanner = true);
      provider.setIsBankConnected(false);
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (mounted) setState(() => _showBankBanner = false);
      });
    }
  });
}
```

- [ ] **Step 3: Wrap the ready-state Scaffold body in a Stack and add the banner**

In the ready-state return (around line 77), change `body: Column(children: [` to:
```dart
body: Stack(children: [
  Column(children: [
    Expanded(
      child: SingleChildScrollView(
        // ... existing content unchanged ...
      ),
    ),
    const AppTabBar(),
  ]),
  if (_showBankBanner)
    Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16, right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kGreenBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kGreenBorder),
            boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 8)],
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_rounded, color: kGreen, size: 18),
            const SizedBox(width: 10),
            Text('Bank Connected', style: GoogleFonts.dmSans(color: kGreen, fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('Sandbox Mode', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
          ]),
        ),
      ),
    ),
]),
```

- [ ] **Step 4: Add "Update Data" button after the YTD header card**

After the YTD header card widget in the scrollable column content, add:
```dart
Padding(
  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
  child: Row(children: [
    GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ImportScreen(isModal: true)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.sync_rounded, color: kTextSecondary, size: 16),
          const SizedBox(width: 6),
          Text('Update Data', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ),
    ),
  ]),
),
```

- [ ] **Step 5: Build to verify**

Run: `flutter build apk --debug 2>&1 | tail -5`
Expected: `Build complete.`

- [ ] **Step 6: Commit**
```bash
git add mobile/lib/screens/dashboard/income_dashboard_screen.dart
git commit -m "feat: add Bank Connected banner and Update Data button to dashboard"
```

---

## Task 9: Add PDF Download to Deductions Screen

**Files:**
- Modify: `mobile/lib/screens/deductions/deductions_roadmap_screen.dart`

- [ ] **Step 1: Read the full deductions screen**

Read `mobile/lib/screens/deductions/deductions_roadmap_screen.dart` from line 60 to end to understand where the deduction card list ends and where the disclaimer text is rendered.

- [ ] **Step 2: Add imports**

Add to the import block at the top of `deductions_roadmap_screen.dart`:
```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/backend_api.dart';
```

- [ ] **Step 3: Add `_pdfLoading`, `_downloadPdf`, and `_profileToJson` to state class**

In `_DeductionsRoadmapScreenState`, add after `_Tab _activeTab = _Tab.deductions;`:
```dart
bool _pdfLoading = false;

Future<void> _downloadPdf(UserProfile profile) async {
  setState(() => _pdfLoading = true);
  try {
    final bytes = await downloadReport(_profileToJson(profile));
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/gigflow_tax_report.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'GigFlow Tax Report');
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not generate report — is the backend running?'),
          backgroundColor: kRed,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _pdfLoading = false);
  }
}

Map<String, dynamic> _profileToJson(UserProfile p) {
  final analysis = p.claudeAnalysis;
  return {
    'state': p.state,
    'filingStatus': p.filingStatus.name,
    'claudeAnalysis': analysis == null
        ? null
        : {
            'deductions': analysis.deductions.map((d) => {
              'id': d.id, 'icon': d.icon, 'name': d.name,
              'explanation': d.explanation, 'value': d.value,
              'eligibility': d.eligibility, 'category': d.category,
            }).toList(),
            'taxEstimate': {
              'selfEmployment': analysis.taxEstimate.selfEmployment,
              'federal': analysis.taxEstimate.federal,
              'state': analysis.taxEstimate.state,
              'total': analysis.taxEstimate.total,
              'monthly': analysis.taxEstimate.monthly,
              'quarterly': analysis.taxEstimate.quarterly,
            },
            'roadmap': analysis.roadmap.map((r) => {
              'id': r.id, 'step': r.step, 'title': r.title,
              'description': r.description, 'deadline': r.deadline,
              'priority': r.priority, 'completed': r.completed,
            }).toList(),
          },
  };
}
```

- [ ] **Step 4: Add download button to deductions tab content**

In the deductions tab build (inside the `_Tab.deductions` branch), after the last deduction card and before any bottom padding, add:
```dart
const SizedBox(height: 12),
GestureDetector(
  onTap: _pdfLoading ? null : () => _downloadPdf(profile),
  child: Container(
    height: 48,
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _pdfLoading ? kBorder : kGreen, width: 1.5),
    ),
    child: _pdfLoading
        ? const Center(
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(color: kGreen, strokeWidth: 2),
            ),
          )
        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.download_rounded, color: kGreen, size: 18),
            const SizedBox(width: 8),
            Text(
              'Download Tax Report',
              style: GoogleFonts.dmSans(color: kGreen, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ]),
  ),
),
const SizedBox(height: 16),
```

- [ ] **Step 5: Build to verify**

Run: `flutter build apk --debug 2>&1 | tail -5`
Expected: `Build complete.`

- [ ] **Step 6: Run all tests**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 7: Commit**
```bash
git add mobile/lib/screens/deductions/deductions_roadmap_screen.dart
git commit -m "feat: add PDF tax report download to deductions screen"
```

---

## Task 10: Final Integration Verification

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 2: Start the Next.js backend**

In the project root (not `mobile/`):
```
npm run dev
```
Expected: `Ready on http://localhost:3000`

- [ ] **Step 3: Run on Android emulator**

In `mobile/`:
```
flutter run
```
Expected: App launches on emulator, splash screen appears.

- [ ] **Step 4: Verify onboarding flow**

- Splash fades in → auto-navigates to ImportScreen
- 4 cards visible: Connect to Bank, Demo Mode, Enter Manually, Upload CSV
- Tap **Demo Mode** → Dashboard loads with data and 4 tabs in bottom bar
- Tap **Spending** tab → header with $2,847, bars animate in from left, Top Merchants list, insight card visible
- Tap **Deductions** tab → "Download Tax Report" button visible at bottom of deductions list
- Tap **Dashboard** tab → "Update Data" pill button visible below YTD header

- [ ] **Step 5: Verify Connect to Bank flow**

- Tap "Update Data" on Dashboard → ImportScreen modal opens (X button top-left)
- Tap "Connect to Bank" → bottom sheet with Plaid animation appears, closes after 1.5s
- Dashboard shows green "Bank Connected / Sandbox Mode" banner for 3s then fades

- [ ] **Step 6: Final commit**

```bash
git add -A
git commit -m "feat: complete mobile backend features — import flow, spending tab, CSV upload, PDF download"
```
