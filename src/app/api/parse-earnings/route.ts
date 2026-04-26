import { NextRequest, NextResponse } from 'next/server';

const GIG_PLATFORMS = ['uber', 'lyft', 'doordash', 'instacart', 'amazon_flex', 'grubhub', 'taskrabbit', 'fiverr', 'upwork', 'rover'] as const;

function parseCSVRow(row: string): string[] {
  const result: string[] = [];
  let current = '';
  let inQuotes = false;
  for (const char of row) {
    if (char === '"') { inQuotes = !inQuotes; continue; }
    if (char === ',' && !inQuotes) { result.push(current.trim()); current = ''; continue; }
    current += char;
  }
  result.push(current.trim());
  return result;
}

function detectPlatform(headers: string[]): typeof GIG_PLATFORMS[number] | 'unknown' {
  const h = headers.join(' ').toLowerCase();
  if (h.includes('fare') || h.includes('uber')) return 'uber';
  if (h.includes('ride type') || h.includes('lyft')) return 'lyft';
  if (h.includes('doordash') || h.includes('dash')) return 'doordash';
  if (h.includes('instacart') || h.includes('batch')) return 'instacart';
  if (h.includes('amazon') || h.includes('package')) return 'amazon_flex';
  if (h.includes('grubhub')) return 'grubhub';
  if (h.includes('taskrabbit') || h.includes('task')) return 'taskrabbit';
  if (h.includes('fiverr')) return 'fiverr';
  if (h.includes('upwork') || h.includes('contract')) return 'upwork';
  if (h.includes('rover')) return 'rover';
  return 'unknown';
}

function findColumnIndex(headers: string[], keywords: string[]): number {
  for (const kw of keywords) {
    const idx = headers.findIndex(h => h.toLowerCase().includes(kw));
    if (idx >= 0) return idx;
  }
  return -1;
}

export async function POST(req: NextRequest) {
  const formData = await req.formData();
  const file = formData.get('file') as File | null;

  if (!file) {
    return NextResponse.json({ error: 'No file uploaded' }, { status: 400 });
  }

  const text = await file.text();
  const lines = text.trim().split('\n').filter(l => l.trim());

  if (lines.length < 2) {
    return NextResponse.json({ error: 'CSV file is too short or empty' }, { status: 400 });
  }

  const headers = parseCSVRow(lines[0]);
  const platform = detectPlatform(headers);
  const amountIdx = findColumnIndex(headers, ['total', 'gross', 'earnings', 'amount', 'pay', 'revenue', 'income']);
  const dateIdx = findColumnIndex(headers, ['date', 'period', 'week', 'day']);

  if (amountIdx < 0) {
    return NextResponse.json({ error: 'Could not find an earnings column. Make sure the CSV has a "Total" or "Earnings" column.' }, { status: 400 });
  }

  let totalEarnings = 0;
  const byMonth: Record<string, number> = {};
  let rowsParsed = 0;

  for (let i = 1; i < lines.length; i++) {
    const cols = parseCSVRow(lines[i]);
    const rawAmount = cols[amountIdx]?.replace(/[$,\s]/g, '') ?? '';
    const amount = parseFloat(rawAmount);
    if (isNaN(amount) || amount <= 0) continue;

    totalEarnings += amount;
    rowsParsed++;

    if (dateIdx >= 0 && cols[dateIdx]) {
      const d = new Date(cols[dateIdx]);
      if (!isNaN(d.getTime())) {
        const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
        byMonth[key] = (byMonth[key] ?? 0) + amount;
      }
    }
  }

  if (rowsParsed === 0) {
    return NextResponse.json({ error: 'No valid earnings rows found in this CSV' }, { status: 400 });
  }

  const monthCount = Object.keys(byMonth).length || 1;

  return NextResponse.json({
    platform,
    totalEarnings: Math.round(totalEarnings * 100) / 100,
    monthlyAverage: Math.round(totalEarnings / monthCount),
    byMonth,
    rowsParsed,
  });
}
