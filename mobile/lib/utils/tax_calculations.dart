import '../models/user_profile.dart';

class MonthlyDataPoint {
  final String month;
  final int earnings;
  final int projected;
  const MonthlyDataPoint({required this.month, required this.earnings, required this.projected});
}

class PlatformBreakdown {
  final Platform platform;
  final double share;
  final int monthly;
  final List<int> trend;
  const PlatformBreakdown({required this.platform, required this.share, required this.monthly, required this.trend});
}

List<MonthlyDataPoint> generateMonthlyData(int monthlyEarnings) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const variances = [0.82, 0.91, 0.88, 0.95, 1.04, 1.12, 1.08, 0.97, 1.15, 1.03, 0.94, 1.20];
  final currentMonth = DateTime.now().month - 1;

  return List.generate(12, (i) => MonthlyDataPoint(
    month: months[i],
    earnings: i <= currentMonth ? (monthlyEarnings * variances[i]).round() : 0,
    projected: i > currentMonth ? (monthlyEarnings * variances[i]).round() : 0,
  ));
}

List<PlatformBreakdown> generatePlatformBreakdown(List<Platform> platforms, int monthlyEarnings) {
  if (platforms.isEmpty) return [];
  final splits = List.generate(platforms.length, (i) {
    final base = 1.0 / platforms.length;
    final jitter = (i % 2 == 0 ? 0.15 : -0.1);
    return (base + jitter / platforms.length).clamp(0.05, 1.0);
  });
  final total = splits.reduce((a, b) => a + b);
  final normalized = splits.map((s) => s / total).toList();
  const trendMults = [0.8, 0.9, 1.0, 0.95, 1.1, 1.05];

  return List.generate(platforms.length, (i) => PlatformBreakdown(
    platform: platforms[i],
    share: normalized[i],
    monthly: (monthlyEarnings * normalized[i]).round(),
    trend: trendMults.map((t) => (monthlyEarnings * normalized[i] * t * 0.2).round()).toList(),
  ));
}

int estimateSelfEmploymentTax(int annualIncome) {
  final netEarnings = annualIncome * 0.9235;
  return (netEarnings * 0.153).round();
}

int estimateFederalTax(int annualIncome, FilingStatus filingStatus, bool hasDependents) {
  final standardDeduction = filingStatus == FilingStatus.marriedJoint ? 29200 : filingStatus == FilingStatus.headOfHousehold ? 21900 : 14600;
  final seTaxDeduction = estimateSelfEmploymentTax(annualIncome) * 0.5;
  final dependentCredit = hasDependents ? 2000 : 0;
  final taxableIncome = (annualIncome - standardDeduction - seTaxDeduction).clamp(0, double.infinity);

  double tax = 0;
  if (filingStatus == FilingStatus.marriedJoint) {
    if (taxableIncome <= 23200) { tax = taxableIncome * 0.10; }
    else if (taxableIncome <= 94300) { tax = 2320 + (taxableIncome - 23200) * 0.12; }
    else if (taxableIncome <= 201050) { tax = 10294 + (taxableIncome - 94300) * 0.22; }
    else { tax = 33832 + (taxableIncome - 201050) * 0.24; }
  } else {
    if (taxableIncome <= 11600) { tax = taxableIncome * 0.10; }
    else if (taxableIncome <= 47150) { tax = 1160 + (taxableIncome - 11600) * 0.12; }
    else if (taxableIncome <= 100525) { tax = 5426 + (taxableIncome - 47150) * 0.22; }
    else { tax = 17168 + (taxableIncome - 100525) * 0.24; }
  }
  return (tax - dependentCredit).clamp(0, double.infinity).round();
}

int estimateStateTax(int annualIncome, String state) {
  const rates = {
    'CA': 0.093, 'NY': 0.085, 'TX': 0.0, 'FL': 0.0, 'WA': 0.0, 'NV': 0.0,
    'OR': 0.099, 'MA': 0.05, 'IL': 0.0495, 'PA': 0.0307, 'OH': 0.04,
    'GA': 0.055, 'NC': 0.0525, 'VA': 0.0575, 'CO': 0.044, 'AZ': 0.025,
    'MN': 0.0985, 'WI': 0.0765, 'MO': 0.048, 'IN': 0.0315,
  };
  final rate = rates[state] ?? 0.05;
  return (annualIncome * rate).round();
}

TaxEstimate calculateTaxBreakdown(UserProfile profile) {
  final annual = profile.monthlyEarnings * 12;
  final se = estimateSelfEmploymentTax(annual);
  final federal = estimateFederalTax(annual, profile.filingStatus, profile.hasDependents);
  final state = estimateStateTax(annual, profile.state);
  final total = se + federal + state;
  return TaxEstimate(
    selfEmployment: se,
    federal: federal,
    state: state,
    total: total,
    monthly: (total / 12).round(),
    quarterly: (total / 4).round(),
  );
}

int calculateTaxHealthScore(UserProfile profile) {
  int score = 40;
  if (profile.platforms.isNotEmpty) score += 10;
  if (profile.vehicleType != VehicleType.none) score += 10;
  if (profile.hasHomeOffice) score += 10;
  if (profile.expenses.health > 0) score += 5;
  if (profile.expenses.phone > 0) score += 5;
  if (profile.hasDependents) score += 5;
  if (profile.claudeAnalysis != null) score += 15;
  return score.clamp(0, 100);
}
