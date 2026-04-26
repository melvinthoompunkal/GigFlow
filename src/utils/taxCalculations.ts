import type { UserProfile } from '../context/UserProfileContext';

export function calculateYTDEarnings(monthlyEarnings: number): number {
  // Backend integration point: Replace with actual platform earnings API data
  const currentMonth = new Date().getMonth(); // 0-indexed
  const monthsElapsed = currentMonth + 1;
  const variance = 0.85 + Math.random() * 0.3;
  return Math.round(monthlyEarnings * monthsElapsed * variance);
}

export function generateMonthlyData(monthlyEarnings: number) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const currentMonth = new Date().getMonth();
  const variances = [0.82, 0.91, 0.88, 0.95, 1.04, 1.12, 1.08, 0.97, 1.15, 1.03, 0.94, 1.20];
  
  return months.map((month, i) => ({
    month,
    earnings: i <= currentMonth ? Math.round(monthlyEarnings * variances[i]) : 0,
    projected: i > currentMonth ? Math.round(monthlyEarnings * variances[i]) : 0,
  }));
}

export function estimateSelfEmploymentTax(annualIncome: number): number {
  const netEarnings = annualIncome * 0.9235;
  return Math.round(netEarnings * 0.153);
}

export function estimateFederalTax(annualIncome: number, filingStatus: string, hasDependents: boolean): number {
  const standardDeduction = filingStatus === 'married_joint' ? 29200 : filingStatus === 'head_of_household' ? 21900 : 14600;
  const seTaxDeduction = estimateSelfEmploymentTax(annualIncome) * 0.5;
  const dependentCredit = hasDependents ? 2000 : 0;
  const taxableIncome = Math.max(0, annualIncome - standardDeduction - seTaxDeduction);
  
  let tax = 0;
  if (filingStatus === 'married_joint') {
    if (taxableIncome <= 23200) tax = taxableIncome * 0.10;
    else if (taxableIncome <= 94300) tax = 2320 + (taxableIncome - 23200) * 0.12;
    else if (taxableIncome <= 201050) tax = 10294 + (taxableIncome - 94300) * 0.22;
    else tax = 33832 + (taxableIncome - 201050) * 0.24;
  } else {
    if (taxableIncome <= 11600) tax = taxableIncome * 0.10;
    else if (taxableIncome <= 47150) tax = 1160 + (taxableIncome - 11600) * 0.12;
    else if (taxableIncome <= 100525) tax = 5426 + (taxableIncome - 47150) * 0.22;
    else tax = 17168 + (taxableIncome - 100525) * 0.24;
  }
  
  return Math.max(0, Math.round(tax - dependentCredit));
}

export function estimateStateTax(annualIncome: number, state: string): number {
  const stateRates: Record<string, number> = {
    CA: 0.093, NY: 0.085, TX: 0, FL: 0, WA: 0, NV: 0, OR: 0.099, MA: 0.05,
    IL: 0.0495, PA: 0.0307, OH: 0.04, GA: 0.055, NC: 0.0525, VA: 0.0575,
    CO: 0.044, AZ: 0.025, MN: 0.0985, WI: 0.0765, MO: 0.048, IN: 0.0315,
  };
  const rate = stateRates[state] ?? 0.05;
  return Math.round(annualIncome * rate);
}

export function calculateTaxBreakdown(profile: UserProfile) {
  const annual = profile.monthlyEarnings * 12;
  const se = estimateSelfEmploymentTax(annual);
  const federal = estimateFederalTax(annual, profile.filingStatus, profile.hasDependents);
  const state = estimateStateTax(annual, profile.state);
  const total = se + federal + state;
  return {
    selfEmployment: se,
    federal,
    state,
    total,
    monthly: Math.round(total / 12),
    quarterly: Math.round(total / 4),
  };
}

export function calculateTaxHealthScore(profile: UserProfile): number {
  let score = 40;
  if (profile.platforms.length > 0) score += 10;
  if (profile.vehicleType !== 'none') score += 10;
  if (profile.hasHomeOffice) score += 10;
  if (profile.expenses.health > 0) score += 5;
  if (profile.expenses.phone > 0) score += 5;
  if (profile.hasDependents) score += 5;
  if (profile.claudeAnalysis) score += 15;
  return Math.min(score, 100);
}

export function generatePlatformBreakdown(platforms: string[], monthlyEarnings: number) {
  if (platforms.length === 0) return [];
  const splits = platforms.map((_, i) => {
    const base = 1 / platforms.length;
    const jitter = (i % 2 === 0 ? 0.15 : -0.1);
    return Math.max(0.05, base + jitter / platforms.length);
  });
  const total = splits.reduce((a, b) => a + b, 0);
  const normalized = splits.map(s => s / total);
  
  return platforms.map((platform, i) => ({
    platform,
    share: normalized[i],
    monthly: Math.round(monthlyEarnings * normalized[i]),
    trend: [0.8, 0.9, 1.0, 0.95, 1.1, 1.05].map(t => Math.round(monthlyEarnings * normalized[i] * t * 0.2)),
  }));
}