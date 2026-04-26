import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_profile.dart';
import '../../providers/user_profile_provider.dart';
import '../../utils/constants.dart';
import '../../utils/claude_api.dart';

const _totalSteps = 10;

class OnboardingSurveyScreen extends StatefulWidget {
  const OnboardingSurveyScreen({super.key});

  @override
  State<OnboardingSurveyScreen> createState() => _OnboardingSurveyScreenState();
}

class _OnboardingSurveyScreenState extends State<OnboardingSurveyScreen> {
  int _step = 0;
  bool _forward = true;
  bool _isLoading = false;
  String _stateSearch = '';

  void _goNext() {
    if (_step < _totalSteps - 1) {
      setState(() { _forward = true; _step++; });
    } else {
      _handleComplete();
    }
  }

  void _goBack() {
    if (_step > 0) {
      setState(() { _forward = false; _step--; });
    }
  }

  Future<void> _handleComplete() async {
    setState(() => _isLoading = true);
    final provider = context.read<UserProfileProvider>();
    final analysis = await fetchGigAnalysis(provider.profile);
    provider.setAnalysis(analysis);
    provider.update((p) => p.copyWith(isOnboarded: true));
    if (mounted) Navigator.pushReplacementNamed(context, '/income-dashboard');
  }

  bool _canProceed() {
    final p = context.read<UserProfileProvider>().profile;
    switch (_step) {
      case 0: return p.platforms.isNotEmpty;
      case 1: return p.monthlyEarnings > 0;
      case 4: return p.state.isNotEmpty;
      default: return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0F12),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00E676).withValues(alpha: 0.08),
                    border: Border.all(color: const Color(0xFF2A2D35), width: 2),
                  ),
                  child: const Center(child: CircularProgressIndicator(color: Color(0xFF00E676), strokeWidth: 2)),
                ),
                const SizedBox(height: 40),
                Text('Analyzing your finances...', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 14)),
                const SizedBox(height: 8),
                const LinearProgressIndicator(backgroundColor: Color(0xFF2A2D35), color: Color(0xFF00E676)),
                const SizedBox(height: 40),
                Text('Building your financial profile', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Personalized for your gig work', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 14)),
              ],
            ),
          ),
        ),
      );
    }

    return Consumer<UserProfileProvider>(
      builder: (context, provider, _) {
        final profile = provider.profile;
        final canProceed = _canProceed();

        return Scaffold(
          backgroundColor: const Color(0xFF0D0F12),
          body: SafeArea(
            child: Column(
              children: [
                // Progress bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Step ${_step + 1} of $_totalSteps',
                            style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
                          GestureDetector(
                            onTap: () {
                              provider.activateDemoMode();
                              Navigator.pushReplacementNamed(context, '/income-dashboard');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E676).withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3)),
                              ),
                              child: Text('Demo Mode', style: GoogleFonts.dmSans(color: const Color(0xFF00E676), fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: (_step + 1) / _totalSteps),
                          duration: const Duration(milliseconds: 300),
                          builder: (_, val, __) => LinearProgressIndicator(
                            value: val,
                            minHeight: 4,
                            backgroundColor: const Color(0xFF2A2D35),
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF00E676)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Step content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, animation) {
                      final offset = _forward ? const Offset(1, 0) : const Offset(-1, 0);
                      return SlideTransition(
                        position: Tween(begin: offset, end: Offset.zero).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildStep(profile, provider),
                      ),
                    ),
                  ),
                ),

                // Navigation
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      if (_step > 0) ...[
                        GestureDetector(
                          onTap: _goBack,
                          child: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1D23),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF2A2D35)),
                            ),
                            child: const Icon(Icons.chevron_left_rounded, color: Color(0xFF8B90A0), size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: GestureDetector(
                          onTap: canProceed ? _goNext : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: canProceed
                                  ? const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00E676)])
                                  : null,
                              color: canProceed ? null : const Color(0xFF2A2D35),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: canProceed
                                  ? [const BoxShadow(color: Color(0x4000E676), blurRadius: 16, offset: Offset(0, 4))]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _step == _totalSteps - 1 ? 'Analyze My Finances' : 'Continue',
                                  style: GoogleFonts.dmSans(
                                    color: canProceed ? const Color(0xFF0D0F12) : const Color(0xFF4A4F5C),
                                    fontSize: 16, fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  _step == _totalSteps - 1 ? Icons.check_rounded : Icons.chevron_right_rounded,
                                  color: canProceed ? const Color(0xFF0D0F12) : const Color(0xFF4A4F5C),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep(UserProfile profile, UserProfileProvider provider) {
    switch (_step) {
      case 0: return _StepPlatforms(
          platforms: profile.platforms,
          onToggle: (p) {
            final next = profile.platforms.contains(p)
                ? profile.platforms.where((x) => x != p).toList()
                : [...profile.platforms, p];
            provider.update((pr) => pr.copyWith(platforms: next));
          },
        );
      case 1: return _StepEarnings(
          value: profile.monthlyEarnings,
          onChange: (v) => provider.update((p) => p.copyWith(monthlyEarnings: v)),
        );
      case 2: return _StepFilingStatus(
          value: profile.filingStatus,
          onChange: (v) => provider.update((p) => p.copyWith(filingStatus: v)),
        );
      case 3: return _StepDependents(
          value: profile.hasDependents,
          onChange: (v) => provider.update((p) => p.copyWith(hasDependents: v)),
        );
      case 4: return _StepState(
          value: profile.state,
          search: _stateSearch,
          onSearchChange: (v) => setState(() => _stateSearch = v),
          onSelect: (v) {
            provider.update((p) => p.copyWith(state: v));
            setState(() => _stateSearch = '');
          },
        );
      case 5: return _StepHousing(
          value: profile.housingType,
          onChange: (v) => provider.update((p) => p.copyWith(housingType: v)),
        );
      case 6: return _StepHomeOffice(
          value: profile.hasHomeOffice,
          onChange: (v) => provider.update((p) => p.copyWith(hasHomeOffice: v)),
        );
      case 7: return _StepVehicle(
          value: profile.vehicleType,
          onChange: (v) => provider.update((p) => p.copyWith(vehicleType: v)),
        );
      case 8: return _StepExpenses(
          expenses: profile.expenses,
          onChange: (key, val) {
            final e = profile.expenses;
            provider.update((p) => p.copyWith(expenses: _updateExpense(e, key, val)));
          },
        );
      case 9: return _StepReview(profile: profile);
      default: return const SizedBox.shrink();
    }
  }

  Expenses _updateExpense(Expenses e, String key, int val) {
    switch (key) {
      case 'gas': return e.copyWith(gas: val);
      case 'phone': return e.copyWith(phone: val);
      case 'insurance': return e.copyWith(insurance: val);
      case 'equipment': return e.copyWith(equipment: val);
      case 'health': return e.copyWith(health: val);
      case 'food': return e.copyWith(food: val);
      default: return e;
    }
  }
}

// ── Step sub-widgets ──────────────────────────────────────────────────────────

class _StepPlatforms extends StatelessWidget {
  final List<Platform> platforms;
  final void Function(Platform) onToggle;
  const _StepPlatforms({required this.platforms, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Which platforms do you work on?', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Select all that apply. This helps us find your deductions.', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 14)),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.8,
          children: kPlatformConfig.entries.map((entry) {
            final selected = platforms.contains(entry.key);
            return GestureDetector(
              onTap: () => onToggle(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF00E676).withValues(alpha: 0.1) : const Color(0xFF1A1D23),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selected ? const Color(0xFF00E676) : const Color(0xFF2A2D35)),
                ),
                child: Row(
                  children: [
                    Text(entry.value.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry.value.label, style: GoogleFonts.dmSans(color: selected ? const Color(0xFF00E676) : const Color(0xFFF0F2F5), fontSize: 13, fontWeight: FontWeight.w500))),
                    if (selected) Container(
                      width: 18, height: 18,
                      decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: Color(0xFF0D0F12), size: 12),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StepEarnings extends StatelessWidget {
  final int value;
  final void Function(int) onChange;
  const _StepEarnings({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Monthly earnings across all platforms?', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Estimate your average monthly gross income.', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 14)),
        const SizedBox(height: 24),
        ...kEarningsOptions.map((opt) {
          final selected = value == opt.value;
          return GestureDetector(
            onTap: () => onChange(opt.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF00E676).withValues(alpha: 0.1) : const Color(0xFF1A1D23),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? const Color(0xFF00E676) : const Color(0xFF2A2D35)),
              ),
              child: Row(
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opt.label, style: GoogleFonts.dmMono(color: selected ? const Color(0xFF00E676) : const Color(0xFFF0F2F5), fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(opt.sublabel, style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
                    ],
                  )),
                  if (selected) Container(
                    width: 24, height: 24,
                    decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: Color(0xFF0D0F12), size: 14),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StepFilingStatus extends StatelessWidget {
  final FilingStatus value;
  final void Function(FilingStatus) onChange;
  const _StepFilingStatus({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('What is your filing status?', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('This affects your standard deduction and tax brackets.', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 14)),
        const SizedBox(height: 24),
        ...kFilingStatusOptions.map((opt) {
          final selected = value == opt.value;
          return GestureDetector(
            onTap: () => onChange(opt.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF00E676).withValues(alpha: 0.1) : const Color(0xFF1A1D23),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? const Color(0xFF00E676) : const Color(0xFF2A2D35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20, height: 20,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: selected ? const Color(0xFF00E676) : const Color(0xFF4A4F5C), width: 2),
                    ),
                    child: selected ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle))) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opt.label, style: GoogleFonts.dmSans(color: selected ? const Color(0xFF00E676) : const Color(0xFFF0F2F5), fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(opt.description, style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
                    ],
                  )),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StepDependents extends StatelessWidget {
  final bool value;
  final void Function(bool) onChange;
  const _StepDependents({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    const opts = [
      (val: true, label: 'Yes', sublabel: 'I claim dependents on my return', emoji: '👨‍👧'),
      (val: false, label: 'No', sublabel: 'Filing without dependents', emoji: '👤'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Do you have dependents?', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Children or qualifying relatives you support financially.', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 14)),
        const SizedBox(height: 32),
        ...opts.map((opt) {
          final selected = value == opt.val;
          return GestureDetector(
            onTap: () => onChange(opt.val),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF00E676).withValues(alpha: 0.1) : const Color(0xFF1A1D23),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? const Color(0xFF00E676) : const Color(0xFF2A2D35)),
              ),
              child: Row(
                children: [
                  Text(opt.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opt.label, style: GoogleFonts.dmSans(color: selected ? const Color(0xFF00E676) : const Color(0xFFF0F2F5), fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(opt.sublabel, style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 13)),
                    ],
                  )),
                  if (selected) Container(
                    width: 24, height: 24,
                    decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: Color(0xFF0D0F12), size: 14),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StepState extends StatelessWidget {
  final String value;
  final String search;
  final void Function(String) onSearchChange;
  final void Function(String) onSelect;
  const _StepState({required this.value, required this.search, required this.onSearchChange, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final filtered = kUsStates.where((s) =>
      s['name']!.toLowerCase().contains(search.toLowerCase()) ||
      s['code']!.toLowerCase().contains(search.toLowerCase())
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Which state do you work in?', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('State taxes vary significantly for gig workers.', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 14)),
        const SizedBox(height: 16),
        if (value.isNotEmpty) Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF00E676).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00E676)),
          ),
          child: Row(children: [
            const Icon(Icons.check_rounded, color: Color(0xFF00E676), size: 16),
            const SizedBox(width: 8),
            Text('${kUsStates.firstWhere((s) => s['code'] == value, orElse: () => {'name': value})['name']} selected',
              style: GoogleFonts.dmSans(color: const Color(0xFF00E676), fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
        ),
        TextField(
          onChanged: onSearchChange,
          style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search state...',
            hintStyle: GoogleFonts.dmSans(color: const Color(0xFF4A4F5C)),
            filled: true, fillColor: const Color(0xFF1A1D23),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2D35))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2D35))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00E676))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final s = filtered[i];
              final selected = value == s['code'];
              return GestureDetector(
                onTap: () => onSelect(s['code']!),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF00E676).withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? const Color(0xFF00E676).withValues(alpha: 0.4) : Colors.transparent),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s['name']!, style: GoogleFonts.dmSans(color: selected ? const Color(0xFF00E676) : const Color(0xFFF0F2F5), fontSize: 14)),
                      Text(s['code']!, style: GoogleFonts.dmMono(color: const Color(0xFF8B90A0), fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StepHousing extends StatelessWidget {
  final HousingType value;
  final void Function(HousingType) onChange;
  const _StepHousing({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    const opts = [
      (val: HousingType.own, label: 'I own my home', desc: 'Mortgage interest may be deductible', emoji: '🏠'),
      (val: HousingType.rent, label: 'I rent', desc: 'Portion of rent may be deductible', emoji: '🏢'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Do you own or rent your home?', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Affects home office deduction calculations.', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 14)),
        const SizedBox(height: 32),
        ...opts.map((opt) {
          final selected = value == opt.val;
          return GestureDetector(
            onTap: () => onChange(opt.val),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF00E676).withValues(alpha: 0.1) : const Color(0xFF1A1D23),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? const Color(0xFF00E676) : const Color(0xFF2A2D35)),
              ),
              child: Row(
                children: [
                  Text(opt.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opt.label, style: GoogleFonts.dmSans(color: selected ? const Color(0xFF00E676) : const Color(0xFFF0F2F5), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(opt.desc, style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 13)),
                    ],
                  )),
                  if (selected) Container(
                    width: 24, height: 24,
                    decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: Color(0xFF0D0F12), size: 14),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StepHomeOffice extends StatelessWidget {
  final bool value;
  final void Function(bool) onChange;
  const _StepHomeOffice({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    const opts = [
      (val: true, label: 'Yes, I have a home office', desc: 'Dedicated workspace in my home', emoji: '💻'),
      (val: false, label: 'No home office', desc: 'I work primarily on the road', emoji: '🚗'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Do you use part of your home for work?', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('A dedicated home office space qualifies for the home office deduction.', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 14)),
        const SizedBox(height: 32),
        ...opts.map((opt) {
          final selected = value == opt.val;
          return GestureDetector(
            onTap: () => onChange(opt.val),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF00E676).withValues(alpha: 0.1) : const Color(0xFF1A1D23),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? const Color(0xFF00E676) : const Color(0xFF2A2D35)),
              ),
              child: Row(
                children: [
                  Text(opt.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opt.label, style: GoogleFonts.dmSans(color: selected ? const Color(0xFF00E676) : const Color(0xFFF0F2F5), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(opt.desc, style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 13)),
                    ],
                  )),
                  if (selected) Container(
                    width: 24, height: 24,
                    decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: Color(0xFF0D0F12), size: 14),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StepVehicle extends StatelessWidget {
  final VehicleType value;
  final void Function(VehicleType) onChange;
  const _StepVehicle({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('What type of vehicle do you use?', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Used to calculate your mileage deduction rate.', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 14)),
        const SizedBox(height: 24),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: kVehicleConfig.entries.map((entry) {
              final selected = value == entry.key;
              return GestureDetector(
                onTap: () => onChange(entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF00E676).withValues(alpha: 0.1) : const Color(0xFF1A1D23),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: selected ? const Color(0xFF00E676) : const Color(0xFF2A2D35)),
                  ),
                  child: Column(
                    children: [
                      Text(entry.value.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text(entry.value.label, textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: selected ? const Color(0xFF00E676) : const Color(0xFFF0F2F5), fontSize: 12, fontWeight: FontWeight.w500)),
                      if (entry.value.mileageRate > 0) ...[
                        const SizedBox(height: 4),
                        Text('\$${entry.value.mileageRate}/mi', style: GoogleFonts.dmMono(color: const Color(0xFF8B90A0), fontSize: 11)),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StepExpenses extends StatelessWidget {
  final Expenses expenses;
  final void Function(String, int) onChange;
  const _StepExpenses({required this.expenses, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final fields = [
      ('gas', 'Gas & Fuel', expenses.gas, 600),
      ('phone', 'Phone & Data', expenses.phone, 300),
      ('insurance', 'Vehicle Insurance', expenses.insurance, 400),
      ('equipment', 'Tools & Equipment', expenses.equipment, 300),
      ('health', 'Health Insurance', expenses.health, 800),
      ('food', 'Food & Meals (business)', expenses.food, 300),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Monthly business expenses', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Drag sliders to estimate your monthly costs. These become deductions.', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 14)),
        const SizedBox(height: 24),
        ...fields.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(f.$2, style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 14, fontWeight: FontWeight.w500)),
                  Text('\$${f.$3}/mo', style: GoogleFonts.dmMono(color: const Color(0xFF00E676), fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF00E676),
                  inactiveTrackColor: const Color(0xFF2A2D35),
                  thumbColor: const Color(0xFF00E676),
                  overlayColor: const Color(0xFF00E676).withValues(alpha: 0.15),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: f.$3.toDouble(),
                  min: 0, max: f.$4.toDouble(), divisions: f.$4 ~/ 10,
                  onChanged: (v) => onChange(f.$1, v.round()),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StepReview extends StatelessWidget {
  final UserProfile profile;
  const _StepReview({required this.profile});

  @override
  Widget build(BuildContext context) {
    final annualEst = profile.monthlyEarnings * 12;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Ready to analyze your finances', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Here is a summary of your profile. Tap Analyze to get your personalized tax plan.', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 14)),
        const SizedBox(height: 24),
        _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PLATFORMS', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 11, letterSpacing: 0.12)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: profile.platforms.map((p) {
              final cfg = kPlatformConfig[p];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.2)),
                ),
                child: Text('${cfg?.emoji} ${cfg?.label}', style: GoogleFonts.dmSans(color: const Color(0xFF00E676), fontSize: 12)),
              );
            }).toList()),
          ],
        )),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Est. Annual', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
            const SizedBox(height: 4),
            Text('\$${annualEst.toLocaleString()}', style: GoogleFonts.dmMono(color: const Color(0xFF00E676), fontSize: 18, fontWeight: FontWeight.bold)),
          ]))),
          const SizedBox(width: 12),
          Expanded(child: _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('State', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
            const SizedBox(height: 4),
            Text(profile.state.isEmpty ? '—' : profile.state, style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 18, fontWeight: FontWeight.bold)),
          ]))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Filing Status', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
            const SizedBox(height: 4),
            Text(profile.filingStatus.name.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim(), style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 13, fontWeight: FontWeight.w500)),
          ]))),
          const SizedBox(width: 12),
          Expanded(child: _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Vehicle', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
            const SizedBox(height: 4),
            Text('${kVehicleConfig[profile.vehicleType]?.emoji} ${kVehicleConfig[profile.vehicleType]?.label}', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 13, fontWeight: FontWeight.w500)),
          ]))),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF00E676).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.2)),
          ),
          child: Text('✨ AI analysis will identify your personalized deductions and quarterly tax schedule',
            style: GoogleFonts.dmSans(color: const Color(0xFF00E676), fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFF1A1D23), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2A2D35))),
    child: child,
  );
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
