import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_profile.dart';

class _PriorityConfig {
  final Color color;
  final String label;
  final String dot;
  const _PriorityConfig({required this.color, required this.label, required this.dot});
}

const _priorityConfig = {
  'high': _PriorityConfig(color: Color(0xFFFF5252), label: 'High Priority', dot: '🔴'),
  'medium': _PriorityConfig(color: Color(0xFFFFB300), label: 'Medium', dot: '🟡'),
  'low': _PriorityConfig(color: Color(0xFF448AFF), label: 'Low Priority', dot: '🔵'),
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
    final priority = _priorityConfig[widget.step.priority] ?? _priorityConfig['medium']!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.step.completed
                      ? const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00E676)])
                      : null,
                  color: widget.step.completed
                      ? null
                      : widget.step.priority == 'high'
                          ? priority.color.withValues(alpha: 0.15)
                          : const Color(0xFF1A1D23),
                  border: widget.step.completed
                      ? null
                      : Border.all(color: priority.color, width: 2),
                ),
                child: Center(
                  child: widget.step.completed
                      ? const Icon(Icons.check_rounded, color: Color(0xFF0D0F12), size: 14)
                      : Text('${widget.step.step}', style: GoogleFonts.dmMono(color: priority.color, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              if (!widget.isLast)
                Container(
                  width: 1,
                  height: _expanded ? 120 : 60,
                  color: priority.color.withValues(alpha: 0.3),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _expanded ? const Color(0xFF22262E) : const Color(0xFF1A1D23),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _expanded ? priority.color.withValues(alpha: 0.25) : const Color(0xFF2A2D35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8, runSpacing: 6,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: priority.color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: priority.color.withValues(alpha: 0.25)),
                                    ),
                                    child: Text('${priority.dot} ${priority.label}', style: GoogleFonts.dmSans(color: priority.color, fontSize: 10)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: const Color(0xFF2A2D35), borderRadius: BorderRadius.circular(8)),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Icon(Icons.access_time_rounded, size: 10, color: Color(0xFF8B90A0)),
                                      const SizedBox(width: 3),
                                      Text(widget.step.deadline, style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 10)),
                                    ]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(widget.step.title, style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: const Color(0xFF4A4F5C), size: 18),
                      ],
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFF2A2D35), height: 1),
                      const SizedBox(height: 12),
                      Text(widget.step.description, style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 13, height: 1.5)),
                      if (widget.step.priority == 'high') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5252).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 14),
                            const SizedBox(width: 8),
                            Text('Deadline approaching — take action soon', style: GoogleFonts.dmSans(color: const Color(0xFFFF5252), fontSize: 12)),
                          ]),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
