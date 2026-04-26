import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/colors.dart';
import '../../utils/demo_data.dart';
import '../../widgets/app_tab_bar.dart';

enum _Mode { picker, demo, plaid, manual }

const _kCategoryColors = [
  kGreen, kBlue, kAmber, Color(0xFFEC4899), kTeal,
  Color(0xFF8B5CF6), Color(0xFFEF4444), Color(0xFFF97316),
];

class SpendingAnalysisScreen extends StatefulWidget {
  const SpendingAnalysisScreen({super.key});
  @override
  State<SpendingAnalysisScreen> createState() => _SpendingAnalysisScreenState();
}

class _SpendingAnalysisScreenState extends State<SpendingAnalysisScreen> {
  _Mode _mode = _Mode.picker;
  bool _plaidDone = false;

  final List<_Entry> _entries = [
    _Entry('Groceries', 0),
    _Entry('Eating Out', 0),
    _Entry('Transportation', 0),
    _Entry('Entertainment', 0),
    _Entry('Shopping', 0),
  ];
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  int get _manualTotal => _entries.fold(0, (s, e) => s + e.amount);

  void _addCustomCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_entries.any((e) => e.label.toLowerCase() == trimmed.toLowerCase())) return;
    setState(() => _entries.add(_Entry(trimmed, 0)));
    _customController.clear();
  }

  Widget _buildHeader(String title, String subtitle, {bool showBack = false}) {
    return Container(
      color: kCard,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(children: [
            if (showBack) ...[
              GestureDetector(
                onTap: () => setState(() { _mode = _Mode.picker; _plaidDone = false; }),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: kBg, shape: BoxShape.circle, border: Border.all(color: kBorder)),
                  child: const Icon(Icons.arrow_back_rounded, color: kTextSecondary, size: 17),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              Text(subtitle, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
            ])),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        Expanded(child: _buildBody()),
        const AppTabBar(),
      ]),
    );
  }

  Widget _buildBody() {
    switch (_mode) {
      case _Mode.picker: return _buildPicker();
      case _Mode.demo:   return _buildDemo();
      case _Mode.plaid:  return _buildPlaid();
      case _Mode.manual: return _buildManual();
    }
  }

  // ── Picker ────────────────────────────────────────────────────────────────

  Widget _buildPicker() {
    return Column(children: [
      _buildHeader('Spending', 'Track where your money goes'),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const ClampingScrollPhysics(),
        child: Column(children: [
          const SizedBox(height: 16),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: kGreenBg, shape: BoxShape.circle, border: Border.all(color: kGreenBorder)),
            child: const Center(child: Text('📊', style: TextStyle(fontSize: 30))),
          ),
          const SizedBox(height: 16),
          Text('How do you want to track spending?', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 17, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 28),
          _PickerCard(
            icon: Icons.edit_note_rounded, iconColor: kAmber, iconBg: kAmberBg,
            title: 'Enter Manually',
            subtitle: 'Add your spending categories and amounts. See a live breakdown with percentages.',
            onTap: () => setState(() => _mode = _Mode.manual),
          ),
          const SizedBox(height: 12),
          _PickerCard(
            icon: Icons.account_balance_rounded, iconColor: kBlue, iconBg: kBlueBg,
            title: 'Connect via Plaid',
            subtitle: 'Securely link your bank to auto-import and categorize transactions.',
            onTap: () => setState(() => _mode = _Mode.plaid),
          ),
          const SizedBox(height: 12),
          _PickerCard(
            icon: Icons.auto_awesome_rounded, iconColor: kGreen, iconBg: kGreenBg,
            title: 'Demo Data', badge: 'Demo',
            subtitle: 'Preview with sample spending data. No account needed.',
            onTap: () => setState(() => _mode = _Mode.demo),
          ),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock_outline_rounded, color: kTextMuted, size: 13),
            const SizedBox(width: 5),
            Text('Your data stays private and secure', style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 12)),
          ]),
        ]),
      )),
    ]);
  }

  // ── Demo ──────────────────────────────────────────────────────────────────

  Widget _buildDemo() {
    return Column(children: [
      _buildHeader('Spending', 'Last 30 days · Demo data', showBack: true),
      Expanded(child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [kGreenDark, kGreen], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                child: Text('Demo Data', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 10),
              Text('\$${_fmt(kDemoTotalSpend)}', style: GoogleFonts.dmMono(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
              Text('total spent this month', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              _DemoBarChart(),
              const SizedBox(height: 16),
              _DemoTopMerchants(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: kGreenBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: kGreenBorder)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.lightbulb_rounded, color: kGreen, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'Eating out is your 2nd biggest spend at 17.5% of total. Cutting back by \$100/mo saves \$1,200/year.',
                    style: GoogleFonts.dmSans(color: kGreen, fontSize: 13, height: 1.4),
                  )),
                ]),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ]),
      )),
    ]);
  }

  // ── Plaid ─────────────────────────────────────────────────────────────────

  Widget _buildPlaid() {
    return Column(children: [
      _buildHeader('Connect Bank', 'Secure bank linking via Plaid', showBack: !_plaidDone),
      Expanded(child: Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: _plaidDone
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(color: kGreenBg, shape: BoxShape.circle, border: Border.all(color: kGreenBorder)),
                  child: const Icon(Icons.check_rounded, color: kGreen, size: 36),
                ),
                const SizedBox(height: 20),
                Text('Bank Connected!', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Plaid sandbox connected. Real transaction import requires production Plaid credentials.', textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 13, height: 1.5)),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () => setState(() { _mode = _Mode.picker; _plaidDone = false; }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                    decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(14)),
                    child: Text('Done', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ])
            : _PlaidConnectFlow(onDone: () => setState(() => _plaidDone = true)),
      ))),
    ]);
  }

  // ── Manual ────────────────────────────────────────────────────────────────

  Widget _buildManual() {
    final total = _manualTotal;
    final activeEntries = _entries.where((e) => e.amount > 0).toList();

    return Column(children: [
      _buildHeader('Manual Spending', 'Slide to set monthly amounts', showBack: true),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const ClampingScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Total banner ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kGreenDark, kGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Monthly Total', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12)),
                Text('\$${_fmt(total)}/mo', style: GoogleFonts.dmMono(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              ]),
              Text('${activeEntries.length} categories', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Live breakdown chart (shows when any amount > 0) ──
          if (activeEntries.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: kCardDecoration(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Spending Breakdown', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 14),
                ...activeEntries.asMap().entries.map((e) {
                  final pct = e.value.amount / total;
                  final color = _kCategoryColors[e.key % _kCategoryColors.length];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Row(children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(e.value.label, style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 13)),
                        ]),
                        Row(children: [
                          Text('\$${_fmt(e.value.amount)}', style: GoogleFonts.dmMono(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                            child: Text('${(pct * 100).toStringAsFixed(0)}%', style: GoogleFonts.dmSans(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ]),
                      ]),
                      const SizedBox(height: 6),
                      TweenAnimationBuilder<double>(
                        key: ValueKey('${e.value.label}-${e.value.amount}'),
                        tween: Tween(begin: 0, end: pct),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        builder: (_, val, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: val, minHeight: 7,
                            backgroundColor: kBorder,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ),
                    ]),
                  );
                }),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // ── Category sliders ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: kCardDecoration(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Categories', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ..._entries.asMap().entries.map((e) {
                final i = e.key;
                final entry = e.value;
                final color = _kCategoryColors[i % _kCategoryColors.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(children: [
                    Row(children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entry.label, style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text('\$${entry.amount}/mo', style: GoogleFonts.dmMono(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _entries.removeAt(i)),
                        child: const Icon(Icons.close_rounded, color: kTextMuted, size: 16),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: color,
                        inactiveTrackColor: kBorder,
                        thumbColor: color,
                        overlayColor: color.withValues(alpha: 0.12),
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      ),
                      child: Slider(
                        value: entry.amount.toDouble(),
                        min: 0, max: 3000, divisions: 60,
                        onChanged: (v) => setState(() => _entries[i] = _Entry(entry.label, v.round())),
                      ),
                    ),
                  ]),
                );
              }),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Add custom category ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: kCardDecoration(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add Category', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _customController,
                    style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. Subscriptions, Gym...',
                      hintStyle: GoogleFonts.dmSans(color: kTextMuted, fontSize: 14),
                      filled: true, fillColor: kBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kGreen, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      isDense: true,
                    ),
                    onSubmitted: _addCustomCategory,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _addCustomCategory(_customController.text),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: _presetChips()),
            ]),
          ),
          const SizedBox(height: 80),
        ]),
      )),
    ]);
  }

  List<Widget> _presetChips() {
    const presets = ['Subscriptions', 'Gym', 'Utilities', 'Healthcare', 'Travel', 'Gas', 'Clothing'];
    return presets
        .where((p) => !_entries.any((e) => e.label.toLowerCase() == p.toLowerCase()))
        .map((p) => GestureDetector(
              onTap: () => setState(() => _entries.add(_Entry(p, 0))),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add_rounded, color: kGreen, size: 14),
                  const SizedBox(width: 4),
                  Text(p, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                ]),
              ),
            ))
        .toList();
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

class _Entry {
  final String label;
  final int amount;
  const _Entry(this.label, this.amount);
}

// ── Plaid connect flow ────────────────────────────────────────────────────────

class _PlaidConnectFlow extends StatefulWidget {
  final VoidCallback onDone;
  const _PlaidConnectFlow({required this.onDone});
  @override
  State<_PlaidConnectFlow> createState() => _PlaidConnectFlowState();
}

class _PlaidConnectFlowState extends State<_PlaidConnectFlow> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(color: kBlueBg, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.account_balance_rounded, color: kBlue, size: 30),
      ),
      const SizedBox(height: 18),
      Text('Connecting to Plaid...', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text('Securely linking your bank account', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 13)),
      const SizedBox(height: 24),
      const ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        child: LinearProgressIndicator(color: kBlue, backgroundColor: kBorder, minHeight: 4),
      ),
    ]);
  }
}

// ── Demo widgets ─────────────────────────────────────────────────────────────

class _DemoBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            children: kDemoSpendingCategories.map((cat) => _DemoBar(cat: cat, animValue: anim)).toList(),
          ),
        ),
      ]),
    );
  }
}

class _DemoBar extends StatelessWidget {
  final SpendingCategory cat;
  final double animValue;
  const _DemoBar({required this.cat, required this.animValue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        SizedBox(width: 95, child: Text(cat.label, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
        Expanded(child: Stack(children: [
          Container(height: 8, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(4))),
          FractionallySizedBox(
            widthFactor: (cat.percentage * animValue).clamp(0.0, 1.0),
            child: Container(height: 8, decoration: BoxDecoration(color: cat.color, borderRadius: BorderRadius.circular(4))),
          ),
        ])),
        const SizedBox(width: 8),
        Text('\$${cat.amount}', style: GoogleFonts.dmMono(color: kTextPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        Text('${(cat.percentage * 100).toStringAsFixed(0)}%', style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 11)),
      ]),
    );
  }
}

class _DemoTopMerchants extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: kGreenLight, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text(m.name, style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 14)),
            ]),
            Text('\$${m.amount}', style: GoogleFonts.dmMono(color: kTextSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
        )),
      ]),
    );
  }
}

// ── Picker card ───────────────────────────────────────────────────────────────

class _PickerCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  final String? badge;
  final VoidCallback onTap;
  const _PickerCard({required this.icon, required this.iconColor, required this.iconBg, required this.title, required this.subtitle, this.badge, required this.onTap});

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
            Row(children: [
              Text(title, style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: kGreenBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: kGreenBorder)),
                  child: Text(badge!, style: GoogleFonts.dmSans(color: kGreen, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
            const SizedBox(height: 3),
            Text(subtitle, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12, height: 1.4)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: kTextMuted, size: 18),
        ]),
      ),
    );
  }
}
