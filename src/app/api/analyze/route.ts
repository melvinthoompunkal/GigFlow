import { NextRequest, NextResponse } from 'next/server';

const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

export async function POST(req: NextRequest) {
  const profile = await req.json();
  const apiKey = process.env.GEMINI_API_KEY;

  if (!apiKey) {
    return NextResponse.json({ error: 'GEMINI_API_KEY not set' }, { status: 500 });
  }

  const platformNames = (profile.platforms ?? []).join(', ');
  const platformBreakdown = Object.entries(profile.platformEarnings ?? {})
    .map(([p, amt]) => `${p}: $${amt}/mo`)
    .join(', ');

  const prompt = `You are GigFlow AI, a specialized financial advisor for gig economy workers.
Analyzing profile:
- Platforms: ${platformNames}
- Per-platform monthly earnings: ${platformBreakdown || `total $${profile.monthlyEarnings}/mo`}
- Monthly total: $${profile.monthlyEarnings}
- Annual estimated: $${profile.monthlyEarnings * 12}
- Filing status: ${profile.filingStatus}
- Dependents: ${profile.dependentCount ?? 0} (Child Tax Credit: $${(profile.dependentCount ?? 0) * 2000}/yr)
- Monthly rent/mortgage: $${profile.monthlyRent ?? 0}
- State: ${profile.state}
- Housing: ${profile.housingType}
- Home office: ${profile.hasHomeOffice}
- Vehicle: ${profile.vehicleType}
- Monthly expenses: Gas $${profile.expenses?.gas}, Phone $${profile.expenses?.phone}, Insurance $${profile.expenses?.insurance}, Equipment $${profile.expenses?.equipment}, Health $${profile.expenses?.health}

Analyze this gig worker's tax situation and return ONLY valid JSON (no markdown, no code fences) with this exact structure:
{"deductions":[{"id":"unique-id","icon":"emoji","name":"name","explanation":"max 100 chars","value":1234,"eligibility":"high|medium|low","category":"Category"}],"taxEstimate":{"selfEmployment":1234,"federal":1234,"state":1234,"total":1234,"monthly":1234,"quarterly":1234},"roadmap":[{"id":"rm-1","step":1,"title":"title","description":"description","deadline":"timeframe","priority":"high|medium|low","completed":false}]}
Provide 5-7 deductions, accurate tax estimates for ${profile.state}, and 4 roadmap steps for platforms: ${platformNames}.`;

  try {
    const response = await fetch(`${GEMINI_API_URL}?key=${apiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { maxOutputTokens: 2000, temperature: 0.3 },
      }),
    });

    if (!response.ok) {
      const detail = await response.text();
      return NextResponse.json({ error: `Gemini API error: ${response.status}`, detail }, { status: response.status });
    }

    const data = await response.json();
    const content = data.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (!jsonMatch) return NextResponse.json({ error: 'No JSON in response' }, { status: 500 });

    return NextResponse.json(JSON.parse(jsonMatch[0]));
  } catch {
    return NextResponse.json({ error: 'Internal error' }, { status: 500 });
  }
}
