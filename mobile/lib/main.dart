import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/user_profile_provider.dart';
import 'utils/colors.dart';
import 'screens/splash_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/onboarding/onboarding_survey_screen.dart';
import 'screens/dashboard/income_dashboard_screen.dart';
import 'screens/deductions/deductions_roadmap_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/import/import_screen.dart';
import 'screens/spending/spending_analysis_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // GoogleFonts.config.allowRuntimeFetching = false;
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: kCard,
    systemNavigationBarIconBrightness: Brightness.dark,
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
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.light(
          primary: kGreen,
          surface: kCard,
        ),
        textTheme: GoogleFonts.dmSansTextTheme(ThemeData.light().textTheme),
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
        '/import': (ctx) => const ImportScreen(),
        '/onboarding': (ctx) => const OnboardingSurveyScreen(),
        '/loading': (ctx) => const LoadingScreen(),
        '/income-dashboard': (ctx) => const IncomeDashboardScreen(),
        '/deductions-roadmap': (ctx) => const DeductionsRoadmapScreen(),
        '/spending': (ctx) => const SpendingAnalysisScreen(),
        '/chat': (ctx) => const ChatScreen(),
      },
    );
  }
}
