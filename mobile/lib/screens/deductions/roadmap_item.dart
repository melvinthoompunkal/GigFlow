import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_profile.dart';
import '../../utils/colors.dart';

class _PC { final Color color; final String label, dot; const _PC({required this.color, required this.label, required this.dot}); }
const _priorityConfig = {
  'high': _PC(color: kRed, label: 'High Priority', dot: '🔴'),
  'medium': _PC(color: kAmber, label: 'Medium', dot: '🟡'),
  'low': _PC(color: kBlue, label: 'Low Priority', dot: '🔵'),
};

class RoadmapItem extends StatefulWidget {
  final RoadmapStep step;
  final bool isLast;
  const RoadmapItem({super.key, required this.step, required this.isLast});

  @override
  State<RoadmapItem> createState() => _RoadmapItemState();
}

class _RoadmapItemState extends State<RoadmapItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = _priorityConfig[widget.step.priority] ?? _priorityConfig['medium']!;

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 32, child: Column(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: widget.step.completed ? const LinearGradient(colors: [kGreenDark, kGreen]) : null,
            color: widget.step.completed ? null : widget.step.priority == 'high' ? kRedBg : kBg,
            border: widget.step.completed ? null : Border.all(color: p.color, width: 1.5),
          ),
          child: Center(child: widget.step.completed
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
              : Text('${widget.step.step}', style: GoogleFonts.dmMono(color: p.color, fontSize: 12, fontWeight: FontWeight.bold))),
        ),
        if (!widget.isLast) Container(width: 1.5, height: _expanded ? 120 : 56, color: kBorder),
      ])),
      const SizedBox(width: 12),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _expanded ? p.color.withValues(alpha: 0.25) : kBorder),
              boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: p.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: p.color.withValues(alpha: 0.2))),
                      child: Text('${p.dot} ${p.label}', style: GoogleFonts.dmSans(color: p.color, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: kBorder)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.access_time_rounded, size: 10, color: kTextMuted),
                        const SizedBox(width: 3),
                        Text(widget.step.deadline, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 10)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(widget.step.title, style: GoogleFonts.dmSans(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                ])),
                Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: kTextMuted, size: 18),
              ]),
              if (_expanded) ...[
                const SizedBox(height: 10),
                const Divider(color: kBorder, height: 1),
                const SizedBox(height: 10),
                Text(widget.step.description, style: GoogleFonts.dmSans(color: kTextSecondary, fontSize: 13, height: 1.5)),
                if (widget.step.priority == 'high') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: kRedBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFECACA))),
                    child: Row(children: [
                      const Icon(Icons.warning_amber_rounded, color: kRed, size: 14),
                      const SizedBox(width: 8),
                      Text('Deadline approaching — take action soon', style: GoogleFonts.dmSans(color: kRed, fontSize: 12)),
                    ]),
                  ),
                ],
              ],
            ]),
          ),
        ),
      )),
    ]);
  }
}
