import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_profile.dart';
import '../../providers/user_profile_provider.dart';
import '../../utils/constants.dart';
import '../../utils/colors.dart';
import '../../utils/claude_api.dart';

const _totalSteps = 11;

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
    if (_step > 0) setState(() { _forward = false; _step--; });
  }

  Future<void> _handleComplete() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final provider = context.read<UserProfileProvider>();
    // Compute total from per-platform map before analysis
    final totalEarnings = provider.profile.platformEarnings.values.fold<int>(0, (s, v) => s + v);
    provider.update((p) => p.copyWith(monthlyEarnings: totalEarnings));
    final analysis = await fetchGigAnalysis(provider.profile);
    provider.setAnalysis(analysis);
    provider.update((p) => p.copyWith(isOnboarded: true));
    if (mounted) Navigator.pushReplacementNamed(context, '/income-dashboard');
  }

  bool _canProceed() {
    final p = context.read<UserProfileProvider>().profile;
    switch (_step) {
      case 0: return p.platforms.isNotEmpty || p.customPlatforms.isNotEmpty;
      case 1: return p.platformEarnings.values.any((v) => v > 0);
      case 4: return p.state.isNotEmpty;
      default: return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kCard,
        body: SafeArea(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, color: kGreenBg, border: Border.all(color: kBorder)),
              child: const Center(child: CircularProgressIndicator(color: kGreen, strokeWidth: 2)),
            ),
            const SizedBox(height: 32),
            Text('Analyzing your finances...', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            const LinearProgressIndicator(backgroundColor: kBorder, color: kGreen),
            const SizedBox(height: 32),
            RichText(text: TextSpan(children: [
              TextSpan(text: 'gig', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
              TextSpan(text: 'Flow', style: GoogleFonts.dmSans(color: kGreen, fontSize: 20, fontWeight: FontWeight.w800)),
            ])),
            const SizedBox(height: 4),
            Text('Building your financial profile', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
        )),
      );
    }

    return Consumer<UserProfileProvider>(builder: (context, provider, _) {
      final profile = provider.profile;
      final canProceed = _canProceed();

      return Scaffold(
        backgroundColor: kBg,
        body: SafeArea(child: Column(children: [
          // Header / progress
          Container(
            color: kCard,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                RichText(text: TextSpan(children: [
                  TextSpan(text: 'gig', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                  TextSpan(text: 'Flow', style: GoogleFonts.dmSans(color: kGreen, fontSize: 18, fontWeight: FontWeight.w800)),
                ])),
                GestureDetector(
                  onTap: () { provider.activateDemoMode(); Navigator.pushReplacementNamed(context, '/income-dashboard'); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: kGreenBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: kGreenBorder)),
                    child: Text('Try Demo', style: GoogleFonts.dmSans(color: kGreen, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Step ${_step + 1} of $_totalSteps', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
                Text('${((_step + 1) / _totalSteps * 100).round()}%', style: GoogleFonts.dmSans(color: kGreen, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: (_step + 1) / _totalSteps),
                  duration: const Duration(milliseconds: 300),
                  builder: (_, val, __) => LinearProgressIndicator(value: val, minHeight: 4, backgroundColor: kBorder, valueColor: const AlwaysStoppedAnimation(kGreen)),
                ),
              ),
            ]),
          ),

          // Step content
          Expanded(
            child: RepaintBoundary(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) {
                  final offset = _forward ? const Offset(1, 0) : const Offset(-1, 0);
                  return SlideTransition(
                    position: Tween(begin: offset, end: Offset.zero)
                        .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                    child: child,
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _buildStep(profile, provider),
                ),
              ),
            ),
          ),

          // Navigation
          Container(
            color: kCard,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(children: [
              if (_step > 0) ...[
                GestureDetector(
                  onTap: _goBack,
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
                    child: const Icon(Icons.chevron_left_rounded, color: kTextSecondary, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: canProceed ? _goNext : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 52,
                    decoration: BoxDecoration(
                      color: canProceed ? kGreen : kBorder,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: canProceed ? [const BoxShadow(color: Color(0x25059669), blurRadius: 12, offset: Offset(0, 4))] : null,
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(
                        _step == _totalSteps - 1 ? 'Analyze My Finances' : 'Continue',
                        style: GoogleFonts.dmSans(color: canProceed ? Colors.white : kTextMuted, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Icon(_step == _totalSteps - 1 ? Icons.auto_awesome_rounded : Icons.arrow_forward_rounded, color: canProceed ? Colors.white : kTextMuted, size: 18),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ])),
      );
    });
  }

  Widget _buildStep(UserProfile profile, UserProfileProvider provider) {
    switch (_step) {
      case 0: return _StepPlatforms(
          platforms: profile.platforms,
          customPlatforms: profile.customPlatforms,
          onToggle: (p) {
            final next = profile.platforms.contains(p)
                ? profile.platforms.where((x) => x != p).toList()
                : [...profile.platforms, p];
            provider.update((pr) => pr.copyWith(platforms: next));
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
          onChanged: (key, val) => provider.update((p) => p.copyWith(
            platformEarnings: {...p.platformEarnings, key: val},
          )),
        );
      case 2: return _StepFilingStatus(value: profile.filingStatus, onChange: (v) => provider.update((p) => p.copyWith(filingStatus: v)));
      case 3: return _StepDependentCount(value: profile.dependentCount, onChange: (v) => provider.update((p) => p.copyWith(dependentCount: v)));
      case 4: return _StepState(
          value: profile.state,
          search: _stateSearch,
          onSearchChange: (v) => setState(() => _stateSearch = v),
          onSelect: (v) { provider.update((p) => p.copyWith(state: v)); setState(() => _stateSearch = ''); },
        );
      case 5: return _StepHousing(value: profile.housingType, onChange: (v) => provider.update((p) => p.copyWith(housingType: v)));
      case 6: return _StepMonthlyRent(value: profile.monthlyRent, housingType: profile.housingType, onChange: (v) => provider.update((p) => p.copyWith(monthlyRent: v)));
      case 7: return _StepHomeOffice(value: profile.hasHomeOffice, onChange: (v) => provider.update((p) => p.copyWith(hasHomeOffice: v)));
      case 8: return _StepVehicle(value: profile.vehicleType, onChange: (v) => provider.update((p) => p.copyWith(vehicleType: v)));
      case 9: return _StepExpenses(expenses: profile.expenses, onChange: (key, val) => provider.update((p) => p.copyWith(expenses: _updateExpense(p.expenses, key, val))));
      case 10: return _StepReview(profile: profile);
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

// ── Shared widgets ────────────────────────────────────────────────────────────

Widget _stepHeader(String title, String subtitle) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(title, style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
    const SizedBox(height: 4),
    Text(subtitle, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 14)),
    const SizedBox(height: 20),
  ],
);

Widget _selectionCard({required bool selected, required VoidCallback onTap, required Widget child}) =>
  GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? kGreenBg : kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? kGreen : kBorder, width: selected ? 1.5 : 1),
        boxShadow: [BoxShadow(
          color: selected ? const Color(0x15059669) : const Color(0x06000000),
          blurRadius: selected ? 8 : 4,
          offset: const Offset(0, 2),
        )],
      ),
      child: child,
    ),
  );

Widget _checkBadge() => Container(
  width: 22, height: 22,
  decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
  child: const Icon(Icons.check_rounded, color: Colors.white, size: 13),
);

// ── Platform logo widget ──────────────────────────────────────────────────────

class _PlatformLogo extends StatelessWidget {
  final String logoUrl;
  final String fallbackEmoji;
  const _PlatformLogo({required this.logoUrl, required this.fallbackEmoji});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36, height: 36,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          logoUrl,
          width: 36, height: 36,
          fit: BoxFit.contain,
          frameBuilder: (_, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: child,
            );
          },
          errorBuilder: (_, __, ___) => Center(
            child: Text(fallbackEmoji, style: const TextStyle(fontSize: 22)),
          ),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              decoration: BoxDecoration(color: kCardAlt, borderRadius: BorderRadius.circular(8)),
            );
          },
        ),
      ),
    );
  }
}

// ── Step 0: Platforms ─────────────────────────────────────────────────────────

class _StepPlatforms extends StatefulWidget {
  final List<Platform> platforms;
  final List<String> customPlatforms;
  final void Function(Platform) onToggle;
  final void Function(String) onAddCustom;
  final void Function(String) onRemoveCustom;

  const _StepPlatforms({
    required this.platforms,
    required this.customPlatforms,
    required this.onToggle,
    required this.onAddCustom,
    required this.onRemoveCustom,
  });

  @override
  State<_StepPlatforms> createState() => _StepPlatformsState();
}

class _StepPlatformsState extends State<_StepPlatforms> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<Platform, PlatformConfig>> get _filtered {
    if (_search.isEmpty) return kPlatformConfig.entries.toList();
    final q = _search.toLowerCase();
    return kPlatformConfig.entries.where((e) => e.value.label.toLowerCase().contains(q)).toList();
  }

  bool get _hasExactMatch {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return true;
    return kPlatformConfig.values.any((v) => v.label.toLowerCase() == q) ||
        widget.customPlatforms.any((c) => c.toLowerCase() == q);
  }

  int get _totalSelected => widget.platforms.length + widget.customPlatforms.length;

  String _categoryFor(Platform p) {
    switch (p) {
      case Platform.uber:
      case Platform.lyft:        return 'Rideshare';
      case Platform.doordash:
      case Platform.grubhub:     return 'Food delivery';
      case Platform.instacart:   return 'Grocery delivery';
      case Platform.amazonFlex:  return 'Package delivery';
      case Platform.upwork:
      case Platform.fiverr:      return 'Freelance / creative';
      case Platform.taskrabbit:  return 'On-demand tasks';
      case Platform.rover:       return 'Pet care';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final showAddCustom = _search.trim().isNotEmpty && !_hasExactMatch;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _stepHeader('Which platforms do you work on?', 'Select all that apply. This helps us find your deductions.'),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _search = v),
            style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search or add a platform...',
              hintStyle: GoogleFonts.dmSans(color: kTextMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: kTextMuted, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? GestureDetector(
                      onTap: () { _searchController.clear(); setState(() => _search = ''); },
                      child: const Icon(Icons.close_rounded, color: kTextMuted, size: 18),
                    )
                  : null,
              filled: true, fillColor: kCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGreen, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          if (_totalSelected > 0)
            Text('$_totalSelected selected', style: GoogleFonts.dmSans(color: kGreen, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
        ]),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          physics: const ClampingScrollPhysics(),
          children: [
            if (showAddCustom)
              GestureDetector(
                onTap: () {
                  widget.onAddCustom(_search.trim());
                  _searchController.clear();
                  setState(() => _search = '');
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: kGreenBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kGreenBorder, width: 1.5),
                  ),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Add "${_search.trim()}"', style: GoogleFonts.dmSans(color: kGreen, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('Add as a custom platform', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
                    ])),
                    const Icon(Icons.arrow_forward_ios_rounded, color: kGreen, size: 14),
                  ]),
                ),
              ),
            ...widget.customPlatforms.map((name) => _PlatformRow(
              logo: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: kGreenBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kGreenBorder)),
                child: Center(child: Text(name[0].toUpperCase(), style: GoogleFonts.dmSans(color: kGreen, fontSize: 16, fontWeight: FontWeight.bold))),
              ),
              label: name,
              sublabel: 'Custom platform',
              selected: true,
              onTap: () => widget.onRemoveCustom(name),
            )),
            ...filtered.map((entry) => _PlatformRow(
              logo: _PlatformLogo(logoUrl: entry.value.logoUrl, fallbackEmoji: entry.value.emoji),
              label: entry.value.label,
              sublabel: _categoryFor(entry.key),
              selected: widget.platforms.contains(entry.key),
              onTap: () => widget.onToggle(entry.key),
            )),
          ],
        ),
      ),
    ]);
  }
}

class _PlatformRow extends StatelessWidget {
  final Widget logo;
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;
  const _PlatformRow({required this.logo, required this.label, required this.sublabel, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? kGreenBg : kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? kGreen : kBorder, width: selected ? 1.5 : 1),
        ),
        child: Row(children: [
          logo,
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.dmSans(color: selected ? kGreen : kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            Text(sublabel, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
          ])),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: selected ? kGreen : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: selected ? kGreen : kBorder, width: 1.5),
            ),
            child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 13) : null,
          ),
        ]),
      ),
    );
  }
}

// ── Steps ─────────────────────────────────────────────────────────────────────

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
    final allPlatforms = [
      ...platforms.map((p) {
        final cfg = kPlatformConfig[p]!;
        return (key: p.name, label: cfg.label, emoji: cfg.emoji, max: 8000);
      }),
      ...customPlatforms.map((name) => (key: name.toLowerCase(), label: name, emoji: '💼', max: 8000)),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const ClampingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepHeader('How much do you earn per platform?', 'Slide to set your average monthly earnings per platform.'),
        ...allPlatforms.map((p) {
          final val = earnings[p.key] ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: kCardDecoration(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Text(p.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Text(p.label, style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: kGreenBg, borderRadius: BorderRadius.circular(8)),
                  child: Text('\$$val/mo', style: GoogleFonts.dmMono(color: kGreen, fontSize: 13, fontWeight: FontWeight.bold)),
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
                  value: val.toDouble(),
                  min: 0, max: p.max.toDouble(),
                  divisions: p.max ~/ 50,
                  onChanged: (v) => onChanged(p.key, v.round()),
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

class _StepFilingStatus extends StatelessWidget {
  final FilingStatus value;
  final void Function(FilingStatus) onChange;
  const _StepFilingStatus({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const ClampingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepHeader('What is your filing status?', 'This affects your standard deduction and tax brackets.'),
        ...kFilingStatusOptions.map((opt) {
          final selected = value == opt.value;
          return _selectionCard(
            selected: selected,
            onTap: () => onChange(opt.value),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 20, height: 20, margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? kGreen : kBorder, width: 2)),
                child: selected ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle))) : null,
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(opt.label, style: GoogleFonts.dmSans(color: selected ? kGreen : kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(opt.description, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
              ])),
            ]),
          );
        }),
      ]),
    );
  }
}

class _StepDependentCount extends StatelessWidget {
  final int value;
  final void Function(int) onChange;
  const _StepDependentCount({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final ctcSavings = value * 2000;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const ClampingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepHeader('How many dependents do you claim?', 'Children or qualifying relatives you support financially.'),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: kCardDecoration(),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              GestureDetector(
                onTap: value > 0 ? () => onChange(value - 1) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: value > 0 ? kGreen : kBorder,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.remove_rounded, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 32),
              Text('$value', style: GoogleFonts.dmMono(color: kTextPrimary, fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(width: 32),
              GestureDetector(
                onTap: value < 6 ? () => onChange(value + 1) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: value < 6 ? kGreen : kBorder,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            if (value > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: kGreenBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kGreenBorder)),
                child: Row(children: [
                  const Icon(Icons.savings_rounded, color: kGreen, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'Child Tax Credit: ~\$${_fmt(ctcSavings)}/yr saved',
                    style: GoogleFonts.dmSans(color: kGreen, fontSize: 13, fontWeight: FontWeight.w600),
                  )),
                ]),
              )
            else
              Text('Enter 0 if you have no dependents', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  String _fmt(int v) {
    final s = v.toString();
    final r = StringBuffer();
    for (var i = 0; i < s.length; i++) { if (i > 0 && (s.length - i) % 3 == 0) r.write(','); r.write(s[i]); }
    return r.toString();
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
    final filtered = kUsStates
        .where((s) => s['name']!.toLowerCase().contains(search.toLowerCase()) || s['code']!.toLowerCase().contains(search.toLowerCase()))
        .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _stepHeader('Which state do you work in?', 'State taxes vary significantly for gig workers.'),
          if (value.isNotEmpty) Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: kGreenBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kGreenBorder)),
            child: Row(children: [
              const Icon(Icons.check_circle_rounded, color: kGreen, size: 16),
              const SizedBox(width: 8),
              Text(
                '${kUsStates.firstWhere((s) => s['code'] == value, orElse: () => {'name': value})['name']} selected',
                style: GoogleFonts.dmSans(color: kGreen, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ]),
          ),
          TextField(
            onChanged: onSearchChange,
            style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search state...',
              hintStyle: GoogleFonts.dmSans(color: kTextMuted),
              prefixIcon: const Icon(Icons.search_rounded, color: kTextMuted, size: 20),
              filled: true, fillColor: kCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGreen, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const ClampingScrollPhysics(),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final s = filtered[i];
            final selected = value == s['code'];
            return GestureDetector(
              onTap: () => onSelect(s['code']!),
              child: Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? kGreenBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? kGreenBorder : Colors.transparent),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(s['name']!, style: GoogleFonts.dmSans(color: selected ? kGreen : kTextPrimary, fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                  Text(s['code']!, style: GoogleFonts.dmMono(color: kTextMuted, fontSize: 12)),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _StepHousing extends StatelessWidget {
  final HousingType value;
  final void Function(HousingType) onChange;
  const _StepHousing({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    const opts = [
      (val: HousingType.own,  label: 'I own my home', desc: 'Mortgage interest may be deductible', emoji: '🏠'),
      (val: HousingType.rent, label: 'I rent',         desc: 'Portion of rent may be deductible',   emoji: '🏢'),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const ClampingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepHeader('Do you own or rent your home?', 'Affects home office deduction calculations.'),
        ...opts.map((opt) {
          final selected = value == opt.val;
          return _selectionCard(
            selected: selected, onTap: () => onChange(opt.val),
            child: Row(children: [
              Text(opt.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(opt.label, style: GoogleFonts.dmSans(color: selected ? kGreen : kTextPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(opt.desc, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
              ])),
              if (selected) _checkBadge(),
            ]),
          );
        }),
      ]),
    );
  }
}

class _StepMonthlyRent extends StatelessWidget {
  final int value;
  final HousingType housingType;
  final void Function(int) onChange;
  const _StepMonthlyRent({required this.value, required this.housingType, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final label = housingType == HousingType.rent ? 'Monthly Rent' : 'Monthly Mortgage';
    const sublabel = 'Used to calculate your home office deduction';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const ClampingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepHeader(label, sublabel),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: kCardDecoration(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(label, style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: kGreenBg, borderRadius: BorderRadius.circular(8)),
                child: Text('\$$value/mo', style: GoogleFonts.dmMono(color: kGreen, fontSize: 13, fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 4),
            Text('Optional — skip if not applicable', style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 12)),
          ]),
        ),
      ]),
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
      (val: true,  label: 'Yes, I have a home office', desc: 'Dedicated workspace in my home', emoji: '💻'),
      (val: false, label: 'No home office',             desc: 'I work primarily on the road',   emoji: '🚗'),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const ClampingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepHeader('Do you use part of your home for work?', 'A dedicated home office qualifies for the home office deduction.'),
        ...opts.map((opt) {
          final selected = value == opt.val;
          return _selectionCard(
            selected: selected, onTap: () => onChange(opt.val),
            child: Row(children: [
              Text(opt.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(opt.label, style: GoogleFonts.dmSans(color: selected ? kGreen : kTextPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(opt.desc, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 12)),
              ])),
              if (selected) _checkBadge(),
            ]),
          );
        }),
      ]),
    );
  }
}

class _StepVehicle extends StatelessWidget {
  final VehicleType value;
  final void Function(VehicleType) onChange;
  const _StepVehicle({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const ClampingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepHeader('What type of vehicle do you use?', 'Used to calculate your mileage deduction rate.'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(children: kVehicleConfig.entries.map((entry) {
            final selected = value == entry.key;
            return GestureDetector(
              onTap: () => onChange(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 96, margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? kGreenBg : kCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: selected ? kGreen : kBorder, width: selected ? 1.5 : 1),
                ),
                child: Column(children: [
                  Text(entry.value.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 6),
                  Text(entry.value.label, textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: selected ? kGreen : kTextPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                  if (entry.value.mileageRate > 0) ...[
                    const SizedBox(height: 3),
                    Text('\$${entry.value.mileageRate}/mi', style: GoogleFonts.dmMono(color: kTextMuted, fontSize: 10)),
                  ],
                ]),
              ),
            );
          }).toList()),
        ),
      ]),
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
      ('gas',       'Gas & Fuel',              expenses.gas,       600),
      ('phone',     'Phone & Data',            expenses.phone,     300),
      ('insurance', 'Vehicle Insurance',       expenses.insurance, 400),
      ('equipment', 'Tools & Equipment',       expenses.equipment, 300),
      ('health',    'Health Insurance',        expenses.health,    800),
      ('food',      'Food & Meals (business)', expenses.food,      300),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const ClampingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepHeader('Monthly business expenses', 'Slide to estimate your monthly costs — these become deductions.'),
        ...fields.map((f) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: kCardDecoration(),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(f.$2, style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: kGreenBg, borderRadius: BorderRadius.circular(8)),
                child: Text('\$${f.$3}/mo', style: GoogleFonts.dmMono(color: kGreen, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 10),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: kGreen, inactiveTrackColor: kBorder,
                thumbColor: kGreen, overlayColor: kGreen.withValues(alpha: 0.12),
                trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(value: f.$3.toDouble(), min: 0, max: f.$4.toDouble(), divisions: f.$4 ~/ 10, onChanged: (v) => onChange(f.$1, v.round())),
            ),
          ]),
        )),
      ]),
    );
  }
}

class _StepReview extends StatelessWidget {
  final UserProfile profile;
  const _StepReview({required this.profile});

  @override
  Widget build(BuildContext context) {
    final monthly = profile.platformEarnings.values.fold<int>(0, (s, v) => s + v);
    final annualEst = monthly * 12;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const ClampingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepHeader('Ready to analyze your finances', 'Review your profile below then tap Analyze.'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: kCardDecoration(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PLATFORMS', style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 11, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ...profile.platforms.map((p) {
                final cfg = kPlatformConfig[p]!;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: kGreenBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: kGreenBorder)),
                  child: Text('${cfg.emoji} ${cfg.label}', style: GoogleFonts.dmSans(color: kGreen, fontSize: 12, fontWeight: FontWeight.w500)),
                );
              }),
              ...profile.customPlatforms.map((name) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: kGreenBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: kGreenBorder)),
                child: Text(name, style: GoogleFonts.dmSans(color: kGreen, fontSize: 12, fontWeight: FontWeight.w500)),
              )),
            ]),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: kCardDecoration(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Est. Annual', style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text('\$${_fmt(annualEst)}', style: GoogleFonts.dmMono(color: kGreen, fontSize: 20, fontWeight: FontWeight.bold)),
          ]))),
          const SizedBox(width: 10),
          Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: kCardDecoration(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('State', style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(profile.state.isEmpty ? '—' : profile.state, style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          ]))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: kCardDecoration(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Filing Status', style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              profile.filingStatus.name
                  .replaceAll('marriedJoint', 'Married Joint')
                  .replaceAll('marriedSeparate', 'Married Sep.')
                  .replaceAll('headOfHousehold', 'Head of HH')
                  .replaceAll('single', 'Single'),
              style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ]))),
          const SizedBox(width: 10),
          Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: kCardDecoration(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Vehicle', style: GoogleFonts.dmSans(color: kTextMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text('${kVehicleConfig[profile.vehicleType]?.emoji} ${kVehicleConfig[profile.vehicleType]?.label}', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ]))),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kGreenBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: kGreenBorder)),
          child: Row(children: [
            const Icon(Icons.auto_awesome_rounded, color: kGreen, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text('AI analysis will identify your personalized deductions and quarterly tax schedule', style: GoogleFonts.dmSans(color: kGreen, fontSize: 13))),
          ]),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  String _fmt(int v) {
    final s = v.toString();
    final r = StringBuffer();
    for (var i = 0; i < s.length; i++) { if (i > 0 && (s.length - i) % 3 == 0) r.write(','); r.write(s[i]); }
    return r.toString();
  }
}
