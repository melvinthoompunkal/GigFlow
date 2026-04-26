import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _steps = [
  'Analyzing your platforms...',
  'Calculating deductions...',
  'Estimating tax liability...',
  'Building your roadmap...',
  'Personalizing insights...',
];

class LoadingScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  const LoadingScreen({super.key, this.onComplete});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  int _stepIndex = 0;
  double _progress = 0;
  bool _isDone = false;
  late final AnimationController _progressController;
  late final AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _dotController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    _runSteps();
  }

  void _runSteps() {
    const stepDuration = Duration(milliseconds: 600);
    for (var i = 0; i < _steps.length; i++) {
      Future.delayed(stepDuration * i, () {
        if (!mounted) return;
        setState(() {
          _stepIndex = i;
          _progress = (i + 1) / _steps.length;
        });
      });
    }
    Future.delayed(stepDuration * _steps.length + const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _isDone = true);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        if (widget.onComplete != null) {
          widget.onComplete!();
        } else {
          Navigator.pushReplacementNamed(context, '/income-dashboard');
        }
      });
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F12),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isDone ? _buildDoneIcon() : _buildLoadingIcon(),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isDone ? 'Analysis complete!' : _steps[_stepIndex],
                    style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 14),
                  ),
                  Text(
                    '${(_progress * 100).round()}%',
                    style: GoogleFonts.dmMono(color: const Color(0xFF00E676), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _progress),
                  duration: const Duration(milliseconds: 400),
                  builder: (_, value, __) => LinearProgressIndicator(
                    value: value,
                    minHeight: 4,
                    backgroundColor: const Color(0xFF2A2D35),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF00E676)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Building your financial profile',
                style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Personalized for your gig work',
                style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIcon() {
    return Container(
      key: const ValueKey('loading'),
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF00E676).withValues(alpha: 0.08),
        border: Border.all(color: const Color(0xFF2A2D35), width: 2),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _dotController,
          builder: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: 0.3 + (i == (_dotController.value * 2.99).floor() ? 0.7 : 0),
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle),
                ),
              ),
            )),
          ),
        ),
      ),
    );
  }

  Widget _buildDoneIcon() {
    return Container(
      key: const ValueKey('done'),
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF00E676).withValues(alpha: 0.15),
        border: Border.all(color: const Color(0xFF00E676), width: 2),
      ),
      child: const Icon(Icons.check_rounded, color: Color(0xFF00E676), size: 36),
    );
  }
}
