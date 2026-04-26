import type { UserProfile, Deduction, TaxEstimate, RoadmapStep } from '../context/UserProfileContext';
import { FALLBACK_DEDUCTIONS, FALLBACK_TAX_ESTIMATE, FALLBACK_ROADMAP } from '../context/UserProfileContext';
import { PLATFORM_CONFIG } from './constants';

// Backend integration point: This calls Anthropic API directly from browser
// In production, proxy through a backend to protect API key
const CLAUDE_API_URL = 'https://api.anthropic.com/v1/messages';

function buildSystemPrompt(profile: UserProfile): string {
  const platformNames = profile.platforms.map(p => PLATFORM_CONFIG[p]?.label ?? p).join(', ');
  return `You are GigFlow AI, a specialized financial advisor for gig economy workers. 
You are analyzing the profile of a gig worker with the following details:
- Platforms: ${platformNames}
- Monthly earnings: $${profile.monthlyEarnings}
- Annual estimated: $${profile.monthlyEarnings * 12}
- Filing status: ${profile.filingStatus}
- Has dependents: ${profile.hasDependents}
- State: ${profile.state}
- Housing: ${profile.housingType}
- Home office: ${profile.hasHomeOffice}
- Vehicle: ${profile.vehicleType}
- Monthly expenses: Gas $${profile.expenses.gas}, Phone $${profile.expenses.phone}, Insurance $${profile.expenses.insurance}, Equipment $${profile.expenses.equipment}, Health $${profile.expenses.health}

Provide highly personalized, actionable tax and financial advice. Use specific dollar amounts. Be direct and practical.`;
}

function buildAnalysisPrompt(profile: UserProfile): string {
  return `Analyze this gig worker's tax situation and return ONLY valid JSON (no markdown, no explanation) with this exact structure:
{
  "deductions": [
    {
      "id": "unique-id",
      "icon": "emoji",
      "name": "Deduction name",
      "explanation": "Brief explanation (max 100 chars)",
      "value": 1234,
      "eligibility": "high|medium|low",
      "category": "Category name"
    }
  ],
  "taxEstimate": {
    "selfEmployment": 1234,
    "federal": 1234,
    "state": 1234,
    "total": 1234,
    "monthly": 1234,
    "quarterly": 1234
  },
  "roadmap": [
    {
      "id": "rm-1",
      "step": 1,
      "title": "Action title",
      "description": "Detailed description",
      "deadline": "Timeframe",
      "priority": "high|medium|low",
      "completed": false
    }
  ]
}
Provide 5-7 deductions, accurate tax estimates for ${profile.state}, and 4 roadmap steps tailored to this worker's platforms: ${profile.platforms.join(', ')}.`;
}

export async function fetchGigAnalysis(profile: UserProfile): Promise<{
  deductions: Deduction[];
  taxEstimate: TaxEstimate;
  roadmap: RoadmapStep[];
}> {
  const apiKey = process.env.NEXT_PUBLIC_ANTHROPIC_API_KEY;
  
  if (!apiKey) {
    console.warn('GigFlow: No API key found, using fallback data');
    return { deductions: FALLBACK_DEDUCTIONS, taxEstimate: FALLBACK_TAX_ESTIMATE, roadmap: FALLBACK_ROADMAP };
  }

  try {
    // Backend integration point: Replace with /api/analyze endpoint in production
    const response = await fetch(CLAUDE_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'anthropic-dangerous-direct-browser-access': 'true',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 2000,
        system: buildSystemPrompt(profile),
        messages: [{ role: 'user', content: buildAnalysisPrompt(profile) }],
      }),
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.status}`);
    }

    const data = await response.json();
    const content = data.content?.[0]?.text ?? '';
    
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (!jsonMatch) throw new Error('No JSON in response');
    
    const parsed = JSON.parse(jsonMatch[0]);
    return {
      deductions: parsed.deductions ?? FALLBACK_DEDUCTIONS,
      taxEstimate: parsed.taxEstimate ?? FALLBACK_TAX_ESTIMATE,
      roadmap: parsed.roadmap ?? FALLBACK_ROADMAP,
    };
  } catch (err) {
    console.error('GigFlow API error, using fallback:', err);
    return { deductions: FALLBACK_DEDUCTIONS, taxEstimate: FALLBACK_TAX_ESTIMATE, roadmap: FALLBACK_ROADMAP };
  }
}

export async function* streamChatMessage(
  messages: Array<{ role: 'user' | 'assistant'; content: string }>,
  profile: UserProfile
): AsyncGenerator<string> {
  const apiKey = process.env.NEXT_PUBLIC_ANTHROPIC_API_KEY;

  if (!apiKey) {
    yield "I'm GigFlow AI. It looks like the API key isn't configured yet. Once connected, I'll give you personalized tax advice based on your gig work profile. For now, check out your Deductions tab for estimated savings!";
    return;
  }

  try {
    // Backend integration point: Replace with /api/chat/stream endpoint in production
    const response = await fetch(CLAUDE_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'anthropic-dangerous-direct-browser-access': 'true',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 1024,
        stream: true,
        system: buildSystemPrompt(profile),
        messages,
      }),
    });

    if (!response.ok) throw new Error(`API error: ${response.status}`);
    if (!response.body) throw new Error('No response body');

    const reader = response.body.getReader();
    const decoder = new TextDecoder();

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      const chunk = decoder.decode(value);
      const lines = chunk.split('\n').filter(l => l.startsWith('data: '));

      for (const line of lines) {
        const data = line.slice(6);
        if (data === '[DONE]') return;
        try {
          const parsed = JSON.parse(data);
          const text = parsed.delta?.text ?? '';
          if (text) yield text;
        } catch {
          // skip malformed chunks
        }
      }
    }
  } catch (err) {
    console.error('Chat stream error:', err);
    yield "I'm having trouble connecting right now. Please check your internet connection and try again. Your financial data is still available in the Dashboard and Deductions tabs.";
  }
}