import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/user_profile_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/onboarding/onboarding_survey_screen.dart';
import 'screens/dashboard/income_dashboard_screen.dart';
import 'screens/deductions/deductions_roadmap_screen.dart';
import 'screens/chat/chat_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D0F12),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProfileProvider(),
      child: const GigFlowApp(),
    ),
  );
}

class GigFlowApp extends StatelessWidget {
  const GigFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GigFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0D0F12),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          surface: Color(0xFF0D0F12),
        ),
        textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (ctx) => const SplashScreen(),
        '/onboarding': (ctx) => const OnboardingSurveyScreen(),
        '/loading': (ctx) => const LoadingScreen(),
        '/income-dashboard': (ctx) => const IncomeDashboardScreen(),
        '/deductions-roadmap': (ctx) => const DeductionsRoadmapScreen(),
        '/chat': (ctx) => const ChatScreen(),
      },
    );
  }
}
