import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_profile.dart';
import '../../utils/colors.dart';

class _EC {
  final String label;
  final Color color, bg, border;
  const _EC({required this.label, required this.color, required this.bg, required this.border});
}

const _eligConfig = {
  'high': _EC(label: 'High Eligibility', color: kGreen, bg: kGreenBg, border: kGreenBorder),
  'medium': _EC(label: 'Medium', color: kAmber, bg: kAmberBg, border: Color(0xFFFDE68A)),
  'low': _EC(label: 'Lower Likelihood', color: kRed, bg: kRedBg, border: Color(0xFFFECACA)),
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
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _expanded ? elig.color.withValues(alpha: 0.3) : kBorder),
          boxShadow: [BoxShadow(color: _expanded ? elig.color.withValues(alpha: 0.06) : const Color(0x06000000), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: elig.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: elig.border)),
                child: Center(child: Text(widget.deduction.icon, style: const TextStyle(fontSize: 19))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.deduction.name, style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: elig.bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: elig.border)),
                    child: Text(elig.label, style: GoogleFonts.dmSans(color: elig.color, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Text(widget.deduction.category, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 11)),
                ]),
              ])),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('\$${_fmt(widget.deduction.value)}', style: GoogleFonts.dmMono(color: kGreen, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: kTextMuted, size: 18),
              ]),
            ]),
          ),
          if (_expanded) ...[
            const Divider(color: kBorder, height: 1, indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.deduction.explanation, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 13, height: 1.5)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10)),
                    child: Column(children: [
                      Text('Annual Deduction', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text('\$${_fmt(widget.deduction.value)}', style: GoogleFonts.dmMono(color: kGreen, fontSize: 14, fontWeight: FontWeight.bold)),
                    ]),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10)),
                    child: Column(children: [
                      Text('Tax Savings Est.', style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text('\$${_fmt((widget.deduction.value * 0.22).round())}', style: GoogleFonts.dmMono(color: kTeal, fontSize: 14, fontWeight: FontWeight.bold)),
                    ]),
                  )),
                ]),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

String _fmt(int v) {
  final s = v.toString(); final r = StringBuffer();
  for (var i = 0; i < s.length; i++) { if (i > 0 && (s.length - i) % 3 == 0) r.write(','); r.write(s[i]); }
  return r.toString();
}
