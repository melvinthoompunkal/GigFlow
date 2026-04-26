import { NextRequest, NextResponse } from 'next/server';

const CLAUDE_API_URL = 'https://api.anthropic.com/v1/messages';
const CLAUDE_MODEL = 'claude-haiku-4-5-20251001';

export async function POST(req: NextRequest) {
  const { messages, profile } = await req.json();
  const apiKey = process.env.ANTHROPIC_API_KEY;

  if (!apiKey) {
    return NextResponse.json({ error: 'ANTHROPIC_API_KEY not set' }, { status: 500 });
  }

  const platformBreakdown = Object.entries(profile?.platformEarnings ?? {})
    .map(([p, amt]) => `${p}: $${amt}/mo`)
    .join(', ');

  const system = `You are GigFlow AI, a friendly and knowledgeable financial advisor specializing in gig economy workers. Give practical, personalized tax and financial advice.

User's profile:
- Platforms: ${(profile?.platforms ?? []).join(', ')}
- Per-platform earnings: ${platformBreakdown || `total $${profile?.monthlyEarnings ?? 0}/mo`}
- Annual estimated: $${(profile?.monthlyEarnings ?? 0) * 12}
- Filing status: ${profile?.filingStatus ?? 'unknown'}
- Dependents: ${profile?.dependentCount ?? 0}
- State: ${profile?.state ?? 'unknown'}
- Housing: ${profile?.housingType ?? 'unknown'}
- Home office: ${profile?.hasHomeOffice ?? false}
- Vehicle: ${profile?.vehicleType ?? 'unknown'}
- Monthly rent/mortgage: $${profile?.monthlyRent ?? 0}
- Monthly expenses: Gas $${profile?.expenses?.gas ?? 0}, Phone $${profile?.expenses?.phone ?? 0}, Insurance $${profile?.expenses?.insurance ?? 0}

Keep responses concise (2-4 sentences unless detail is needed). Be specific with numbers. Plain text only — no markdown.`;

  // Build Claude messages array — must start with 'user' and alternate roles.
  // Flutter history includes the AI welcome message first, so drop leading assistant turns.
  const rawMessages = (messages as { role: string; content: string }[])
    .filter((m) => m.content.trim().length > 0)
    .map((m) => ({ role: m.role === 'user' ? 'user' : 'assistant', content: m.content }));

  const firstUserIdx = rawMessages.findIndex((m) => m.role === 'user');
  if (firstUserIdx < 0) {
    return NextResponse.json({ error: 'No user message found' }, { status: 400 });
  }

  // Trim leading assistant messages, then merge any consecutive same-role messages
  const trimmed = rawMessages.slice(firstUserIdx);
  const claudeMessages: { role: 'user' | 'assistant'; content: string }[] = [];
  for (const msg of trimmed) {
    const last = claudeMessages[claudeMessages.length - 1];
    if (last && last.role === msg.role) {
      last.content += '\n' + msg.content;
    } else {
      claudeMessages.push({ role: msg.role as 'user' | 'assistant', content: msg.content });
    }
  }

  try {
    const response = await fetch(CLAUDE_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: CLAUDE_MODEL,
        max_tokens: 512,
        system,
        messages: claudeMessages,
      }),
    });

    if (!response.ok) {
      const detail = await response.text();
      return NextResponse.json({ error: `Claude API error: ${response.status}`, detail }, { status: response.status });
    }

    const data = await response.json();
    const reply = data.content?.[0]?.text ?? "I'm having trouble responding right now. Please try again.";

    return NextResponse.json({ reply });
  } catch {
    return NextResponse.json({ error: 'Internal error' }, { status: 500 });
  }
}
