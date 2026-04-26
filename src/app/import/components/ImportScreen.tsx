'use client';
import React, { useState, useRef, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import { Building2, FileSpreadsheet, CheckCircle2, AlertCircle, ArrowRight, Loader2, Upload, X } from 'lucide-react';
import { usePlaidLink } from 'react-plaid-link';
import { useUserProfile } from '../../../context/UserProfileContext';
import type { Platform } from '../../../context/UserProfileContext';

type ImportResult = {
  source: 'plaid' | 'csv';
  platform?: string;
  totalEarnings: number;
  monthlyAverage: number;
  byPlatform?: Record<string, number>;
  rowsParsed?: number;
};

type State =
  | { phase: 'idle' }
  | { phase: 'plaid-loading' }
  | { phase: 'plaid-open'; linkToken: string }
  | { phase: 'processing' }
  | { phase: 'success'; result: ImportResult }
  | { phase: 'error'; message: string };

// Separate component so usePlaidLink hook is only mounted when we have a token
function PlaidOpener({
  linkToken,
  onSuccess,
  onExit,
}: {
  linkToken: string;
  onSuccess: (publicToken: string) => void;
  onExit: () => void;
}) {
  const { open, ready } = usePlaidLink({
    token: linkToken,
    onSuccess: (publicToken) => onSuccess(publicToken),
    onExit: () => onExit(),
  });

  useEffect(() => {
    if (ready) open();
  }, [ready, open]);

  return (
    <div className="flex flex-col items-center justify-center gap-3 py-12">
      <Loader2 size={32} color="#00E676" className="animate-spin" />
      <p className="text-sm" style={{ color: '#8B90A0' }}>Opening bank connection...</p>
      <button onClick={() => onExit()} className="text-xs mt-2" style={{ color: '#4A4F5C' }}>
        Cancel
      </button>
    </div>
  );
}

const GIG_PLATFORM_LABELS: Record<string, string> = {
  uber: 'Uber', lyft: 'Lyft', doordash: 'DoorDash', instacart: 'Instacart',
  amazon_flex: 'Amazon Flex', grubhub: 'Grubhub', taskrabbit: 'TaskRabbit',
  fiverr: 'Fiverr', upwork: 'Upwork', rover: 'Rover',
};

const KNOWN_PLATFORMS = Object.keys(GIG_PLATFORM_LABELS) as Platform[];

export default function ImportScreen() {
  const router = useRouter();
  const { updateProfile, activateDemoMode } = useUserProfile();
  const [state, setState] = useState<State>({ phase: 'idle' });
  const fileRef = useRef<HTMLInputElement>(null);

  const handleConnectBank = async () => {
    setState({ phase: 'plaid-loading' });
    try {
      const res = await fetch('/api/plaid/create-link-token', { method: 'POST' });
      const data = await res.json();
      if (!data.link_token) throw new Error(data.error ?? 'Failed to initialize Plaid');
      setState({ phase: 'plaid-open', linkToken: data.link_token });
    } catch (err: unknown) {
      setState({ phase: 'error', message: (err as Error).message });
    }
  };

  const handlePlaidSuccess = async (publicToken: string) => {
    setState({ phase: 'processing' });
    try {
      const res = await fetch('/api/plaid/exchange-token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ public_token: publicToken }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? 'Failed to fetch transactions');
      setState({
        phase: 'success',
        result: {
          source: 'plaid',
          totalEarnings: data.total,
          monthlyAverage: data.monthlyAverage,
          byPlatform: data.byPlatform,
        },
      });
    } catch (err: unknown) {
      setState({ phase: 'error', message: (err as Error).message });
    }
  };

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setState({ phase: 'processing' });
    try {
      const formData = new FormData();
      formData.append('file', file);
      const res = await fetch('/api/parse-earnings', { method: 'POST', body: formData });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? 'Failed to parse CSV');
      setState({
        phase: 'success',
        result: {
          source: 'csv',
          platform: data.platform,
          totalEarnings: data.totalEarnings,
          monthlyAverage: data.monthlyAverage,
          rowsParsed: data.rowsParsed,
        },
      });
    } catch (err: unknown) {
      setState({ phase: 'error', message: (err as Error).message });
    }
    if (fileRef.current) fileRef.current.value = '';
  };

  const handleUseData = useCallback(() => {
    if (state.phase !== 'success') return;
    const { result } = state;
    const updates: Partial<Parameters<typeof updateProfile>[0]> = {
      monthlyEarnings: result.monthlyAverage,
    };
    if (result.byPlatform) {
      const detectedPlatforms = Object.keys(result.byPlatform).filter(k =>
        KNOWN_PLATFORMS.includes(k as Platform)
      ) as Platform[];
      if (detectedPlatforms.length > 0) updates.platforms = detectedPlatforms;
    } else if (result.platform && KNOWN_PLATFORMS.includes(result.platform as Platform)) {
      updates.platforms = [result.platform as Platform];
    }
    updateProfile(updates);
    router.push('/onboarding-survey');
  }, [state, updateProfile, router]);

  const handleDemo = () => {
    activateDemoMode();
    router.push('/income-dashboard');
  };

  return (
    <div
      className="flex flex-col h-screen px-5 pt-12"
      style={{ background: '#0D0F12', maxWidth: 430, margin: '0 auto' }}
    >
      {/* Header */}
      <div className="mb-8">
        <button
          onClick={() => router.back()}
          className="flex items-center gap-1 text-xs mb-6"
          style={{ color: '#8B90A0' }}
        >
          <X size={14} /> Close
        </button>
        <h1 className="text-2xl font-bold mb-1" style={{ color: '#F0F2F5', fontFamily: 'DM Sans, sans-serif' }}>
          Import Your Earnings
        </h1>
        <p className="text-sm" style={{ color: '#8B90A0' }}>
          Connect your bank or upload a CSV to auto-fill your earnings data.
        </p>
      </div>

      <AnimatePresence mode="wait">
        {/* ── Idle: show choices ── */}
        {state.phase === 'idle' && (
          <motion.div key="idle" initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }}>
            {/* Plaid card */}
            <button
              onClick={handleConnectBank}
              className="w-full p-5 rounded-2xl mb-4 text-left transition-all active:scale-95"
              style={{ background: '#1A1D23', border: '1px solid #2A2D35' }}
            >
              <div className="flex items-center gap-4 mb-3">
                <div className="w-12 h-12 rounded-xl flex items-center justify-center" style={{ background: 'rgba(0,230,118,0.1)', border: '1px solid rgba(0,230,118,0.25)' }}>
                  <Building2 size={22} color="#00E676" />
                </div>
                <div>
                  <p className="font-semibold" style={{ color: '#F0F2F5' }}>Connect Your Bank</p>
                  <p className="text-xs mt-0.5" style={{ color: '#8B90A0' }}>Powered by Plaid</p>
                </div>
                <ArrowRight size={18} color="#4A4F5C" className="ml-auto" />
              </div>
              <p className="text-xs leading-relaxed" style={{ color: '#8B90A0' }}>
                Securely connect your bank account. We detect deposits from Uber, DoorDash, Lyft, and 7 other platforms automatically.
              </p>
              <div className="flex gap-2 mt-3">
                {['Instant', 'Read-only', 'Bank-grade encryption'].map(tag => (
                  <span key={tag} className="text-xs px-2 py-0.5 rounded-full" style={{ background: 'rgba(0,230,118,0.08)', color: '#00E676', border: '1px solid rgba(0,230,118,0.2)' }}>
                    {tag}
                  </span>
                ))}
              </div>
            </button>

            {/* CSV card */}
            <button
              onClick={() => fileRef.current?.click()}
              className="w-full p-5 rounded-2xl mb-6 text-left transition-all active:scale-95"
              style={{ background: '#1A1D23', border: '1px solid #2A2D35' }}
            >
              <div className="flex items-center gap-4 mb-3">
                <div className="w-12 h-12 rounded-xl flex items-center justify-center" style={{ background: 'rgba(68,138,255,0.1)', border: '1px solid rgba(68,138,255,0.25)' }}>
                  <FileSpreadsheet size={22} color="#448AFF" />
                </div>
                <div>
                  <p className="font-semibold" style={{ color: '#F0F2F5' }}>Upload Earnings CSV</p>
                  <p className="text-xs mt-0.5" style={{ color: '#8B90A0' }}>From any gig platform</p>
                </div>
                <Upload size={18} color="#4A4F5C" className="ml-auto" />
              </div>
              <p className="text-xs leading-relaxed" style={{ color: '#8B90A0' }}>
                Export your earnings from Uber, DoorDash, Lyft, Instacart, or any platform and upload the CSV here.
              </p>
              <div className="flex gap-2 mt-3">
                {['Uber', 'DoorDash', 'Lyft', 'Instacart'].map(p => (
                  <span key={p} className="text-xs px-2 py-0.5 rounded-full" style={{ background: 'rgba(68,138,255,0.08)', color: '#448AFF', border: '1px solid rgba(68,138,255,0.2)' }}>
                    {p}
                  </span>
                ))}
              </div>
            </button>

            <input ref={fileRef} type="file" accept=".csv" className="hidden" onChange={handleFileChange} />

            {/* Demo link */}
            <div className="text-center">
              <button onClick={handleDemo} className="text-sm" style={{ color: '#8B90A0' }}>
                or{' '}
                <span style={{ color: '#00E676' }}>explore with Demo Data</span>
                {' '}→
              </button>
            </div>
          </motion.div>
        )}

        {/* ── Plaid Loading ── */}
        {state.phase === 'plaid-loading' && (
          <motion.div key="plaid-loading" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            className="flex flex-col items-center justify-center py-16 gap-4">
            <Loader2 size={32} color="#00E676" className="animate-spin" />
            <p className="text-sm" style={{ color: '#8B90A0' }}>Initializing secure connection...</p>
          </motion.div>
        )}

        {/* ── Plaid Link Open ── */}
        {state.phase === 'plaid-open' && (
          <motion.div key="plaid-open" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
            <PlaidOpener
              linkToken={state.linkToken}
              onSuccess={handlePlaidSuccess}
              onExit={() => setState({ phase: 'idle' })}
            />
          </motion.div>
        )}

        {/* ── Processing ── */}
        {state.phase === 'processing' && (
          <motion.div key="processing" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            className="flex flex-col items-center justify-center py-16 gap-4">
            <Loader2 size={32} color="#00E676" className="animate-spin" />
            <p className="text-sm" style={{ color: '#8B90A0' }}>Analyzing your earnings data...</p>
          </motion.div>
        )}

        {/* ── Success ── */}
        {state.phase === 'success' && (
          <motion.div key="success" initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }}>
            <div className="p-5 rounded-2xl mb-4" style={{ background: 'rgba(0,230,118,0.06)', border: '1px solid rgba(0,230,118,0.3)' }}>
              <div className="flex items-center gap-3 mb-4">
                <CheckCircle2 size={22} color="#00E676" />
                <p className="font-semibold" style={{ color: '#00E676' }}>
                  {state.result.source === 'plaid' ? 'Bank connected!' : 'CSV imported!'}
                </p>
              </div>

              <div className="grid grid-cols-2 gap-3 mb-4">
                <div className="p-3 rounded-xl" style={{ background: '#1A1D23' }}>
                  <p className="text-xs mb-1" style={{ color: '#8B90A0' }}>
                    {state.result.source === 'plaid' ? '90-Day Total' : 'Total Found'}
                  </p>
                  <p className="text-lg font-bold font-mono" style={{ color: '#00E676', fontFamily: 'DM Mono, monospace' }}>
                    ${state.result.totalEarnings.toLocaleString()}
                  </p>
                </div>
                <div className="p-3 rounded-xl" style={{ background: '#1A1D23' }}>
                  <p className="text-xs mb-1" style={{ color: '#8B90A0' }}>Monthly Average</p>
                  <p className="text-lg font-bold font-mono" style={{ color: '#F0F2F5', fontFamily: 'DM Mono, monospace' }}>
                    ${state.result.monthlyAverage.toLocaleString()}
                  </p>
                </div>
              </div>

              {state.result.byPlatform && Object.keys(state.result.byPlatform).length > 0 && (
                <div>
                  <p className="text-xs mb-2" style={{ color: '#8B90A0' }}>Detected platforms</p>
                  <div className="flex flex-col gap-1.5">
                    {Object.entries(state.result.byPlatform).map(([k, v]) => (
                      <div key={k} className="flex items-center justify-between">
                        <span className="text-xs capitalize" style={{ color: '#F0F2F5' }}>
                          {GIG_PLATFORM_LABELS[k] ?? k}
                        </span>
                        <span className="text-xs font-mono" style={{ color: '#00E676', fontFamily: 'DM Mono, monospace' }}>
                          ${(v as number).toLocaleString()}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {state.result.platform && state.result.platform !== 'unknown' && !state.result.byPlatform && (
                <p className="text-xs mt-2" style={{ color: '#8B90A0' }}>
                  Detected platform: <span style={{ color: '#F0F2F5' }}>{GIG_PLATFORM_LABELS[state.result.platform] ?? state.result.platform}</span>
                  {state.result.rowsParsed ? ` · ${state.result.rowsParsed} rows` : ''}
                </p>
              )}
            </div>

            <button
              onClick={handleUseData}
              className="w-full h-14 rounded-xl font-semibold flex items-center justify-center gap-2 transition-all active:scale-95 mb-3"
              style={{ background: 'linear-gradient(135deg, #00C853, #00E676)', color: '#0D0F12', fontSize: 16, fontFamily: 'DM Sans, sans-serif' }}
            >
              Use This Data <ArrowRight size={18} />
            </button>
            <button
              onClick={() => setState({ phase: 'idle' })}
              className="w-full h-10 rounded-xl text-sm"
              style={{ color: '#8B90A0' }}
            >
              Try a different method
            </button>
          </motion.div>
        )}

        {/* ── Error ── */}
        {state.phase === 'error' && (
          <motion.div key="error" initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }}>
            <div className="p-5 rounded-2xl mb-4" style={{ background: 'rgba(255,82,82,0.06)', border: '1px solid rgba(255,82,82,0.3)' }}>
              <div className="flex items-center gap-3 mb-2">
                <AlertCircle size={20} color="#FF5252" />
                <p className="font-semibold text-sm" style={{ color: '#FF5252' }}>Something went wrong</p>
              </div>
              <p className="text-xs leading-relaxed" style={{ color: '#8B90A0' }}>{state.message}</p>
            </div>
            <button
              onClick={() => setState({ phase: 'idle' })}
              className="w-full h-12 rounded-xl font-semibold text-sm transition-all active:scale-95"
              style={{ background: '#1A1D23', border: '1px solid #2A2D35', color: '#F0F2F5' }}
            >
              Try Again
            </button>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
