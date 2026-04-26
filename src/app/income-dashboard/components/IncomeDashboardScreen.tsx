'use client';
import React, { useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { motion } from 'framer-motion';
import { Bell, ToggleLeft, ToggleRight, TrendingUp, TrendingDown, AlertCircle, CheckCircle2 } from 'lucide-react';
import { useUserProfile } from '../../../context/UserProfileContext';
import { generateMonthlyData, generatePlatformBreakdown, calculateTaxBreakdown, calculateTaxHealthScore } from '../../../utils/taxCalculations';
import { PLATFORM_CONFIG, QUARTERLY_DEADLINES } from '../../../utils/constants';
import TabBar from '../../../components/TabBar';
import EarningsChart from './EarningsChart';

export default function IncomeDashboardScreen() {
  const router = useRouter();
  const { profile, activateDemoMode, resetProfile } = useUserProfile();
  const [showDemoToast, setShowDemoToast] = useState(false);

  const isReady = profile.isOnboarded || profile.isDemoMode;

  if (!isReady) {
    return (
      <div className="flex flex-col h-screen items-center justify-center px-6" style={{ background: '#0D0F12' }}>
        <div className="text-center">
          <div className="text-5xl mb-4">💰</div>
          <h2 className="text-xl font-bold mb-2" style={{ color: '#F0F2F5' }}>No profile yet</h2>
          <p className="text-sm mb-6" style={{ color: '#8B90A0' }}>Complete the onboarding survey to see your personalized dashboard.</p>
          <button
            onClick={() => router.push('/onboarding-survey')}
            className="px-6 py-3 rounded-xl font-semibold text-sm active:scale-95 transition-all"
            style={{ background: 'linear-gradient(135deg, #00C853, #00E676)', color: '#0D0F12' }}
          >
            Start Onboarding
          </button>
          <button
            onClick={() => { activateDemoMode(); setShowDemoToast(true); setTimeout(() => setShowDemoToast(false), 2500); }}
            className="block mx-auto mt-3 text-sm"
            style={{ color: '#8B90A0' }}
          >
            or try Demo Mode
          </button>
        </div>
        {showDemoToast && (
          <div className="fixed bottom-24 left-1/2 -translate-x-1/2 px-4 py-2 rounded-xl text-sm" style={{ background: '#1A1D23', border: '1px solid #00E676', color: '#00E676' }}>
            Demo mode activated ✓
          </div>
        )}
      </div>
    );
  }

  const monthlyData = useMemo(() => generateMonthlyData(profile.monthlyEarnings), [profile.monthlyEarnings]);
  const platformBreakdown = useMemo(() => generatePlatformBreakdown(profile.platforms, profile.monthlyEarnings), [profile.platforms, profile.monthlyEarnings]);
  const taxBreakdown = useMemo(() => profile.claudeAnalysis?.taxEstimate ?? calculateTaxBreakdown(profile), [profile]);
  const taxHealthScore = useMemo(() => calculateTaxHealthScore(profile), [profile]);

  const currentMonth = new Date().getMonth();
  const ytdEarnings = monthlyData.slice(0, currentMonth + 1).reduce((sum, d) => sum + d.earnings, 0);
  const thisMonthEarnings = monthlyData[currentMonth]?.earnings ?? 0;
  const lastMonthEarnings = currentMonth > 0 ? monthlyData[currentMonth - 1]?.earnings ?? 0 : 0;
  const monthOverMonth = lastMonthEarnings > 0 ? ((thisMonthEarnings - lastMonthEarnings) / lastMonthEarnings) * 100 : 0;
  const avgWeekly = Math.round(ytdEarnings / ((currentMonth + 1) * 4.33));

  return (
    <div className="flex flex-col h-screen overflow-hidden" style={{ background: '#0D0F12' }}>
      <div className="flex-1 overflow-y-auto scrollbar-hide pb-24">
        {/* Header */}
        <div className="px-5 pt-14 pb-4">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-xs uppercase tracking-widest mb-1" style={{ color: '#8B90A0', letterSpacing: '0.12em' }}>
                YTD GROSS EARNINGS
              </p>
              <motion.p
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                className="font-mono font-bold"
                style={{ color: '#00E676', fontSize: 36, fontFamily: 'DM Mono, monospace', lineHeight: 1.1 }}
              >
                ${ytdEarnings.toLocaleString()}
              </motion.p>
              <p className="text-xs mt-1" style={{ color: '#8B90A0' }}>
                Jan 1 – Apr 26, 2025
              </p>
            </div>
            <div className="flex items-center gap-3">
              <button
                onClick={() => {
                  if (profile.isDemoMode) { resetProfile(); } else { activateDemoMode(); }
                }}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs transition-all"
                style={{
                  background: profile.isDemoMode ? 'rgba(0,230,118,0.1)' : '#1A1D23',
                  border: profile.isDemoMode ? '1px solid #00E676' : '1px solid #2A2D35',
                  color: profile.isDemoMode ? '#00E676' : '#8B90A0',
                }}
              >
                {profile.isDemoMode ? <ToggleRight size={14} /> : <ToggleLeft size={14} />}
                Demo
              </button>
              <button className="w-9 h-9 rounded-full flex items-center justify-center" style={{ background: '#1A1D23', border: '1px solid #2A2D35' }}>
                <Bell size={18} color="#8B90A0" />
              </button>
            </div>
          </div>

          {/* Stat pills */}
          <div className="flex gap-3 mt-4">
            <div className="flex-1 flex items-center gap-2 px-3 py-2.5 rounded-xl" style={{ background: '#1A1D23', border: '1px solid #2A2D35' }}>
              <div>
                <p className="text-xs" style={{ color: '#8B90A0' }}>This Month</p>
                <p className="font-mono font-bold text-sm" style={{ color: '#F0F2F5', fontFamily: 'DM Mono, monospace' }}>
                  ${thisMonthEarnings.toLocaleString()}
                </p>
              </div>
              <div className="ml-auto flex items-center gap-1">
                {monthOverMonth >= 0 ? (
                  <TrendingUp size={14} color="#00E676" />
                ) : (
                  <TrendingDown size={14} color="#FF5252" />
                )}
                <span className="text-xs font-mono" style={{ color: monthOverMonth >= 0 ? '#00E676' : '#FF5252', fontFamily: 'DM Mono, monospace' }}>
                  {monthOverMonth >= 0 ? '+' : ''}{monthOverMonth.toFixed(1)}%
                </span>
              </div>
            </div>
            <div className="flex-1 flex items-center gap-2 px-3 py-2.5 rounded-xl" style={{ background: '#1A1D23', border: '1px solid #2A2D35' }}>
              <div>
                <p className="text-xs" style={{ color: '#8B90A0' }}>Avg / Week</p>
                <p className="font-mono font-bold text-sm" style={{ color: '#F0F2F5', fontFamily: 'DM Mono, monospace' }}>
                  ${avgWeekly.toLocaleString()}
                </p>
              </div>
              <div className="ml-auto">
                <span className="text-xs px-2 py-0.5 rounded-full" style={{ background: 'rgba(0,230,118,0.1)', color: '#00E676' }}>
                  /wk
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Platform breakdown cards */}
        {platformBreakdown.length > 0 && (
          <div className="mb-5">
            <div className="px-5 mb-3 flex items-center justify-between">
              <p className="text-sm font-semibold" style={{ color: '#F0F2F5' }}>Platform Breakdown</p>
              <p className="text-xs" style={{ color: '#8B90A0' }}>{profile.platforms.length} active</p>
            </div>
            <div className="flex gap-3 px-5 overflow-x-auto scrollbar-hide pb-1">
              {platformBreakdown.map(item => {
                const cfg = PLATFORM_CONFIG[item.platform as keyof typeof PLATFORM_CONFIG];
                if (!cfg) return null;
                return (
                  <PlatformCard key={`plat-card-${item.platform}`} platform={item.platform} cfg={cfg} monthly={item.monthly} share={item.share} trend={item.trend} />
                );
              })}
            </div>
          </div>
        )}

        {/* Earnings chart */}
        <div className="mx-5 mb-5 p-4 rounded-2xl" style={{ background: '#1A1D23', border: '1px solid #2A2D35' }}>
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className="text-sm font-semibold" style={{ color: '#F0F2F5' }}>Monthly Earnings</p>
              <p className="text-xs mt-0.5" style={{ color: '#8B90A0' }}>Jan – Dec 2025</p>
            </div>
            <div className="flex items-center gap-3">
              <div className="flex items-center gap-1.5">
                <div className="w-2 h-2 rounded-full" style={{ background: '#00E676' }} />
                <span className="text-xs" style={{ color: '#8B90A0' }}>Actual</span>
              </div>
              <div className="flex items-center gap-1.5">
                <div className="w-2 h-2 rounded-full" style={{ background: '#2A2D35', border: '1px dashed #4A4F5C' }} />
                <span className="text-xs" style={{ color: '#8B90A0' }}>Projected</span>
              </div>
            </div>
          </div>
          <EarningsChart data={monthlyData} />
        </div>

        {/* Tax snapshot */}
        <div className="px-5 mb-5">
          <p className="text-sm font-semibold mb-3" style={{ color: '#F0F2F5' }}>Tax Snapshot</p>
          <div className="grid grid-cols-2 gap-3">
            <TaxCard
              label="Q2 Estimated Tax"
              value={`$${taxBreakdown.quarterly.toLocaleString()}`}
              sublabel="Due Jun 17, 2025"
              accent="#FFB300"
              icon={<AlertCircle size={16} color="#FFB300" />}
              urgent
            />
            <TaxCard
              label="Monthly Set-Aside"
              value={`$${taxBreakdown.monthly.toLocaleString()}`}
              sublabel="Recommended savings"
              accent="#00E676"
              icon={<CheckCircle2 size={16} color="#00E676" />}
            />
            <TaxCard
              label="SE Tax (Annual)"
              value={`$${taxBreakdown.selfEmployment.toLocaleString()}`}
              sublabel="15.3% of net earnings"
              accent="#448AFF"
              icon={<TrendingUp size={16} color="#448AFF" />}
            />
            <TaxCard
              label="Total Tax Liability"
              value={`$${taxBreakdown.total.toLocaleString()}`}
              sublabel="SE + Federal + State"
              accent="#FF5252"
              icon={<TrendingDown size={16} color="#FF5252" />}
            />
          </div>
        </div>

        {/* Tax health meter */}
        <div className="mx-5 mb-5 p-4 rounded-2xl" style={{ background: '#1A1D23', border: '1px solid #2A2D35' }}>
          <div className="flex items-center justify-between mb-3">
            <div>
              <p className="text-sm font-semibold" style={{ color: '#F0F2F5' }}>Tax Health Score</p>
              <p className="text-xs mt-0.5" style={{ color: '#8B90A0' }}>Based on your profile completeness</p>
            </div>
            <span className="font-mono font-bold text-xl" style={{ color: taxHealthScore >= 70 ? '#00E676' : taxHealthScore >= 50 ? '#FFB300' : '#FF5252', fontFamily: 'DM Mono, monospace' }}>
              {taxHealthScore}
            </span>
          </div>
          <div className="w-full h-2.5 rounded-full mb-2" style={{ background: '#2A2D35' }}>
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: `${taxHealthScore}%` }}
              transition={{ duration: 0.8, ease: 'easeOut', delay: 0.3 }}
              className="h-full rounded-full"
              style={{
                background: taxHealthScore >= 70
                  ? 'linear-gradient(90deg, #00C853, #00E676)'
                  : taxHealthScore >= 50
                  ? 'linear-gradient(90deg, #E65100, #FFB300)'
                  : 'linear-gradient(90deg, #B71C1C, #FF5252)',
                boxShadow: taxHealthScore >= 70 ? '0 0 8px rgba(0, 230, 118, 0.4)' : 'none',
              }}
            />
          </div>
          <div className="flex justify-between">
            <span className="text-xs" style={{ color: '#8B90A0' }}>0</span>
            <span className="text-xs" style={{ color: '#8B90A0' }}>
              {taxHealthScore >= 70 ? '✅ Good standing' : taxHealthScore >= 50 ? '⚠️ Needs attention' : '🚨 Action required'}
            </span>
            <span className="text-xs" style={{ color: '#8B90A0' }}>100</span>
          </div>
        </div>

        {/* Quarterly timeline */}
        <div className="px-5 mb-6">
          <p className="text-sm font-semibold mb-3" style={{ color: '#F0F2F5' }}>Quarterly Deadlines</p>
          <div className="flex gap-3 overflow-x-auto scrollbar-hide pb-1">
            {QUARTERLY_DEADLINES.map(q => (
              <QuarterPill key={`q-${q.quarter}`} quarter={q} amount={taxBreakdown.quarterly} />
            ))}
          </div>
        </div>
      </div>

      <TabBar />
    </div>
  );
}

function PlatformCard({ platform, cfg, monthly, share, trend }: {
  platform: string;
  cfg: typeof PLATFORM_CONFIG[keyof typeof PLATFORM_CONFIG];
  monthly: number;
  share: number;
  trend: number[];
}) {
  const trendMax = Math.max(...trend, 1);
  return (
    <div
      className="flex-shrink-0 p-4 rounded-2xl"
      style={{ width: 140, background: '#1A1D23', border: '1px solid #2A2D35' }}
    >
      <div className="flex items-center gap-2 mb-3">
        <img 
          src={cfg.logo} 
          alt={cfg.label}
          className="w-5 h-5 object-contain"
        />
        <span className="text-xs font-medium" style={{ color: '#F0F2F5' }}>{cfg.label}</span>
      </div>
      <p className="font-mono font-bold text-base mb-1" style={{ color: '#F0F2F5', fontFamily: 'DM Mono, monospace' }}>
        ${monthly.toLocaleString()}
      </p>
      <p className="text-xs mb-3" style={{ color: '#8B90A0' }}>{Math.round(share * 100)}% of total</p>
      {/* Mini SVG bar chart */}
      <svg width="100%" height="32" viewBox="0 0 112 32" aria-label={`${cfg.label} earnings trend`}>
        {trend.map((val, i) => {
          const barH = Math.max(2, (val / trendMax) * 28);
          return (
            <rect
              key={`bar-${platform}-${i}`}
              x={i * 19}
              y={32 - barH}
              width={14}
              height={barH}
              rx={3}
              fill={i === trend.length - 1 ? '#00E676' : '#2A2D35'}
            />
          );
        })}
      </svg>
    </div>
  );
}

function TaxCard({ label, value, sublabel, accent, icon, urgent }: {
  label: string; value: string; sublabel: string; accent: string; icon: React.ReactNode; urgent?: boolean;
}) {
  return (
    <div
      className="p-4 rounded-2xl"
      style={{
        background: urgent ? `rgba(${accent === '#FFB300' ? '255, 179, 0' : '255, 82, 82'}, 0.06)` : '#1A1D23',
        border: urgent ? `1px solid rgba(${accent === '#FFB300' ? '255, 179, 0' : '255, 82, 82'}, 0.3)` : '1px solid #2A2D35',
      }}
    >
      <div className="flex items-center gap-1.5 mb-2">
        {icon}
        <span className="text-xs" style={{ color: '#8B90A0' }}>{label}</span>
      </div>
      <p className="font-mono font-bold text-lg" style={{ color: accent, fontFamily: 'DM Mono, monospace' }}>
        {value}
      </p>
      <p className="text-xs mt-0.5" style={{ color: '#8B90A0' }}>{sublabel}</p>
    </div>
  );
}

function QuarterPill({ quarter, amount }: { quarter: typeof QUARTERLY_DEADLINES[0]; amount: number }) {
  const statusColors = { paid: '#00E676', upcoming: '#FFB300', future: '#4A4F5C' };
  const statusBg = { paid: 'rgba(0,230,118,0.1)', upcoming: 'rgba(255,179,0,0.1)', future: '#1A1D23' };
  const color = statusColors[quarter.status as keyof typeof statusColors];
  const bg = statusBg[quarter.status as keyof typeof statusBg];

  return (
    <div
      className="flex-shrink-0 px-4 py-3 rounded-2xl"
      style={{ background: bg, border: `1px solid ${color}40`, minWidth: 160 }}
    >
      <div className="flex items-center justify-between mb-1">
        <span className="font-bold text-sm" style={{ color }}>
          {quarter.quarter}
        </span>
        <span
          className="text-xs px-2 py-0.5 rounded-full"
          style={{ background: `${color}20`, color }}
        >
          {quarter.status === 'paid' ? '✓ Paid' : quarter.status === 'upcoming' ? '⚡ Due Soon' : 'Upcoming'}
        </span>
      </div>
      <p className="font-mono font-bold" style={{ color: '#F0F2F5', fontFamily: 'DM Mono, monospace', fontSize: 18 }}>
        ${amount.toLocaleString()}
      </p>
      <p className="text-xs mt-1" style={{ color: '#8B90A0' }}>{quarter.deadline}</p>
    </div>
  );
}
