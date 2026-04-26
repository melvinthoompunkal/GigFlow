import { NextRequest, NextResponse } from 'next/server';
import { PDFDocument, StandardFonts, rgb } from 'pdf-lib';

const C = {
  green: rgb(0, 0.902, 0.463),
  dark: rgb(0.051, 0.059, 0.071),
  gray: rgb(0.545, 0.565, 0.627),
  white: rgb(1, 1, 1),
  card: rgb(0.102, 0.114, 0.137),
  border: rgb(0.165, 0.18, 0.208),
  greenDim: rgb(0, 0.5, 0.25),
};

function stripNonAscii(str: string): string {
  return (str ?? '').replace(/[^\x00-\x7F]/g, '').trim();
}

export async function POST(req: NextRequest) {
  const { profile } = await req.json();
  const analysis = profile?.claudeAnalysis;
  if (!analysis) return NextResponse.json({ error: 'No analysis data in profile' }, { status: 400 });

  const pdfDoc = await PDFDocument.create();
  const page = pdfDoc.addPage([612, 792]);
  const { width, height } = page.getSize();

  const bold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
  const regular = await pdfDoc.embedFont(StandardFonts.Helvetica);
  const oblique = await pdfDoc.embedFont(StandardFonts.HelveticaOblique);

  // ── Header ──
  page.drawRectangle({ x: 0, y: height - 70, width, height: 70, color: C.dark });
  page.drawText('GigFlow', { x: 36, y: height - 38, size: 26, font: bold, color: C.green });
  page.drawText('Tax & Earnings Report', { x: 152, y: height - 36, size: 14, font: regular, color: C.white });
  const today = new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });
  const meta = `${today}  |  ${profile.state || 'N/A'}  |  ${(profile.filingStatus || '').replace(/_/g, ' ')}`;
  page.drawText(meta, { x: 36, y: height - 56, size: 8, font: regular, color: C.gray });

  let y = height - 84;

  // ── Tax Summary ──
  page.drawText('TAX SUMMARY', { x: 36, y, size: 8, font: bold, color: C.gray });
  y -= 12;

  const tax = analysis.taxEstimate ?? {};
  page.drawRectangle({ x: 36, y: y - 46, width: width - 72, height: 50, color: C.card, borderColor: C.green, borderWidth: 1 });
  page.drawText('ESTIMATED TOTAL TAX OWED', { x: 48, y: y - 14, size: 8, font: bold, color: C.green });
  page.drawText(`$${(tax.total ?? 0).toLocaleString()}`, { x: 48, y: y - 34, size: 22, font: bold, color: C.white });
  page.drawText(`Set aside $${(tax.monthly ?? 0).toLocaleString()}/mo`, { x: 300, y: y - 18, size: 9, font: regular, color: C.gray });
  page.drawText(`Quarterly payment: $${(tax.quarterly ?? 0).toLocaleString()}`, { x: 300, y: y - 32, size: 9, font: regular, color: C.gray });
  y -= 58;

  const breakdowns = [
    { label: 'Self-Employment', value: tax.selfEmployment ?? 0 },
    { label: 'Federal Income', value: tax.federal ?? 0 },
    { label: 'State Income', value: tax.state ?? 0 },
  ];
  const colW = Math.floor((width - 80) / 3);
  breakdowns.forEach((item, i) => {
    const x = 36 + i * (colW + 4);
    page.drawRectangle({ x, y: y - 38, width: colW, height: 42, color: C.card });
    page.drawText(item.label, { x: x + 8, y: y - 14, size: 7.5, font: regular, color: C.gray });
    page.drawText(`$${item.value.toLocaleString()}`, { x: x + 8, y: y - 30, size: 13, font: bold, color: C.white });
  });
  y -= 50;

  // ── Deductions ──
  page.drawText('TOP DEDUCTIONS', { x: 36, y, size: 8, font: bold, color: C.gray });
  y -= 12;

  const deductions = (analysis.deductions ?? []).slice(0, 6);
  for (const ded of deductions) {
    page.drawRectangle({ x: 36, y: y - 30, width: width - 72, height: 34, color: C.card });
    page.drawText(stripNonAscii(ded.name ?? ''), { x: 48, y: y - 12, size: 9, font: bold, color: C.white });
    const exp = stripNonAscii(ded.explanation ?? '').substring(0, 82);
    page.drawText(exp, { x: 48, y: y - 23, size: 7.5, font: regular, color: C.gray });
    page.drawText(`$${(ded.value ?? 0).toLocaleString()}`, { x: width - 105, y: y - 14, size: 11, font: bold, color: C.green });
    const eligColor = ded.eligibility === 'high' ? C.green : C.gray;
    page.drawText((ded.eligibility ?? 'low').toUpperCase(), { x: width - 105, y: y - 25, size: 7, font: bold, color: eligColor });
    y -= 38;
  }

  const totalDed = deductions.reduce((s: number, d: { value?: number }) => s + (d.value ?? 0), 0);
  page.drawText(`Total potential deductions: $${totalDed.toLocaleString()}`, { x: 36, y, size: 8.5, font: bold, color: C.green });
  y -= 20;

  // ── Roadmap ──
  page.drawText('90-DAY ACTION ROADMAP', { x: 36, y, size: 8, font: bold, color: C.gray });
  y -= 12;

  const roadmap = (analysis.roadmap ?? []).slice(0, 4);
  for (const step of roadmap) {
    page.drawRectangle({ x: 36, y: y - 38, width: width - 72, height: 42, color: C.card });
    const numBg = step.priority === 'high' ? C.green : C.border;
    page.drawRectangle({ x: 44, y: y - 28, width: 20, height: 20, color: numBg });
    const numColor = step.priority === 'high' ? C.dark : C.white;
    page.drawText(String(step.step ?? ''), { x: 50, y: y - 20, size: 9, font: bold, color: numColor });
    page.drawText(stripNonAscii(step.title ?? ''), { x: 72, y: y - 14, size: 9, font: bold, color: C.white });
    const desc = stripNonAscii(step.description ?? '').substring(0, 86);
    page.drawText(desc, { x: 72, y: y - 26, size: 7.5, font: regular, color: C.gray });
    page.drawText(step.deadline ?? '', { x: width - 120, y: y - 20, size: 8, font: oblique, color: C.gray });
    y -= 48;
  }

  // ── Footer ──
  page.drawLine({ start: { x: 36, y: 46 }, end: { x: width - 36, y: 46 }, thickness: 0.5, color: C.border });
  page.drawText('For informational purposes only. Not professional tax or financial advice. Consult a licensed CPA.', {
    x: 36, y: 32, size: 7, font: oblique, color: C.gray,
  });
  page.drawText('Generated by GigFlow', { x: 36, y: 20, size: 7, font: regular, color: C.gray });

  const pdfBytes = await pdfDoc.save();
  return new NextResponse(Buffer.from(pdfBytes), {
    headers: {
      'Content-Type': 'application/pdf',
      'Content-Disposition': 'attachment; filename="gigflow-tax-report.pdf"',
    },
  });
}
