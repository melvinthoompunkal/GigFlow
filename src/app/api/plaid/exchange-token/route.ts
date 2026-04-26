import { NextRequest, NextResponse } from 'next/server';
import { Configuration, PlaidApi, PlaidEnvironments } from 'plaid';

function getPlaidClient() {
  const clientId = process.env.PLAID_CLIENT_ID;
  const secret = process.env.PLAID_SECRET;
  const env = (process.env.PLAID_ENV ?? 'sandbox') as keyof typeof PlaidEnvironments;
  if (!clientId || !secret) return null;
  return new PlaidApi(new Configuration({
    basePath: PlaidEnvironments[env],
    baseOptions: { headers: { 'PLAID-CLIENT-ID': clientId, 'PLAID-SECRET': secret } },
  }));
}

const GIG_KEYWORDS = ['uber', 'lyft', 'doordash', 'instacart', 'amazon flex', 'grubhub', 'taskrabbit', 'fiverr', 'upwork', 'rover'];

export async function POST(req: NextRequest) {
  const { public_token } = await req.json();
  const plaid = getPlaidClient();
  if (!plaid) return NextResponse.json({ error: 'Plaid not configured' }, { status: 500 });

  try {
    const { data: exchangeData } = await plaid.itemPublicTokenExchange({ public_token });
    const accessToken = exchangeData.access_token;

    const endDate = new Date().toISOString().split('T')[0];
    const startDate = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

    const { data: txData } = await plaid.transactionsGet({
      access_token: accessToken,
      start_date: startDate,
      end_date: endDate,
    });

    // Plaid: negative amount = income (credit to account)
    const gigTxs = txData.transactions.filter(tx => {
      const name = (tx.merchant_name ?? tx.name).toLowerCase();
      return GIG_KEYWORDS.some(k => name.includes(k)) && tx.amount < 0;
    });

    const byPlatform: Record<string, number> = {};
    let total = 0;

    for (const tx of gigTxs) {
      const amount = Math.abs(tx.amount);
      total += amount;
      const name = (tx.merchant_name ?? tx.name).toLowerCase();
      const platform = GIG_KEYWORDS.find(k => name.includes(k)) ?? 'other';
      byPlatform[platform] = (byPlatform[platform] ?? 0) + amount;
    }

    return NextResponse.json({
      total: Math.round(total * 100) / 100,
      byPlatform,
      transactionCount: gigTxs.length,
      monthlyAverage: Math.round(total / 3),
    });
  } catch (err: unknown) {
    const msg = (err as { response?: { data?: { error_message?: string } } })?.response?.data?.error_message ?? 'Plaid error';
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
