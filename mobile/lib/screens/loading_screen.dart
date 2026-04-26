import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';

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

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  int _stepIndex = 0;
  double _progress = 0;
  bool _isDone = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _runSteps();
  }

  void _runSteps() {
    const stepDuration = Duration(milliseconds: 600);
    for (var i = 0; i < _steps.length; i++) {
      Future.delayed(stepDuration * i, () {
        if (!mounted) return;
        setState(() { _stepIndex = i; _progress = (i + 1) / _steps.length; });
      });
    }
    Future.delayed(stepDuration * _steps.length + const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _isDone = true);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        if (widget.onComplete != null) { widget.onComplete!(); } else { Navigator.pushReplacementNamed(context, '/income-dashboard'); }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCard,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isDone
                    ? Container(
                        key: const ValueKey('done'),
                        width: 80, height: 80,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: kGreenBg, border: Border.all(color: kGreen, width: 2)),
                        child: const Icon(Icons.check_rounded, color: kGreen, size: 36),
                      )
                    : AnimatedBuilder(
                        key: const ValueKey('loading'),
                        animation: _pulseController,
                        builder: (_, __) => Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.lerp(kGreenBg, kCard, _pulseController.value),
                            border: Border.all(color: kBorder, width: 2),
                          ),
                          child: const Center(child: CircularProgressIndicator(color: kGreen, strokeWidth: 2.5)),
                        ),
                      ),
              ),
              const SizedBox(height: 40),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_isDone ? 'Analysis complete!' : _steps[_stepIndex], style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 14)),
                Text('${(_progress * 100).round()}%', style: GoogleFonts.dmMono(color: kGreen, fontSize: 14, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _progress),
                  duration: const Duration(milliseconds: 400),
                  builder: (_, val, __) => LinearProgressIndicator(value: val, minHeight: 4, backgroundColor: kBorder, valueColor: const AlwaysStoppedAnimation(kGreen)),
                ),
              ),
              const SizedBox(height: 40),
              RichText(text: TextSpan(children: [
                TextSpan(text: 'gig', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                TextSpan(text: 'Flow', style: GoogleFonts.dmSans(color: kGreen, fontSize: 22, fontWeight: FontWeight.w800)),
              ])),
              const SizedBox(height: 6),
              Text('Building your financial profile', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Personalized for your gig work', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
