import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../utils/constants.dart';
import '../providers/user_profile_provider.dart';

const _apiUrl = 'https://api.anthropic.com/v1/messages';
const _model = 'claude-sonnet-4-20250514';

String _apiKey() => const String.fromEnvironment('ANTHROPIC_API_KEY');

String _buildSystemPrompt(UserProfile profile) {
  final platformNames = profile.platforms.map((p) => kPlatformConfig[p]?.label ?? p.name).join(', ');
  return '''You are GigFlow AI, a specialized financial advisor for gig economy workers.
You are analyzing the profile of a gig worker with the following details:
- Platforms: $platformNames
- Monthly earnings: \$${profile.monthlyEarnings}
- Annual estimated: \$${profile.monthlyEarnings * 12}
- Filing status: ${profile.filingStatus.name}
- Has dependents: ${profile.hasDependents}
- State: ${profile.state}
- Housing: ${profile.housingType.name}
- Home office: ${profile.hasHomeOffice}
- Vehicle: ${profile.vehicleType.name}
- Monthly expenses: Gas \$${profile.expenses.gas}, Phone \$${profile.expenses.phone}, Insurance \$${profile.expenses.insurance}, Equipment \$${profile.expenses.equipment}, Health \$${profile.expenses.health}

Provide highly personalized, actionable tax and financial advice. Use specific dollar amounts. Be direct and practical.''';
}

Future<ClaudeAnalysis?> fetchGigAnalysis(UserProfile profile) async {
  final key = _apiKey();
  if (key.isEmpty) return null;

  try {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': key,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 2000,
        'system': _buildSystemPrompt(profile),
        'messages': [
          {
            'role': 'user',
            'content':
                'Analyze this gig worker\'s tax situation and return ONLY valid JSON (no markdown) with this exact structure: {"deductions":[{"id":"uid","icon":"emoji","name":"name","explanation":"explanation","value":1234,"eligibility":"high|medium|low","category":"Category"}],"taxEstimate":{"selfEmployment":1234,"federal":1234,"state":1234,"total":1234,"monthly":1234,"quarterly":1234},"roadmap":[{"id":"rm-1","step":1,"title":"title","description":"description","deadline":"timeframe","priority":"high|medium|low","completed":false}]}. Provide 5-7 deductions and 4 roadmap steps for: ${profile.platforms.map((p) => p.name).join(', ')} in ${profile.state}.',
          }
        ],
      }),
    );

    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    final content = data['content']?[0]?['text'] ?? '';
    final match = RegExp(r'\{[\s\S]*\}').firstMatch(content);
    if (match == null) return null;
    final parsed = jsonDecode(match.group(0)!);

    return ClaudeAnalysis(
      deductions: (parsed['deductions'] as List).map((d) => Deduction.fromJson(d)).toList(),
      taxEstimate: TaxEstimate.fromJson(parsed['taxEstimate']),
      roadmap: (parsed['roadmap'] as List).map((r) => RoadmapStep.fromJson(r)).toList(),
    );
  } catch (_) {
    return null;
  }
}

Stream<String> streamChatMessage(List<Map<String, String>> messages, UserProfile profile) async* {
  final key = _apiKey();
  if (key.isEmpty) {
    yield "I'm GigFlow AI. Once the API key is configured, I'll give you personalized tax advice based on your gig work profile. Check out your Deductions tab for estimated savings!";
    return;
  }

  try {
    final request = http.Request('POST', Uri.parse(_apiUrl));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'x-api-key': key,
      'anthropic-version': '2023-06-01',
    });
    request.body = jsonEncode({
      'model': _model,
      'max_tokens': 1024,
      'stream': true,
      'system': _buildSystemPrompt(profile),
      'messages': messages,
    });

    final client = http.Client();
    final response = await client.send(request);
    if (response.statusCode != 200) {
      client.close();
      yield "I'm having trouble connecting. Please try again.";
      return;
    }

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      for (final line in chunk.split('\n')) {
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6).trim();
        if (data == '[DONE]') {
          client.close();
          return;
        }
        try {
          final parsed = jsonDecode(data);
          final text = parsed['delta']?['text'] ?? '';
          if (text is String && text.isNotEmpty) yield text;
        } catch (_) {}
      }
    }
    client.close();
  } catch (_) {
    yield "I'm having trouble connecting right now. Please check your internet connection and try again.";
  }
}
