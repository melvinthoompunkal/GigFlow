enum Platform { uber, lyft, doordash, instacart, upwork, fiverr, amazonFlex, grubhub, taskrabbit, rover }

enum FilingStatus { single, marriedJoint, marriedSeparate, headOfHousehold }

enum VehicleType { car, suv, truck, motorcycle, bicycle, none }

enum HousingType { own, rent }

class Deduction {
  final String id;
  final String icon;
  final String name;
  final String explanation;
  final int value;
  final String eligibility;
  final String category;

  const Deduction({
    required this.id,
    required this.icon,
    required this.name,
    required this.explanation,
    required this.value,
    required this.eligibility,
    required this.category,
  });

  factory Deduction.fromJson(Map<String, dynamic> j) => Deduction(
        id: j['id'] as String,
        icon: j['icon'] as String,
        name: j['name'] as String,
        explanation: j['explanation'] as String,
        value: (j['value'] as num).toInt(),
        eligibility: j['eligibility'] as String,
        category: j['category'] as String,
      );
}

class TaxEstimate {
  final int selfEmployment;
  final int federal;
  final int state;
  final int total;
  final int monthly;
  final int quarterly;

  const TaxEstimate({
    required this.selfEmployment,
    required this.federal,
    required this.state,
    required this.total,
    required this.monthly,
    required this.quarterly,
  });

  factory TaxEstimate.fromJson(Map<String, dynamic> j) => TaxEstimate(
        selfEmployment: (j['selfEmployment'] as num).toInt(),
        federal: (j['federal'] as num).toInt(),
        state: (j['state'] as num).toInt(),
        total: (j['total'] as num).toInt(),
        monthly: (j['monthly'] as num).toInt(),
        quarterly: (j['quarterly'] as num).toInt(),
      );
}

class RoadmapStep {
  final String id;
  final int step;
  final String title;
  final String description;
  final String deadline;
  final String priority;
  final bool completed;

  const RoadmapStep({
    required this.id,
    required this.step,
    required this.title,
    required this.description,
    required this.deadline,
    required this.priority,
    required this.completed,
  });

  factory RoadmapStep.fromJson(Map<String, dynamic> j) => RoadmapStep(
        id: j['id'] as String,
        step: (j['step'] as num).toInt(),
        title: j['title'] as String,
        description: j['description'] as String,
        deadline: j['deadline'] as String,
        priority: j['priority'] as String,
        completed: j['completed'] as bool? ?? false,
      );
}

class ClaudeAnalysis {
  final List<Deduction> deductions;
  final TaxEstimate taxEstimate;
  final List<RoadmapStep> roadmap;

  const ClaudeAnalysis({
    required this.deductions,
    required this.taxEstimate,
    required this.roadmap,
  });
}

class Expenses {
  final int gas;
  final int phone;
  final int insurance;
  final int equipment;
  final int health;
  final int food;

  const Expenses({
    this.gas = 0,
    this.phone = 0,
    this.insurance = 0,
    this.equipment = 0,
    this.health = 0,
    this.food = 0,
  });

  Expenses copyWith({int? gas, int? phone, int? insurance, int? equipment, int? health, int? food}) {
    return Expenses(
      gas: gas ?? this.gas,
      phone: phone ?? this.phone,
      insurance: insurance ?? this.insurance,
      equipment: equipment ?? this.equipment,
      health: health ?? this.health,
      food: food ?? this.food,
    );
  }
}

class UserProfile {
  final List<Platform> platforms;
  final List<String> customPlatforms;
  /// Maps Platform.name (e.g. 'uber') → monthly earnings in dollars.
  final Map<String, int> platformEarnings;
  /// Computed from platformEarnings; stored separately for CSV/demo paths.
  final int monthlyEarnings;
  final FilingStatus filingStatus;
  final int dependentCount;
  final String state;
  final HousingType housingType;
  /// Monthly rent or mortgage payment. Used for home office deduction.
  final int monthlyRent;
  final bool hasHomeOffice;
  final VehicleType vehicleType;
  final Expenses expenses;
  final ClaudeAnalysis? claudeAnalysis;
  final bool isOnboarded;
  final bool isDemoMode;
  final bool isBankConnected;

  bool get hasDependents => dependentCount > 0;

  const UserProfile({
    this.platforms = const [],
    this.customPlatforms = const [],
    this.platformEarnings = const {},
    this.monthlyEarnings = 0,
    this.filingStatus = FilingStatus.single,
    this.dependentCount = 0,
    this.state = '',
    this.housingType = HousingType.rent,
    this.monthlyRent = 0,
    this.hasHomeOffice = false,
    this.vehicleType = VehicleType.car,
    this.expenses = const Expenses(),
    this.claudeAnalysis,
    this.isOnboarded = false,
    this.isDemoMode = false,
    this.isBankConnected = false,
  });

  UserProfile copyWith({
    List<Platform>? platforms,
    List<String>? customPlatforms,
    Map<String, int>? platformEarnings,
    int? monthlyEarnings,
    FilingStatus? filingStatus,
    int? dependentCount,
    String? state,
    HousingType? housingType,
    int? monthlyRent,
    bool? hasHomeOffice,
    VehicleType? vehicleType,
    Expenses? expenses,
    ClaudeAnalysis? claudeAnalysis,
    bool? isOnboarded,
    bool? isDemoMode,
    bool? isBankConnected,
  }) {
    return UserProfile(
      platforms: platforms ?? this.platforms,
      customPlatforms: customPlatforms ?? this.customPlatforms,
      platformEarnings: platformEarnings ?? this.platformEarnings,
      monthlyEarnings: monthlyEarnings ?? this.monthlyEarnings,
      filingStatus: filingStatus ?? this.filingStatus,
      dependentCount: dependentCount ?? this.dependentCount,
      state: state ?? this.state,
      housingType: housingType ?? this.housingType,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      hasHomeOffice: hasHomeOffice ?? this.hasHomeOffice,
      vehicleType: vehicleType ?? this.vehicleType,
      expenses: expenses ?? this.expenses,
      claudeAnalysis: claudeAnalysis ?? this.claudeAnalysis,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      isBankConnected: isBankConnected ?? this.isBankConnected,
    );
  }
}
