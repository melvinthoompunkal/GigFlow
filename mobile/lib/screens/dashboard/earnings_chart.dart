import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/tax_calculations.dart';
import '../../utils/colors.dart';

class EarningsChart extends StatelessWidget {
  final List<MonthlyDataPoint> data;
  const EarningsChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateTime.now().month - 1;
    final allValues = data.map((d) => d.earnings > 0 ? d.earnings : d.projected).where((v) => v > 0);
    final maxY = allValues.isEmpty ? 1000.0 : allValues.reduce((a, b) => a > b ? a : b) * 1.2;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    LineChartBarData buildLine({required List<FlSpot> spots, required Color color, required bool dashed, double strokeWidth = 2}) {
      return LineChartBarData(
        spots: spots, isCurved: true, color: color, barWidth: strokeWidth,
        dashArray: dashed ? [6, 4] : null, isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: !dashed,
          gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
      );
    }

    final actualSpots = <FlSpot>[];
    final projectedSpots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      if (data[i].earnings > 0) actualSpots.add(FlSpot(i.toDouble(), data[i].earnings.toDouble()));
      if (data[i].projected > 0) projectedSpots.add(FlSpot(i.toDouble(), data[i].projected.toDouble()));
    }

    return SizedBox(
      height: 180,
      child: LineChart(LineChartData(
        minX: 0, maxX: 11, minY: 0, maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true, drawVerticalLine: false, horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => const FlLine(color: kBorderLight, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 36, interval: maxY / 4,
            getTitlesWidget: (val, _) => val == 0 ? const SizedBox.shrink()
                : Text('\$${(val / 1000).toStringAsFixed(0)}k', style: GoogleFonts.dmMono(color: kTextMuted, fontSize: 10)),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, interval: 1,
            getTitlesWidget: (val, _) {
              final i = val.toInt();
              if (i < 0 || i >= 12) return const SizedBox.shrink();
              return Text(months[i], style: GoogleFonts.dmMono(color: kTextMuted, fontSize: 10));
            },
          )),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        extraLinesData: ExtraLinesData(verticalLines: [
          VerticalLine(x: currentMonth.toDouble(), color: kGreen.withValues(alpha: 0.4), strokeWidth: 1, dashArray: [4, 4]),
        ]),
        lineBarsData: [
          if (actualSpots.isNotEmpty) buildLine(spots: actualSpots, color: kGreen, dashed: false),
          if (projectedSpots.isNotEmpty) buildLine(spots: projectedSpots, color: kTextMuted, dashed: true, strokeWidth: 1.5),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => kCard,
            tooltipBorder: const BorderSide(color: kBorder),
            getTooltipItems: (spots) => spots.map((s) {
              final isProjected = s.barIndex == 1;
              return LineTooltipItem(
                '\$${s.y.round().toLocaleString()}${isProjected ? '\nProjected' : ''}',
                GoogleFonts.dmMono(color: isProjected ? kTextSecondary : kGreen, fontSize: 12, fontWeight: FontWeight.bold),
              );
            }).toList(),
          ),
        ),
      )),
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
