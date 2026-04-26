import { NextRequest, NextResponse } from 'next/server';

const CLAUDE_API_URL = 'https://api.anthropic.com/v1/messages';

export async function POST(req: NextRequest) {
  const { messages, profile } = await req.json();
  const apiKey = process.env.ANTHROPIC_API_KEY;

  if (!apiKey) {
    return new NextResponse('ANTHROPIC_API_KEY not set', { status: 500 });
  }

  const systemPrompt = `You are GigFlow AI, a specialized financial advisor for gig economy workers.
Analyzing profile:
- Platforms: ${(profile.platforms ?? []).join(', ')}
- Monthly earnings: $${profile.monthlyEarnings}
- Annual estimated: $${profile.monthlyEarnings * 12}
- Filing status: ${profile.filingStatus}
- Has dependents: ${profile.hasDependents}
- State: ${profile.state}
- Housing: ${profile.housingType}
- Home office: ${profile.hasHomeOffice}
- Vehicle: ${profile.vehicleType}
- Monthly expenses: Gas $${profile.expenses?.gas}, Phone $${profile.expenses?.phone}, Insurance $${profile.expenses?.insurance}, Equipment $${profile.expenses?.equipment}, Health $${profile.expenses?.health}
Provide highly personalized, actionable tax and financial advice. Use specific dollar amounts. Be direct and practical.`;

  const anthropicResponse = await fetch(CLAUDE_API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 1024,
      stream: true,
      system: systemPrompt,
      messages,
    }),
  });

  if (!anthropicResponse.ok) {
    return new NextResponse('Claude API error', { status: anthropicResponse.status });
  }

  return new NextResponse(anthropicResponse.body, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
    },
  });
}
