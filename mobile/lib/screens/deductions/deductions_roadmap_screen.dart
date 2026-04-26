import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/user_profile_provider.dart';
import '../../models/user_profile.dart';
import '../../utils/colors.dart';
import '../../utils/backend_api.dart';
import '../../utils/tax_calculations.dart';
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

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, provider, _) {
        final profile = provider.profile;
        final isReady = profile.isOnboarded || profile.isDemoMode;

        if (!isReady) {
          return Scaffold(
            backgroundColor: kBg,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🧾', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text('No deductions yet', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Complete onboarding to unlock your personalized deduction analysis.', textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 14)),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(context, '/onboarding'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: kGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Start Onboarding', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => provider.activateDemoMode(),
                      child: Text('or try Demo Mode', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final deductions = calculateDeductions(profile);
        final roadmap = profile.claudeAnalysis?.roadmap ?? provider.fallbackAnalysis.roadmap;
        final totalSavings = deductions.fold(0, (sum, d) => sum + d.value);

        return Scaffold(
          backgroundColor: kBg,
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
                                  Text('Tax Optimizer', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Deductions & 90-day action plan', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 14)),
                                ],
                              ),
                            ),

                            // Segmented control
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: kCardAlt,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: kBorder),
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
                                            color: isActive ? kGreen : null,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: isActive ? [const BoxShadow(color: Color(0x1A059669), blurRadius: 8, offset: Offset(0, 2))] : null,
                                          ),
                                          child: Text(
                                            tab == _Tab.deductions ? '💰 Deductions' : '🗺️ Roadmap',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.dmSans(
                                              color: isActive ? Colors.white : kTextSecondary,
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
                              color: kGreenBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: kGreenBorder),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('TOTAL IDENTIFIED DEDUCTIONS', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 10, letterSpacing: 0.1)),
                                  const SizedBox(height: 4),
                                  Text('\$${totalSavings.toLocaleString()}', style: GoogleFonts.dmMono(color: kGreen, fontSize: 24, fontWeight: FontWeight.bold)),
                                  Text('${deductions.length} deductions found for your profile', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
                                ]),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('Effective saving', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
                                  Text('~${((totalSavings / (profile.monthlyEarnings * 12 == 0 ? 1 : profile.monthlyEarnings * 12)) * 100).round()}%',
                                    style: GoogleFonts.dmMono(color: kGreenDark, fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text('of gross income', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
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
                            _EligDot(color: kGreen, label: 'High Eligibility'),
                            const SizedBox(width: 16),
                            _EligDot(color: kAmber, label: 'Medium'),
                            const SizedBox(width: 16),
                            _EligDot(color: kRed, label: 'Low'),
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
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: GestureDetector(
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
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kAmberBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Text('⚠️ These estimates are for planning purposes only. Consult a CPA for filing advice. Deduction amounts may vary based on actual documentation.',
                              style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
                          ),
                        ),
                      ),
                    ] else ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: kCardDecoration(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Your 90-Day Financial Roadmap', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text('Personalized action steps to optimize your gig finances and minimize tax liability.', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _RoadmapStat(label: 'Steps', value: '${roadmap.length}', color: kGreen),
                                    _RoadmapStat(label: 'High Priority', value: '${roadmap.where((r) => r.priority == 'high').length}', color: kRed),
                                    _RoadmapStat(label: 'Completed', value: '${roadmap.where((r) => r.completed).length}', color: kTextSecondary),
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
                                color: kGreen,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [BoxShadow(color: Color(0x2A059669), blurRadius: 16, offset: Offset(0, 4))],
                              ),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Text('💬', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Text('Ask AI About My Roadmap', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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
      Text(label, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
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
      Text(label, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
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
