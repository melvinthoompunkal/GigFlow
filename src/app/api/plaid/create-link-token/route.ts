import { NextRequest, NextResponse } from 'next/server';
import { Configuration, PlaidApi, PlaidEnvironments, Products, CountryCode } from 'plaid';

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

export async function POST(_req: NextRequest) {
  const plaid = getPlaidClient();
  if (!plaid) {
    return NextResponse.json({ error: 'Plaid credentials not configured. Add PLAID_CLIENT_ID and PLAID_SECRET to .env' }, { status: 500 });
  }

  try {
    const res = await plaid.linkTokenCreate({
      user: { client_user_id: `gigflow-${Date.now()}` },
      client_name: 'GigFlow',
      products: [Products.Transactions],
      country_codes: [CountryCode.Us],
      language: 'en',
    });
    return NextResponse.json({ link_token: res.data.link_token });
  } catch (err: unknown) {
    const msg = (err as { response?: { data?: { error_message?: string } } })?.response?.data?.error_message ?? 'Plaid error';
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
