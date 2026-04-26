import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_profile.dart';

class _EligConfig {
  final String label;
  final Color color;
  final Color bg;
  final Color border;
  const _EligConfig({required this.label, required this.color, required this.bg, required this.border});
}

const _eligConfig = {
  'high': _EligConfig(label: 'High Eligibility', color: Color(0xFF00E676), bg: Color(0x1A00E676), border: Color(0x4D00E676)),
  'medium': _EligConfig(label: 'Medium', color: Color(0xFFFFB300), bg: Color(0x1AFFB300), border: Color(0x4DFFB300)),
  'low': _EligConfig(label: 'Lower Likelihood', color: Color(0xFFFF5252), bg: Color(0x1AFF5252), border: Color(0x4DFF5252)),
};

class DeductionCard extends StatefulWidget {
  final Deduction deduction;
  final int index;
  const DeductionCard({super.key, required this.deduction, required this.index});

  @override
  State<DeductionCard> createState() => _DeductionCardState();
}

class _DeductionCardState extends State<DeductionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final elig = _eligConfig[widget.deduction.eligibility] ?? _eligConfig['medium']!;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _expanded ? const Color(0xFF22262E) : const Color(0xFF1A1D23),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _expanded ? elig.color.withValues(alpha: 0.25) : const Color(0xFF2A2D35)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: elig.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: elig.border),
                    ),
                    child: Center(child: Text(widget.deduction.icon, style: const TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.deduction.name, style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: elig.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: elig.border)),
                            child: Text(elig.label, style: GoogleFonts.dmSans(color: elig.color, fontSize: 10)),
                          ),
                          const SizedBox(width: 8),
                          Text(widget.deduction.category, style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 11)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${widget.deduction.value.toLocaleString()}', style: GoogleFonts.dmMono(color: const Color(0xFF00E676), fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: const Color(0xFF4A4F5C), size: 16),
                    ],
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const Divider(color: Color(0xFF2A2D35), height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.deduction.explanation, style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 13, height: 1.5)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF0D0F12), borderRadius: BorderRadius.circular(12)),
                        child: Column(children: [
                          Text('Annual Deduction', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 11)),
                          const SizedBox(height: 4),
                          Text('\$${widget.deduction.value.toLocaleString()}', style: GoogleFonts.dmMono(color: const Color(0xFF00E676), fontSize: 14, fontWeight: FontWeight.bold)),
                        ]),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF0D0F12), borderRadius: BorderRadius.circular(12)),
                        child: Column(children: [
                          Text('Tax Savings Est.', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 11)),
                          const SizedBox(height: 4),
                          Text('\$${(widget.deduction.value * 0.22).round().toLocaleString()}', style: GoogleFonts.dmMono(color: const Color(0xFF1DE9B6), fontSize: 14, fontWeight: FontWeight.bold)),
                        ]),
                      )),
                    ]),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
