import 'dart:async';
import '../models/user_profile.dart';
import 'backend_api.dart';

Map<String, dynamic> _profileToJson(UserProfile profile) {
  return {
    'platforms': [
      ...profile.platforms.map((p) => p.name),
      ...profile.customPlatforms,
    ],
    'monthlyEarnings': profile.monthlyEarnings,
    'filingStatus': profile.filingStatus.name,
    'platformEarnings': profile.platformEarnings,
    'dependentCount': profile.dependentCount,
    'monthlyRent': profile.monthlyRent,
    'state': profile.state,
    'housingType': profile.housingType.name,
    'hasHomeOffice': profile.hasHomeOffice,
    'vehicleType': profile.vehicleType.name,
    'expenses': {
      'gas': profile.expenses.gas,
      'phone': profile.expenses.phone,
      'insurance': profile.expenses.insurance,
      'equipment': profile.expenses.equipment,
      'health': profile.expenses.health,
    },
  };
}

Future<ClaudeAnalysis?> fetchGigAnalysis(UserProfile profile) async {
  try {
    final data = await analyzeFinances(_profileToJson(profile));
    if (data == null) return null;

    return ClaudeAnalysis(
      deductions: (data['deductions'] as List).map((d) => Deduction.fromJson(d)).toList(),
      taxEstimate: TaxEstimate.fromJson(data['taxEstimate']),
      roadmap: (data['roadmap'] as List).map((r) => RoadmapStep.fromJson(r)).toList(),
    );
  } catch (_) {
    return null;
  }
}

Stream<String> streamChatMessage(List<Map<String, String>> messages, UserProfile profile) async* {
  try {
    final reply = await sendChatMessage(messages, _profileToJson(profile));
    final text = reply ?? "I'm having trouble connecting right now. Please try again in a moment.";
    // Yield word by word for the streaming typing effect
    final words = text.split(' ');
    for (var i = 0; i < words.length; i++) {
      yield i == 0 ? words[i] : ' ${words[i]}';
      await Future.delayed(const Duration(milliseconds: 18));
    }
  } catch (_) {
    yield "I'm having trouble connecting right now. Please try again in a moment.";
  }
}
