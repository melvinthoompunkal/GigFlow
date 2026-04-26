import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';

class _Tab {
  final String label;
  final IconData icon;
  final String route;
  const _Tab(this.label, this.icon, this.route);
}

const _tabs = [
  _Tab('Dashboard',  Icons.bar_chart_rounded,   '/income-dashboard'),
  _Tab('Deductions', Icons.receipt_long_rounded, '/deductions-roadmap'),
  _Tab('Spending',   Icons.pie_chart_rounded,    '/spending'),
  _Tab('AI Chat',    Icons.chat_bubble_rounded,  '/chat'),
];

class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name ?? '';
    final activeIndex = _tabs.indexWhere((t) => route.startsWith(t.route));

    return Container(
      decoration: const BoxDecoration(
        color: kCard,
        border: Border(top: BorderSide(color: kBorder)),
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final isActive = i == activeIndex;
              final tab = _tabs[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () { if (!isActive) Navigator.pushReplacementNamed(context, tab.route); },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? kGreenBg : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(tab.icon, size: 20, color: isActive ? kGreen : kTextMuted),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tab.label,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? kGreen : kTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
