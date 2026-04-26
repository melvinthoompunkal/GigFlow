import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/app_tab_bar.dart';
import 'deduction_card.dart';
import 'roadmap_item.dart';

enum _Tab { deductions, roadmap }

class DeductionsRoadmapScreen extends StatefulWidget {
  const DeductionsRoadmapScreen({super.key});

  @override
  State<DeductionsRoadmapScreen> createState() => _DeductionsRoadmapScreenState();
}

class _DeductionsRoadmapScreenState extends State<DeductionsRoadmapScreen> {
  _Tab _activeTab = _Tab.deductions;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, provider, _) {
        final profile = provider.profile;
        final isReady = profile.isOnboarded || profile.isDemoMode;

        if (!isReady) {
          return Scaffold(
            backgroundColor: const Color(0xFF0D0F12),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🧾', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text('No deductions yet', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Complete onboarding to unlock your personalized deduction analysis.', textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 14)),
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
                      onTap: () => provider.activateDemoMode(),
                      child: Text('or try Demo Mode', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final deductions = profile.claudeAnalysis?.deductions ?? provider.fallbackAnalysis.deductions;
        final roadmap = profile.claudeAnalysis?.roadmap ?? provider.fallbackAnalysis.roadmap;
        final totalSavings = deductions.fold(0, (sum, d) => sum + d.value);

        return Scaffold(
          backgroundColor: const Color(0xFF0D0F12),
          body: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tax Optimizer', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 24, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Deductions & 90-day action plan', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 14)),
                                ],
                              ),
                            ),

                            // Segmented control
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1D23),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF2A2D35)),
                                ),
                                child: Row(
                                  children: _Tab.values.map((tab) {
                                    final isActive = _activeTab == tab;
                                    return Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => _activeTab = tab),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            gradient: isActive ? const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00E676)]) : null,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            tab == _Tab.deductions ? '💰 Deductions' : '🗺️ Roadmap',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.dmSans(
                                              color: isActive ? const Color(0xFF0D0F12) : const Color(0xFF8B90A0),
                                              fontSize: 14, fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_activeTab == _Tab.deductions) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('TOTAL IDENTIFIED DEDUCTIONS', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 10, letterSpacing: 0.1)),
                                  const SizedBox(height: 4),
                                  Text('\$${totalSavings.toLocaleString()}', style: GoogleFonts.dmMono(color: const Color(0xFF00E676), fontSize: 24, fontWeight: FontWeight.bold)),
                                  Text('${deductions.length} deductions found for your profile', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
                                ]),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('Effective saving', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
                                  Text('~${((totalSavings / (profile.monthlyEarnings * 12 == 0 ? 1 : profile.monthlyEarnings * 12)) * 100).round()}%',
                                    style: GoogleFonts.dmMono(color: const Color(0xFF1DE9B6), fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text('of gross income', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Row(children: [
                            _EligDot(color: const Color(0xFF00E676), label: 'High Eligibility'),
                            const SizedBox(width: 16),
                            _EligDot(color: const Color(0xFFFFB300), label: 'Medium'),
                            const SizedBox(width: 16),
                            _EligDot(color: const Color(0xFFFF5252), label: 'Low'),
                          ]),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: DeductionCard(deduction: deductions[i], index: i),
                          ),
                          childCount: deductions.length,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFF1A1D23), borderRadius: BorderRadius.circular(12)),
                            child: Text('⚠️ These estimates are for planning purposes only. Consult a CPA for filing advice. Deduction amounts may vary based on actual documentation.',
                              style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
                          ),
                        ),
                      ),
                    ] else ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: const Color(0xFF1A1D23), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2A2D35))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Your 90-Day Financial Roadmap', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text('Personalized action steps to optimize your gig finances and minimize tax liability.', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _RoadmapStat(label: 'Steps', value: '${roadmap.length}', color: const Color(0xFF00E676)),
                                    _RoadmapStat(label: 'High Priority', value: '${roadmap.where((r) => r.priority == 'high').length}', color: const Color(0xFFFF5252)),
                                    _RoadmapStat(label: 'Completed', value: '${roadmap.where((r) => r.completed).length}', color: const Color(0xFF8B90A0)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            child: RoadmapItem(step: roadmap[i], isLast: i == roadmap.length - 1),
                          ),
                          childCount: roadmap.length,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                          child: GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(context, '/chat'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00E676)]),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [BoxShadow(color: Color(0x4000E676), blurRadius: 16, offset: Offset(0, 4))],
                              ),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Text('💬', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Text('Ask AI About My Roadmap', style: GoogleFonts.dmSans(color: const Color(0xFF0D0F12), fontSize: 14, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),
              const AppTabBar(),
            ],
          ),
        );
      },
    );
  }
}

class _EligDot extends StatelessWidget {
  final Color color;
  final String label;
  const _EligDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
    ]);
  }
}

class _RoadmapStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RoadmapStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(value, style: GoogleFonts.dmMono(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
    ]));
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
