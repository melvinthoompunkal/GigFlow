import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

const _fallbackDeductions = [
  Deduction(id: 'ded-mileage', icon: '🚗', name: 'Standard Mileage Deduction', explanation: 'Deduct 67¢ per mile driven for gig work in 2024. Based on your vehicle type and estimated annual mileage.', value: 3685, eligibility: 'high', category: 'Vehicle'),
  Deduction(id: 'ded-phone', icon: '📱', name: 'Phone & Data Plan', explanation: 'Business-use portion of your phone bill. Gig apps require a phone — typically 80-90% deductible.', value: 540, eligibility: 'high', category: 'Technology'),
  Deduction(id: 'ded-se-tax', icon: '🏛️', name: 'Self-Employment Tax Deduction', explanation: 'Deduct 50% of your SE tax from gross income. This reduces your adjusted gross income automatically.', value: 1834, eligibility: 'high', category: 'Tax'),
  Deduction(id: 'ded-qbi', icon: '💼', name: 'Qualified Business Income (QBI)', explanation: 'Deduct up to 20% of qualified business income under Section 199A. Significant savings for sole proprietors.', value: 2160, eligibility: 'medium', category: 'Business'),
  Deduction(id: 'ded-health', icon: '🏥', name: 'Self-Employed Health Insurance', explanation: 'Deduct 100% of health insurance premiums if you are not eligible for employer coverage.', value: 1800, eligibility: 'medium', category: 'Health'),
  Deduction(id: 'ded-sep-ira', icon: '🏦', name: 'SEP-IRA Contribution', explanation: 'Contribute up to 25% of net self-employment income to a SEP-IRA and deduct the full amount.', value: 3600, eligibility: 'medium', category: 'Retirement'),
];

const _fallbackTaxEstimate = TaxEstimate(
  selfEmployment: 6786,
  federal: 3240,
  state: 1296,
  total: 11322,
  monthly: 944,
  quarterly: 2830,
);

const _fallbackRoadmap = [
  RoadmapStep(id: 'rm-1', step: 1, title: 'Open a dedicated business checking account', description: 'Separate your gig income from personal funds. Makes bookkeeping 10x easier and strengthens deduction claims.', deadline: 'This week', priority: 'high', completed: false),
  RoadmapStep(id: 'rm-2', step: 2, title: 'Set up automatic tax savings transfer', description: 'Auto-transfer 25% of every deposit to a high-yield savings account earmarked for quarterly taxes.', deadline: 'Within 2 weeks', priority: 'high', completed: false),
  RoadmapStep(id: 'rm-3', step: 3, title: 'Start tracking mileage with an app', description: 'Use MileIQ or Everlance to auto-track every business mile. This deduction alone saves you \$3,685.', deadline: 'Within 30 days', priority: 'medium', completed: false),
  RoadmapStep(id: 'rm-4', step: 4, title: 'File Q2 estimated taxes', description: 'Pay your Q2 estimated taxes by June 17, 2025 to avoid underpayment penalties. Amount: \$2,830.', deadline: 'Jun 17, 2025', priority: 'high', completed: false),
];

const _fallbackAnalysis = ClaudeAnalysis(
  deductions: _fallbackDeductions,
  taxEstimate: _fallbackTaxEstimate,
  roadmap: _fallbackRoadmap,
);

const _demoProfile = UserProfile(
  platforms: [Platform.uber, Platform.doordash, Platform.lyft],
  monthlyEarnings: 4200,
  filingStatus: FilingStatus.single,
  hasDependents: false,
  state: 'CA',
  housingType: HousingType.rent,
  hasHomeOffice: true,
  vehicleType: VehicleType.car,
  expenses: Expenses(gas: 280, phone: 65, insurance: 150, equipment: 40, health: 180),
  isOnboarded: true,
  isDemoMode: true,
  claudeAnalysis: _fallbackAnalysis,
);

class UserProfileProvider extends ChangeNotifier {
  UserProfile _profile = const UserProfile();

  UserProfile get profile => _profile;
  ClaudeAnalysis get fallbackAnalysis => _fallbackAnalysis;

  void update(UserProfile Function(UserProfile) updater) {
    _profile = updater(_profile);
    notifyListeners();
  }

  void setAnalysis(ClaudeAnalysis? analysis) {
    _profile = _profile.copyWith(claudeAnalysis: analysis ?? _fallbackAnalysis);
    notifyListeners();
  }

  void activateDemoMode() {
    _profile = _demoProfile;
    notifyListeners();
  }

  void reset() {
    _profile = const UserProfile();
    notifyListeners();
  }
}
