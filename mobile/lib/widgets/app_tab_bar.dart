import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class _Tab {
  final String label;
  final IconData icon;
  final String route;
  const _Tab(this.label, this.icon, this.route);
}

const _tabs = [
  _Tab('Dashboard', Icons.bar_chart_rounded, '/income-dashboard'),
  _Tab('Deductions', Icons.receipt_long_rounded, '/deductions-roadmap'),
  _Tab('AI Chat', Icons.chat_bubble_rounded, '/chat'),
];

class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name ?? '';
    final activeIndex = _tabs.indexWhere((t) => route.startsWith(t.route));

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF2A2D35))),
        color: Color(0xFF0D0F12),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Stack(
            children: [
              if (activeIndex >= 0)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  top: 0,
                  left: MediaQuery.of(context).size.width / _tabs.length * activeIndex +
                      MediaQuery.of(context).size.width / _tabs.length / 2 - 20,
                  child: Container(
                    width: 40,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.6), blurRadius: 8)],
                    ),
                  ),
                ),
              Row(
                children: List.generate(_tabs.length, (i) {
                  final isActive = i == activeIndex;
                  final tab = _tabs[i];
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (!isActive) {
                          Navigator.pushReplacementNamed(context, tab.route);
                        }
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          Icon(
                            tab.icon,
                            size: 22,
                            color: isActive ? const Color(0xFF00E676) : const Color(0xFF4A4F5C),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tab.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isActive ? const Color(0xFF00E676) : const Color(0xFF4A4F5C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
