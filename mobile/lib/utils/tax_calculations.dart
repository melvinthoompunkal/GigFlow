import '../models/user_profile.dart';

class MonthlyDataPoint {
  final String month;
  final int earnings;
  final int projected;
  const MonthlyDataPoint({required this.month, required this.earnings, required this.projected});
}

class PlatformBreakdown {
  final Platform? platform;
  final String? customName;
  final double share;
  final int monthly;
  final List<int> trend;
  const PlatformBreakdown({this.platform, this.customName, required this.share, required this.monthly, required this.trend});
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

List<PlatformBreakdown> generatePlatformBreakdown(UserProfile profile) {
  final platforms = profile.platforms;
  final customPlatforms = profile.customPlatforms;
  if (platforms.isEmpty && customPlatforms.isEmpty) return [];
  final total = profile.monthlyEarnings;
  const trendMults = [0.8, 0.9, 1.0, 0.95, 1.1, 1.05];

  if (profile.platformEarnings.isNotEmpty) {
    final grandTotal = profile.platformEarnings.values.fold(0, (s, v) => s + v);
    if (grandTotal == 0) return [];

    final standard = platforms
        .map((p) {
          final monthly = profile.platformEarnings[p.name.toLowerCase()] ?? 0;
          if (monthly == 0) return null;
          return PlatformBreakdown(
            platform: p,
            share: monthly / grandTotal,
            monthly: monthly,
            trend: trendMults.map((t) => (monthly * t * 0.2).round()).toList(),
          );
        })
        .whereType<PlatformBreakdown>();

    final custom = customPlatforms
        .map((name) {
          final monthly = profile.platformEarnings[name.toLowerCase()] ?? 0;
          if (monthly == 0) return null;
          return PlatformBreakdown(
            customName: name,
            share: monthly / grandTotal,
            monthly: monthly,
            trend: trendMults.map((t) => (monthly * t * 0.2).round()).toList(),
          );
        })
        .whereType<PlatformBreakdown>();

    return [...standard, ...custom];
  }

  final allCount = platforms.length + customPlatforms.length;
  if (allCount == 0 || total == 0) return [];
  final splits = List.generate(allCount, (i) {
    final base = 1.0 / allCount;
    final jitter = (i % 2 == 0 ? 0.15 : -0.1);
    return (base + jitter / allCount).clamp(0.05, 1.0);
  });
  final splitTotal = splits.reduce((a, b) => a + b);
  final normalized = splits.map((s) => s / splitTotal).toList();

  return [
    ...List.generate(platforms.length, (i) => PlatformBreakdown(
      platform: platforms[i],
      share: normalized[i],
      monthly: (total * normalized[i]).round(),
      trend: trendMults.map((t) => (total * normalized[i] * t * 0.2).round()).toList(),
    )),
    ...List.generate(customPlatforms.length, (i) {
      final j = platforms.length + i;
      return PlatformBreakdown(
        customName: customPlatforms[i],
        share: normalized[j],
        monthly: (total * normalized[j]).round(),
        trend: trendMults.map((t) => (total * normalized[j] * t * 0.2).round()).toList(),
      );
    }),
  ];
}

int _progressive(int income, List<(double, double)> brackets) {
  double tax = 0;
  double prev = 0;
  for (final (limit, rate) in brackets) {
    if (income <= prev) break;
    final top = limit == double.infinity ? income.toDouble() : limit;
    final slice = (income < top ? income.toDouble() : top) - prev;
    tax += slice * rate;
    if (income <= limit) break;
    prev = limit;
  }
  return tax.round();
}

int estimateStateTax(int annualIncome, String state) {
  const noTax = {'TX', 'FL', 'WA', 'NV', 'WY', 'SD', 'AK', 'TN', 'NH'};
  if (noTax.contains(state)) return 0;

  switch (state) {
    case 'CA':
      return _progressive(annualIncome, [
        (10412,  0.01), (24684,  0.02), (38959,  0.04),
        (54081,  0.06), (68350,  0.08), (349137, 0.093),
        (418961, 0.103),(698274, 0.113),(double.infinity, 0.123),
      ]);
    case 'NY':
      return _progressive(annualIncome, [
        (17150,  0.040), (23600,  0.045), (27900,  0.0525),
        (161550, 0.0585),(323200, 0.0625),(2155350, 0.0685),
        (double.infinity, 0.109),
      ]);
    case 'OR':
      return _progressive(annualIncome, [
        (17400, 0.0475),(43750, 0.0675),
        (250000, 0.0875),(double.infinity, 0.099),
      ]);
    case 'MN':
      return _progressive(annualIncome, [
        (31690,  0.0535),(104090, 0.068),
        (193240, 0.0785),(double.infinity, 0.0985),
      ]);
    case 'WI':
      return _progressive(annualIncome, [
        (13810,  0.0354),(27630,  0.0465),
        (304170, 0.053),(double.infinity, 0.0765),
      ]);
    case 'NJ':
      return _progressive(annualIncome, [
        (20000,  0.014),(35000,  0.0175),(40000,  0.035),
        (75000,  0.05525),(500000, 0.0637),(double.infinity, 0.1075),
      ]);
    case 'VA':
      return _progressive(annualIncome, [
        (3000,  0.02),(5000,  0.03),
        (17000, 0.05),(double.infinity, 0.0575),
      ]);
    case 'MD':
      return _progressive(annualIncome, [
        (1000,   0.02),(2000,   0.03),(3000,   0.04),
        (100000, 0.0475),(125000, 0.05),(150000, 0.0525),
        (250000, 0.055),(double.infinity, 0.0575),
      ]);
    case 'CT':
      return _progressive(annualIncome, [
        (10000,  0.02),(50000,  0.045),(100000, 0.055),
        (200000, 0.06),(250000, 0.065),(double.infinity, 0.0699),
      ]);
    case 'HI':
      return _progressive(annualIncome, [
        (9600,  0.014),(19200, 0.032),(28800, 0.055),
        (38400, 0.064),(48000, 0.068),(150000, 0.072),
        (175000, 0.076),(200000, 0.079),(double.infinity, 0.11),
      ]);
    case 'OH':
      return _progressive(annualIncome, [
        (26050, 0.0),(100000, 0.02765),(double.infinity, 0.0399),
      ]);
    case 'MA': return (annualIncome * 0.05).round();
    case 'IL': return (annualIncome * 0.0495).round();
    case 'PA': return (annualIncome * 0.0307).round();
    case 'CO': return (annualIncome * 0.044).round();
    case 'AZ': return (annualIncome * 0.025).round();
    case 'GA': return (annualIncome * 0.0549).round();
    case 'NC': return (annualIncome * 0.0475).round();
    case 'IN': return (annualIncome * 0.0305).round();
    case 'MI': return (annualIncome * 0.0425).round();
    case 'MO': return (annualIncome * 0.0495).round();
    case 'SC': return (annualIncome * 0.064).round();
    case 'AL': return (annualIncome * 0.05).round();
    case 'KY': return (annualIncome * 0.045).round();
    case 'LA': return (annualIncome * 0.0425).round();
    case 'MS': return (annualIncome * 0.05).round();
    case 'ID': return (annualIncome * 0.058).round();
    case 'UT': return (annualIncome * 0.0485).round();
    case 'NM': return (annualIncome * 0.059).round();
    case 'KS': return (annualIncome * 0.057).round();
    case 'IA': return (annualIncome * 0.06).round();
    case 'NE': return (annualIncome * 0.0664).round();
    case 'AR': return (annualIncome * 0.0475).round();
    case 'OK': return (annualIncome * 0.0475).round();
    case 'DE': return (annualIncome * 0.066).round();
    case 'RI': return (annualIncome * 0.0599).round();
    case 'VT': return (annualIncome * 0.0875).round();
    case 'ME': return (annualIncome * 0.0715).round();
    case 'ND': return (annualIncome * 0.025).round();
    case 'MT': return (annualIncome * 0.0675).round();
    case 'WV': return (annualIncome * 0.065).round();
    default:   return (annualIncome * 0.05).round();
  }
}

int estimateSelfEmploymentTax(int annualIncome) {
  final netEarnings = annualIncome * 0.9235;
  return (netEarnings * 0.153).round();
}

int estimateFederalTax(int annualIncome, FilingStatus filingStatus, int dependentCount) {
  final standardDeduction = filingStatus == FilingStatus.marriedJoint
      ? 29200
      : filingStatus == FilingStatus.headOfHousehold
          ? 21900
          : 14600;
  final seTaxDeduction = estimateSelfEmploymentTax(annualIncome) * 0.5;
  final taxableIncome = (annualIncome - standardDeduction - seTaxDeduction).clamp(0, double.infinity).toInt();

  int tax;
  if (filingStatus == FilingStatus.marriedJoint) {
    tax = _progressive(taxableIncome, [
      (23200,  0.10),
      (94300,  0.12),
      (201050, 0.22),
      (383900, 0.24),
      (487450, 0.32),
      (731200, 0.35),
      (double.infinity, 0.37),
    ]);
  } else if (filingStatus == FilingStatus.headOfHousehold) {
    tax = _progressive(taxableIncome, [
      (16550,  0.10),
      (63100,  0.12),
      (100500, 0.22),
      (191950, 0.24),
      (243700, 0.32),
      (609350, 0.35),
      (double.infinity, 0.37),
    ]);
  } else if (filingStatus == FilingStatus.marriedSeparate) {
    tax = _progressive(taxableIncome, [
      (11600,  0.10),
      (47150,  0.12),
      (100525, 0.22),
      (191950, 0.24),
      (243725, 0.32),
      (609350, 0.35),
      (double.infinity, 0.37),
    ]);
  } else {
    // FilingStatus.single
    tax = _progressive(taxableIncome, [
      (11600,  0.10),
      (47150,  0.12),
      (100525, 0.22),
      (191950, 0.24),
      (243725, 0.32),
      (609350, 0.35),
      (double.infinity, 0.37),
    ]);
  }

  final credit = dependentCount * 2000;
  return (tax - credit).clamp(0, double.infinity).round();
}

TaxEstimate calculateTaxBreakdown(UserProfile profile) {
  final annual = profile.monthlyEarnings * 12;
  final se = estimateSelfEmploymentTax(annual);
  final federal = estimateFederalTax(annual, profile.filingStatus, profile.dependentCount);
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
  if (profile.hasHomeOffice && profile.monthlyRent > 0) score += 5;
  if (profile.expenses.health > 0) score += 5;
  if (profile.expenses.phone > 0) score += 5;
  if (profile.dependentCount > 0) score += 5;
  if (profile.claudeAnalysis != null) score += 10;
  return score.clamp(0, 100);
}

const _drivingPlatforms = {
  'uber', 'lyft', 'doordash', 'grubhub', 'instacart', 'amazonflex', 'taskrabbit', 'rover',
};

List<Deduction> calculateDeductions(UserProfile profile) {
  final annualGross = profile.platformEarnings.isNotEmpty
      ? profile.platformEarnings.values.fold<int>(0, (s, v) => s + v) * 12
      : profile.monthlyEarnings * 12;

  final hasDrivingPlatform = profile.platforms.any(
    (p) => _drivingPlatforms.contains(p.name.toLowerCase()),
  );

  final mileageRate = switch (profile.vehicleType) {
    VehicleType.car || VehicleType.suv || VehicleType.truck => 0.67,
    VehicleType.motorcycle => 0.21,
    VehicleType.bicycle || VehicleType.none => 0.0,
  };

  final seTax = estimateSelfEmploymentTax(annualGross);
  final seDeduction = (seTax * 0.5).round();
  final netQBI = (annualGross - seDeduction).clamp(0, 999999999);
  final qbi = (netQBI * 0.20).round();

  final result = <Deduction>[];

  if (hasDrivingPlatform && mileageRate > 0) {
    final value = (annualGross * 0.4 * mileageRate).round();
    if (value > 0) {
      result.add(Deduction(
        id: 'mileage',
        icon: '🚗',
        name: 'Standard Mileage',
        explanation: '${(mileageRate * 100).toStringAsFixed(0)}¢/mile for estimated business driving.',
        value: value,
        eligibility: 'Eligible — ${profile.vehicleType.name} used for gig work',
        category: 'vehicle',
      ));
    }
  }

  if ((!hasDrivingPlatform || mileageRate == 0) && profile.expenses.gas > 0) {
    result.add(Deduction(
      id: 'gas',
      icon: '⛽',
      name: 'Vehicle Fuel',
      explanation: 'Deduct actual gas costs when mileage rate does not apply.',
      value: profile.expenses.gas * 12,
      eligibility: 'Eligible — actual expense method',
      category: 'vehicle',
    ));
  }

  if (profile.expenses.phone > 0) {
    result.add(Deduction(
      id: 'phone',
      icon: '📱',
      name: 'Phone & Data',
      explanation: '85% of your monthly phone bill deducted as a business expense.',
      value: (profile.expenses.phone * 0.85 * 12).round(),
      eligibility: 'Eligible — business-use portion',
      category: 'business',
    ));
  }

  if (seDeduction > 0) {
    result.add(Deduction(
      id: 'se_tax',
      icon: '💼',
      name: 'SE Tax Deduction',
      explanation: 'Deduct half of self-employment tax from your gross income.',
      value: seDeduction,
      eligibility: 'Eligible — all self-employed workers qualify',
      category: 'tax',
    ));
  }

  if (profile.hasHomeOffice && profile.monthlyRent > 0) {
    result.add(Deduction(
      id: 'home_office',
      icon: '🏠',
      name: 'Home Office',
      explanation: '~12% of rent/mortgage for a dedicated workspace.',
      value: (profile.monthlyRent * 0.12 * 12).round(),
      eligibility: 'Eligible — dedicated home office space',
      category: 'housing',
    ));
  }

  if (qbi > 0) {
    result.add(Deduction(
      id: 'qbi',
      icon: '📊',
      name: 'QBI Deduction',
      explanation: '20% of qualified business income under Section 199A.',
      value: qbi,
      eligibility: 'Eligible — gig income qualifies as QBI',
      category: 'tax',
    ));
  }

  if (profile.expenses.health > 0) {
    result.add(Deduction(
      id: 'health',
      icon: '🏥',
      name: 'Health Insurance',
      explanation: '100% of self-paid health insurance premiums are deductible.',
      value: profile.expenses.health * 12,
      eligibility: 'Eligible — self-employed health insurance deduction',
      category: 'health',
    ));
  }

  if (profile.expenses.equipment > 0) {
    result.add(Deduction(
      id: 'equipment',
      icon: '🔧',
      name: 'Equipment & Supplies',
      explanation: 'Deduct business equipment costs under Section 179.',
      value: profile.expenses.equipment * 12,
      eligibility: 'Eligible — business-use equipment',
      category: 'business',
    ));
  }

  if (annualGross > 0) {
    final sepValue = (netQBI * 0.25).round().clamp(0, 66000);
    if (sepValue > 0) {
      result.add(Deduction(
        id: 'sep_ira',
        icon: '🏦',
        name: 'SEP-IRA Contribution',
        explanation: r'Contribute up to 25% of net earnings (max $66,000) to a SEP-IRA.',
        value: sepValue,
        eligibility: 'Eligible — available to all self-employed workers',
        category: 'retirement',
      ));
    }
  }

  return result;
}
