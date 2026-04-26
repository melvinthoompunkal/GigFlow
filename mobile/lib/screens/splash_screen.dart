import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_profile_provider.dart';
import '../utils/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    Future.delayed(const Duration(milliseconds: 900), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final profile = context.read<UserProfileProvider>().profile;
    if (profile.isOnboarded || profile.isDemoMode) {
      Navigator.pushReplacementNamed(context, '/income-dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/import');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCard,
      body: FadeTransition(
        opacity: _fadeController,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // GigFlow logo mark
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: kGreenBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kGreenBorder, width: 1.5),
                ),
                child: Center(
                  child: Text('G', style: GoogleFonts.dmSans(color: kGreen, fontSize: 32, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 16),
              // GigFlow wordmark
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'gig', style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 28, fontWeight: FontWeight.w800)),
                    TextSpan(text: 'Flow', style: GoogleFonts.dmSans(color: kGreen, fontSize: 28, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text('Financial OS for Gig Workers', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
