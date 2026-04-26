import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/user_profile_provider.dart';
import '../../utils/constants.dart';
import '../../utils/tax_calculations.dart';
import '../../utils/colors.dart';
import '../../widgets/app_tab_bar.dart';
import 'earnings_chart.dart';
import '../import/import_screen.dart';

class IncomeDashboardScreen extends StatefulWidget {
  const IncomeDashboardScreen({super.key});
  @override
  State<IncomeDashboardScreen> createState() => _IncomeDashboardScreenState();
}

class _IncomeDashboardScreenState extends State<IncomeDashboardScreen> {
  bool _showDemoToast = false;
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

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(builder: (context, provider, _) {
      final profile = provider.profile;
      final isReady = profile.isOnboarded || profile.isDemoMode;

      if (!isReady) {
        return Scaffold(
          backgroundColor: kBg,
          body: Stack(children: [
            Center(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 72, height: 72, decoration: BoxDecoration(color: kGreenBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: kGreenBorder)), child: const Center(child: Text('💰', style: TextStyle(fontSize: 32)))),
                const SizedBox(height: 20),
                Text('No profile yet', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Complete the onboarding survey to see your personalized dashboard.', textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 14)),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/onboarding'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [kGreenDark, kGreen]), borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x30059669), blurRadius: 12, offset: Offset(0, 4))]),
                    child: Text('Start Onboarding', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () { provider.activateDemoMode(); setState(() => _showDemoToast = true); Future.delayed(const Duration(milliseconds: 2500), () { if (mounted) setState(() => _showDemoToast = false); }); },
                  child: Text('or try Demo Mode', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 14)),
                ),
              ]),
            )),
            if (_showDemoToast) Positioned(
              bottom: 100, left: 0, right: 0,
              child: Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: kGreenBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kGreenBorder), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 8)]),
                child: Text('Demo mode activated ✓', style: GoogleFonts.dmSans(color: kGreen, fontSize: 14, fontWeight: FontWeight.w600)),
              )),
            ),
          ]),
        );
      }

      final monthlyData = generateMonthlyData(profile.monthlyEarnings);
      final platformBreakdown = generatePlatformBreakdown(profile);
      final taxBreakdown = calculateTaxBreakdown(profile);
      final taxHealthScore = calculateTaxHealthScore(profile);
      final currentMonth = DateTime.now().month - 1;
      final ytdEarnings = monthlyData.take(currentMonth + 1).fold(0, (sum, d) => sum + d.earnings);
      final thisMonthEarnings = monthlyData[currentMonth].earnings;
      final lastMonthEarnings = currentMonth > 0 ? monthlyData[currentMonth - 1].earnings : 0;
      final monthOverMonth = lastMonthEarnings > 0 ? ((thisMonthEarnings - lastMonthEarnings) / lastMonthEarnings) * 100 : 0.0;
      final avgWeekly = (ytdEarnings / ((currentMonth + 1) * 4.33)).round();

      return Scaffold(
        backgroundColor: kBg,
        body: Stack(children: [
          Column(children: [
          Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Header card ──
            Container(
              color: kCard,
              child: SafeArea(bottom: false, child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('YTD GROSS EARNINGS', style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 11, letterSpacing: 0.8)),
                      const SizedBox(height: 4),
                      Text('\$${_fmt(ytdEarnings)}', style: GoogleFonts.dmMono(color: kTextPrimary, fontSize: 36, fontWeight: FontWeight.w800, height: 1.1)),
                      const SizedBox(height: 4),
                      Text('Jan 1 – ${_dateLabel()}', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
                    ])),
                    Row(children: [
                      GestureDetector(
                        onTap: () { if (profile.isDemoMode) { provider.reset(); } else { provider.activateDemoMode(); } },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: profile.isDemoMode ? kGreenBg : kBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: profile.isDemoMode ? kGreenBorder : kBorder),
                          ),
                          child: Row(children: [
                            Icon(profile.isDemoMode ? Icons.toggle_on_rounded : Icons.toggle_off_rounded, color: profile.isDemoMode ? kGreen : kTextMuted, size: 16),
                            const SizedBox(width: 4),
                            Text('Demo', style: GoogleFonts.dmSans(color: profile.isDemoMode ? kGreen : kTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: kBg, border: Border.all(color: kBorder)), child: const Icon(Icons.notifications_none_rounded, color: kTextSecondary, size: 18)),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _StatPill(label: 'This Month', value: '\$${_fmt(thisMonthEarnings)}', badge: '${monthOverMonth >= 0 ? '+' : ''}${monthOverMonth.toStringAsFixed(1)}%', badgeColor: monthOverMonth >= 0 ? kGreen : kRed, trendUp: monthOverMonth >= 0)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatPill(label: 'Avg / Week', value: '\$${_fmt(avgWeekly)}', badge: '/wk', badgeColor: kGreen)),
                  ]),
                ]),
              )),
            ),
            const SizedBox(height: 16),

            // ── Update Data button ──
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

            // ── Platform breakdown ──
            if (platformBreakdown.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Platform Breakdown', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  Text('${profile.platforms.length + profile.customPlatforms.length} active', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 10),
              SizedBox(height: 140, child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: platformBreakdown.length,
                itemBuilder: (_, i) {
                  final item = platformBreakdown[i];
                  final PlatformConfig cfg;
                  if (item.customName != null) {
                    cfg = PlatformConfig(label: item.customName!, emoji: '💼', logoUrl: '');
                  } else {
                    final found = kPlatformConfig[item.platform];
                    if (found == null) return const SizedBox.shrink();
                    cfg = found;
                  }
                  return _PlatformCard(cfg: cfg, item: item);
                },
              )),
              const SizedBox(height: 16),
            ],

            // ── Earnings chart ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: kCardDecoration(),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Monthly Earnings', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('Jan – Dec 2025', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
                    ]),
                    Row(children: [
                      _LegendDot(color: kGreen, label: 'Actual'),
                      const SizedBox(width: 12),
                      _LegendDot(color: kTextMuted, label: 'Projected', dashed: true),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  EarningsChart(data: monthlyData),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // ── Tax snapshot ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tax Snapshot', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.55,
                  children: [
                    _TaxCard(label: 'Q2 Estimated Tax', value: '\$${_fmt(taxBreakdown.quarterly)}', sublabel: 'Due Jun 17, 2025', accent: kAmber, icon: Icons.warning_amber_rounded, urgent: true),
                    _TaxCard(label: 'Monthly Set-Aside', value: '\$${_fmt(taxBreakdown.monthly)}', sublabel: 'Recommended savings', accent: kGreen, icon: Icons.check_circle_outline_rounded),
                    _TaxCard(label: 'SE Tax (Annual)', value: '\$${_fmt(taxBreakdown.selfEmployment)}', sublabel: '15.3% of net earnings', accent: kBlue, icon: Icons.trending_up_rounded),
                    _TaxCard(label: 'Total Tax Liability', value: '\$${_fmt(taxBreakdown.total)}', sublabel: 'SE + Federal + State', accent: kRed, icon: Icons.trending_down_rounded),
                  ],
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Tax health score ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: kCardDecoration(),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Tax Health Score', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('Based on your profile completeness', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
                    ]),
                    Text('$taxHealthScore', style: GoogleFonts.dmMono(color: taxHealthScore >= 70 ? kGreen : taxHealthScore >= 50 ? kAmber : kRed, fontSize: 24, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 12),
                  ClipRRect(borderRadius: BorderRadius.circular(4), child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: taxHealthScore / 100),
                    duration: const Duration(milliseconds: 800),
                    builder: (_, val, __) => LinearProgressIndicator(
                      value: val, minHeight: 8,
                      backgroundColor: kBorder,
                      valueColor: AlwaysStoppedAnimation(taxHealthScore >= 70 ? kGreen : taxHealthScore >= 50 ? kAmber : kRed),
                    ),
                  )),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('0', style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 11)),
                    Text(taxHealthScore >= 70 ? '✅ Good standing' : taxHealthScore >= 50 ? '⚠️ Needs attention' : '🚨 Action required', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 11)),
                    Text('100', style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 11)),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // ── Quarterly deadlines ──
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text('Quarterly Deadlines', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w700))),
            const SizedBox(height: 10),
            SizedBox(height: 100, child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: kQuarterlyDeadlines.length,
              itemBuilder: (_, i) => _QuarterPill(quarter: kQuarterlyDeadlines[i], amount: taxBreakdown.quarterly),
            )),
            const SizedBox(height: 100),
          ]))),
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
      );
    });
  }

  String _dateLabel() {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final now = DateTime.now();
    return '${m[now.month - 1]} ${now.day}, ${now.year}';
  }
}

String _fmt(int v) {
  final s = v.toString(); final r = StringBuffer();
  for (var i = 0; i < s.length; i++) { if (i > 0 && (s.length - i) % 3 == 0) r.write(','); r.write(s[i]); }
  return r.toString();
}

class _StatPill extends StatelessWidget {
  final String label, value, badge;
  final Color badgeColor;
  final bool trendUp;
  const _StatPill({required this.label, required this.value, required this.badge, required this.badgeColor, this.trendUp = true});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: kCardDecoration(),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.dmMono(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(badge, style: GoogleFonts.dmMono(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold))),
    ]),
  );
}

class _PlatformCard extends StatelessWidget {
  final dynamic cfg, item;
  const _PlatformCard({required this.cfg, required this.item});

  @override
  Widget build(BuildContext context) {
    final trendMax = (item.trend as List<int>).reduce((a, b) => a > b ? a : b);
    return Container(
      width: 140, margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12), decoration: kCardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(cfg.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(child: Text(cfg.label, style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 6),
        Text('\$${_fmt(item.monthly as int)}', style: GoogleFonts.dmMono(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
        Text('${((item.share as double) * 100).round()}% of total', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 11)),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate((item.trend as List).length, (i) {
          final barH = trendMax > 0 ? ((item.trend[i] as int) / trendMax) * 24.0 : 2.0;
          return Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(height: barH.clamp(2.0, 24.0), decoration: BoxDecoration(color: i == (item.trend as List).length - 1 ? kGreen : kBorder, borderRadius: BorderRadius.circular(2))),
          ));
        })),
      ]),
    );
  }
}

class _TaxCard extends StatelessWidget {
  final String label, value, sublabel;
  final Color accent;
  final IconData icon;
  final bool urgent;
  const _TaxCard({required this.label, required this.value, required this.sublabel, required this.accent, required this.icon, this.urgent = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: urgent ? accent.withValues(alpha: 0.05) : kCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: urgent ? accent.withValues(alpha: 0.25) : kBorder),
      boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: accent, size: 15), const SizedBox(width: 6), Expanded(child: Text(label, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 11), overflow: TextOverflow.ellipsis))]),
      const SizedBox(height: 6),
      Text(value, style: GoogleFonts.dmMono(color: accent, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(sublabel, style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 11)),
    ]),
  );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _LegendDot({required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: dashed ? Colors.transparent : color, shape: BoxShape.circle, border: dashed ? Border.all(color: color) : null)),
    const SizedBox(width: 4),
    Text(label, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
  ]);
}

class _QuarterPill extends StatelessWidget {
  final QuarterDeadline quarter;
  final int amount;
  const _QuarterPill({required this.quarter, required this.amount});

  @override
  Widget build(BuildContext context) {
    final colors = {'paid': kGreen, 'upcoming': kAmber, 'future': kTextMuted};
    final color = colors[quarter.status] ?? kTextMuted;
    return Container(
      width: 160, margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: quarter.status == 'upcoming' ? color.withValues(alpha: 0.4) : kBorder),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(quarter.quarter, style: GoogleFonts.dmSans(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(quarter.status == 'paid' ? '✓ Paid' : quarter.status == 'upcoming' ? '⚡ Due Soon' : 'Upcoming', style: GoogleFonts.dmSans(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 4),
        Text('\$${_fmt(amount)}', style: GoogleFonts.dmMono(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(quarter.deadline, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 11)),
      ]),
    );
  }
}
