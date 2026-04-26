import '../models/user_profile.dart';

class PlatformConfig {
  final String label;
  final String emoji;
  final String logoUrl;
  const PlatformConfig({required this.label, required this.emoji, required this.logoUrl});
}

const Map<Platform, PlatformConfig> kPlatformConfig = {
  Platform.uber:        PlatformConfig(label: 'Uber',         emoji: '🚗', logoUrl: 'https://logo.clearbit.com/uber.com'),
  Platform.lyft:        PlatformConfig(label: 'Lyft',         emoji: '🩷', logoUrl: 'https://logo.clearbit.com/lyft.com'),
  Platform.doordash:    PlatformConfig(label: 'DoorDash',     emoji: '🍕', logoUrl: 'https://logo.clearbit.com/doordash.com'),
  Platform.instacart:   PlatformConfig(label: 'Instacart',    emoji: '🛒', logoUrl: 'https://logo.clearbit.com/instacart.com'),
  Platform.upwork:      PlatformConfig(label: 'Upwork',       emoji: '💻', logoUrl: 'https://logo.clearbit.com/upwork.com'),
  Platform.fiverr:      PlatformConfig(label: 'Fiverr',       emoji: '🎨', logoUrl: 'https://logo.clearbit.com/fiverr.com'),
  Platform.amazonFlex:  PlatformConfig(label: 'Amazon Flex',  emoji: '📦', logoUrl: 'https://logo.clearbit.com/amazon.com'),
  Platform.grubhub:     PlatformConfig(label: 'Grubhub',      emoji: '🥡', logoUrl: 'https://logo.clearbit.com/grubhub.com'),
  Platform.taskrabbit:  PlatformConfig(label: 'TaskRabbit',   emoji: '🔧', logoUrl: 'https://logo.clearbit.com/taskrabbit.com'),
  Platform.rover:       PlatformConfig(label: 'Rover',        emoji: '🐾', logoUrl: 'https://logo.clearbit.com/rover.com'),
};

class VehicleConfig {
  final String label;
  final String emoji;
  final double mileageRate;
  const VehicleConfig({required this.label, required this.emoji, required this.mileageRate});
}

const Map<VehicleType, VehicleConfig> kVehicleConfig = {
  VehicleType.car:        VehicleConfig(label: 'Car',        emoji: '🚗', mileageRate: 0.67),
  VehicleType.suv:        VehicleConfig(label: 'SUV',        emoji: '🚙', mileageRate: 0.67),
  VehicleType.truck:      VehicleConfig(label: 'Truck',      emoji: '🛻', mileageRate: 0.67),
  VehicleType.motorcycle: VehicleConfig(label: 'Motorcycle', emoji: '🏍️', mileageRate: 0.21),
  VehicleType.bicycle:    VehicleConfig(label: 'Bicycle',    emoji: '🚲', mileageRate: 0.0),
  VehicleType.none:       VehicleConfig(label: 'No Vehicle', emoji: '🚶', mileageRate: 0.0),
};

const List<Map<String, String>> kUsStates = [
  {'code': 'AL', 'name': 'Alabama'}, {'code': 'AK', 'name': 'Alaska'}, {'code': 'AZ', 'name': 'Arizona'},
  {'code': 'AR', 'name': 'Arkansas'}, {'code': 'CA', 'name': 'California'}, {'code': 'CO', 'name': 'Colorado'},
  {'code': 'CT', 'name': 'Connecticut'}, {'code': 'DE', 'name': 'Delaware'}, {'code': 'FL', 'name': 'Florida'},
  {'code': 'GA', 'name': 'Georgia'}, {'code': 'HI', 'name': 'Hawaii'}, {'code': 'ID', 'name': 'Idaho'},
  {'code': 'IL', 'name': 'Illinois'}, {'code': 'IN', 'name': 'Indiana'}, {'code': 'IA', 'name': 'Iowa'},
  {'code': 'KS', 'name': 'Kansas'}, {'code': 'KY', 'name': 'Kentucky'}, {'code': 'LA', 'name': 'Louisiana'},
  {'code': 'ME', 'name': 'Maine'}, {'code': 'MD', 'name': 'Maryland'}, {'code': 'MA', 'name': 'Massachusetts'},
  {'code': 'MI', 'name': 'Michigan'}, {'code': 'MN', 'name': 'Minnesota'}, {'code': 'MS', 'name': 'Mississippi'},
  {'code': 'MO', 'name': 'Missouri'}, {'code': 'MT', 'name': 'Montana'}, {'code': 'NE', 'name': 'Nebraska'},
  {'code': 'NV', 'name': 'Nevada'}, {'code': 'NH', 'name': 'New Hampshire'}, {'code': 'NJ', 'name': 'New Jersey'},
  {'code': 'NM', 'name': 'New Mexico'}, {'code': 'NY', 'name': 'New York'}, {'code': 'NC', 'name': 'North Carolina'},
  {'code': 'ND', 'name': 'North Dakota'}, {'code': 'OH', 'name': 'Ohio'}, {'code': 'OK', 'name': 'Oklahoma'},
  {'code': 'OR', 'name': 'Oregon'}, {'code': 'PA', 'name': 'Pennsylvania'}, {'code': 'RI', 'name': 'Rhode Island'},
  {'code': 'SC', 'name': 'South Carolina'}, {'code': 'SD', 'name': 'South Dakota'}, {'code': 'TN', 'name': 'Tennessee'},
  {'code': 'TX', 'name': 'Texas'}, {'code': 'UT', 'name': 'Utah'}, {'code': 'VT', 'name': 'Vermont'},
  {'code': 'VA', 'name': 'Virginia'}, {'code': 'WA', 'name': 'Washington'}, {'code': 'WV', 'name': 'West Virginia'},
  {'code': 'WI', 'name': 'Wisconsin'}, {'code': 'WY', 'name': 'Wyoming'},
];

class EarningsOption {
  final String label;
  final int value;
  final String sublabel;
  const EarningsOption({required this.label, required this.value, required this.sublabel});
}

const List<EarningsOption> kEarningsOptions = [
  EarningsOption(label: 'Under \$1,500', value: 1250, sublabel: 'Part-time hustle'),
  EarningsOption(label: '\$1,500 – \$3,000', value: 2250, sublabel: 'Side income'),
  EarningsOption(label: '\$3,000 – \$5,000', value: 4000, sublabel: 'Primary income'),
  EarningsOption(label: '\$5,000 – \$8,000', value: 6500, sublabel: 'Full-time gig'),
  EarningsOption(label: '\$8,000+', value: 9000, sublabel: 'Power earner'),
];

class FilingStatusOption {
  final FilingStatus value;
  final String label;
  final String description;
  const FilingStatusOption({required this.value, required this.label, required this.description});
}

const List<FilingStatusOption> kFilingStatusOptions = [
  FilingStatusOption(value: FilingStatus.single, label: 'Single', description: 'Not married, no qualifying dependents'),
  FilingStatusOption(value: FilingStatus.marriedJoint, label: 'Married Filing Jointly', description: 'Married, filing with spouse'),
  FilingStatusOption(value: FilingStatus.marriedSeparate, label: 'Married Filing Separately', description: 'Married, filing independently'),
  FilingStatusOption(value: FilingStatus.headOfHousehold, label: 'Head of Household', description: 'Unmarried with qualifying dependents'),
];

class QuarterDeadline {
  final String quarter;
  final String label;
  final String deadline;
  final String status;
  const QuarterDeadline({required this.quarter, required this.label, required this.deadline, required this.status});
}

const List<QuarterDeadline> kQuarterlyDeadlines = [
  QuarterDeadline(quarter: 'Q1', label: 'Jan 1 – Mar 31', deadline: 'Apr 15, 2025', status: 'paid'),
  QuarterDeadline(quarter: 'Q2', label: 'Apr 1 – May 31', deadline: 'Jun 17, 2025', status: 'upcoming'),
  QuarterDeadline(quarter: 'Q3', label: 'Jun 1 – Aug 31', deadline: 'Sep 16, 2025', status: 'future'),
  QuarterDeadline(quarter: 'Q4', label: 'Sep 1 – Dec 31', deadline: 'Jan 15, 2026', status: 'future'),
];
