import type { UserProfile, Deduction, TaxEstimate, RoadmapStep } from '../context/UserProfileContext';
import { FALLBACK_DEDUCTIONS, FALLBACK_TAX_ESTIMATE, FALLBACK_ROADMAP } from '../context/UserProfileContext';

export async function fetchGigAnalysis(profile: UserProfile): Promise<{
  deductions: Deduction[];
  taxEstimate: TaxEstimate;
  roadmap: RoadmapStep[];
}> {
  try {
    const response = await fetch('/api/analyze', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(profile),
    });

    if (!response.ok) throw new Error(`API error: ${response.status}`);

    const parsed = await response.json();
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
  try {
    const response = await fetch('/api/chat/stream', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ messages, profile }),
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

export async function downloadTaxReport(profile: UserProfile): Promise<void> {
  const response = await fetch('/api/report', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ profile }),
  });

  if (!response.ok) throw new Error('Failed to generate report');

  const blob = await response.blob();
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'gigflow-tax-report.pdf';
  a.click();
  URL.revokeObjectURL(url);
}