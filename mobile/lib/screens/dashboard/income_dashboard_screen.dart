import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/user_profile_provider.dart';
import '../../utils/constants.dart';
import '../../utils/tax_calculations.dart';
import '../../widgets/app_tab_bar.dart';
import 'earnings_chart.dart';

class IncomeDashboardScreen extends StatefulWidget {
  const IncomeDashboardScreen({super.key});

  @override
  State<IncomeDashboardScreen> createState() => _IncomeDashboardScreenState();
}

class _IncomeDashboardScreenState extends State<IncomeDashboardScreen> {
  bool _showDemoToast = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, provider, _) {
        final profile = provider.profile;
        final isReady = profile.isOnboarded || profile.isDemoMode;

        if (!isReady) {
          return Scaffold(
            backgroundColor: const Color(0xFF0D0F12),
            body: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('💰', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text('No profile yet', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Complete the onboarding survey to see your personalized dashboard.', textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 14)),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(context, '/onboarding'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00E676)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('Start Onboarding', style: GoogleFonts.dmSans(color: const Color(0xFF0D0F12), fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            provider.activateDemoMode();
                            setState(() => _showDemoToast = true);
                            Future.delayed(const Duration(milliseconds: 2500), () {
                              if (mounted) setState(() => _showDemoToast = false);
                            });
                          },
                          child: Text('or try Demo Mode', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showDemoToast)
                  Positioned(
                    bottom: 96,
                    left: 0, right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1D23),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00E676)),
                        ),
                        child: Text('Demo mode activated ✓', style: GoogleFonts.dmSans(color: const Color(0xFF00E676), fontSize: 14)),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        final monthlyData = generateMonthlyData(profile.monthlyEarnings);
        final platformBreakdown = generatePlatformBreakdown(profile.platforms, profile.monthlyEarnings);
        final taxBreakdown = profile.claudeAnalysis?.taxEstimate ?? calculateTaxBreakdown(profile);
        final taxHealthScore = calculateTaxHealthScore(profile);

        final currentMonth = DateTime.now().month - 1;
        final ytdEarnings = monthlyData.take(currentMonth + 1).fold(0, (sum, d) => sum + d.earnings);
        final thisMonthEarnings = monthlyData[currentMonth].earnings;
        final lastMonthEarnings = currentMonth > 0 ? monthlyData[currentMonth - 1].earnings : 0;
        final monthOverMonth = lastMonthEarnings > 0
            ? ((thisMonthEarnings - lastMonthEarnings) / lastMonthEarnings) * 100
            : 0.0;
        final avgWeekly = ((ytdEarnings / ((currentMonth + 1) * 4.33))).round();

        return Scaffold(
          backgroundColor: const Color(0xFF0D0F12),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('YTD GROSS EARNINGS', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 11, letterSpacing: 0.12)),
                                        const SizedBox(height: 4),
                                        Text('\$${ytdEarnings.toLocaleString()}', style: GoogleFonts.dmMono(color: const Color(0xFF00E676), fontSize: 36, fontWeight: FontWeight.bold, height: 1.1)),
                                        const SizedBox(height: 4),
                                        Text('Jan 1 – ${_currentDateLabel()}', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (profile.isDemoMode) { provider.reset(); } else { provider.activateDemoMode(); }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: profile.isDemoMode ? const Color(0xFF00E676).withValues(alpha: 0.1) : const Color(0xFF1A1D23),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: profile.isDemoMode ? const Color(0xFF00E676) : const Color(0xFF2A2D35)),
                                          ),
                                          child: Row(children: [
                                            Icon(profile.isDemoMode ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                                              color: profile.isDemoMode ? const Color(0xFF00E676) : const Color(0xFF8B90A0), size: 14),
                                            const SizedBox(width: 4),
                                            Text('Demo', style: GoogleFonts.dmSans(color: profile.isDemoMode ? const Color(0xFF00E676) : const Color(0xFF8B90A0), fontSize: 12)),
                                          ]),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1A1D23), border: Border.all(color: const Color(0xFF2A2D35))),
                                        child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF8B90A0), size: 18),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(children: [
                                Expanded(child: _StatPill(
                                  label: 'This Month',
                                  value: '\$${thisMonthEarnings.toLocaleString()}',
                                  badge: '${monthOverMonth >= 0 ? '+' : ''}${monthOverMonth.toStringAsFixed(1)}%',
                                  badgeColor: monthOverMonth >= 0 ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                                  showTrend: true,
                                  trendUp: monthOverMonth >= 0,
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: _StatPill(
                                  label: 'Avg / Week',
                                  value: '\$${avgWeekly.toLocaleString()}',
                                  badge: '/wk',
                                  badgeColor: const Color(0xFF00E676),
                                )),
                              ]),
                            ],
                          ),
                        ),
                      ),

                      // Platform breakdown
                      if (platformBreakdown.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Platform Breakdown', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 14, fontWeight: FontWeight.w600)),
                              Text('${profile.platforms.length} active', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 140,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: platformBreakdown.length,
                            itemBuilder: (_, i) {
                              final item = platformBreakdown[i];
                              final cfg = kPlatformConfig[item.platform];
                              if (cfg == null) return const SizedBox.shrink();
                              return _PlatformCard(cfg: cfg, item: item);
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Earnings chart
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFF1A1D23), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2A2D35))),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Monthly Earnings', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 14, fontWeight: FontWeight.w600)),
                                    Text('Jan – Dec 2025', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
                                  ]),
                                  Row(children: [
                                    _LegendDot(color: const Color(0xFF00E676), label: 'Actual'),
                                    const SizedBox(width: 12),
                                    _LegendDot(color: const Color(0xFF4A4F5C), label: 'Projected', dashed: true),
                                  ]),
                                ],
                              ),
                              const SizedBox(height: 16),
                              EarningsChart(data: monthlyData),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tax snapshot
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tax Snapshot', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            GridView.count(
                              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
                              children: [
                                _TaxCard(label: 'Q2 Estimated Tax', value: '\$${taxBreakdown.quarterly.toLocaleString()}', sublabel: 'Due Jun 17, 2025', accent: const Color(0xFFFFB300), icon: Icons.warning_amber_rounded, urgent: true),
                                _TaxCard(label: 'Monthly Set-Aside', value: '\$${taxBreakdown.monthly.toLocaleString()}', sublabel: 'Recommended savings', accent: const Color(0xFF00E676), icon: Icons.check_circle_outline_rounded),
                                _TaxCard(label: 'SE Tax (Annual)', value: '\$${taxBreakdown.selfEmployment.toLocaleString()}', sublabel: '15.3% of net earnings', accent: const Color(0xFF448AFF), icon: Icons.trending_up_rounded),
                                _TaxCard(label: 'Total Tax Liability', value: '\$${taxBreakdown.total.toLocaleString()}', sublabel: 'SE + Federal + State', accent: const Color(0xFFFF5252), icon: Icons.trending_down_rounded),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tax health score
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFF1A1D23), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2A2D35))),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Tax Health Score', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 14, fontWeight: FontWeight.w600)),
                                    Text('Based on your profile completeness', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
                                  ]),
                                  Text('$taxHealthScore', style: GoogleFonts.dmMono(
                                    color: taxHealthScore >= 70 ? const Color(0xFF00E676) : taxHealthScore >= 50 ? const Color(0xFFFFB300) : const Color(0xFFFF5252),
                                    fontSize: 22, fontWeight: FontWeight.bold,
                                  )),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: taxHealthScore / 100),
                                  duration: const Duration(milliseconds: 800),
                                  builder: (_, val, __) => LinearProgressIndicator(
                                    value: val, minHeight: 10,
                                    backgroundColor: const Color(0xFF2A2D35),
                                    valueColor: AlwaysStoppedAnimation(
                                      taxHealthScore >= 70 ? const Color(0xFF00E676) : taxHealthScore >= 50 ? const Color(0xFFFFB300) : const Color(0xFFFF5252),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('0', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
                                  Text(
                                    taxHealthScore >= 70 ? '✅ Good standing' : taxHealthScore >= 50 ? '⚠️ Needs attention' : '🚨 Action required',
                                    style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12),
                                  ),
                                  Text('100', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quarterly deadlines
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text('Quarterly Deadlines', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: kQuarterlyDeadlines.length,
                          itemBuilder: (_, i) => _QuarterPill(quarter: kQuarterlyDeadlines[i], amount: taxBreakdown.quarterly),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              const AppTabBar(),
            ],
          ),
        );
      },
    );
  }

  String _currentDateLabel() {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final String badge;
  final Color badgeColor;
  final bool showTrend;
  final bool trendUp;
  const _StatPill({required this.label, required this.value, required this.badge, required this.badgeColor, this.showTrend = false, this.trendUp = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFF1A1D23), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2A2D35))),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.dmMono(color: const Color(0xFFF0F2F5), fontSize: 14, fontWeight: FontWeight.bold)),
          ])),
          Row(children: [
            if (showTrend) Icon(trendUp ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: badgeColor, size: 14),
            const SizedBox(width: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(badge, style: GoogleFonts.dmMono(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
        ],
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  final dynamic cfg;
  final dynamic item;
  const _PlatformCard({required this.cfg, required this.item});

  @override
  Widget build(BuildContext context) {
    final trendMax = item.trend.reduce((a, b) => a > b ? a : b);
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1A1D23), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2A2D35))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(cfg.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Expanded(child: Text(cfg.label, style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),
          Text('\$${item.monthly.toLocaleString()}', style: GoogleFonts.dmMono(color: const Color(0xFFF0F2F5), fontSize: 15, fontWeight: FontWeight.bold)),
          Text('${(item.share * 100).round()}% of total', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 11)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(item.trend.length, (i) {
              final barH = trendMax > 0 ? (item.trend[i] / trendMax) * 24.0 : 2.0;
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Container(
                  height: barH.clamp(2.0, 24.0),
                  decoration: BoxDecoration(
                    color: i == item.trend.length - 1 ? const Color(0xFF00E676) : const Color(0xFF2A2D35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ));
            }),
          ),
        ],
      ),
    );
  }
}

class _TaxCard extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;
  final Color accent;
  final IconData icon;
  final bool urgent;
  const _TaxCard({required this.label, required this.value, required this.sublabel, required this.accent, required this.icon, this.urgent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: urgent ? accent.withValues(alpha: 0.06) : const Color(0xFF1A1D23),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: urgent ? accent.withValues(alpha: 0.3) : const Color(0xFF2A2D35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: accent, size: 16),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 11), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.dmMono(color: accent, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(sublabel, style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 11)),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _LegendDot({required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: dashed ? Colors.transparent : color,
          shape: BoxShape.circle,
          border: dashed ? Border.all(color: color, width: 1) : null,
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
    ]);
  }
}

class _QuarterPill extends StatelessWidget {
  final QuarterDeadline quarter;
  final int amount;
  const _QuarterPill({required this.quarter, required this.amount});

  @override
  Widget build(BuildContext context) {
    final colors = {'paid': const Color(0xFF00E676), 'upcoming': const Color(0xFFFFB300), 'future': const Color(0xFF4A4F5C)};
    final bgs = {'paid': const Color(0xFF00E676), 'upcoming': const Color(0xFFFFB300), 'future': const Color(0xFF1A1D23)};
    final color = colors[quarter.status] ?? const Color(0xFF4A4F5C);
    final bg = bgs[quarter.status] ?? const Color(0xFF1A1D23);

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: quarter.status == 'future' ? 1 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(quarter.quarter, style: GoogleFonts.dmSans(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  quarter.status == 'paid' ? '✓ Paid' : quarter.status == 'upcoming' ? '⚡ Due Soon' : 'Upcoming',
                  style: GoogleFonts.dmSans(color: color, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('\$${amount.toLocaleString()}', style: GoogleFonts.dmMono(color: const Color(0xFFF0F2F5), fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(quarter.deadline, style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 11)),
        ],
      ),
    );
  }
}

extension on int {
  String toLocaleString() {
    final str = toString();
    final result = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) result.write(',');
      result.write(str[i]);
    }
    return result.toString();
  }
}
